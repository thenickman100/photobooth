/*
 * photobooth-screens.js - port of com.karthik.photobooth: platform shims
 * (Camera, Video, Loader, FileReference), embedded assets, the model, all
 * skins, and the effect screens. The UI shell is in photobooth.js.
 *
 * Every class follows the decompiled ActionScript in reference/as3/.
 * Comments starting with "CHANGE:" mark where this port differs from the
 * original, and why.
 */
(function (global) {
"use strict";

var F = global.flash, K = global.karthik;
var PB = global.photobooth = {};
var Singletons = K.Singletons, HashUtil = K.HashUtil, TimerManager = K.TimerManager;
var KComponent = K.KComponent, KSkin = K.KSkin, KButtonSkin = K.KButtonSkin, KSprite = K.KSprite;
var Event = F.Event, MouseEvent = F.MouseEvent, Matrix = F.Matrix, Point = F.Point, Rectangle = F.Rectangle, BitmapData = F.BitmapData;

// ---------------------------------------------------------------------------
// Embedded assets ([Embed] classes in the SWF). Filled in by the boot code.
// ---------------------------------------------------------------------------

var Assets = PB.Assets = { bitmaps: {} };
function embedded(name) { return Assets.bitmaps[name]; }

// ---------------------------------------------------------------------------
// Platform shims: flash.media.Camera / Video, flash.display.Loader,
// flash.net.FileReference
// ---------------------------------------------------------------------------

// CHANGE: Flash asked for the camera synchronously; browsers ask
// asynchronously. The boot code calls getUserMedia first and stores the
// result here, so Camera.getCamera() keeps its original meaning (null when
// there is no camera, or when permission is refused).
class Camera {
   constructor(videoEl) { this.videoEl = videoEl; }
   static getCamera() { return Camera._instance || null; }
   setMode(w, h, fps) {}
   setQuality(bandwidth, quality) {}
}
Camera._instance = null;
PB.Camera = Camera;

class Video extends F.MediaDisplay {
   constructor(w, h) { super(null, w, h); this.camera = null; }
   attachCamera(cam) { this.camera = cam; this.source = cam ? cam.videoEl : null; }
   // CHANGE: Flash stretched whatever mode the webcam picked into 640x480.
   // Webcams of 2011 were 4:3; modern ones are 16:9 and phones are portrait,
   // so the frame is centre-cropped to 4:3 instead of stretched.
   get crop() {
      var v = this.source;
      if (!v || !v.videoWidth) return null;
      var vw = v.videoWidth, vh = v.videoHeight, target = this._w / this._h;
      if (vw / vh > target) { var cw = vh * target; return { x: (vw - cw) / 2, y: 0, w: cw, h: vh }; }
      var ch = vw / target;
      return { x: 0, y: (vh - ch) / 2, w: vw, h: ch };
   }
}
PB.Video = Video;

class PerspectiveProjection { constructor() { this.focalLength = 500; this.projectionCenter = null; } }
PB.PerspectiveProjection = PerspectiveProjection;

// A loaded SWF movie (one of the backdrops), now an HTML video.
class MovieClip extends F.MediaDisplay {
   constructor(videoEl) { super(videoEl, videoEl.videoWidth, videoEl.videoHeight); }
   gotoAndPlay(frame) {
      var v = this.source;
      v.currentTime = 0;
      var p = v.play();
      if (p && p.catch) p.catch(function () {});
      this.live = true;
   }
   gotoAndStop(frame) {
      var v = this.source;
      v.pause();
      if (v.currentTime !== 0) v.currentTime = 0;
      this.live = false;
      this._invalidate();
      var self = this;
      v.addEventListener("seeked", function () { self._invalidate(); }, { once: true });
   }
}
PB.MovieClip = MovieClip;

class URLRequest { constructor(url) { this.url = url; } }
PB.URLRequest = URLRequest;

var videoExt = null;
function backdropVideoExt() {
   if (videoExt) return videoExt;
   var v = document.createElement("video");
   videoExt = v.canPlayType('video/webm; codecs="vp9"') ? "webm" : "mp4";
   return videoExt;
}

class Loader {
   constructor() { this.contentLoaderInfo = new F.EventDispatcher(); this.content = null; }
   // CHANGE: the original loaded "images/<name>.jpg|swf" from beside the
   // projector. The JPEGs now live in backdrops/, and each SWF (which only
   // held a VP6 video) is replaced by the same video re-encoded as WebM/MP4.
   load(req) {
      var url = req.url, m = /^images\/(.+)\.(jpg|swf)$/i.exec(url), isMovie = false;
      if (m) {
         isMovie = m[2].toLowerCase() === "swf";
         url = (PB.baseUrl || "") + "backdrops/" + m[1] + "." + (isMovie ? backdropVideoExt() : "jpg");
      }
      var self = this;
      fetch(url).then(function (res) {
         if (!res.ok) throw new Error(res.status + " " + url);
         var total = Number(res.headers.get("content-length")) || 0, loaded = 0, chunks = [];
         var reader = res.body && res.body.getReader ? res.body.getReader() : null;
         if (!reader) return res.blob();
         return (function pump() {
            return reader.read().then(function (r) {
               if (r.done) return new Blob(chunks, { type: res.headers.get("content-type") || "" });
               chunks.push(r.value);
               loaded += r.value.length;
               self.contentLoaderInfo.dispatchEvent(new F.ProgressEvent(F.ProgressEvent.PROGRESS, loaded, total || loaded));
               return pump();
            });
         })();
      }).then(function (blob) {
         self._fromBlob(blob, isMovie);
      }).catch(function (err) {
         console.error(err);
         self.contentLoaderInfo.dispatchEvent(new F.IOErrorEvent(F.IOErrorEvent.IO_ERROR));
      });
   }
   loadBytes(bytes) { this._fromBlob(new Blob([bytes]), false); }
   _fromBlob(blob, isMovie) {
      var self = this, url = URL.createObjectURL(blob);
      if (isMovie) {
         var v = document.createElement("video");
         v.muted = true; v.loop = true; v.playsInline = true; v.preload = "auto";
         v.setAttribute("playsinline", ""); v.setAttribute("muted", "");
         v.addEventListener("loadeddata", function () {
            self.content = new MovieClip(v);
            self.contentLoaderInfo.dispatchEvent(new Event(Event.INIT));
         }, { once: true });
         v.src = url;
         v.load();
      } else {
         var img = new Image();
         img.onload = function () {
            self.content = new F.MediaDisplay(img, img.naturalWidth, img.naturalHeight);
            self.contentLoaderInfo.dispatchEvent(new Event(Event.INIT));
         };
         img.src = url;
      }
   }
   unload() {}
}
PB.Loader = Loader;

class FileFilter { constructor(description, extension, macType) { this.description = description; this.extension = extension; } }
PB.FileFilter = FileFilter;

class FileReference extends F.EventDispatcher {
   constructor() { super(); this.data = null; this.file = null; }
   browse(filters) {
      var self = this, input = document.createElement("input");
      input.type = "file";
      var exts = [];
      (filters || []).forEach(function (f) {
         f.extension.split(";").forEach(function (e) {
            e = e.replace("*", "");
            // CHANGE: uploading a .swf as a backdrop can't work without a
            // Flash player, so the picker offers only the image formats.
            if (e && e !== ".swf") exts.push(e);
         });
      });
      input.accept = exts.join(",");
      input.style.display = "none";
      input.addEventListener("change", function () {
         if (input.files && input.files[0]) {
            self.file = input.files[0];
            self.dispatchEvent(new Event(Event.SELECT));
         }
         input.remove();
      });
      input.addEventListener("cancel", function () { self.dispatchEvent(new Event(Event.CANCEL)); input.remove(); });
      document.body.appendChild(input);
      input.click();
      return true;
   }
   load() {
      var self = this;
      this.file.arrayBuffer().then(function (buf) {
         self.data = buf;
         self.dispatchEvent(new Event(Event.COMPLETE));
      });
   }
   // CHANGE: browsers report nothing back after a download starts, so the
   // COMPLETE event (which shows "Save Complete") fires straight away.
   save(data, name) {
      var self = this;
      var blob = data instanceof Blob ? data : new Blob([data], { type: "image/jpeg" });
      var url = URL.createObjectURL(blob), a = document.createElement("a");
      a.href = url;
      a.download = name;
      document.body.appendChild(a);
      a.click();
      a.remove();
      setTimeout(function () { URL.revokeObjectURL(url); }, 60000);
      setTimeout(function () { self.dispatchEvent(new Event(Event.COMPLETE)); }, 0);
   }
}
PB.FileReference = FileReference;

// ---------------------------------------------------------------------------
// com.karthik.photobooth.Model and events
// ---------------------------------------------------------------------------

class Model extends F.EventDispatcher {
   constructor() {
      super();
      this._mainState = 1;
      this.screens = ["sepia", "comic_book", "thermal", "black_white", "normal", "xray", "glow", "sketch", "popart",
         "bulge", "pinch", "light_tunnel", "dent", "normal", "fish_eye", "twirl", "mirror", "stretch",
         "clouds", "effel_tower", "rollercoaster", "color_dots", "normal", "sunset", "earthrise", "fish", "yosemite",
         "upload", "upload", "upload", "upload", "normal", "upload", "upload", "upload", "upload"];
      this.photos = new K.ArrayCollection([]);
      this.pic4Buffer = [];
      this._picMode = 1;
      this._effectScreenHScroll = 0;
      this._selectedPhotoIndex = 0;
   }
   set picMode(v) { if (v === this.picMode) return; this._picMode = v; this.dispatchEvent(new Event("picModeChange")); }
   get picMode() { return this._picMode; }
   set effectScreenHScroll(v) {
      v = v < 0 ? 0 : (v > Model.MAX_SCREEN_HSCROLL ? Model.MAX_SCREEN_HSCROLL : v);
      if (v === this.effectScreenHScroll) return;
      this._effectScreenHScroll = v;
      this.dispatchEvent(new Event("screenHScrollChange"));
   }
   get effectScreenHScroll() { return this._effectScreenHScroll; }
   set selectedPhotoIndex(v) { if (v === this.selectedPhotoIndex) return; this._selectedPhotoIndex = v; this.dispatchEvent(new Event("selectedPhotoChange")); }
   get selectedPhotoIndex() { return this._selectedPhotoIndex; }
   set mainState(v) { if (v === this.mainState) return; this._mainState = v; this.dispatchEvent(new Event("modeChange")); }
   get mainState() { return this._mainState; }
}
Model.MODE_PIC = 1;
Model.MODE_EFFECTS = 2;
Model.MODE_TAKING_PIC = 5;
Model.MODE_VIEWER = 3;
Model.MODE_TAKING_VIDEO = 4;
Model.MAX_SCREEN_HSCROLL = 3;
Model.PIC_MODE_1PIC = 1;
Model.PIC_MODE_4_PIC = 2;
PB.Model = Model;

class ModeChangeEvent extends Event {
   constructor() { super(ModeChangeEvent.MODE_CHANGE, true); this.targetMode = 0; }
}
ModeChangeEvent.MODE_CHANGE = "modeChange";
PB.ModeChangeEvent = ModeChangeEvent;

class PhotoItemEvent extends Event {
   constructor(type) { super(type); this.index = 0; }
}
PhotoItemEvent.TYPE_PHOTO_SELECT = "photoSelect";
PhotoItemEvent.TYPE_PHOTO_DELETE = "photoDelete";
PB.PhotoItemEvent = PhotoItemEvent;

var ItemTypes = { TYPE_1PIC: "type_1pic", TYPE_4PIC: "type_4pic", TYPE_VIDEO: "type_video" };
PB.ItemTypes = ItemTypes;

class Item1Pic {
   constructor(bmp) { this._bmp = bmp; }
   get type() { return ItemTypes.TYPE_1PIC; }
   get dateTaken() { return new Date(); }
   get itemData() { return [this._bmp]; }
}
PB.Item1Pic = Item1Pic;

class Item4Pic {
   constructor(tl, tr, bl, br) { this.bmpTL = tl; this.bmpTR = tr; this.bmpBL = bl; this.bmpBR = br; }
   get itemData() { return [this.bmpTL, this.bmpTR, this.bmpBL, this.bmpBR]; }
   getComposite() {
      var half = new BitmapData(this.bmpTL.width / 2, this.bmpTL.height / 2);
      var out = new BitmapData(this.bmpTL.width, this.bmpTL.height);
      half.draw(this.bmpTL, new Matrix(0.5, 0, 0, 0.5));
      out.copyPixels(half, half.rect, new Point(0, 0));
      half.draw(this.bmpTR, new Matrix(0.5, 0, 0, 0.5));
      out.copyPixels(half, half.rect, new Point(half.width, 0));
      half.draw(this.bmpBL, new Matrix(0.5, 0, 0, 0.5));
      out.copyPixels(half, half.rect, new Point(0, half.height));
      half.draw(this.bmpBR, new Matrix(0.5, 0, 0, 0.5));
      out.copyPixels(half, half.rect, new Point(half.width, half.height));
      return out;
   }
   get dateTaken() { return new Date(); }
   get type() { return ItemTypes.TYPE_4PIC; }
}
PB.Item4Pic = Item4Pic;

// ---------------------------------------------------------------------------
// Skins (com.karthik.photobooth.skins.*)
// ---------------------------------------------------------------------------

class MainSkin extends KSkin {
   draw(t) {
      this.clear(t);
      this.drawKRoundRect({ target: t, width: t.width, height: t.height, lineStyle: { thickness: 1, color: 8947848, alpha: 0.5 }, fillStyle: { color: 4210752, alpha: 1 }, radius: 8 });
      this.drawKRoundRect({ target: t, x: 1, y: 1, width: t.width - 1, height: 21, lineStyle: { alpha: 0 }, fillStyle: { color: 15197412, alpha: 1 }, radius: 8, faceDown: true });
      this.drawKRoundRect({ target: t, x: 1, y: 2, width: t.width - 1, height: 20, lineStyle: { thickness: 0, alpha: 0 },
         fillStyle: { type: "gradient", colors: [12895428, 9934743], box: { width: t.width - 2, height: 20, x: 1, y: 2 } }, radius: 8, faceDown: true });
      this.drawPath({ target: t, fillStyle: null, lineStyle: { color: 15197412, alpha: 1 }, pts: [[1, t.height - 21], [t.width - 1, t.height - 21]] });
      this.drawKRoundRect({ target: t, x: 1, y: t.height - 20, width: t.width - 1, height: 20, lineStyle: { thickness: 0, alpha: 0 },
         fillStyle: { type: "gradient", colors: [12895428, 9934743], box: { width: t.width - 2, height: 20, x: 1, y: t.height - 20 } }, radius: 8, faceUp: true });
   }
}
PB.MainSkin = MainSkin;

class MainShadowMockSkin extends KSkin {
   draw(t) {
      this.drawKRoundRect({ target: t, width: t.width, height: t.height, lineStyle: { thickness: 1, color: 8947848, alpha: 0 }, fillStyle: { color: 4210752, alpha: 0.5 }, radius: 8 });
   }
}

class ScreenContainerSkin extends KSkin {
   draw(t) {
      this.clear(t.graphics);
      this.drawRect({ target: t, width: t.width, height: t.height, lineStyle: null, fillStyle: { color: 0, alpha: 1 } });
   }
}

class SimpleWindowSkin extends KSkin {
   draw(t) {
      this.drawKRoundRect({ target: t, width: t.width, height: t.height, lineStyle: { thickness: 1, color: 8947848, alpha: 0.5 }, fillStyle: { color: 4210752, alpha: 1 }, radius: 8 });
      this.drawKRoundRect({ target: t, x: 1, y: 1, width: t.width - 1, height: 21, lineStyle: { alpha: 0 }, fillStyle: { color: 15197412, alpha: 1 }, radius: 8, faceDown: true });
      this.drawKRoundRect({ target: t, x: 1, y: 2, width: t.width - 1, height: 20, lineStyle: { thickness: 0, alpha: 0 },
         fillStyle: { type: "gradient", colors: [12895428, 9934743], box: { width: t.width - 2, height: 20, x: 1, y: 2 } }, radius: 8, faceDown: true });
   }
}
PB.SimpleWindowSkin = SimpleWindowSkin;

class PhotoListSkin extends KSkin {
   draw(t) {
      this.clear(t);
      this.drawRect({ target: t, lineStyle: null, fillStyle: { type: "gradient", colors: [5855577, 8816006, 10395294], alphas: [1, 1, 1], ratios: [0, 127, 255] } });
   }
}

class PBSliderSkin extends KSkin {
   draw(t, o) {
      var track = o.track, thumb = o.thumb;
      this.clear(t, track, thumb);
      var base = { target: t, lineStyle: null, fillStyle: { type: "color" } };
      this.drawRoundRect(base, { width: t.width, height: t.height, radius: 8, fillStyle: { color: 0, alpha: 0.6 } });
      this.drawCircle(base, { x: 39, y: t.height / 2, radius: 4, fillStyle: { color: 16777215, alpha: 1 } });
      this.drawCircle(base, { x: t.width - 36, y: t.height / 2, radius: 7, fillStyle: { color: 16777215, alpha: 1 } });
      this.drawCircle({ target: thumb, x: thumb.width / 2, y: thumb.height / 2, radius: Math.min(thumb.width, thumb.height) / 2,
         lineStyle: { thickness: 1, color: 14342617, alpha: 1 },
         fillStyle: { type: "gradient", box: { width: thumb.width, height: thumb.height }, colors: [4737098, 2960685] } });
      this.drawRoundRect({ target: track, lineStyle: { color: 10065814 }, fillStyle: { color: 5722448, alpha: 1 }, width: track.width, height: track.height, radius: 2 });
   }
}
PB.PBSliderSkin = PBSliderSkin;

class GrowlBoxSkin extends KSkin {
   draw(t) {
      this.clear(t);
      this.drawKRoundRect({ target: t, lineStyle: { thickness: 4, color: 0, alpha: 0.4 }, fillStyle: { type: "gradient", colors: [15332089, 11785200] }, radius: 5 });
   }
}

class GrowBoxCloseButtonSkin extends KButtonSkin {
   drawOver() { this.drawNormal(); }
   drawNormal() {
      this.drawCircle({ target: this.btn, x: 11, y: 11, radius: 11, lineStyle: { thickness: 2, color: 16777215, alpha: 1 }, fillStyle: { color: 0, alpha: 0.6 } });
      this.drawPath({ target: this.btn, lineStyle: { thickness: 2, color: 16777215, alpha: 1 }, pts: [[7, 7], [15, 15]] });
      this.drawPath({ target: this.btn, lineStyle: { thickness: 2, color: 16777215, alpha: 1 }, pts: [[15, 7], [7, 15]] });
      this.btn.filters = [];
   }
   drawDown() { this.drawNormal(); this.btn.filters = [new F.DropShadowFilter(0, 0, 0, 0.8, 10, 10, 1, 2, true)]; }
}

class ScrollBtnSkinBase extends KButtonSkin {
   drawDisabled() {
      this.drawRect({ lineStyle: { alpha: 0 }, fillStyle: { color: 14342874, alpha: 1 }, target: this.btn });
      this.drawLines(9013641);
      this.btn.filters = [];
   }
   drawNormal() {
      this.drawRect({ lineStyle: { alpha: 0 }, fillStyle: { color: 13553358, alpha: 1 }, target: this.btn });
      this.drawLines(4605510);
      this.btn.filters = [];
   }
   drawDown() {
      this.drawNormal();
      this.drawLines(0);
      this.btn.filters = [new F.DropShadowFilter(0, 0, 0, 0.8, 20, 30, 1, 2, true)];
   }
   drawOver() { this.drawNormal(); }
}

class ScrollBtnLeftSkin extends ScrollBtnSkinBase {
   drawLines(color) {
      var btn = this.btn;
      this.drawPath({ target: btn, lineStyle: { color: 15198183, alpha: 1, thickness: 1 }, fillStyle: null, pts: [[0, 0], [btn.width - 1, 0]] });
      this.drawPath({ target: btn, lineStyle: { color: 12171705, alpha: 1, thickness: 1 }, fillStyle: null, pts: [[0, 0], [0, btn.height - 1], [btn.width - 1, btn.height - 1]], closed: false });
      this.drawPath({ target: btn, lineStyle: { color: 4210752, alpha: 1, thickness: 1 }, fillStyle: null, pts: [[btn.width - 1, 0], [btn.width - 1, btn.height - 1]] });
      this.drawPath({ target: btn, lineStyle: { color: 4210752, alpha: 0, thickness: 1 }, fillStyle: { color: color, alpha: 1 }, pts: [[15, 42], [15, 55], [9, 48], [15, 42]], closed: true });
   }
}

class ScrollBtnRightSkin extends ScrollBtnSkinBase {
   drawLines(color) {
      var btn = this.btn, r = btn.width - 1;
      this.drawPath({ target: btn, lineStyle: { color: 15198183, alpha: 1, thickness: 1 }, fillStyle: null, pts: [[0, 0], [btn.width - 1, 0]] });
      this.drawPath({ target: btn, lineStyle: { color: 12171705, alpha: 1, thickness: 1 }, fillStyle: null, pts: [[r - 0, 0], [r - 0, btn.height - 1], [r - (btn.width - 1), btn.height - 1]], closed: false });
      this.drawPath({ target: btn, lineStyle: { color: 4210752, alpha: 1, thickness: 1 }, fillStyle: null, pts: [[r - (btn.width - 1), 0], [r - (btn.width - 1), btn.height - 1]] });
      this.drawPath({ target: btn, lineStyle: { color: 4210752, alpha: 0, thickness: 1 }, fillStyle: { color: color, alpha: 1 }, pts: [[r - 15, 42], [r - 15, 55], [r - 9, 48], [r - 15, 42]], closed: true });
   }
}
PB.ScrollBtnLeftSkin = ScrollBtnLeftSkin;
PB.ScrollBtnRightSkin = ScrollBtnRightSkin;

class DeleteButtonSkinVec extends KButtonSkin {
   drawOver() { this.drawDeleteBtn(6710886, 13948116, 1048575); }
   drawNormal() { this.drawDeleteBtn(11711154, 15329769, 16777215); }
   drawDeleteBtn(c1, c2, c3) {
      this.drawCircle({ target: this.btn, radius: 5.5, x: 5.5, y: 6.5, lineStyle: { alpha: 0 }, fillStyle: { color: c2, alpha: 1 } });
      this.drawCircle({ target: this.btn, radius: 5.5, x: 5.5, y: 5.5, lineStyle: { alpha: 0 }, fillStyle: { color: c1, alpha: 1 } });
      this.drawPath({ target: this.btn, lineStyle: { thickness: 1, color: c3, alpha: 1 }, fillStyle: null, pts: [[3, 3], [7, 7]] });
      this.drawPath({ target: this.btn, lineStyle: { thickness: 1, color: c3, alpha: 1 }, fillStyle: null, pts: [[3, 7], [7, 3]] });
   }
   drawDown() { this.drawDeleteBtn(3289650, 13092807, 11382189); }
}

class DeleteButtonSelectedSkinVec extends DeleteButtonSkinVec {
   drawOver() { this.drawDeleteBtn(16777215, 2651099, 2651099); }
   drawNormal() { this.drawDeleteBtn(13229302, 2651099, 2651099); }
   drawDown() { this.drawDeleteBtn(9611738, 2651099, 2651099); }
}

class PhotoItemRendererSkin extends KSkin {
   draw(t, o) {
      var item = o.data;
      if (!item) return;
      this.clear(t);
      var thumb = new BitmapData(80, 60);
      if (item instanceof Item1Pic) {
         thumb.draw(item.itemData[0], new Matrix(80 / 640, 0, 0, 60 / 480));
      } else if (item instanceof Item4Pic) {
         var q = new BitmapData(40, 30);
         q.draw(item.itemData[0], new Matrix(40 / 640, 0, 0, 30 / 480));
         thumb.copyPixels(q, q.rect, new Point(0, 0));
         q.draw(item.itemData[1], new Matrix(40 / 640, 0, 0, 30 / 480));
         thumb.copyPixels(q, q.rect, new Point(40, 0));
         q.draw(item.itemData[2], new Matrix(40 / 640, 0, 0, 30 / 480));
         thumb.copyPixels(q, q.rect, new Point(0, 30));
         q.draw(item.itemData[3], new Matrix(40 / 640, 0, 0, 30 / 480));
         thumb.copyPixels(q, q.rect, new Point(40, 30));
      }
      this.drawRect({ target: t, lineStyle: { alpha: 0 }, fillStyle: { type: "bmp", bmp: thumb }, width: 80, height: 60 });
   }
}
PB.PhotoItemRendererSkin = PhotoItemRendererSkin;

class PhotoItemSkin extends KSkin {
   constructor() {
      super();
      this.target = null;
      this.normalSkin = Singletons.getInstance(DeleteButtonSkinVec);
      this.gradColor = [16777215, 15658734];
      this.selectSkin = Singletons.getInstance(DeleteButtonSelectedSkinVec);
   }
   draw(t) {
      this.target = t;
      t.label.fontSize = 9;
      var base = { lineStyle: null, target: t, width: t.width, height: t.height };
      this.clear(t.graphics);
      this.drawRect(base, { fillStyle: { type: "gradient", colors: this.gradColor, box: { rotation: Math.PI / 2 } } });
      if (t.selected) {
         this.drawRoundRect(base, { fillStyle: { type: "color", color: 2651099, alpha: 1 }, x: 3, y: t.height - 20, width: t.width - 6, height: 15, radius: 15 });
         t.button.skin = this.selectSkin;
         t.label.fontColor = 16777215;
      } else {
         t.button.skin = this.normalSkin;
         t.label.fontColor = 8421504;
      }
      t.button.setActualSize(11, 12);
      t.button.move(5, t.height - 18);
      t.label.text = t.index.toString();
      var lw = t.label.getMeasuredWidth();
      t.label.move(t.width - lw - 10, t.height - 20);
      var item = t.data;
      if (!item) return;
      var data = item.itemData;
      var bmp = new BitmapData(80, 60);
      var s = 80 / 640;
      // The original passes (s/2, 0, s/2, 0) as (a, b, c, d), a matrix with
      // d = 0 that draws nothing, so this paints a plain white 80 x 60 box.
      // The thumbnail itself comes from PhotoItemRendererSkin on `render`.
      if (data.length === 4) {
         bmp.draw(data[0], new Matrix(s / 2, 0, s / 2, 0));
         bmp.draw(data[1], new Matrix(s / 2, 0, s / 2, 0, 40));
         bmp.draw(data[2], new Matrix(s / 2, 0, s / 2, 0, 0, 30));
         bmp.draw(data[3], new Matrix(s / 2, 0, s / 2, 0, 40, 30));
      } else {
         if (data.length !== 1) throw new Error("unkown data length assigned to the PhotoItem's data attribute");
         if (!(data[0] instanceof BitmapData)) throw new Error("video support not here yet...");
         bmp.draw(data[0], new Matrix(s, 0, s, 0));
      }
      t.graphics.beginBitmapFill(bmp);
      t.graphics.drawRect(3, 3, 80, 60);
      t.graphics.endFill();
   }
}
PB.PhotoItemSkin = PhotoItemSkin;

class ControlBarSkin extends KSkin {
   drawGreyBackground(t) {
      this.drawRect({ target: t, width: t.width, height: t.height - 1, y: 1, lineStyle: null,
         fillStyle: { type: "gradient", colors: [12763842, 9934743], box: { x: 0, y: 1, width: t.width, height: t.height - 1 } } });
      this.drawPath({ target: t, fillStyle: null, lineStyle: { color: 14408667, hint: false }, pts: [[0, 0], [t.width, 0]] });
   }
   drawRedBackground(t) {
      this.drawRect({ target: t, width: t.width, height: t.height - 1, y: 1, lineStyle: null,
         fillStyle: { type: "gradient", colors: [16729930, 15990784], box: { x: 0, y: 1, width: t.width, height: t.height - 1 } } });
      this.drawPath({ target: t, fillStyle: null, lineStyle: { color: 14408667, hint: false }, pts: [[0, 0], [t.width, 0]] });
   }
   draw(t) {
      this.clear(t);
      if (t.mode === 5) this.drawRedBackground(t);   // ControlBar.MODE_TAKING_PIC
      else this.drawGreyBackground(t);
   }
}
PB.ControlBarSkin = ControlBarSkin;

class LBSkin extends KButtonSkin {
   drawOver() { this.drawNormal(); }
   drawNormal() {
      var btn = this.btn;
      this.drawRect({ target: btn, lineStyle: null, fillStyle: { type: "gradient", colors: [16645629, 11382189] } });
      this.drawPath({ target: btn, fillStyle: null, lineStyle: { color: 4473924, thickness: 1, alpha: 1 }, pts: [[btn.width, 0], [btn.width, btn.height]] });
      var c = btn.disabled ? 10395294 : 0;
      this.drawPath({ target: btn, fillStyle: { type: "color", color: c, alpha: 1 }, closed: true, lineStyle: { color: c, thickness: 1, alpha: 1 },
         pts: [[30 - 6, 9], [30 - 13, 9], [30 - 13, 5], [30 - 21.5, 10.5], [30 - 13, 16], [30 - 13, 12], [30 - 6, 12]] });
   }
   drawDown() {
      this.drawNormal();
      if (this.btn.disabled) return;
      this.drawRect({ target: this.btn, lineStyle: null, fillStyle: { color: 0, alpha: 0.3 } });
   }
}

class RBSkin extends KButtonSkin {
   drawOver() { this.drawNormal(); }
   drawNormal() {
      var btn = this.btn;
      this.drawRect({ target: btn, lineStyle: null, fillStyle: { type: "gradient", colors: [16645629, 11382189] } });
      this.drawPath({ target: btn, fillStyle: null, lineStyle: { color: 4473924, thickness: 1, alpha: 1 }, pts: [[-1, 0], [-1, btn.height]] });
      var c = btn.disabled ? 10395294 : 0;
      this.drawPath({ target: btn, fillStyle: { type: "color", color: c, alpha: 1 }, closed: true, lineStyle: { color: c, thickness: 1, alpha: 1 },
         pts: [[6, 9], [13, 9], [13, 5], [21.5, 10.5], [13, 16], [13, 12], [6, 12]] });
   }
   drawDown() {
      this.drawNormal();
      if (this.btn.disabled) return;
      this.drawRect({ target: this.btn, lineStyle: null, fillStyle: { color: 0, alpha: 0.3 } });
   }
}

class EBSkinNormal extends KButtonSkin {
   constructor() { super(); this.efb = null; this.isEffects = false; }
   draw(t, o) {
      var left = o.left, right = o.right, label = o.label, mask1 = o.mask1, mask2 = o.mask2;
      this.efb = t;
      if (this.efb.mode === 2) {   // EffectsButton.MODE_EFFECTS
         this.isEffects = true;
         label.fontColor = 16777215;
      } else {
         this.isEffects = false;
         label.fontColor = 4802889;
      }
      left.skin = Singletons.getInstance(LBSkin);
      right.skin = Singletons.getInstance(RBSkin);
      super.draw(t, o);
      this.clear(mask1);
      this.drawKRoundRect({ lineStyle: null, target: mask1, x: 2, y: 1, width: t.width - 3, height: t.height - 2, fillStyle: { color: 0, alpha: 1 }, radius: 3 });
      this.clear(mask2);
      this.drawKRoundRect({ lineStyle: null, target: mask2, x: 2, y: 1, width: t.width - 3, height: t.height - 2, fillStyle: { color: 0, alpha: 1 }, radius: 3 });
   }
   drawDown() {
      this.drawKRoundRect(this.opt, { fillStyle: null, y: 1, lineStyle: { color: 13553358 } });
      if (this.isEffects) this.opt = HashUtil.mergeHash(this.opt, { fillStyle: { colors: [3355443, 6776679] } });
      else this.opt = HashUtil.mergeHash(this.opt, { fillStyle: { colors: [12040119, 8289918] } });
      this.drawKRoundRect(this.opt);
   }
   drawOver() { this.drawNormal(); }
   opSet() {
      this.opt = HashUtil.mergeHash(this.opt, {
         lineStyle: { type: "color", thickness: 1, alpha: 1, color: 4934475, hint: true },
         fillStyle: { type: "gradient", colors: [16645629, 11382189], box: { x: 0, y: 1, width: this.btn.width, height: this.btn.height - 1 } },
         height: this.btn.height - 2, width: this.btn.width - 2, radius: 3, y: 0, x: 1
      });
   }
   drawNormal() {
      this.drawKRoundRect(this.opt, { fillStyle: null, y: 1, lineStyle: { color: 13553358 } });
      if (this.isEffects) this.opt = HashUtil.mergeHash(this.opt, { fillStyle: { colors: [3355443, 6776679] } });
      this.drawKRoundRect(this.opt);
   }
}
PB.EBSkinNormal = EBSkinNormal;

class MacButtonSkin extends KButtonSkin {
   drawDisabled() { this.drawNormal(); }
   opSet() {
      this.opt = HashUtil.mergeHash(this.opt, {
         lineStyle: { type: "color", thickness: 1, alpha: 1, color: 4934475, hint: true },
         fillStyle: { type: "gradient", colors: [16645629, 11382189], box: { x: 0, y: 1, width: this.btn.width, height: this.btn.height - 1 } },
         height: this.btn.height - 2, width: this.btn.width - 2, radius: 3, y: 0, x: 1
      });
   }
   drawDown() {
      this.drawNormal();
      this.btn.filters = [new F.DropShadowFilter(0, 0, 0, 0.7, this.btn.width / 2, this.btn.height / 2, 1, 2, true)];
   }
   drawOver() { this.drawNormal(); }
   drawNormal() {
      this.drawKRoundRect(this.opt, { fillStyle: null, y: 1, lineStyle: { color: 2236962 } });
      this.drawKRoundRect(this.opt);
      this.btn.filters = [];
   }
}
PB.MacButtonSkin = MacButtonSkin;

// Download / Facebook / Flickr / Picasa buttons: a bitmap plus a filter.
class ServiceBtnSkin extends KButtonSkin {
   constructor(bmpName, shadowWhenNormal) { super(); this.bmpName = bmpName; this.shadowWhenNormal = shadowWhenNormal; }
   get normBmp() { return embedded(this.bmpName); }
   drawDown() { this.drawNormal(); this.btn.filters = [new F.GlowFilter(0, 0.3, 30, 30, 2, 1, true)]; }
   drawNormal() {
      this.drawRect({ target: this.btn, lineStyle: { alpha: 0 }, fillStyle: { type: "bmp", bmp: this.normBmp } });
      this.btn.filters = this.shadowWhenNormal ? [new F.DropShadowFilter(0, 0, 0, 0.8, 4, 4)] : [];
   }
   drawOver() { this.drawNormal(); }
}
class DLBtnSkin extends ServiceBtnSkin { constructor() { super("DLBtnSkin_Norm", true); } }
class FBBtnSkin extends ServiceBtnSkin { constructor() { super("FBBtnSkin_Norm", false); } }
class FlickrBtnSkin extends ServiceBtnSkin { constructor() { super("FlickrBtnSkin_Norm", false); } }
class PicasaBtnSkin extends ServiceBtnSkin { constructor() { super("PicasaBtnSkin_Norm", false); } }
PB.DLBtnSkin = DLBtnSkin; PB.FBBtnSkin = FBBtnSkin; PB.FlickrBtnSkin = FlickrBtnSkin; PB.PicasaBtnSkin = PicasaBtnSkin;

class ShutterButtonSkinNormal extends KButtonSkin {
   opSet() { this.opt = HashUtil.mergeHash(this.opt, { lineStyle: null, fillStyle: { type: "bmp" } }); }
   drawDown() { this.drawNormal(); this.btn.filters = [new F.DropShadowFilter(0, 0, 0, 0.8, 10, 10, 1, 2, true)]; }
   drawNormal() {
      var bmp = this.btn.inactive ? embedded("ShutterButtonSkinNormal_NormI") : embedded("ShutterButtonSkinNormal_Norm");
      this.drawRect(this.opt, { fillStyle: { bmp: bmp } });
      this.btn.filters = [];
   }
   drawOver() { this.drawNormal(); }
}
PB.ShutterButtonSkinNormal = ShutterButtonSkinNormal;

class CountdownCamSkin extends KSkin {
   constructor() {
      super();
      var s = new F.Sprite();
      this.drawCam(s.graphics, 0.2);
      this.alphaLess = this.bmpFromSprite(s);
      this.drawCam(s.graphics, 1);
      this.alphaMore = this.bmpFromSprite(s);
   }
   drawCam(g, a) {
      var r = 19, deg = Math.PI / 180;
      g.clear();
      g.beginFill(16777215, a);
      g.lineStyle(0, 0, 0);
      g.moveTo(19, 19);
      g.lineTo(38, 19);
      var k = 0.268;
      for (var i = 0; i < 12; i++) {
         var x = r * Math.cos((i + 1) * 30 * deg), y = r * Math.sin((i + 1) * 30 * deg);
         var cx = x + r * k * Math.cos(((i + 1) * 30 - 90) * deg), cy = y + r * k * Math.sin(((i + 1) * 30 - 90) * deg);
         g.curveTo(cx + r, cy + r, x + r, y + r);
      }
      g.moveTo(8, 10); g.lineTo(11, 10); g.lineTo(13, 8); g.lineTo(24, 8); g.lineTo(26, 10); g.lineTo(29, 10);
      g.lineTo(31, 12); g.lineTo(31, 26); g.lineTo(29, 28); g.lineTo(8, 28); g.lineTo(6, 26); g.lineTo(6, 12); g.lineTo(8, 10);
      g.endFill();
      g.lineStyle(2, 16777215, a);
      g.drawCircle(r, r, 5);
      g.endFill();
   }
   draw(t, o) {
      var glowMask = o.glowMask;
      this.clear(t);
      this.clear(glowMask);
      switch (t.state) {
         case 1: this.drawSprite(t, this.alphaLess); break;                                     // STATE_DIM
         case 2: this.drawSprite(glowMask, this.alphaMore); break;                              // STATE_BRIGHT
         case 3: this.drawSprite(t, this.alphaLess); this.drawSprite(glowMask, this.makeComp(1)); break;
         case 4: this.drawSprite(t, this.alphaLess); this.drawSprite(glowMask, this.makeComp(2)); break;
         case 5: this.drawSprite(t, this.alphaLess); this.drawSprite(glowMask, this.makeComp(3)); break;
      }
   }
   drawSprite(s, bmp) { this.drawRect({ target: s, width: 38, height: 38, lineStyle: { alpha: 0 }, fillStyle: { type: "bmp", bmp: bmp } }); }
   bmpFromSprite(s) { var b = new BitmapData(38, 38, true, 0); b.draw(s); return b; }
   makeComp(n) {
      var b = new BitmapData(38, 38, true, 0);
      switch (n) {
         case 3: b.copyPixels(this.alphaMore, new Rectangle(19, 19, 19, 19), new Point(19, 19));
         // falls through
         case 2: b.copyPixels(this.alphaMore, new Rectangle(19, 0, 19, 19), new Point(19, 0));
         // falls through
         case 1: b.copyPixels(this.alphaMore, new Rectangle(0, 0, 19, 19), new Point(0, 0));
      }
      return b;
   }
}
PB.CountdownCamSkin = CountdownCamSkin;

class PicModeSkinUtil {
   constructor() { this.rect = new Rectangle(0, 0, 0, 0); }
   make1PicIcon(c1, c2) {
      var b = this.baseBmp();
      b.fillRect(this.setRect(0, 0, 14, 12), c1);
      b.fillRect(this.setRect(2, 2, 10, 8), 0);
      b.fillRect(this.setRect(0, 12, 14, 1), c2);
      return b;
   }
   setRect(x, y, w, h) { this.rect.x = x; this.rect.y = y; this.rect.width = w; this.rect.height = h; return this.rect; }
   baseBmp() { return new BitmapData(14, 13, true, 0); }
   makeVidIcon(c1, c2) {
      var b = this.baseBmp();
      b.fillRect(this.setRect(0, 0, 14, 12), c1);
      b.fillRect(this.setRect(4, 2, 6, 3), 0);
      b.fillRect(this.setRect(4, 7, 6, 3), 0);
      [[1, 1], [1, 4], [1, 7], [1, 10], [12, 1], [12, 4], [12, 7], [12, 10]].forEach(function (p) { b.setPixel32(p[0], p[1], 0); });
      b.fillRect(this.setRect(0, 12, 14, 1), c2);
      return b;
   }
   make4PicIcon(c1, c2) {
      var b = this.baseBmp();
      b.fillRect(this.setRect(0, 0, 14, 12), c1);
      b.fillRect(this.setRect(2, 2, 4, 3), 0);
      b.fillRect(this.setRect(8, 2, 4, 3), 0);
      b.fillRect(this.setRect(2, 7, 4, 3), 0);
      b.fillRect(this.setRect(8, 7, 4, 3), 0);
      b.fillRect(this.setRect(0, 12, 14, 1), c2);
      return b;
   }
}

class PicModeIconSkin extends KButtonSkin {
   constructor(iconFn, hasDown) { super(); this.util = Singletons.getInstance(PicModeSkinUtil); this.iconFn = iconFn; this.hasDown = hasDown; }
   icon(bmp) {
      this.drawRect({ target: this.btn, lineStyle: { alpha: 0 }, fillStyle: { type: "bmp", bmp: bmp, matr: new Matrix(1, 0, 0, 1, 8, 5), repeat: false }, x: 8, y: 5, width: bmp.width, height: bmp.height });
   }
   drawDown() {
      if (!this.hasDown) { this.drawNormal(); return; }
      this.drawRect({ target: this.btn, lineStyle: { alpha: 0 }, fillStyle: { type: "gradient", colors: [2894892, 6579300] } });
      this.icon(this.util[this.iconFn](4294967295, 4281413937));
   }
   drawOver() { this.drawNormal(); }
   drawNormal() {
      this.drawRect({ target: this.btn, lineStyle: { alpha: 0 }, fillStyle: { type: "gradient", colors: [16645629, 11382189] } });
      if (this.iconFn === "makeVidIcon") this.icon(this.util.makeVidIcon(4287137928, 4293717228));
      else this.icon(this.util[this.iconFn](4278190080, 4292664540));
   }
}
class PicModePic1Skin extends PicModeIconSkin { constructor() { super("make1PicIcon", true); } }
class PicModePic4Skin extends PicModeIconSkin { constructor() { super("make4PicIcon", true); } }
// The video button never got a "down" look: video mode was never built.
class PicModeVidSkin extends PicModeIconSkin { constructor() { super("makeVidIcon", false); } }
PB.PicModePic1Skin = PicModePic1Skin; PB.PicModePic4Skin = PicModePic4Skin; PB.PicModeVidSkin = PicModeVidSkin;

class PicModeBtnBarSkin extends KSkin {
   draw(t, o) {
      var maskL = o.maskL, maskR = o.maskR;
      this.clear(maskL); this.clear(t); this.clear(maskR);
      this.drawKRoundRect({ lineStyle: { alpha: 0 }, target: maskL, fillStyle: { color: 5460819, alpha: 1 }, height: t.height - 3, width: t.width - 2, radius: 3, x: 1, y: 1 });
      this.drawKRoundRect({ lineStyle: { alpha: 0 }, target: maskR, fillStyle: { color: 5460819, alpha: 1 }, height: t.height - 3, width: t.width - 2, radius: 3, x: 1, y: 1 });
      this.drawKRoundRect({ lineStyle: { alpha: 0 }, target: t, fillStyle: { color: 5460819, alpha: 1 }, height: t.height - 1, radius: 3 });
      this.drawPath({ target: t, lineStyle: { color: 13158600, thickness: 1, alpha: 1 }, pts: [[3, t.height - 1], [t.width - 2, t.height - 1]] });
   }
}
PB.PicModeBtnBarSkin = PicModeBtnBarSkin;

class View4PicSkin extends KSkin {
   draw(t) { this.drawRect({ target: t, lineStyle: null, fillStyle: { type: "gradient", colors: [197379, 5263712] } }); }
}
PB.View4PicSkin = View4PicSkin;

class MsgBoxSkin extends KSkin {
   draw(t) {
      this.clear(t);
      this.drawKRoundRect({ radius: 4, target: t, lineStyle: { alpha: 0 }, fillStyle: { alpha: 0.5, color: 0 } });
   }
}

class ProgressBarSkin extends KSkin {
   draw(t) {
      this.drawRect({ target: t, lineStyle: { thickness: 1, alpha: 1, color: t.outLineColor }, fillStyle: null });
      var w = Math.round(t.progress * (t.width - 2));
      this.drawRect({ target: t, lineStyle: { alpha: 0 }, fillStyle: { alpha: 1, color: t.barColor }, x: 1, y: 1, width: w, height: t.height - 1 });
   }
}

// Mannequin outline shown on background-removal thumbnails.
class FigureSkin extends KSkin {
   draw(t, o) {
      var w = o.width | 0, h = o.height | 0;
      this.clear(t);
      var pts = [[12, 143], [22, 134], [28, 131], [34, 129], [40, 127], [48, 124], [57, 121], [64, 118], [67, 116], [70, 113], [73, 110], [75, 107], [74, 99], [72, 95], [70, 91], [69, 88], [69, 77], [65, 77], [64, 74], [63, 71], [62, 68], [62, 58], [63, 56], [62, 54], [61, 48], [61, 42], [62, 36], [63, 30], [65, 26], [67, 22], [69, 19], [74, 15], [78, 13], [83, 11], [88, 10], [92, 9]];
      for (var i = pts.length - 1; i >= 0; i--) {
         var p = pts[i];
         pts[i][1] += 1;
         pts.push([193 - p[0], p[1] | 0]);
      }
      var scaled = [];
      for (var j = 0; j < pts.length; j++) scaled.push([Math.round(w / 194 * pts[j][0]), Math.round(h / 144 * pts[j][1])]);
      this.drawPath({ target: t, lineStyle: { alpha: 0 }, fillStyle: { color: 0, alpha: 0.7 }, pts: scaled, closed: true });
   }
}

// ---------------------------------------------------------------------------
// Screens (com.karthik.photobooth.screens.*)
// ---------------------------------------------------------------------------

class BaseScreen extends KComponent {
   constructor() {
      super();
      this._bgBmp = null;
      this.lastBmp = null;
      this._magnitude = 0.5;
      this._usePosition = false;
      this.matr = new Matrix();
      this.screenName = "Normal";
      this._useBgBmp = false;
      this.drawBmp = null;
      this._useMsg = false;
      this.bmpInvalid = false;
      this.wasBmpResized = true;
      this._labelVisible = true;
      this.bgBitmapChanged = false;
      this.effectDirty = true;
      this._useSlider = false;
      this.canvas = null;
      this._centerX = 0.5;
      this._centerY = 0.5;
      this.label = null;
   }
   get bgBmp() { return this._bgBmp; }
   set bgBmp(v) { if (v === this.bgBmp) return; this._bgBmp = v; }
   get magnitude() { return this._magnitude; }
   set magnitude(v) { if (this._magnitude === v) return; this._magnitude = v; this.effectDirty = true; this.invalidate(); }
   forceUpdate(bmp) {
      if (!this.visible) return;
      this.lastBmp = bmp;
      this.bmpDraw();
   }
   set useSlider(v) { this._useSlider = v; }
   get useSlider() { return this._useSlider; }
   createChildren() {
      super.createChildren();
      this.canvas = new KSprite();
      this.addChild(this.canvas);
      this.createLabel();
   }
   get useMsg() { return this._useMsg; }
   set useMsg(v) { this._useMsg = v; }
   set usePosition(v) { this._usePosition = v; }
   get usePosition() { return this._usePosition; }
   get centerX() { return this._centerX; }
   set centerX(v) { if (this._centerX === v) return; this._centerX = v; this.effectDirty = true; this.invalidate(); }
   get centerY() { return this._centerY; }
   set centerY(v) { if (this._centerY === v) return; this._centerY = v; this.effectDirty = true; this.invalidate(); }
   set labelVisible(v) {
      if (this._labelVisible === v) return;
      this._labelVisible = v;
      this.label.visible = v;
      this.invalidate();
   }
   get labelVisible() { return this._labelVisible; }
   bmpTransformations() {}
   positionLabel() {
      this.label.validateNow();
      var w = this.label.getMeasuredWidth(), h = this.label.getMeasuredHeight();
      this.label.move((this.width - w) / 2, this.height - h - 10);
   }
   get useBgBmp() { return this._useBgBmp; }
   set useBgBmp(v) { this._useBgBmp = v; }
   createLabel() {
      this.label = new K.Label();
      this.label.filters = [new F.DropShadowFilter(0, 0, 0, 0.6, 5, 5, 1, 2)];
      this.label.text = this.screenName;
      this.label.fontSize = 14;
      this.label.fontColor = 16777215;
      this.label.visible = this._labelVisible;
      this.addChild(this.label);
   }
   update() {
      if ((this.wasResized || this.wasBmpResized) && this.lastBmp) {
         this.graphics.clear();
         this.graphics.beginFill(0, 0.5);
         this.graphics.drawRect(0, 0, this.width, this.height);
         this.graphics.endFill();
         this.wasBmpResized = false;
         this.matr.a = this.width / this.lastBmp.width;
         this.matr.d = this.height / this.lastBmp.height;
      }
      if (this.lastBmp) this.bmpDraw();
      if (this.wasResized) this.positionLabel();
   }
   bmpDraw() {
      this.drawBmp = this.lastBmp;
      this.bmpTransformations();
      this.canvas.graphics.clear();
      this.matr.a = this.width / this.lastBmp.width;
      this.matr.d = this.height / this.lastBmp.height;
      this.canvas.graphics.beginBitmapFill(this.drawBmp, this.matr);
      this.canvas.graphics.drawRect(0, 0, this.width, this.height);
   }
}
PB.BaseScreen = BaseScreen;

class PBJScreen extends BaseScreen {
   constructor() { super(); this.shaderFilter = null; this.shader = null; }
}
PB.PBJScreen = PBJScreen;

class PBSlider extends K.Slider {
   constructor() {
      super({ skin: Singletons.getInstance(PBSliderSkin), thumbWidth: 14, thumbHeight: 14, trackHeight: 5, padLeft: 53, padRight: 53, width: 240, height: 49, min: 0, max: 1, value: 0.5 });
      this.addEventListener(MouseEvent.MOUSE_DOWN, this.b.listener);
   }
   listener(e) { e.stopPropagation(); }
}
PB.PBSlider = PBSlider;

// Displacement screens share one shape: a PBJ kernel on the canvas, fed the
// effect centre (and for some, magnitude and size).
class DisplacementScreen extends PBJScreen {
   constructor(kernel, name, usePos, params) {
      super();
      this.usePosition = usePos;
      this.useSlider = usePos;
      this.screenName = name;
      this.shader = new F.Shader(kernel);
      this.shaderFilter = new F.ShaderFilter(this.shader);
      this.effectDirty = true;
      this.params = params;
   }
   update() {
      super.update();
      if (this.effectDirty || this.wasResized) {
         this.effectDirty = false;
         var d = this.shader.data;
         d.x.value = [this.width * this._centerX];
         d.y.value = [this.height * this._centerY];
         if (this.params.indexOf("magnitude") >= 0) d.magnitude.value = [this.magnitude];
         if (this.params.indexOf("image_height") >= 0) d.image_height.value = [this.height];
         if (this.params.indexOf("image_width") >= 0) d.image_width.value = [this.width];
         this.canvas.filters = [this.shaderFilter];
      }
   }
}
class BulgeScreen extends DisplacementScreen { constructor() { super("Bulge", "Bulge", true, ["magnitude", "image_width"]); } }
BulgeScreen.TYPE = "bulge";
class DentScreen extends DisplacementScreen { constructor() { super("Dent", "Dent", true, ["magnitude", "image_height", "image_width"]); } }
DentScreen.TYPE = "dent";
class FisheyeScreen extends DisplacementScreen { constructor() { super("Fisheye", "Fish Eye", false, []); } }
FisheyeScreen.TYPE = "fish_eye";
class LightTunnelScreen extends DisplacementScreen { constructor() { super("LightTunnel", "Light Tunnel", true, ["magnitude", "image_height", "image_width"]); } }
LightTunnelScreen.TYPE = "light_tunnel";
class PinchScreen extends DisplacementScreen { constructor() { super("Pinch", "Pinch", true, ["magnitude", "image_height", "image_width"]); } }
PinchScreen.TYPE = "pinch";
class StretchScreen extends DisplacementScreen { constructor() { super("Stretch", "Stretch", false, ["image_width"]); } }
StretchScreen.TYPE = "stretch";
class TwirlScreen extends DisplacementScreen { constructor() { super("Twirl", "Twirl", true, ["magnitude", "image_height", "image_width"]); } }
TwirlScreen.TYPE = "twirl";

class MirrorScreen extends BaseScreen {
   constructor() { super(); this.screenName = "Mirror"; this.ct = null; }
   bmpTransformations() {
      var last = this.lastBmp;
      this.drawBmp = last.clone();
      this.drawBmp.draw(last, new Matrix(-1, 0, 0, 1, last.width));
      this.drawBmp.copyPixels(last, new Rectangle(0, 0, last.width / 2, last.height), new Point(0, 0));
   }
}
MirrorScreen.TYPE = "mirror";

class BlackWhiteScreen extends BaseScreen {
   constructor() {
      super();
      this.screenName = "Black and White";
      var r = 0.2225, g = 0.7169, b = 0.0606;
      this.filters = [new F.ColorMatrixFilter([r, g, b, 0, 0, r, g, b, 0, 0, r, g, b, 0, 0, 0, 0, 0, 1, 0])];
   }
}
BlackWhiteScreen.TYPE = "black_white";

class ComicBookScreen extends PBJScreen {
   constructor() { super(); this.screenName = "Comic Book"; }
   createChildren() {
      super.createChildren();
      this.shader = new F.Shader("ComicBook");
      this.shaderFilter = new F.ShaderFilter(this.shader);
      this.shader.data.dot_spacing.value = [5.5];
      this.shader.data.max_dot_size.value = [5];
      this.canvas.filters = [this.shaderFilter];
   }
}
ComicBookScreen.TYPE = "comic_book";

class HueColorMatrixFilter {
   constructor() { this.matrix = null; this._h = 0; this.Identity(); }
   set Saturation(s) {
      var lum = [0.213, 0.715, 0.072, 0.213, 0.715, 0.072, 0.213, 0.715, 0.072];
      var sat = [0.787, -0.715, -0.072, -0.212, 0.285, -0.072, -0.213, -0.715, 0.928];
      var m = this.add(lum, this.multiply(s, sat));
      this.concat([m[0], m[1], m[2], 0, 0, m[3], m[4], m[5], 0, 0, m[6], m[7], m[8], 0, 0, 0, 0, 0, 1, 0]);
   }
   add(a, b) { return a.map(function (v, i) { return v + b[i]; }); }
   multiply(k, a) { return a.map(function (v) { return v === 0 ? 0 : k * v; }); }
   reset() { this.Identity(); }
   set Hue(h) {
      this._h = h;
      h = this._h / 180 * Math.PI;
      var lum = [0.213, 0.715, 0.072, 0.213, 0.715, 0.072, 0.213, 0.715, 0.072];
      var cosM = [0.787, -0.715, -0.072, -0.212, 0.285, -0.072, -0.213, -0.715, 0.928];
      var sinM = [-0.213, -0.715, 0.928, 0.143, 0.14, -0.283, -0.787, 0.715, 0.072];
      var m = this.add(lum, this.add(this.multiply(Math.cos(h), cosM), this.multiply(Math.sin(h), sinM)));
      this.concat([m[0], m[1], m[2], 0, 0, m[3], m[4], m[5], 0, 0, m[6], m[7], m[8], 0, 0, 0, 0, 0, 1, 0]);
   }
   get Hue() { return this._h; }
   concat(p) {
      var r = [], m = this.matrix;
      r[0] = m[0] * p[0] + m[1] * p[5] + m[2] * p[10];
      r[1] = m[0] * p[1] + m[1] * p[6] + m[2] * p[11];
      r[2] = m[0] * p[2] + m[1] * p[7] + m[2] * p[12];
      r[3] = 0; r[4] = 0;
      r[5] = m[5] * p[0] + m[6] * p[5] + m[7] * p[10];
      r[6] = m[5] * p[1] + m[6] * p[6] + m[7] * p[11];
      r[7] = m[5] * p[2] + m[6] * p[7] + m[7] * p[12];
      r[8] = 0; r[9] = 0;
      r[10] = m[10] * p[0] + m[11] * p[5] + m[12] * p[10];
      r[11] = m[10] * p[1] + m[11] * p[6] + m[12] * p[11];
      r[12] = m[10] * p[2] + m[11] * p[7] + m[12] * p[12];
      r[13] = 0; r[14] = 0; r[15] = 0; r[16] = 0; r[17] = 0; r[18] = 1; r[19] = 0;
      this.matrix = r;
   }
   Identity() { this.matrix = [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0]; }
   get Filter() { return new F.ColorMatrixFilter(this.matrix); }
}

class GlowScreen extends BaseScreen {
   constructor() { super(); this.screenName = "Glow"; this.overlayCanvas = null; this.blurOverlay = null; }
   update() {
      super.update();
      if (this.wasResized) this.scrollRect = new Rectangle(0, 0, this.width, this.height);
   }
   bmpDraw() {
      super.bmpDraw();
      if (this.lastBmp) {
         this.overlayCanvas.graphics.clear();
         this.overlayCanvas.graphics.beginBitmapFill(this.lastBmp, this.matr);
         this.overlayCanvas.graphics.drawRect(0, 0, this.width, this.height);
      }
   }
   createChildren() {
      super.createChildren();
      this.blurOverlay = new F.Sprite();
      this.overlayCanvas = new F.Sprite();
      var blur = new F.BlurFilter(20, 20, 1);
      var cm = new F.ColorMatrixFilter([0.8, 0.39, 0.05, 0, 42, 0.2, 1, 0.05, 0, 62, 0.2, 0.39, 0.67, 0, 75, 0, 0, 0, 1, 0]);
      this.blurOverlay.alpha = 0.9;
      this.blurOverlay.filters = [blur, cm];
      this.blurOverlay.blendMode = F.BlendMode.HARDLIGHT;
      this.blurOverlay.x = this.blurOverlay.y = 0;
      this.blurOverlay.addChild(this.overlayCanvas);
      this.addChild(this.blurOverlay);
      var hue = new HueColorMatrixFilter();
      hue.Saturation = 1.2;
      this.canvas.filters = [hue.Filter];
      this.setChildIndex(this.label, this.numChildren - 1);
   }
}
GlowScreen.TYPE = "glow";

function palletize(bmp, row) {
   var r = [], g = [], b = [];
   var d = bmp.ctx.getImageData(0, row, bmp.width, 1).data;
   for (var i = 0; i < bmp.width; i++) {
      r[i] = d[i * 4] << 16;
      g[i] = d[i * 4 + 1] << 8;
      b[i] = d[i * 4 + 2];
   }
   return [r, g, b];
}

class PopArtScreen extends BaseScreen {
   constructor() {
      super();
      this._cacheMatr = new Matrix(0.5, 0, 0, 0.5);
      var pal = embedded("PopArtScreen_Pallette");
      this.pallets = [palletize(pal, 0), palletize(pal, 1), palletize(pal, 2), palletize(pal, 3)];
      this.screenName = "Pop Art";
   }
   bmpTransformations() {
      this.drawBmp = this.lastBmp.clone();
      var half = new BitmapData(this.drawBmp.width / 2, this.drawBmp.height / 2);
      half.draw(this.drawBmp, this._cacheMatr);
      var p = this.pallets, r = half.rect;
      this.drawBmp.paletteMap(half, r, r.topLeft, p[0][0], p[0][1], p[0][2]);
      this.drawBmp.paletteMap(half, r, new Point(r.width, 0), p[1][0], p[1][1], p[1][2]);
      this.drawBmp.paletteMap(half, r, new Point(0, r.height), p[2][0], p[2][1], p[2][2]);
      this.drawBmp.paletteMap(half, r, new Point(r.width, r.height), p[3][0], p[3][1], p[3][2]);
   }
}
PopArtScreen.TYPE = "popart";

class SepiaScreen extends PBJScreen {
   constructor() { super(); this.screenName = "Sepia"; }
   createChildren() {
      super.createChildren();
      this.shader = new F.Shader("Sepia");
      this.shaderFilter = new F.ShaderFilter(this.shader);
      this.canvas.filters = [this.shaderFilter];
   }
}
SepiaScreen.TYPE = "sepia";

class SketchScreen extends BaseScreen {
   constructor() { super(); this.screenName = "Sketch"; this.sketchBmp = embedded("SketchScreen_Sketch"); this.sketchOverlay = null; }
   update() {
      super.update();
      if (this.wasResized) {
         this.sketchOverlay.graphics.clear();
         this.sketchOverlay.graphics.beginBitmapFill(this.sketchBmp, this.matr);
         this.sketchOverlay.graphics.drawRect(0, 0, this.width, this.height);
      }
   }
   createChildren() {
      this.sketchOverlay = new F.Sprite();
      this.filters = [new F.ColorMatrixFilter([1.03204, 0.85316, 0.1148, 0, -3.5, 0.43204, 1.45316, 0.1148, 0, -3.5, 0.43204, 0.85316, 0.7148, 0, -3.5, 0, 0, 0, 1, 0])];
      this.addChild(this.sketchOverlay);
      super.createChildren();
      this.canvas.blendMode = F.BlendMode.HARDLIGHT;
   }
}
SketchScreen.TYPE = "sketch";

class ThermalScreen extends BaseScreen {
   constructor() {
      super();
      this.rgbPallete = palletize(embedded("ThermalScreen_Pallette"), 0);
      this.screenName = "Thermal Camera";
   }
   bmpTransformations() {
      this.drawBmp = this.lastBmp.clone();
      var r = this.lastBmp.rect;
      this.drawBmp.paletteMap(this.lastBmp, r, r.topLeft, this.rgbPallete[0], this.rgbPallete[1], this.rgbPallete[2]);
   }
}
ThermalScreen.TYPE = "thermal";

class XrayScreen extends BaseScreen {
   constructor() { super(); this.screenName = "X-Ray"; }
   createChildren() {
      super.createChildren();
      this.canvas.filters = [new F.ColorMatrixFilter([-1, 0, 0, 0, 255, 0, -1, 0, 0, 255, 0, 0, -1, 0, 255, 0, 0, 0, 1, 0])];
   }
}
XrayScreen.TYPE = "xray";

// --- background removal ---------------------------------------------------

class SimpleProgressBar extends KComponent {
   constructor() {
      super({ outLineColor: 6710886, barColor: 6710886, skin: Singletons.getInstance(ProgressBarSkin) });
      this.outLineColor = 0; this.barColor = 0; this.skin = null;
      this.progressChanged = true;
      this._progress = 0;
   }
   set progress(v) { if (v === this._progress) return; this._progress = v; this.progressChanged = true; this.invalidate(); }
   get progress() { return this._progress; }
   update() {
      if (this.progressChanged) {
         this.progressChanged = false;
         this.skin.draw(this);
      }
   }
}
PB.SimpleProgressBar = SimpleProgressBar;

class MsgBox extends KComponent {
   constructor() {
      super({ skin: Singletons.getInstance(MsgBoxSkin) });
      this.skin = null;
      this._text = "Your Msg";
      this.textChagned = true;
      this.lbl = null;
   }
   set text(v) { if (v === this.text) return; this._text = v; this.textChagned = true; this.invalidate(); }
   get text() { return this._text; }
   autoCenter() {}
   update() {
      if (this.textChagned) {
         this.textChagned = false;
         this.lbl.text = this.text;
         this.lbl.validateNow();
         var w = this.lbl.getMeasuredWidth() + 20, h = this.lbl.getMeasuredHeight() + 10;
         this.setActualSize(w, h);
         this.lbl.move(6, 3);
         this.skin.draw(this);
         this.autoCenter();
      }
   }
   createChildren() {
      super.createChildren();
      this.lbl = new K.Label();
      this.lbl.fontSize = 26;
      this.lbl.fontColor = 16777215;
      this.addChild(this.lbl);
   }
}
PB.MsgBox = MsgBox;

class LoaderScreen extends KComponent {
   constructor(src) {
      super();
      this.imgSrc = src || "";
      this._showProgress = true;
      this.showProgressChanged = true;
      this.loaderContent = null;
      this.loader = null;
      this.lbl = null;
      this.pgBar = null;
   }
   loadResource(url) {
      this.loader = new Loader();
      this.loader.contentLoaderInfo.addEventListener(Event.INIT, this.b.doneLoading);
      this.loader.contentLoaderInfo.addEventListener(F.ProgressEvent.PROGRESS, this.b.loadProgress);
      this.loader.load(new URLRequest(url));
   }
   loadBytes(bytes) {
      this.loader = new Loader();
      this.loader.contentLoaderInfo.addEventListener(Event.INIT, this.b.doneLoading);
      this.loader.contentLoaderInfo.addEventListener(F.ProgressEvent.PROGRESS, this.b.loadProgress);
      this.loader.loadBytes(bytes);
   }
   doneLoading(e) {
      if (this.loaderContent) return;
      this.loaderContent = this.loader.content;
      this.loader.contentLoaderInfo.removeEventListener(Event.INIT, this.b.doneLoading);
      this.loader.unload();
      this.addChild(this.loaderContent);
      this.loaderContent.width = this.width;
      this.loaderContent.height = this.height;
      this.stopContentMovie();
      this.dispatchEvent(new Event("loadComplete"));
   }
   set showProgress(v) { if (v === this.showProgress) return; this._showProgress = v; this.showProgressChanged = true; this.invalidate(); }
   get showProgress() { return this._showProgress; }
   playContentMovie() { if (this.loaderContent instanceof MovieClip) this.loaderContent.gotoAndPlay(1); }
   stopContentMovie() { if (this.loaderContent instanceof MovieClip) this.loaderContent.gotoAndStop(1); }
   update() {
      super.update();
      if (this.showProgressChanged) {
         this.showProgressChanged = false;
         this.lbl.visible = this.pgBar.visible = this.showProgress;
      }
      if (this.wasResized) {
         this.graphics.clear();
         this.graphics.beginFill(3355443);
         this.graphics.drawRect(0, 0, this.width, this.height);
         this.lbl.fontColor = 16777215;
         this.lbl.fontSize = 11;
         this.lbl.validateNow();
         this.lbl.move((this.width - this.lbl.width) / 2 + 18, (this.height - this.lbl.height) / 2 + 20);
         this.pgBar.setActualSize(120, 10);
         this.pgBar.move((this.width - 120) / 2, (this.height - 10) / 2);
         if (this.loaderContent) {
            this.loaderContent.width = this.width;
            this.loaderContent.height = this.height;
         }
      }
   }
   loadProgress(e) { this.pgBar.progress = e.bytesLoaded / e.bytesTotal; }
   createChildren() {
      this.lbl = new K.Label();
      this.lbl.text = "Loading...";
      this.addChild(this.lbl);
      this.pgBar = new SimpleProgressBar();
      this.addChild(this.pgBar);
      if (this.imgSrc !== "") this.loadResource(this.imgSrc);
   }
}
PB.LoaderScreen = LoaderScreen;

// Detects a still, empty background by differencing half-size frames taken
// two seconds apart.
class BackgroundRemover extends F.EventDispatcher {
   constructor(video) {
      super();
      this.threshHoldMap = null;
      this.thisBmp = null;
      this.debugMap = null;
      this.lastBmp = null;
      this.detectedBackground = null;
      this.matr = null;
      this.debug = true;
      this.video = video;
   }
   stopDetection() { TimerManager.getInstance().removeCallBack(this.startDetection); }
   startDetection() {
      if (this.lastBmp == null) {
         this.matr = this.video.width > 400 ? new Matrix(0.5, 0, 0, 0.5) : new Matrix(1, 0, 0, 1);
         this.lastBmp = new BitmapData(this.video.width * this.matr.a, this.video.height * this.matr.a);
         this.thisBmp = new BitmapData(this.video.width * this.matr.a, this.video.height * this.matr.a);
         this.lastBmp.draw(this.video, this.matr);
         TimerManager.getInstance().addCallBack(this.startDetection, 0.5, true, this);
         return;
      }
      this.thisBmp.draw(this.video, this.matr);
      var current = this.thisBmp.clone();
      this.thisBmp.draw(this.lastBmp, new Matrix(), null, F.BlendMode.DIFFERENCE);
      this.thisBmp.threshold(this.thisBmp, this.thisBmp.rect, this.thisBmp.rect.topLeft, ">", 4279308561, 4294901760, 16777215, false);
      if (this.debug) this.debugMap = this.thisBmp;
      // Sum of the red channel (getPixel(x, y) >> 16) over the whole frame.
      // CHANGE: read from the raw threshold result, because a canvas cannot
      // keep colour in fully transparent pixels the way BitmapData can.
      var sum = 0, raw = this.thisBmp._raw;
      for (var i = 0; i < raw.length; i += 4) sum += raw[i];
      if (sum > 0 && sum < 2200000 * this.matr.a * this.matr.a) {
         this.detectedBackground = new BitmapData(this.video.width, this.video.height);
         this.detectedBackground.draw(this.video);
         this.dispatchEvent(new Event("backgroundDetected"));
      } else {
         this.lastBmp = current;
         TimerManager.getInstance().addCallBack(this.startDetection, 0.5, true, this);
      }
   }
   resetDetector() { this.lastBmp = null; this.thisBmp = null; }
}
PB.BackgroundRemover = BackgroundRemover;

class BGRemovedScreen extends PBJScreen {
   constructor(resource, name) {
      super();
      this.useBgBmp = true;
      this.resourceName = resource;
      this.effectDirty = false;
      this.screenName = name == null ? "background remove" : name;
      this.skin = Singletons.getInstance(FigureSkin);
      this.background = null;
      this.isMaxed = false;
      this.prevWidth = 0;
   }
   get bgBmp() { return this._bgBmp; }
   set bgBmp(v) {
      if (v !== this._bgBmp) this._bgBmp = v;
      this.bgBitmapChanged = true;
      this.effectDirty = true;
      this.invalidate();
   }
   update() {
      this.isMaxed = this.width === 640;
      super.update();
      if (this.effectDirty) {
         this.effectDirty = false;
         this.initBGRemove();
      }
      if (this.wasResized) {
         if (this.background) this.background.setActualSize(this.width, this.height);
         this.prevWidth = this.width;
         if (this.isMaxed) {
            this.background.playContentMovie();
            this.canvas.alpha = 1;
         } else {
            this.background.stopContentMovie();
            this.drawManniquin();
         }
      }
   }
   bmpDraw() { if (this.isMaxed) super.bmpDraw(); }
   initBGRemove() {
      this.shader.data.bg.input = this.bgBmp;
      this.shaderFilter = new F.ShaderFilter(this.shader);
      this.canvas.filters = [this.shaderFilter];
   }
   createChildren() {
      this.background = new LoaderScreen(this.resourceName);
      this.addChild(this.background);
      this.shader = new F.Shader("BGRemoved");
      super.createChildren();
   }
   drawManniquin() { this.skin.draw(this.canvas, { width: this.width, height: this.height }); }
}
BGRemovedScreen.TYPE = "background_remove";
PB.BGRemovedScreen = BGRemovedScreen;

class UploadBgScreen extends BGRemovedScreen {
   constructor() {
      super("", "Click to upload image");
      this.file = null;
      this.bgLoaded = false;
      this.addEventListener(MouseEvent.CLICK, this.b.clickListener);
   }
   doneLoading(e) { this.bgLoaded = true; this.labelVisible = false; }
   positionLabel() {
      this.label.validateNow();
      this.label.move((this.width - this.label.getMeasuredWidth()) / 2, (this.height - this.label.getMeasuredHeight()) / 2);
   }
   fileSelectListener(e) {
      this.file.addEventListener(Event.COMPLETE, this.b.fileOpenListener);
      this.file.load();
   }
   fileOpenListener(e) {
      this.background.loadBytes(this.file.data);
      this.background.addEventListener("loadComplete", this.b.doneLoading);
   }
   createChildren() {
      super.createChildren();
      this.background.showProgress = false;
   }
   clickListener(e) {
      if (this.bgLoaded) return;
      e.stopImmediatePropagation();
      this.file = new FileReference();
      this.file.addEventListener(Event.SELECT, this.b.fileSelectListener);
      this.file.browse([new FileFilter("All Formats (*.jpg,*.gif,*.png,*.swf)", "*.jpg;*.gif;*.png;*.swf", "JPEG;jp2_;GIFF;SWFL")]);
   }
   get labelVisible() { return this._labelVisible; }
   set labelVisible(v) {
      if (this.bgLoaded) super.labelVisible = false;
      else super.labelVisible = v;
   }
}
UploadBgScreen.TYPE = "upload";
PB.UploadBgScreen = UploadBgScreen;

class ScreenFactory {
   newScreenInstance(type) {
      switch (String(type)) {
         case BlackWhiteScreen.TYPE: return new BlackWhiteScreen();
         case GlowScreen.TYPE: return new GlowScreen();
         case SepiaScreen.TYPE: return new SepiaScreen();
         case PopArtScreen.TYPE: return new PopArtScreen();
         case ThermalScreen.TYPE: return new ThermalScreen();
         case ComicBookScreen.TYPE: return new ComicBookScreen();
         case SketchScreen.TYPE: return new SketchScreen();
         case XrayScreen.TYPE: return new XrayScreen();
         case TwirlScreen.TYPE: return new TwirlScreen();
         case LightTunnelScreen.TYPE: return new LightTunnelScreen();
         case MirrorScreen.TYPE: return new MirrorScreen();
         case FisheyeScreen.TYPE: return new FisheyeScreen();
         case StretchScreen.TYPE: return new StretchScreen();
         case BulgeScreen.TYPE: return new BulgeScreen();
         case PinchScreen.TYPE: return new PinchScreen();
         case DentScreen.TYPE: return new DentScreen();
         case "clouds": return new BGRemovedScreen("images/clouds.jpg", "Clouds");
         case "color_dots": return new BGRemovedScreen("images/colored_dots.jpg", "Color Dots");
         case "earthrise": return new BGRemovedScreen("images/earth_rise.jpg", "Earthrise");
         case "effel_tower": return new BGRemovedScreen("images/Effel_Tower.swf", "Effel Tower");
         case "fish": return new BGRemovedScreen("images/Fish.swf", "Fish");
         case "rollercoaster": return new BGRemovedScreen("images/RollerCoaster.swf", "RollerCoaster");
         case "sunset": return new BGRemovedScreen("images/Sunset.swf", "Sunset");
         case "yosemite": return new BGRemovedScreen("images/Yosmite.swf", "Yosmite");
         case UploadBgScreen.TYPE: return new UploadBgScreen();
         default: return new BaseScreen();
      }
   }
}
PB.ScreenFactory = ScreenFactory;

// Skins shared with photobooth.js.
PB.skins = {
   MainShadowMockSkin: MainShadowMockSkin, ScreenContainerSkin: ScreenContainerSkin, PhotoListSkin: PhotoListSkin,
   GrowlBoxSkin: GrowlBoxSkin, GrowBoxCloseButtonSkin: GrowBoxCloseButtonSkin
};

})(window);
