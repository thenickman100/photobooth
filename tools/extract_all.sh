#!/usr/bin/env bash
# Rebuilds every extracted file in this repo from the original Photobooth.exe.
#
#   tools/extract_all.sh path/to/Photobooth.exe [output-dir]
#
# Needs python3, java (for JPEXS FFDec, downloaded on first run) and ffmpeg
# with libvpx-vp9 and libx264. Output defaults to ./extracted; compare it with
# assets/, backdrops/, shaders/pbj/ and reference/.
set -euo pipefail

EXE=${1:?usage: tools/extract_all.sh Photobooth.exe [output-dir]}
OUT=${2:-extracted}
TOOLS=$(cd "$(dirname "$0")" && pwd)
FFDEC_VERSION=24.1.1
FFDEC_DIR="$TOOLS/.ffdec"

expected_sha=8237330be5e1939376a7648507ff672a10da6cf684c6abae55de987d6d25b781
actual_sha=$(sha256sum "$EXE" | cut -d' ' -f1)
[ "$actual_sha" = "$expected_sha" ] || echo "warning: $EXE is not the known Photobooth.exe ($actual_sha)" >&2

mkdir -p "$OUT"/{swf,assets,backdrops,shaders/pbj,reference/as3,reference/original,reference/backdrop_flv}

# 1. The six zlib-compressed SWFs and the three backdrop JPEGs.
python3 -I "$TOOLS/extract.py" "$EXE" "$OUT/swf"
python3 -I "$TOOLS/jpg.py" "$EXE" "$OUT/swf"
cp "$OUT/swf/jpg_513786.jpg" "$OUT/backdrops/clouds.jpg"
cp "$OUT/swf/jpg_560697.jpg" "$OUT/backdrops/colored_dots.jpg"
cp "$OUT/swf/jpg_587142.jpg" "$OUT/backdrops/earth_rise.jpg"

# 2. JPEXS Free Flash Decompiler.
if [ ! -f "$FFDEC_DIR/ffdec.jar" ]; then
   mkdir -p "$FFDEC_DIR"
   curl -sSL -o "$FFDEC_DIR/ffdec.zip" "https://github.com/jindrapetrik/jpexs-decompiler/releases/download/version$FFDEC_VERSION/ffdec_$FFDEC_VERSION.zip"
   (cd "$FFDEC_DIR" && unzip -q ffdec.zip)
fi
ffdec() { java -jar "$FFDEC_DIR/ffdec.jar" "$@"; }

# 3. Main SWF: ActionScript, bitmaps, Pixel Bender binaries, font.
MAIN="$OUT/swf/swf_393216_raw.swf"
ffdec -export script,image,binaryData,font "$OUT/swf/main" "$MAIN" > /dev/null
cp -r "$OUT/swf/main/scripts/." "$OUT/reference/as3/"
# Karthik's Facebook and Flickr app secrets are not republished.
sed -i 's/"secret":"[0-9a-f]*"/"secret":"REDACTED"/' "$OUT/reference/as3/com/karthik/photobooth/Main.as"
for f in "$OUT"/swf/main/images/*; do
   name=$(basename "$f" | sed -E 's/^[0-9]+_//; s/^com\.karthik\.photobooth\.([a-z_]+\.)*//')
   cp "$f" "$OUT/assets/$name"
done
cp "$OUT"/swf/main/fonts/*.ttf "$OUT/assets/LucidaGrande.ttf"
for f in "$OUT"/swf/main/binaryData/*.bin; do
   name=$(basename "$f" .bin | sed -E 's/.*\.([A-Za-z]+)Screen_PbjSource/\1/')
   cp "$f" "$OUT/shaders/pbj/$name.pbj"
   python3 -I "$TOOLS/pbjdis.py" "$OUT/shaders/pbj/$name.pbj" > "$OUT/shaders/pbj/$name.txt"
done

# 4. Backdrop SWFs: each holds one VP6 video stream (24 fps, 640x480, no
#    sound, no scripts, so the timeline loops). Re-encode for browsers.
while read -r offset name; do
   cp "$OUT/swf/swf_$offset.swf" "$OUT/reference/original/$name.swf"
   ffdec -export movie "$OUT/swf/movie_$name" "$OUT/swf/swf_${offset}_raw.swf" > /dev/null < /dev/null
   flv=$(find "$OUT/swf/movie_$name" -name '*.flv' | head -1)
   cp "$flv" "$OUT/reference/backdrop_flv/$name.flv"
   ffmpeg -nostdin -loglevel error -y -i "$flv" -an -c:v libvpx-vp9 -b:v 0 -crf 32 -row-mt 1 -deadline good -cpu-used 2 -pix_fmt yuv420p "$OUT/backdrops/$name.webm"
   ffmpeg -nostdin -loglevel error -y -i "$flv" -an -c:v libx264 -preset slow -crf 22 -pix_fmt yuv420p -profile:v high -movflags +faststart "$OUT/backdrops/$name.mp4"
done <<'EOF'
615926 Effel_Tower
1705449 Fish
2423105 RollerCoaster
4396434 Sunset
4688260 Yosmite
EOF

cp "$EXE" "$OUT/reference/original/Photobooth.exe"
cp "$OUT/swf/swf_393216.swf" "$OUT/reference/original/photobooth.swf"
echo "done: $OUT"
