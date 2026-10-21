# PhotoBooth for Windows: HTML5 rebuild

This project rebuilds Karthik Tharavaad's Flash app "PhotoBooth for Windows" as a standalone HTML5 app. The copy should look and behave like the original, but use the browser's webcam and WebGL.

The only input file is `Photobooth.exe`. Everything the app needs is inside it.

---

## 1. What the app is

- **Name:** PhotoBooth for Windows, a Windows 7–style clone of Apple's Mac Photo Booth.
- **Author:** Karthik Tharavaad. The app links to `http://tharavaad.wordpress.com/`, and its "No Camera" message gives an email address. Credit him in the app; don't publish the address.
- **Era:** AddictiveTips covered it on July 20, 2011 (https://www.addictivetips.com/?p=64192), describing a portable Windows app with webcam effects and Facebook and Flickr sharing.
- **Web version:** none found. No existing HTML5 project copies this specific app.
- **Packaging:** the exe is an **MDM Zinc** projector (the string `MDM %7` appears) wrapping Flash SWF files. Its PE timestamp (1992) is meaningless.

**Why a rebuild is needed.** The main SWF runs in Ruffle (tested with `@ruffle-rs/ruffle` 0.7.1 in Chromium with a fake webcam), but Ruffle has no webcam support. It logs `Encountered stub: AVM2 flash.media.Camera.getCamera()`, and the app shows only its "No Camera" pop-up. A Ruffle contributor said on https://github.com/ruffle-rs/ruffle/issues/5046 that the Camera API is "not yet fleshed out in ruffle". CheerpX for Flash is commercial and needs a Harman license, so it was ruled out.

---

## 2. What's inside the exe

`Photobooth.exe`: 5,114,696 bytes, SHA-256 `8237330be5e1939376a7648507ff672a10da6cf684c6abae55de987d6d25b781`.

The exe holds six CWS (zlib-compressed) SWF files, all SWF version 10. Byte offsets are within the exe.

| Offset | Uncompressed size | Stage | Frames | Contents | SHA-256 of uncompressed FWS |
|---|---|---|---|---|---|
| 393216 | 208,115 | 500×375, 24 fps | 1 | **The main app** (`com.karthik.photobooth`) | `f43f50f802e37e7b011ed98a12ab4e4d29c4957663a86cb03f8982bc0f7a20c1` |
| 615926 | 1,103,545 | 640×480, 24 fps | 1329 | Backdrop movie | `bab4e6a0768876d196519071faf330f4558c668f382eab741e6ec59c80252251` |
| 1705449 | 720,559 | 640×480, 24 fps | 398 | Backdrop movie | `3016d2ee7338df563e24863582f108807bff40b6bff35422c295d9c08c01a31c` |
| 2423105 | 1,978,969 | 640×480, 24 fps | 1048 | Backdrop movie | `44c81fd0b5cf759ddab3559b392bb04bd42dad245839f5d1ecdbfe23a97a1527` |
| 4396434 | 299,725 | 640×480, 24 fps | 421 | Backdrop movie | `72be4bcba71b959ee1ec9a0ec1481565110f30fb0d10674457753c01aa9d8485` |
| 4688260 | 435,070 | 640×480, 24 fps | 600 | Backdrop movie | `5640f3c21735df9b5171c957491a4078369244e17661673ae1e7eac47b9d2aff` |

The main app references these backdrop names: `Effel_Tower.swf`, `Fish.swf`, `RollerCoaster.swf`, `Sunset.swf` and `Yosmite.swf` (Karthik's spellings). It also references the images `clouds.jpg`, `colored_dots.jpg`, `earth_rise.jpg` and `photo.jpg`. **To do:** match each backdrop file to its name by viewing frame 1, and find where those four JPGs live. They may be inside the main SWF as JPEG tags.

Extraction script, which reproduces the six files:

```python
import re, struct, zlib
data = open('Photobooth.exe', 'rb').read()
for m in re.finditer(b'CWS', data):
    off = m.start(); ver = data[off+3]; ln = struct.unpack('<I', data[off+4:off+8])[0]
    d = zlib.decompressobj(); body = d.decompress(data[off+8:off+8+ln*2])
    if len(body) + 8 != ln: continue
    used = len(data[off+8:off+8+ln*2]) - len(d.unused_data) + 8
    open(f'swf_{off}.swf', 'wb').write(data[off:off+used])                                  # original CWS
    open(f'swf_{off}_raw.swf', 'wb').write(b'FWS' + bytes([ver]) + struct.pack('<I', ln) + body)  # uncompressed
```

### Main SWF contents
- **Code:** one `DoABC` block, about 140 KB of AS3. Flex 4/Spark-style skin classes appear, and the string `http://www.adobe.com/2006/flex/mx/internal` is present.
  - **To check:** whether the Flex framework is compiled in or loaded separately. The app did render under Ruffle, so whatever it needs at startup is present.
- **Shaders:** 10 `DefineBinaryData` tags, about 10 KB, holding the **Pixel Bender (.pbj) shaders**.
- **Images:** 10 `DefineBitsLossless2` and 2 `DefineBitsJPEG2` tags. Most of the interface is drawn by code in skin classes.
- **Font:** 1 `DefineFont3` (embedded font).
- **SymbolClass:** 24 symbols.

**Effect screens (17)**, from the class names:
- **Color effects (`screens.effects`):** BlackWhite, Sepia (PBJ), ComicBook (PBJ), Glow, PopArt (palette image), Sketch (sketch image), Thermal (palette image), Xray, Mirror.
- **Distortions (`screens.displacements`), all PBJ:** Bulge, Dent, Fisheye, LightTunnel, Pinch, Stretch, Twirl.
- **Background removal (`screens.bg_removed`):** BGRemoved (PBJ), plus `UploadBgScreen` for using your own image.
- **Other screens:** BaseScreen, PBJScreen, LoaderScreen.

**Embedded PBJ shaders (10):** Stretch, Dent, Fisheye, Bulge, BGRemoved, ComicBook, LightTunnel, Twirl, Sepia and Pinch (all `*Screen_PbjSource`).

**Code packages:** `control_bar`, `events`, `image`, `image.events`, `managers`, `model`, `photo_list_item`, `popups`, `screens…`, `skins…`, `viewer`, `web_interface`.

**Interface classes worth noting:**
- **Shell:** AppSkin, MainSkin, MainShadowMockSkin, ScreenContainerSkin.
- **Control bar:** ControlBar, ShutterButton, CountdownCamSkin, EffectsButton, PicModeButtonBar, PicModeVidSkin (a video mode appears to exist).
- **Photo strip:** PhotoList, PhotoItem, PhotoItemRendererSkin, ScrollBtnLeft/RightSkin, DeleteButtonSkin.
- **Pop-ups:** GrowlManager/GrowlBoxSkin, MsgBoxSkin, SimpleWindowSkin, PBSliderSkin, ProgressBarSkin.
- **Sharing:** FBBtnSkin, FlickrBtnSkin, PicasaBtnSkin, DLBtnSkin, FacebookAuthPop/FacebookUploadPop, FlickrAuthPop/FlickrUploadPop, UploadPopup, FileEncodingPopup.
- **Queues:** PhotoWebService, TimerManager, SaveQueueItem.

**Old service endpoints in the code (all dead):** Facebook `api.facebook.com/restserver.php` and `facebook.com/login.php?api_key=`, Flickr `api.flickr.com/services/{auth,rest,upload}`, and Picasa.

### Related open-source projects (for borrowing effect math only)
- https://github.com/yeegz/photoshoot (MIT): WebGL2 effects with many of the same names and background replacement. Very new.
- https://github.com/orangecoding/photobooth.js (MIT, 2014): Mac Photo Booth clone using Seriously.js. The author says its technology is outdated.
- Effect libraries: https://github.com/evanw/glfx.js and https://github.com/brianchirls/seriously.js.

The original PBJ shaders are the source of truth for the effects. These projects are only fallbacks.

---

## 3. The plan

### Step 1: Extract everything (report back before rebuilding)
1. Extract the six SWFs (script above).
2. Decompile the main SWF with **JPEXS Free Flash Decompiler (FFDec)**. It is Java and has a CLI, e.g. `ffdec -export script,image,binaryData,font,shape,sprite out/ swf_393216_raw.swf`. Export:
   - **Code:** AS3 source for every class.
   - **Images:** the bitmaps, including the palette and sketch images.
   - **Shaders:** the 10 `.pbj` binaries.
   - **Font:** the embedded font.
   - **Shapes:** any vector shapes and symbols used by skins.
3. Disassemble the PBJ shaders to readable kernels. Options: the PBJ format is documented; FFDec may show them; Ruffle's `naga-pixelbender` crate translates PBJ, and its source helps; or write a small disassembler.
4. Render the five backdrop SWFs to video (WebM, plus MP4 for Safari). Play each with Ruffle in Playwright and capture frames, or use FFDec's frame export, then encode with ffmpeg. Keep 640×480 at 24 fps, and loop if the original loops.
5. Write `INVENTORY.md`, listing every class, screen, asset and shader, and what each does, from reading the code.

Then report what was recovered and wait for a go-ahead.

### Step 2: Rebuild
- **Stack:** plain JavaScript, HTML and CSS, with no framework and no build step. The app is one self-contained folder (`index.html`, `photobooth.js`, `photobooth.css`, `shaders/`, `assets/`, `backdrops/`) that runs from any static host.
- **Code structure:** port the AS3 classes closely, keeping Karthik's structure and names where practical, so the copy can be checked against the decompiled source.
- **Effects:**
  - **PBJ kernels:** translate to GLSL fragment shaders (WebGL 1 or 2), with the same math and parameters.
  - **Flash built-in filters:** reproduce exactly the filters the decompiled code uses (`ColorMatrixFilter`, `GlowFilter`, palette maps, and so on).
- **Background removal:** follow Karthik's method from the code. It most likely captures an empty-background frame and then keys against it. Put the backdrop videos (and uploaded images) behind the keyed result.
- **Interface:** reproduce the skins from the skin code (vector drawing translates to canvas or CSS), using the extracted bitmaps and font. The behavior should match the original, including the shutter countdown, picture modes, effects picker, photo strip, viewer and delete.
- **Size:** the stage is **500×375 (4:3)**. The app should scale to fill whatever container it sits in, keeping 4:3.
- **Saving photos:** the Download button saves the photo as a file.
- **Sharing that can't work:** Facebook, Flickr and Picasa upload. Keep the buttons where they were, disabled, with a comment saying why. Comment out the dead network code instead of deleting it.
- **No camera, or permission denied:** show Karthik's own "No Camera" pop-up, as the original does.
- **Privacy:** everything stays in the browser. Nothing is uploaded anywhere.
- **Comments:** mark anything that differs from the original with a comment explaining the change.

### Step 3: Test
- **Browsers:** desktop Chrome, Firefox and Safari, plus a phone (front camera).
- **Fake webcam:** use Playwright with `--use-fake-device-for-media-stream`, and also a Y4M video through `--use-file-for-fake-video-capture` for repeatable effect checks.
- **Effect accuracy:** where possible, compare each effect against the original running in a real Flash Player, such as the Flash Player 32 projector or Flashpoint on Windows, fed the same test image as a virtual camera.

---

## 4. Open questions
1. **Credit line:** what wording should credit Karthik Tharavaad?
2. **Video mode:** the original seems to have a video mode (`PicModeVidSkin`). Should it record clips (browser `MediaRecorder`, saved as WebM), or stay disabled?
3. **GitHub repository:** which repository should the project live in?
