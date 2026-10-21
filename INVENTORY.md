# Inventory: what's inside Photobooth.exe

Everything in this repo was recovered from `reference/original/Photobooth.exe`
(5,114,696 bytes, SHA-256 `8237330b…d25b781`), an MDM Zinc projector. Run
`tools/extract_all.sh Photobooth.exe` to regenerate all of it. SWFs, JPEGs,
bitmaps, shaders, FLVs, MP4s and the ActionScript come out byte-identical.
The WebM files and the font differ only by encoder thread order and a font
timestamp.

## 1. Files in the projector

| Offset in exe | What | Recovered as |
|---|---|---|
| 393216 | Main app SWF (CWS, v10, 208,115 bytes uncompressed, 500×375 stage, 24 fps) | `reference/original/photobooth.swf` (same bytes as the SWF you uploaded) |
| 513786 | JPEG 640×480 | `backdrops/clouds.jpg` |
| 560697 | JPEG 640×480 | `backdrops/colored_dots.jpg` |
| 587142 | JPEG 640×480 | `backdrops/earth_rise.jpg` |
| 615926 | Backdrop SWF, 1329 frames | `Effel_Tower` |
| 1705449 | Backdrop SWF, 398 frames | `Fish` |
| 2423105 | Backdrop SWF, 1048 frames | `RollerCoaster` |
| 4396434 | Backdrop SWF, 421 frames | `Sunset` |
| 4688260 | Backdrop SWF, 600 frames | `Yosmite` (Karthik's spelling) |

The JPEGs sit right after the main SWF, which is how the app found them as
`images/*.jpg` beside it. `photo.jpg` (mentioned in the handoff) is not
referenced anywhere in the code.

**Backdrop SWFs** are not vector animations. Each one holds a single
`DefineVideoStream` (On2 VP6, 640×480, 24 fps), with no ActionScript and no
sound, so the timeline loops. The streams were exported as FLV
(`reference/backdrop_flv/`) and re-encoded as WebM (VP9) and MP4 (H.264),
with identical frame counts.

## 2. The main SWF

The handoff guessed Flex; it isn't. Karthik wrote his own small component
framework, and the only Flex classes are the `mx.core` asset wrappers the
compiler adds for `[Embed]`.

* 166 classes. The decompiled source is in `reference/as3/` (with the two
  Facebook and Flickr app *secrets* replaced by `REDACTED`).
* 12 bitmaps → `assets/`; 1 font → `assets/LucidaGrande.ttf`; 10 Pixel
  Bender kernels → `shaders/pbj/*.pbj`, with disassembly in `*.txt`.

### Layout

The 500×375 stage size in the SWF header is never used. The app sets
`StageScaleMode.NO_SCALE` and lays itself out on whatever stage the projector
window gives it:

* `AppSkin`: the wallpaper `AppSkin_Bmp.jpg` (1280×854), stretched over the
  whole stage.
* `MainShadowMock`: a rounded rectangle behind the window with
  `DropShadowFilter(1, 0, black, 1, 70, 70, 2, 3)`.
* `Main`: the 642×684 window, centred on the stage:
  * title "Karthik's PictureBooth" (11 px, #333333) at the top;
  * `ScreenContainer` (640×480) at (1, 23), with the `Viewer` on top of it;
  * `ControlBar` (640×59) at (1, 504);
  * `PhotoList` (588×98) at (27, 564), scroll buttons (26×98) at (1, 564)
    and (615, 564);
  * "N Photo(s)" (10 px, #393939) centred at the bottom.
* Credit line, bottom-right of the stage (10 px, #DDDDDD): "Created by
  Karthik Tharavaad, see http://tharavaad.wordpress.com/".
* `Flasher`: full-stage white overlay for the shutter flash.
* `GrowlManager`: 180 px notification boxes stacked from the stage's top-right.

### Framework (`com.karthik.*`)

| Class | Role |
|---|---|
| `KSprite` | Sprite whose `width`/`height` are stored values, not scale. |
| `KComponent` | Deferred validation: `invalidate()` queues the component, `KComponentGlobals` calls `commitProperties()` and `update()` on the next frame. Children are created when the component is first added. Options hash → properties via `HashUtil`. |
| `KSkin` | Drawing helpers driven by option hashes (`drawRect`, `drawKRoundRect`, `drawPath`, `drawCircle`, `drawRoundRect`; colour, gradient and bitmap fills). |
| `KButtonSkin`, `Button` | normal / over / down / disabled states. `disabled` changes the look only; clicks still fire. |
| `Label`, `Slider` | Text label; slider with thumb and track. |
| `TimerManager` | One 50 ms timer runs every callback; `frequency` is calls per second. All animation timing goes through it. |
| `LayoutAnimator`, `LayoutTarget`, `KState` | Eased layout: each 50 ms step moves `progress` of the remaining distance, in integer pixels. Also hides children outside the owner's bounds. |
| `PopUpManager`, `ArrayCollection`, `Singletons` | Pop-up layer with a white 40 % "blur" wash, observable array, per-class singletons. |

### App (`com.karthik.photobooth.*`)

| Class | What it does |
|---|---|
| `Model` | Main state (picture, effects, viewer), picture mode (1 or 4 shots), effect page 0–3, photos, selected photo, and the 36 effect slots. |
| `ScreenContainer` | Draws the webcam (mirrored) into a 640×480 bitmap 20 times a second and feeds it to the screens. Lays out a 3×3 grid per page (cells 192×144, filled column by column) or zooms the selected screen to 640×480. Owns the magnitude slider, the "step out" message box and the `BackgroundRemover`. Click-drag on a positional effect moves its centre. |
| `ControlBar` | Picture-mode bar (1 shot, 4 shots, video), shutter, Effects button with page arrows, four page dots, countdown, and the Download/Facebook/Flickr/Picasa buttons in viewer mode. The Picasa button is created but never shown. |
| `PhotoList`, `PhotoItem` | The strip of 86×88 thumbnails with index and delete button. New photos drop in from above. |
| `Viewer`, `View1Pic`, `View4Pic` | Shows a photo. The 4-shot card is a 2.5D object (focal length 1200, tilted −10°/−10°, z = 2000) with a blurred floor shadow; clicking zooms to a quadrant, clicking again zooms out. |
| `GrowlManager`, `GrowlBox` | Notifications with icon, bold header, body and a close button on hover. They time out after N seconds. |
| `FileEncodingPopup`, `FileCompleteBox`, `KPanel`, `TextButton` | The "Encoding…" progress box, then a modal "Complete" window whose Download button saves the file. |
| `ASJPEGEncoder` | Karthik's own baseline JPEG encoder (quality 50), sliced for progress events. |
| `web_interface/*`, `webapis/*` | Facebook (REST API) and Flickr (frob auth) login and upload. Dead services. |

### Behaviour

* **Start-up.** If `Camera.getCamera()` is null, only the wallpaper shows, plus
  a permanent "No Camera" growl. Otherwise the window appears, and a
  "Welcome!" growl follows after 1 s.
* **Modes.** Picture (live view of the selected effect), Effects (the 3×3
  grid; the dots and arrows change page), Viewer (a photo from the strip).
  Picking a grid cell switches to Picture mode with that effect. Returning to
  Picture mode with nothing selected picks the page's centre cell ("Normal").
* **Shutter.** The bar turns red and "3", "2", "1" glow in turn, one step every
  850 ms (`TimerManager` at 1.2 Hz). Then a white flash and the shot, which
  captures the selected screen including its filters. One-shot mode takes one
  photo; four-shot mode takes four, 850 ms apart, while the camera icon fills
  quadrant by quadrant. The new photo drops into the strip, and the app
  returns to live view once the drop animation ends. Clicking a strip photo
  opens the viewer.
* **Video.** The video button is drawn, but its click handler is empty. Video
  was never implemented.
* **Download.** "Encoding" growl with progress, then the "Complete" pop-up,
  then save. File names are `YourPhoto_`, `FourPic_`, `TopLeft_`, … plus the
  date.
* **Delete.** The ⊗ on a thumbnail removes it and selects a neighbour.

### The 36 effect slots

Pages fill column by column:

| Page | Column 1 | Column 2 | Column 3 |
|---|---|---|---|
| 1 | Sepia, Comic Book, Thermal Camera | Black and White, **Normal**, X-Ray | Glow, Sketch, Pop Art |
| 2 | Bulge, Pinch, Light Tunnel | Dent, **Normal**, Fish Eye | Twirl, Mirror, Stretch |
| 3 | Clouds, Effel Tower, RollerCoaster | Color Dots, **Normal**, Sunset | Earthrise, Fish, Yosmite |
| 4 | Upload ×3 | Upload, **Normal**, Upload | Upload ×3 |

| Effect | How it's made |
|---|---|
| Normal | Camera only. |
| Black and White | `ColorMatrixFilter` on the whole screen, weights (0.2225, 0.7169, 0.0606). |
| Sepia | PBJ `sepia`: RGB→YIQ, I = 0.16, Q = 0, back to RGB. |
| Comic Book | PBJ `HalfToneFilter`: R, G and B dot screens at three angles, spacing 5.5, max dot 5, gamma 0.8 (default), on black. |
| Thermal Camera | `paletteMap` through a 256×1 palette, each channel through its own palette channel. |
| X-Ray | `ColorMatrixFilter` invert. |
| Glow | Canvas saturated ×1.2. Over it, a copy with `BlurFilter(20, 20)` and a warm colour matrix, 90 % alpha, `HARDLIGHT`. |
| Sketch | Pencil texture (182×182, tiled) under the camera in `HARDLIGHT`, then a colour matrix on the whole screen. |
| Pop Art | Half-size frame, four times in a 2×2 grid, each through one row of the 256×4 palette. |
| Bulge | PBJ: k = 1 − m·e^(−r/(130m)). |
| Pinch | PBJ: k = (1 + 60ms/r^1.001)(1 − 0.3ms), s = W/640. Edges mirrored. |
| Dent | PBJ: zoom 1 + 0.8m inside 0.1mW, cosine falloff to 1 at mW/2. Edges mirrored. |
| Twirl | PBJ: angle 200°·m (`max_angle` default) × e^(−(r/R)²), R = 0.5·H·m. Edges mirrored. |
| Light Tunnel | PBJ: untouched inside radius 0.5·H·m; outside, the edge of that circle is streaked outward. |
| Fish Eye | PBJ: d / (cos(r/486)·1.5), defaults only, centred. |
| Stretch | PBJ: each axis squeezed by 1 − 0.67·e^(−(d/120s)²), centred. |
| Mirror | Left half mirrored onto the right. |
| Backdrops, Upload | PBJ `Chroma key` (see below) over a loaded image or looping video. Thumbnails show the first frame under a mannequin silhouette. Upload slots open a file picker. |

Bulge, Pinch, Dent, Twirl and Light Tunnel show the magnitude slider and
follow the mouse (click-drag) for their centre. Kernel parameters the
ActionScript never sets keep their Pixel Bender `defaultValue`: Twirl
`max_angle` 200; Fish Eye `cutoff` 486 and `scale` 1.5; Stretch `scale` 0.67
and `mag` 120; Comic Book `gamma` 0.8; Chroma key `thresh` 3 and weights
0.48 / 0.56 / 0.48.

### Background removal

1. Selecting a backdrop when no background is stored shows "Please step out
   of the Frame".
2. `BackgroundRemover` grabs a half-size frame every 2 s and differences it
   with the previous one (`BlendMode.DIFFERENCE`). Pixels whose red difference
   exceeds 0x11 are set to white, and the red channel is summed over the frame.
3. When 0 < sum < 550,000 (about 2,150 changed pixels out of 76,800), the
   scene is considered still. A full-size frame becomes the background for
   every backdrop screen, and "Background Detected" shows for about 3 s.
4. The kernel keeps a camera pixel only where its weighted YIQ distance from
   the stored background exceeds 0.003, so the person stands in front of the
   backdrop. The background stays stored until the app restarts.

### Assets

| File | Used by |
|---|---|
| `AppSkin_Bmp.jpg` | Wallpaper (the Mac OS X aqua swoosh). |
| `ShutterButtonSkinNormal_Norm.png`, `…_NormI.png` | Red shutter; grey "back to camera" shutter in the viewer. |
| `DLBtnSkin_Norm.png`, `FBBtnSkin_Norm.png`, `FlickrBtnSkin_Norm.png`, `PicasaBtnSkin_Norm.png` | Viewer buttons. |
| `GrowlBox_Icon.png`, `GrowlBox_IconDl.png` | Growl icons ("i" and download). |
| `ThermalScreen_Pallette.png` (256×1), `PopArtScreen_Pallette.png` (256×4) | Palette maps. |
| `SketchScreen_Sketch.jpg` | Pencil texture. |
| `LucidaGrande.ttf` | Lucida Grande regular, Basic Latin subset. Embedded but never switched on (`embedFonts` is never set), so Flash drew text with the installed font of that name. |

Everything else (buttons, bars, sliders, countdown camera, picture-mode
icons, mannequin) is drawn in code by the skin classes.

### Dead network code

`api.facebook.com/restserver.php`, `www.facebook.com/login.php`, and
`api.flickr.com/services/{auth,rest,upload}`. Picasa has a button but no
code.
