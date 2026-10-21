/*
 * karthik.js - port of Karthik Tharavaad's small UI framework
 * (com.karthik.core, components, data, lang, managers, skins).
 *
 * Each class mirrors the decompiled ActionScript in reference/as3/ with the
 * same names and logic. AS3 `int` fields and parameters are truncated with
 * `| 0` where the original relies on it.
 */
(function (global) {
"use strict";

var F = global.flash;
var K = global.karthik = {};

// ---------------------------------------------------------------------------
// com.karthik.lang.HashUtil
// ---------------------------------------------------------------------------

function isPlainObject(v) { return v !== null && typeof v === "object" && Object.getPrototypeOf(v) === Object.prototype; }

var HashUtil = {
   mergeHashArr: function (arr) {
      var out = {};
      if (arr.length === 0) return out;
      for (var i = 0; i < arr.length; i++) {
         var h = arr[i];
         for (var k in h) {
            var v = h[k];
            if (isPlainObject(v) && Object.prototype.hasOwnProperty.call(out, k)) out[k] = HashUtil.mergeHash(out[k], h[k]);
            else out[k] = h[k];
         }
      }
      return out;
   },
   // AS3 hasOwnProperty() is true for declared public members, including
   // accessors; `in` is the closest JS equivalent.
   transferProperties: function (src, dst) {
      for (var k in src) if (k in dst) dst[k] = src[k];
   },
   mergeHash: function () { return HashUtil.mergeHashArr(Array.prototype.slice.call(arguments)); }
};
K.HashUtil = HashUtil;

// ---------------------------------------------------------------------------
// com.karthik.managers.Singletons
// ---------------------------------------------------------------------------

var Singletons = {
   skins: new Map(),
   getInstance: function (cls) {
      if (!this.skins.has(cls)) this.skins.set(cls, new cls());
      return this.skins.get(cls);
   }
};
K.Singletons = Singletons;

// ---------------------------------------------------------------------------
// com.karthik.managers.TimerManager - one 50 ms Timer drives every callback.
// `frequency` is in calls per second.
// ---------------------------------------------------------------------------

class TimerQueueItem {
   constructor() { this.enabled = true; this.dic = {}; this.currentCount = 0; this.frequency = 0; this.args = null; this.callOnce = false; }
}

class TimerManager {
   constructor() {
      this.timer = new F.Timer(TimerManager.defaultDelay);
      this.queue = [];
      this.timer.addEventListener("timer", this.timerEventListener.bind(this));
      this.timer.start();
   }
   static getInstance() {
      if (TimerManager._timerManager == null) TimerManager._timerManager = new TimerManager();
      return TimerManager._timerManager;
   }
   timerEventListener() {
      var any = false;
      for (var i = this.queue.length - 1; i >= 0; i--) {
         var item = this.queue[i];
         if (!item) continue;
         if (item.enabled) {
            any = true;
            var period = 1 / item.frequency * 1000;
            item.currentCount += TimerManager.defaultDelay;
            if (item.currentCount >= period) {
               item.currentCount = 0;
               var cb = item.dic.callback, self = item.dic["this"], args = item.args;
               if (cb != null) cb.apply(self, args || []);
               else this.queue.splice(i, 1);
               if (item.callOnce) {
                  var j = this.queue.indexOf(item);
                  if (j >= 0) this.queue.splice(j, 1);
               }
            }
         }
      }
      if (!any) this.timer.stop();
   }
   resumeCallBack(fn) {
      var item = this.getItemForFunc(fn);
      item.enabled = true;
      if (!this.timer.running) this.timer.start();
   }
   addCallBack(fn, frequency, callOnce, thisObj, args, enabled) {
      var item = new TimerQueueItem();
      item.dic.callback = fn;
      item.frequency = frequency;
      item.callOnce = !!callOnce;
      item.enabled = enabled !== false;
      item.dic["this"] = thisObj;
      item.args = args || null;
      this.queue.push(item);
      if (!this.timer.running) this.timer.start();
   }
   removeCallBack(fn) {
      for (var i = this.queue.length - 1; i >= 0; i--) if (this.queue[i].dic.callback === fn) this.queue.splice(i, 1);
   }
   pauseCallBack(fn) { var item = this.getItemForFunc(fn); if (item) item.enabled = false; }
   getItemForFunc(fn) {
      for (var i = this.queue.length - 1; i >= 0; i--) if (this.queue[i].dic.callback === fn) return this.queue[i];
      return null;
   }
   hasCallBack(fn) { return this.getItemForFunc(fn) != null; }
}
TimerManager._timerManager = null;
TimerManager.defaultDelay = 50;
K.TimerManager = TimerManager;

// ---------------------------------------------------------------------------
// com.karthik.core
// ---------------------------------------------------------------------------

class KSprite extends F.Sprite {
   constructor() { super(); this._height = undefined; this._width = undefined; }
   get height() { return this._height; }
   set height(v) { if (this._height === v) return; this._height = v; }
   get width() { return this._width; }
   set width(v) { if (this._width === v) return; this._width = v; }
}
K.KSprite = KSprite;

class KComponentGlobals extends F.EventDispatcher {
   constructor() { super(); this.added = false; this.invalidateQueue = []; this.noneCount = 0; }
   static initialize(app) {
      KComponentGlobals.APP = app;
      app.stage.align = "TL";
      app.stage.scaleMode = "noScale";
   }
   static getInstance() {
      if (!KComponentGlobals.instance) KComponentGlobals.instance = new KComponentGlobals();
      return KComponentGlobals.instance;
   }
   eventEnterFrame() {
      if (this.invalidateQueue.length === 0) {
         ++this.noneCount;
         if (this.noneCount >= 1) {
            this.noneCount = 0;
            KComponentGlobals.APP.removeEventListener(F.Event.ENTER_FRAME, this.b.eventEnterFrame);
            this.added = false;
         }
         return;
      }
      while (this.invalidateQueue.length > 0) this.invalidateQueue.shift().validateNow();
   }
   invalidateThis(c) {
      if (this.invalidateQueue.indexOf(c) !== -1) return;
      this.invalidateQueue.push(c);
      if (!this.added) {
         KComponentGlobals.APP.addEventListener(F.Event.ENTER_FRAME, this.b.eventEnterFrame);
         this.added = true;
      }
   }
}
K.KComponentGlobals = KComponentGlobals;

class KComponent extends KSprite {
   constructor(options) {
      super();
      this._x = 0;
      this._y = 0;
      this.wasResized = true;
      this.wasMoved = false;
      this.wasVisibilityChanged = false;
      this.intialized = false;
      this.defaultOptions_ = { width: 100, height: 100 };
      this._alpha = 1;
      this.isInvalid = false;
      this._visible = true;
      this.wasAlphaChanged = false;
      this.global = KComponentGlobals.getInstance();
      this.addEventListener(F.Event.ADDED, this.b.addedListener, false, -1, true);
      this.pendingOptions = options;
   }
   removedListener(e) {
      if (e.target !== this) return;
      this.addEventListener(F.Event.ADDED, this.b.addedListener);
      this.intialized = false;
   }
   update() {}
   get width() { return this._width; }
   set width(v) { this._width = v; this.wasResized = true; this.invalidate(); }
   get height() { return this._height; }
   set height(v) { this._height = v; this.wasResized = true; this.invalidate(); }
   commitProperties() {}
   callLater() { TimerManager.getInstance().addCallBack(this.callLaterExe, 20, true, this, Array.prototype.slice.call(arguments)); }
   move(x, y) {
      x = x | 0; y = y | 0;
      if (this._x === x && this._y === y) return;
      this.x = this._x = x;
      this.y = this._y = y;
   }
   addedListener(e) {
      if (e.target !== this) return;
      this.setProperties(this.pendingOptions);
      this.removeEventListener(F.Event.ADDED, this.b.addedListener);
      this.addEventListener(F.Event.REMOVED, this.b.removedListener, false, -1, true);
      this.createChildren();
      this.invalidate();
      this.intialized = true;
   }
   getDefaultOption() { return this.defaultOptions_; }
   createChildren() {}
   callLaterExe() { for (var i = 0; i < arguments.length; i++) arguments[i].apply(this); }
   validate() { this.validateNow(); }
   validateNow() {
      if (!this.intialized) return;
      this.commitProperties();
      this.update();
      this.wasResized = false;
      this.isInvalid = false;
   }
   setActualSize(w, h) {
      w = w | 0; h = h | 0;
      if (this._width === w && this._height === h) return;
      this._width = w;
      this._height = h;
      this.wasResized = true;
      this.validateNow();
   }
   setProperties(opts) { HashUtil.transferProperties(HashUtil.mergeHash(this.getDefaultOption(), opts), this); }
   invalidate() {
      if (this.isInvalid) return;
      this.isInvalid = true;
      this.global.invalidateThis(this);
   }
}
K.KComponent = KComponent;

// com.karthik.core.KSkin - option-hash driven drawing helpers.
class KSkin {
   constructor() {
      this.bmpOpts = { bmp: new F.BitmapData(100, 100), matr: new F.Matrix(), repeat: true };
      this.cirOpts = { x: 0, y: 0 };
      this.gradOpts = { type: "gradient", kind: F.GradientType.LINEAR, spread: F.SpreadMethod.PAD, colors: [16777215, 0], alphas: [1, 1], ratios: [0, 255], box: { rotation: Math.PI / 2 } };
      this.rectOpts = { x: 0, y: 0 };
      this.roundRectOpts = { x: 0, y: 0 };
      this.drawOpts = {
         lineStyle: { thickness: 1, color: 0, alpha: 1, hint: true },
         fillStyle: { type: "color", color: 0, alpha: 0.5 }
      };
      this.ptsOpts = { pts: [[0, 0], [10, 0], [10, 10], [0, 10]], closed: true };
   }
   draw(target, opts) {}
   drawRect() {
      var o = HashUtil.mergeHash(this.drawOpts, this.rectOpts, HashUtil.mergeHashArr(Array.prototype.slice.call(arguments)));
      var t = o.target;
      o = HashUtil.mergeHash({ width: t.width, height: t.height }, o);
      var g = this.initializeGraphics(o);
      g.drawRect(o.x, o.y, o.width, o.height);
      g.endFill();
   }
   drawPath() {
      var o = HashUtil.mergeHash(this.drawOpts, this.ptsOpts, HashUtil.mergeHashArr(Array.prototype.slice.call(arguments)));
      var g = this.initializeGraphics(o);
      var pts = o.pts, closed = !!o.closed, first = pts[0];
      g.moveTo(first[0], first[1]);
      for (var i = 1; i < pts.length; i++) g.lineTo(pts[i][0], pts[i][1]);
      if (closed) {
         g.lineTo(first[0], first[1]);
         g.endFill();
      }
   }
   drawKRoundRect() {
      var o = HashUtil.mergeHash(this.drawOpts, this.roundRectOpts, HashUtil.mergeHashArr(Array.prototype.slice.call(arguments)));
      var t = o.target;
      o = HashUtil.mergeHash({ width: t.width, height: t.height }, o);
      var g = this.initializeGraphics(o);
      var x = Number(o.x), y = Number(o.y), w = Number(o.width), h = Number(o.height), r = Number(o.radius);
      w--;
      if (o.faceUp) { g.moveTo(x, y); g.lineTo(x + w, y); }
      else { g.moveTo(x + r, y); g.lineTo(x + w - r, y); g.curveTo(x + w, y, x + w, y + r); }
      if (o.faceDown) { g.lineTo(x + w, y + h); g.lineTo(x, y + h); }
      else {
         g.lineTo(x + w, y + h - r);
         g.curveTo(x + w, y + h, x + w - r, y + h);
         g.lineTo(x + r, y + h);
         g.curveTo(x, y + h, x, y + h - r);
      }
      if (o.faceUp) g.lineTo(x, y);
      else { g.lineTo(x, y + r); g.curveTo(x, y, x + r, y); }
      g.endFill();
   }
   clear() {
      for (var i = 0; i < arguments.length; i++) {
         var a = arguments[i];
         if (a instanceof F.Graphics) a.clear();
         else if (a instanceof F.Sprite) a.graphics.clear();
      }
   }
   drawCircle() {
      var o = HashUtil.mergeHash(this.drawOpts, this.cirOpts, HashUtil.mergeHashArr(Array.prototype.slice.call(arguments)));
      var t = o.target;
      var r = Math.min(t.width, t.height) / 2;
      o = HashUtil.mergeHash({ radius: r, x: r, y: r }, o);
      var g = this.initializeGraphics(o);
      g.drawCircle(o.x, o.y, o.radius);
   }
   drawRoundRect() {
      var o = HashUtil.mergeHash(this.drawOpts, this.roundRectOpts, HashUtil.mergeHashArr(Array.prototype.slice.call(arguments)));
      var t = o.target;
      o = HashUtil.mergeHash({ width: t.width, height: t.height }, o);
      var g = this.initializeGraphics(o);
      g.drawRoundRect(o.x, o.y, o.width, o.height, o.radius);
   }
   initializeGraphics(o) {
      var t = o.target, g = t.graphics;
      if (o.lineStyle) {
         var l = o.lineStyle;
         g.lineStyle(l.thickness, l.color, l.alpha, l.hint);
      }
      if (o.fillStyle) {
         var f = o.fillStyle;
         switch (f.type) {
            case "gradient":
               f = HashUtil.mergeHash(this.gradOpts, { box: { width: t.width, height: t.height, x: 0, y: 0 } }, f);
               var m = new F.Matrix();
               m.createGradientBox(f.box.width, f.box.height, f.box.rotation, f.box.x, f.box.y);
               g.beginGradientFill(f.kind, f.colors, f.alphas, f.ratios, m, f.spread);
               break;
            case "bmp":
               f = HashUtil.mergeHash(this.bmpOpts, f);
               g.beginBitmapFill(f.bmp, f.matr, f.repeat);
               break;
            default:
               g.beginFill(f.color, f.alpha);
         }
      }
      return g;
   }
}
K.KSkin = KSkin;

// ---------------------------------------------------------------------------
// com.karthik.skins.KButtonSkin
// ---------------------------------------------------------------------------

class KButtonSkin extends KSkin {
   constructor() { super(); this.opt = null; this.btn = null; }
   drawDisabled() { this.drawNormal(); }
   opSet() {}
   draw(target, opts) {
      this.btn = target;
      this.opt = { target: target };
      this.opSet();
      this.clear(target.graphics);
      if (this.btn.disabled) this.drawDisabled();
      else if (this.btn.state === "over") this.drawOver();
      else if (this.btn.state === "down") this.drawDown();
      else this.drawNormal();
   }
   drawNormal() { this.drawRect(this.opt, { fillStyle: { alpha: 0.5 } }); }
   drawDown() { this.drawRect(this.opt, { fillStyle: { alpha: 1 } }); }
   drawOver() { this.drawRect(this.opt, { fillStyle: { alpha: 0.3 } }); }
}
K.KButtonSkin = KButtonSkin;

// ---------------------------------------------------------------------------
// com.karthik.components
// ---------------------------------------------------------------------------

class Button extends KComponent {
   constructor(options) {
      super(HashUtil.mergeHash({ width: 100, height: 30 }, options));
      this._text = undefined;
      this._state = "normal";
      this._disabled = false;
      this._skin = null;
      this.defaultOptions = { skin: Singletons.getInstance(KButtonSkin), width: 100, height: 20 };
      this.stateChanged = true;
      this.addEventListener(F.MouseEvent.ROLL_OVER, this.b.mouseOver, false, -50, false);
      this.addEventListener(F.MouseEvent.ROLL_OUT, this.b.mouseOut, false, -50, false);
      this.addEventListener(F.MouseEvent.MOUSE_DOWN, this.b.mouseDown, false, -50, false);
      this.addEventListener(F.MouseEvent.MOUSE_UP, this.b.mouseUp, false, -50, false);
   }
   update() {
      if (this.wasResized || this.stateChanged) {
         this.stateChanged = false;
         this.skin.draw(this);
      }
   }
   get state() { return this._state; }
   invalidateState() { this.stateChanged = true; this.invalidate(); }
   mouseOver(e) { if (this.disabled) return; this._state = "over"; this.invalidateState(); }
   getDefaultOption() { return this.defaultOptions; }
   mouseDown(e) { if (this.disabled) return; this._state = "down"; this.invalidateState(); }
   mouseOut(e) { if (this.disabled) return; this._state = "normal"; this.invalidateState(); }
   mouseClick(e) { if (this.disabled) e.stopImmediatePropagation(); }
   mouseUp(e) { if (this.disabled) return; this._state = "normal"; this.invalidateState(); }
   set disabled(v) { if (v === this._disabled) return; this._disabled = v; this.invalidateState(); }
   get disabled() { return this._disabled; }
   set skin(v) { if (this._skin === v) return; this._skin = v; this.invalidateState(); }
   get skin() { return this._skin; }
}
K.Button = Button;

class Label extends KComponent {
   constructor() {
      super();
      this.styleChanged = true;
      this.textChanged = false;
      this._text = undefined;
      this.textField = null;
      this._fontSize = 10;
      this._fontColor = 16777215;
      this._multiLine = false;
      this.multiLineChanged = false;
      this._fontFamily = "Lucida Grande";
      this.format = null;
   }
   styleChange() { this.styleChanged = true; this.invalidate(); }
   update() {
      super.update();
      if (this.textChanged) {
         this.textChanged = false;
         this.textField.text = this._text;
         this.styleChanged = true;
      }
      if (this.wasResized) this.textField.height = this.height;
      if (this.styleChanged) {
         this.styleChanged = false;
         this.format.size = this.fontSize;
         this.format.color = this.fontColor;
         this.format.font = this.fontFamily;
         this.textField.setTextFormat(this.format);
      }
   }
   getMeasuredHeight() { return this.textField.textHeight; }
   get fontFamily() { return this._fontFamily; }
   get fontColor() { return this._fontColor; }
   createChildren() {
      super.createChildren();
      this.format = new F.TextFormat("Lucida Grande", 8, 16777215);
      this.textField = new F.TextField();
      this.textField.selectable = false;
      this.textField.autoSize = F.TextFieldAutoSize.LEFT;
      this.addChild(this.textField);
   }
   set fontSize(v) { if (this._fontSize === v) return; this._fontSize = v; this.styleChange(); }
   get fontSize() { return this._fontSize; }
   set text(v) { if (this._text === v) return; this._text = v; this.textChanged = true; this.validateNow(); }
   get text() { return this._text; }
   set fontFamily(v) { if (this._fontFamily === v) return; this._fontFamily = v; this.styleChange(); }
   set fontColor(v) { if (v === this.fontColor) return; this._fontColor = v; this.styleChange(); }
   getMeasuredWidth() { return this.textField.textWidth; }
}
K.Label = Label;

class Slider extends KComponent {
   constructor(options) {
      super(options);
      this.padRight = 0; this.thumbWidth = 0; this.min = 0; this.trackHeight = 0; this.thumbHeight = 0;
      this.padLeft = 0; this.max = 1; this.skin = null;
      this.track = null; this.thumb = null;
      this._orientation = 0;
      this.sliderDefaults = {
         skin: null, thumbWidth: 10, thumbHeight: 10, trackHeight: 4, padLeft: 10, padRight: 10,
         width: 100, height: 30, min: 0, max: 1, value: 0.5
      };
      this._value = 0;
      this.animator = new LayoutAnimator(this);
      this.animator.positionFunc = this.positionFunc;
      this.animator.animationSpeed = 0.1;
   }
   thumb_mouseDown(e) { e.stopPropagation(); this.addthumbListeners(); }
   positionFunc() {
      var trackW = this.width - this.padLeft - this.padRight;
      var x = this.padLeft + this.value / (this.max - this.min) * trackW - this.thumbWidth / 2;
      var y = (this.height - this.thumbHeight) / 2;
      this.animator.setTargets(this.thumb, x, y, this.thumbWidth, this.thumbHeight);
      x = this.padLeft;
      y = (this.height - this.trackHeight) / 2;
      this.animator.setTargets(this.track, x, y, trackW, this.trackHeight);
   }
   stage_mouseUpListener(e) { this.removeThumbListeners(); }
   update() {
      super.update();
      this.animator.validate();
      if (this.wasResized) this.skin.draw(this, { thumb: this.thumb, track: this.track });
   }
   createChildren() {
      super.createChildren();
      this.track = new KComponent();
      this.track.addEventListener(F.MouseEvent.CLICK, this.b.trackClickListener, false, -5, true);
      this.thumb = new KComponent();
      this.thumb.addEventListener(F.MouseEvent.MOUSE_DOWN, this.b.thumb_mouseDown, false, -5, true);
      this.animator.addChild(this.track);
      this.animator.addChild(this.thumb);
      this.addChild(this.track);
      this.addChild(this.thumb);
   }
   stage_mouseOutListener(e) { this.removeThumbListeners(); }
   set value(v) {
      if (v === this._value) return;
      this._value = v;
      this.dispatchEvent(new F.Event("changeValue"));
      this.animator.invalidate();
      this.invalidate();
   }
   get value() { return this._value; }
   addthumbListeners() {
      this.stage.addEventListener(F.MouseEvent.MOUSE_MOVE, this.b.stage_mouseMoveListener);
      this.stage.addEventListener(F.MouseEvent.MOUSE_UP, this.b.stage_mouseUpListener);
      this.stage.addEventListener(F.MouseEvent.ROLL_OUT, this.b.stage_mouseOutListener);
   }
   removeThumbListeners() {
      this.stage.removeEventListener(F.MouseEvent.MOUSE_MOVE, this.b.stage_mouseMoveListener);
      this.stage.removeEventListener(F.MouseEvent.MOUSE_UP, this.b.stage_mouseUpListener);
      this.stage.removeEventListener(F.MouseEvent.ROLL_OUT, this.b.stage_mouseOutListener);
   }
   getDefaultOption() { return this.sliderDefaults; }
   stage_mouseMoveListener(e) {
      var mx = this.mouseX;
      var trackW = this.width - this.padLeft - this.padRight;
      this.animator.targetFor(this.thumb).jumpNext = true;
      if (mx < this.padLeft) this.value = this.min;
      else if (mx > this.width - this.padRight) this.value = this.max;
      else this.value = this.min + (mx - this.padLeft) / trackW * (this.max - this.min);
   }
   trackClickListener(e) {
      e.stopPropagation();
      var trackW = this.width - this.padLeft - this.padRight;
      this.value = this.min + (this.mouseX - this.padLeft) / trackW * (this.max - this.min);
   }
}
Slider.HORIZONTAL = 1;
Slider.VERTICLE = 2;
K.Slider = Slider;

// ---------------------------------------------------------------------------
// com.karthik.managers - layout animation
// ---------------------------------------------------------------------------

class AnimationEvent extends F.Event {
   constructor() { super(AnimationEvent.ANIMATION_COMPLETE); this.interrupted = false; }
}
AnimationEvent.ANIMATION_COMPLETE = "animation_complete";
K.AnimationEvent = AnimationEvent;

// x, y, width and height are AS3 ints (truncated); alpha is a Number.
class KState {
   constructor(x, y, w, h, a) { this.x = x | 0; this.y = y | 0; this.width = w | 0; this.height = h | 0; this.alpha = a; }
   static stateFromKComponent(c, s) { s.update(c.x, c.y, c.width, c.height, c.alpha); return s; }
   update(x, y, w, h, a) { this.x = x | 0; this.y = y | 0; this.width = w | 0; this.height = h | 0; this.alpha = a; }
   toString() { return "x: " + this.x + " y: " + this.y + " width: " + this.width + " height: " + this.height; }
   intersect(s) {
      return !(s.y >= this.y + this.height || s.x + s.width <= this.x || s.x >= this.x + this.width || s.y + s.height <= this.y);
   }
}
K.KState = KState;

class LayoutTarget extends F.EventDispatcher {
   constructor(item) {
      super();
      this._enabled = true;
      this._targetAlpha = 1;
      this._stateCache = new KState(0, 0, 0, 0, 0);
      this._targetX = 0;
      this._targetY = 0;
      this.listeners = 0;
      this.jumpNext = false;
      this.doNotManageVisibility = false;
      this.jumptoPosAfterAdded = true;
      this._animationProgress = 0;
      this.goalSet = true;
      this._item = item;
      this.justAdded = true;
      this.doNotDispatchNext = false;
      this._targetWidth = 0;
      this._targetHeight = 0;
   }
   getNextBounds(speed) {
      var it = this.item, p = this.animationProgress;
      this._stateCache.update(it.x + (this.targetX - it.x) * p, it.y + (this.targetY - it.y) * p,
         it.width + (this.targetWidth - it.width) * p, it.height + (this.targetHeight - it.height) * p,
         it.alpha + (this.targetAlpha - it.alpha) * p);
      return this._stateCache;
   }
   set enabled(v) {
      if (this.doNotManageVisibility) return;
      if (this._enabled === v) return;
      this._enabled = v;
      this.item.visible = v;
   }
   get enabled() { return this._enabled; }
   get item() { return this._item; }
   set item(v) {
      if (this._item === v) return;
      v.move(this._item.x, this._item.y);
      v.setActualSize(this._item.width, this._item.height);
      this._item = v;
   }
   get currentState() { return KState.stateFromKComponent(this._item, this._stateCache); }
   set targetAlpha(v) { if (this._targetAlpha === v) return; this._targetAlpha = v; this.animationProgress = 0; this.dispatchComplete(true); }
   get targetAlpha() { return this._targetAlpha; }
   get targetHeight() { return this._targetHeight; }
   set targetHeight(v) { if (this._targetHeight === v) return; this._targetHeight = v; this.animationProgress = 0; this.dispatchComplete(true); }
   get targetWidth() { return this._targetWidth; }
   set targetWidth(v) { if (this._targetWidth === v) return; this._targetWidth = v; this.animationProgress = 0; this.dispatchComplete(true); }
   get targetX() { return this._targetX; }
   set targetX(v) { if (this._targetX === v) return; this._targetX = v; this.animationProgress = 0; this.dispatchComplete(true); }
   get targetY() { return this._targetY; }
   set targetY(v) { if (this._targetY === v) return; this._targetY = v; this.animationProgress = 0; this.dispatchComplete(true); }
   set animationProgress(v) { if (this._animationProgress === v) return; if (v > 1) v = 1; this._animationProgress = v; }
   get animationProgress() { return this._animationProgress; }
   get height() { return this.item.height; }
   get width() { return this.item.width; }
   get x() { return this.item.x; }
   get y() { return this.item.y; }
   updateTo(s) {
      if (!this.goalSet) this.goalSet = true;
      if (this.isWithinTolerance(s)) {
         this.item.alpha = this._targetAlpha;
         this.item.move(this._targetX, this._targetY);
         this.item.setActualSize(this._targetWidth, this._targetHeight);
         this.dispatchComplete(false);
      } else {
         this._item.alpha = s.alpha;
         this._item.move(s.x, s.y);
         this._item.setActualSize(s.width, s.height);
      }
   }
   jumpToTarget() { this.updateTo(new KState(this._targetX, this._targetY, this._targetWidth, this._targetHeight, this._targetAlpha)); }
   get isDirty() { return !this.isWithinTolerance(this.currentState); }
   removeEventListener(type, fn, c) { super.removeEventListener(type, fn, c); --this.listeners; }
   addEventListener(type, fn, c, p, w) {
      super.addEventListener(type, fn, c, p, w);
      if (type === AnimationEvent.ANIMATION_COMPLETE) this.goalSet = false;
      ++this.listeners;
   }
   dispatchComplete(interrupted) {
      if (this.listeners === 0) return;
      if (!this.goalSet) return;
      var e = new AnimationEvent();
      e.interrupted = interrupted;
      this.dispatchEvent(e);
   }
   isWithinTolerance(s) {
      return Math.abs(s.x - this.targetX) <= 1 && Math.abs(s.y - this.targetY) <= 1 &&
         Math.abs(s.width - this.targetWidth) < 0.5 && Math.abs(s.height - this.targetHeight) < 0.5 &&
         Math.abs(s.alpha - this.targetAlpha) < 0.1;
   }
}
K.LayoutTarget = LayoutTarget;

class LayoutAnimator {
   constructor(owner) {
      this.refreshFrequency = 20;
      this.animationSpeed = 0.1;
      this.positionFunc = null;
      this.positionFuncCalled = false;
      this.positionsInvalid = true;
      this._stateCache = new KState(0, 0, 0, 0, 0);
      this.owner = owner;
      this.doClipping = true;
      this.children = new Map();
   }
   targetFor(c) { return this.children.get(c); }
   validate() {
      if (!this.positionsInvalid) return;
      this.positionsInvalid = false;
      if (!this.positionFuncCalled) this.positionFunc.apply(this.owner);
      this.positionFuncCalled = false;
      var ownerState = null;
      if (this.doClipping) {
         ownerState = KState.stateFromKComponent(this.owner, this._stateCache);
         ownerState.x = 0;
         ownerState.y = 0;
      }
      var self = this;
      Array.from(this.children.values()).forEach(function (t) {
         if (!self.children.has(t.item)) return;
         if (t.isDirty) {
            var next = t.getNextBounds(self.animationSpeed);
            t.animationProgress += self.animationSpeed;
            if (t.justAdded && t.jumptoPosAfterAdded) t.jumpToTarget();
            else if (t.jumpNext) { t.jumpNext = false; t.jumpToTarget(); }
            else t.updateTo(next);
            t.justAdded = false;
            if (t.isDirty) self.positionsInvalid = true;
         }
         if (self.doClipping && !t.doNotManageVisibility) {
            t.enabled = ownerState.intersect(t.currentState);
         }
      });
      if (this.positionsInvalid) TimerManager.getInstance().addCallBack(this.validate, this.refreshFrequency, true, this);
   }
   removeChild(c) { this.children.delete(c); }
   setTargets(c, x, y, w, h, a) {
      var t = this.targetFor(c);
      t.targetX = x; t.targetY = y; t.targetWidth = w; t.targetHeight = h; t.targetAlpha = a == null ? 1 : a;
   }
   addChild(c) { this.children.set(c, new LayoutTarget(c)); }
   invalidate() { this.positionsInvalid = true; }
}
K.LayoutAnimator = LayoutAnimator;

class PopUpManager extends KComponent {
   constructor() { super(); this._root = null; this.blurred = false; }
   initialize(root) { this._root = root; root.addChild(this); }
   makeSureOnTop() {
      if (this._root.getChildIndex(this) < this._root.numChildren - 1) this._root.setChildIndex(this, this._root.numChildren - 1);
   }
   blurBeneath() {
      this.graphics.clear();
      this.graphics.beginFill(16777215, 0.4);
      this.graphics.drawRect(0, 0, this.root.stage.stageWidth, this.root.stage.stageHeight);
      this.blurred = true;
   }
   unblurBeneath() { this.graphics.clear(); this.blurred = false; }
}
K.PopUpManager = PopUpManager;

// ---------------------------------------------------------------------------
// com.karthik.data
// ---------------------------------------------------------------------------

class CollectionEvent extends F.Event {
   constructor() { super(CollectionEvent.COLLECTION_CHANGE); this.index = 0; this.item = null; this.kind = null; }
}
CollectionEvent.COLLECTION_CHANGE = "collection_event";
CollectionEvent.TYPE_ADD = "type_add";
CollectionEvent.TYPE_REMOVE = "type_remove";
CollectionEvent.TYPE_OTHER = "other";
K.CollectionEvent = CollectionEvent;

class ArrayCollection extends F.EventDispatcher {
   constructor(source) { super(); this._source = source; }
   addItem(item) { this.addItemAt(item, this.length); }
   removeItemAt(i) {
      var removed = this._source.splice(i, 1);
      var e = new CollectionEvent();
      e.index = i; e.item = removed; e.kind = CollectionEvent.TYPE_REMOVE;
      this.dispatchEvent(e);
      return removed;
   }
   get length() { return this._source.length; }
   addItemAt(item, i) {
      this._source.splice(i, 0, item);
      var e = new CollectionEvent();
      e.index = i; e.item = item; e.kind = CollectionEvent.TYPE_ADD;
      this.dispatchEvent(e);
   }
   getItemIndex(item) { return this._source.indexOf(item); }
   get source() { return this._source; }
   set source(v) {
      if (this._source === v) return;
      this._source = v;
      var e = new CollectionEvent();
      e.kind = CollectionEvent.TYPE_OTHER;
      this.dispatchEvent(e);
   }
   getItemAt(i) { return this._source[i]; }
   contains(item) { return this.getItemIndex(item) !== -1; }
}
K.ArrayCollection = ArrayCollection;

class ClassFactory { newInstance() {} }
K.ClassFactory = ClassFactory;

})(window);
