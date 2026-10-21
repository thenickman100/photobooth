# PhotoBooth for Windows, in HTML5

A one-to-one rebuild of **Karthik Tharavaad's "PhotoBooth for Windows"**
(2010–2011, http://tharavaad.wordpress.com/), a Flash clone of Apple's Photo
Booth. It runs in the browser using the webcam, WebGL and Canvas, with the
original's layout, skins, effects, backdrops, countdown, photo strip, 4-shot
viewer, download flow and messages.

Everything stays in the browser. No photo is uploaded anywhere.

## Running it

Serve the folder from any static host. The camera needs HTTPS or
`localhost`.

```sh
python3 -m http.server 8000
# open http://localhost:8000/
```

### Embedding

The app fills its container, so give a container element a size and start it:

```html
<link rel="stylesheet" href="photobooth/photobooth.css">
<div id="booth" class="photobooth" style="width: 800px; height: 760px"></div>
<script src="photobooth/flash.js"></script>
<script src="photobooth/karthik.js"></script>
<script src="photobooth/photobooth-screens.js"></script>
<script src="photobooth/photobooth.js"></script>
<script>photobooth.start(document.getElementById("booth"), { baseUrl: "photobooth/" });</script>
```

The window needs 642×684 plus margins (682×740). In a larger container it
shows at its original size, centred on the wallpaper, as in the original. A
smaller container scales it down to fit.

## How it's built

The original's ActionScript was decompiled and ported class by class, keeping
Karthik's names and structure, so the port can be checked against
`reference/as3/`:

| File | Contents |
|---|---|
| `flash.js` | The parts of the Flash API the app uses, rebuilt: display list, `Graphics`, text fields, mouse events, `BitmapData`, filters (blur, drop shadow, glow, colour matrix, Pixel Bender), masks, blend modes and the 2.5D used by the 4-shot viewer. Filters run in WebGL. |
| `karthik.js` | Karthik's UI framework (`com.karthik.*`): components, skins, timer manager, layout animator. |
| `photobooth-screens.js` | Model, skins, every effect screen, background removal, and stand-ins for Camera, Loader and FileReference. |
| `photobooth.js` | Main window, control bar, photo strip, viewer, growl pop-ups, the document class, and start-up. |
| `shaders/*.frag` | GLSL ports of the 10 Pixel Bender kernels. The originals and their disassembly are in `shaders/pbj/`. |
| `assets/`, `backdrops/` | Bitmaps and font from the SWF; backdrop images, plus the backdrop videos re-encoded from their SWFs. |
| `reference/` | The original `.exe`, all SWFs, the backdrop FLVs, the decompiled AS3 and the handoff notes. |
| `tools/` | `extract_all.sh` rebuilds every extracted file from the `.exe`; `pbjdis.py` is a Pixel Bender disassembler. |
| `INVENTORY.md` | Everything found in the `.exe`, and how the app works. |

## Differences from the original

Each one is marked with a `CHANGE:` comment in the code.

* **Facebook and Flickr upload** are disabled, because those APIs were shut
  down. The buttons stay where they were, dimmed, and the upload code is
  kept as comments. The Picasa button was never shown in the original either.
* **Camera.** Permission is requested up front. If it's refused, or there is
  no camera, you get Karthik's own "No Camera" message, as before. Modern
  16:9 and portrait cameras are centre-cropped to 4:3 instead of stretched.
* **Backdrop videos** play from WebM or MP4 instead of the original
  VP6-in-SWF files. Uploads accept JPG, GIF and PNG; SWF backdrops can't be
  played without Flash.
* **Saving** uses the browser's JPEG encoder at the original's quality (50).
  "Save Complete" appears as soon as the download starts, because browsers
  don't report when it finishes. File names keep Karthik's pattern, but with
  the correct month and day (the original wrote a 0-based month and the day
  of the week).
* **Size.** The projector ran at 1:1 in a desktop window. Embedded, the app
  scales down when its container is too small.
* **Font.** The embedded Lucida Grande subset is used. The original embedded
  it but never switched it on, so Flash used whatever font of that name was
  installed.

## Testing

`tests/walkthrough.js` drives the app in Chromium with a fake webcam. It
covers the effect pages, an effect with the slider and centre drag, the
countdown and shot, the viewer, download, 4-shot mode with quadrant zoom,
delete, and background removal. Screenshots go to `tests/out/`.

```sh
python3 -m http.server 8123 &
node tests/walkthrough.js http://localhost:8123/index.html [camera.y4m]
```

For background removal, the Y4M should show a still scene for about 8 s,
then movement; `tests/walkthrough.js` describes it.

So far it has been tested in Chromium (desktop and a 390×844 phone viewport)
with a fake camera. Firefox, Safari, real webcams and real phones have not
been tried yet. Neither has a side-by-side comparison with the original in a
real Flash Player.

## Credits

PhotoBooth for Windows was designed and written by Karthik Tharavaad. This
port keeps his credit line in the app: "Created by Karthik Tharavaad, see
http://tharavaad.wordpress.com/".

The wallpaper, the Lucida Grande font and the eight backdrops were bundled
with the original app and appear to come from Apple's Mac OS X and Photo
Booth. They are included here, unchanged, to keep the replica complete.
