/*
 * flash.js - the small subset of the Flash Player API that PhotoBooth uses,
 * reimplemented on Canvas 2D (display list, vector drawing, text, events,
 * BitmapData) and WebGL (filters, Pixel Bender kernels, 2.5D projection).
 *
 * It exists so Karthik's ActionScript 3 classes can be ported almost line for
 * line (see photobooth.js). Only what the app touches is implemented, and
 * only as far as the app needs it.
 */
(function (global) {
"use strict";

var flash = global.flash = {};

// ---------------------------------------------------------------------------
// Utilities
// ---------------------------------------------------------------------------

function rgba(color, alpha) {
   color = color >>> 0;
   return "rgba(" + ((color >> 16) & 255) + "," + ((color >> 8) & 255) + "," + (color & 255) + "," + (alpha == null ? 1 : alpha) + ")";
}
flash.rgba = rgba;

function makeCanvas(w, h) {
   var c = document.createElement("canvas");
   c.width = Math.max(1, Math.ceil(w));
   c.height = Math.max(1, Math.ceil(h));
   return c;
}
flash.makeCanvas = makeCanvas;

// Cached per-instance bound methods, so `this.b.listener` can be passed to
// addEventListener and later to removeEventListener as the same reference
// (AS3 method closures behave that way; plain JS methods do not).
function boundProxy(obj) {
   if (!obj._boundCache) {
      var cache = new Map();
      obj._boundCache = new Proxy(obj, {
         get: function (t, k) {
            var f = cache.get(k);
            if (!f) {
               f = t[k].bind(t);
               cache.set(k, f);
            }
            return f;
         }
      });
   }
   return obj._boundCache;
}

// ---------------------------------------------------------------------------
// Geometry
// ---------------------------------------------------------------------------

class Point {
   constructor(x, y) { this.x = x || 0; this.y = y || 0; }
}
flash.Point = Point;

class Rectangle {
   constructor(x, y, w, h) { this.x = x || 0; this.y = y || 0; this.width = w || 0; this.height = h || 0; }
   get topLeft() { return new Point(this.x, this.y); }
   contains(px, py) { return px >= this.x && py >= this.y && px < this.x + this.width && py < this.y + this.height; }
   clone() { return new Rectangle(this.x, this.y, this.width, this.height); }
}
flash.Rectangle = Rectangle;

class Matrix {
   constructor(a, b, c, d, tx, ty) {
      this.a = a == null ? 1 : a; this.b = b || 0; this.c = c || 0;
      this.d = d == null ? 1 : d; this.tx = tx || 0; this.ty = ty || 0;
   }
   // Same formula as flash.geom.Matrix.createGradientBox.
   createGradientBox(width, height, rotation, tx, ty) {
      rotation = rotation || 0;
      var cos = Math.cos(rotation), sin = Math.sin(rotation);
      this.a = cos * width / 1638.4;
      this.b = sin * height / 1638.4;
      this.c = -sin * width / 1638.4;
      this.d = cos * height / 1638.4;
      this.tx = (tx || 0) + width / 2;
      this.ty = (ty || 0) + height / 2;
   }
   transformPoint(x, y) { return { x: this.a * x + this.c * y + this.tx, y: this.b * x + this.d * y + this.ty }; }
   toDOM() { return new DOMMatrix([this.a, this.b, this.c, this.d, this.tx, this.ty]); }
}
flash.Matrix = Matrix;

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

class Event {
   constructor(type, bubbles) {
      this.type = type;
      this.bubbles = !!bubbles;
      this.target = null;
      this.currentTarget = null;
      this._stop = false;
      this._stopNow = false;
   }
   stopPropagation() { this._stop = true; }
   stopImmediatePropagation() { this._stop = true; this._stopNow = true; }
}
Event.ADDED = "added";
Event.REMOVED = "removed";
Event.ENTER_FRAME = "enterFrame";
Event.RESIZE = "resize";
Event.COMPLETE = "complete";
Event.CANCEL = "cancel";
Event.INIT = "init";
Event.SELECT = "select";
flash.Event = Event;

class MouseEvent extends Event {
   constructor(type, bubbles) {
      super(type, bubbles);
      this.localX = 0;
      this.localY = 0;
      this.stageX = 0;
      this.stageY = 0;
   }
}
MouseEvent.CLICK = "click";
MouseEvent.MOUSE_DOWN = "mouseDown";
MouseEvent.MOUSE_UP = "mouseUp";
MouseEvent.MOUSE_MOVE = "mouseMove";
MouseEvent.ROLL_OVER = "rollOver";
MouseEvent.ROLL_OUT = "rollOut";
flash.MouseEvent = MouseEvent;

class ProgressEvent extends Event {
   constructor(type, loaded, total) { super(type); this.bytesLoaded = loaded; this.bytesTotal = total; }
}
ProgressEvent.PROGRESS = "progress";
flash.ProgressEvent = ProgressEvent;

class IOErrorEvent extends Event {}
IOErrorEvent.IO_ERROR = "ioError";
flash.IOErrorEvent = IOErrorEvent;

// Objects listening for ENTER_FRAME; Flash broadcasts it to every listener.
var enterFrameListeners = new Set();

class EventDispatcher {
   constructor() { this._listeners = null; }
   get b() { return boundProxy(this); }
   addEventListener(type, fn, useCapture, priority, weak) {
      if (!this._listeners) this._listeners = {};
      var list = this._listeners[type] || (this._listeners[type] = []);
      for (var i = 0; i < list.length; i++) if (list[i].fn === fn) return;
      list.push({ fn: fn, priority: priority || 0, order: EventDispatcher._order++ });
      list.sort(function (a, b) { return b.priority - a.priority || a.order - b.order; });
      if (type === Event.ENTER_FRAME) enterFrameListeners.add(this);
   }
   removeEventListener(type, fn) {
      if (!this._listeners || !this._listeners[type]) return;
      var list = this._listeners[type];
      for (var i = 0; i < list.length; i++) {
         if (list[i].fn === fn) { list.splice(i, 1); break; }
      }
      if (type === Event.ENTER_FRAME && list.length === 0) enterFrameListeners.delete(this);
   }
   hasEventListener(type) { return !!(this._listeners && this._listeners[type] && this._listeners[type].length); }
   _invoke(e) {
      var list = this._listeners && this._listeners[e.type];
      if (!list || !list.length) return;
      e.currentTarget = this;
      list = list.slice();
      for (var i = 0; i < list.length; i++) {
         list[i].fn.call(null, e);
         if (e._stopNow) return;
      }
   }
   dispatchEvent(e) {
      if (e.target == null) e.target = this;
      this._invoke(e);
      if (e.bubbles && !e._stop) {
         var p = this.parent;
         while (p && !e._stop) {
            p._invoke(e);
            p = p.parent;
         }
      }
      return true;
   }
}
EventDispatcher._order = 0;
flash.EventDispatcher = EventDispatcher;

// ---------------------------------------------------------------------------
// Graphics: records drawing commands and replays them onto a 2D context.
// Fills use the even-odd rule, like Flash.
// ---------------------------------------------------------------------------

class Graphics {
   constructor(owner) { this.owner = owner; this.cmds = []; }
   _changed() { if (this.owner) this.owner._invalidate(); }
   clear() { this.cmds.length = 0; this._changed(); }
   lineStyle(thickness, color, alpha, pixelHinting) {
      this.cmds.push(["line", thickness, color || 0, alpha == null ? 1 : alpha, pixelHinting]);
   }
   beginFill(color, alpha) { this.cmds.push(["fill", { type: "color", color: color, alpha: alpha == null ? 1 : alpha }]); this._changed(); }
   beginGradientFill(kind, colors, alphas, ratios, matrix, spread) {
      this.cmds.push(["fill", { type: "gradient", kind: kind, colors: colors, alphas: alphas, ratios: ratios, matrix: matrix || new Matrix() }]);
      this._changed();
   }
   beginBitmapFill(bmp, matrix, repeat, smooth) {
      this.cmds.push(["fill", { type: "bitmap", bmp: bmp, matrix: matrix || null, repeat: repeat !== false, smooth: !!smooth }]);
      this._changed();
   }
   endFill() { this.cmds.push(["end"]); this._changed(); }
   moveTo(x, y) { this.cmds.push(["M", x, y]); }
   lineTo(x, y) { this.cmds.push(["L", x, y]); this._changed(); }
   curveTo(cx, cy, x, y) { this.cmds.push(["Q", cx, cy, x, y]); this._changed(); }
   drawRect(x, y, w, h) { this.cmds.push(["R", x, y, w, h]); this._changed(); }
   drawCircle(x, y, r) { this.cmds.push(["C", x, y, r]); this._changed(); }
   drawRoundRect(x, y, w, h, ew, eh) { this.cmds.push(["RR", x, y, w, h, ew, eh == null ? ew : eh]); this._changed(); }
   get empty() { return this.cmds.length === 0; }

   bounds() {
      var minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity, lw = 0;
      function add(x, y) { if (x < minX) minX = x; if (y < minY) minY = y; if (x > maxX) maxX = x; if (y > maxY) maxY = y; }
      for (var i = 0; i < this.cmds.length; i++) {
         var c = this.cmds[i];
         switch (c[0]) {
            case "line": if (c[3] > 0) lw = Math.max(lw, c[1] || 1); break;
            case "M": case "L": add(c[1], c[2]); break;
            case "Q": add(c[1], c[2]); add(c[3], c[4]); break;
            case "R": case "RR": add(c[1], c[2]); add(c[1] + c[3], c[2] + c[4]); break;
            case "C": add(c[1] - c[3], c[2] - c[3]); add(c[1] + c[3], c[2] + c[3]); break;
         }
      }
      if (minX === Infinity) return null;
      var h = lw / 2 + 1;
      return new Rectangle(minX - h, minY - h, maxX - minX + 2 * h, maxY - minY + 2 * h);
   }

   _fillStyle(ctx, f) {
      if (f.type === "color") return rgba(f.color, f.alpha);
      if (f.type === "gradient") {
         var m = f.matrix;
         var p0 = m.transformPoint(-819.2, 0), p1 = m.transformPoint(819.2, 0);
         var g = ctx.createLinearGradient(p0.x, p0.y, p1.x, p1.y);
         for (var i = 0; i < f.colors.length; i++) {
            var a = f.alphas ? f.alphas[i] : 1;
            g.addColorStop(Math.min(1, Math.max(0, (f.ratios ? f.ratios[i] : i * 255 / (f.colors.length - 1)) / 255)), rgba(f.colors[i], a));
         }
         return g;
      }
      var src = f.bmp.canvas;
      var pat = ctx.createPattern(src, f.repeat ? "repeat" : "no-repeat");
      if (f.matrix) pat.setTransform(f.matrix.toDOM());
      return pat;
   }

   // Replays the commands. When `hit` is given, returns whether the point lies
   // inside any fill (Flash's shape-based hit test) instead of drawing.
   render(ctx, hit) {
      var fill = null, line = null;
      var fillPath = null, strokePath = null, startX = 0, startY = 0, penX = 0, penY = 0;
      var self = this, inside = false;

      function flushStroke() {
         if (strokePath && line && line.alpha > 0 && !hit) {
            ctx.lineWidth = line.thickness > 0 ? line.thickness : 1;
            ctx.strokeStyle = rgba(line.color, line.alpha);
            ctx.lineJoin = "round";
            ctx.lineCap = "round";
            ctx.stroke(strokePath);
         }
         strokePath = null;
      }
      function flushFill() {
         if (fillPath && fill) {
            if (hit) {
               if (ctx.isPointInPath(fillPath, hit.x, hit.y, "evenodd")) inside = true;
            } else {
               var smooth = ctx.imageSmoothingEnabled;
               if (fill.type === "bitmap") ctx.imageSmoothingEnabled = fill.smooth;
               ctx.fillStyle = self._fillStyle(ctx, fill);
               ctx.fill(fillPath, "evenodd");
               ctx.imageSmoothingEnabled = smooth;
            }
         }
         fillPath = null;
      }
      // Pixel hinting: odd line widths sit on pixel centres so 1px lines stay crisp.
      function off() { return line && line.hint !== false && Math.round(line.thickness || 1) % 2 === 1 ? 0.5 : 0; }
      function ensure() {
         if (fill && !fillPath) { fillPath = new Path2D(); fillPath.moveTo(penX, penY); }
         if (line && !strokePath) { strokePath = new Path2D(); var o = off(); strokePath.moveTo(penX + o, penY + o); }
      }
      for (var i = 0; i < this.cmds.length; i++) {
         var c = this.cmds[i], o;
         switch (c[0]) {
            case "line":
               flushStroke();
               // lineStyle() with no thickness turns lines off, as in Flash.
               line = c[1] == null || isNaN(c[1]) ? null : { thickness: c[1], color: c[2], alpha: c[3], hint: c[4] };
               break;
            case "fill":
               flushFill(); flushStroke();
               fill = c[1];
               break;
            case "end":
               flushFill(); flushStroke();
               fill = null;
               break;
            case "M":
               penX = startX = c[1]; penY = startY = c[2];
               if (fillPath) fillPath.moveTo(penX, penY);
               if (strokePath) { o = off(); strokePath.moveTo(penX + o, penY + o); }
               break;
            case "L":
               ensure();
               if (fillPath) fillPath.lineTo(c[1], c[2]);
               if (strokePath) { o = off(); strokePath.lineTo(c[1] + o, c[2] + o); }
               penX = c[1]; penY = c[2];
               break;
            case "Q":
               ensure();
               if (fillPath) fillPath.quadraticCurveTo(c[1], c[2], c[3], c[4]);
               if (strokePath) { o = off(); strokePath.quadraticCurveTo(c[1] + o, c[2] + o, c[3] + o, c[4] + o); }
               penX = c[3]; penY = c[4];
               break;
            case "R": case "C": case "RR":
               ensure();
               var paths = [];
               if (fillPath) paths.push([fillPath, 0]);
               if (strokePath) paths.push([strokePath, off()]);
               for (var k = 0; k < paths.length; k++) {
                  var p = paths[k][0], q = paths[k][1];
                  if (c[0] === "R") p.rect(c[1] + q, c[2] + q, c[3], c[4]);
                  else if (c[0] === "C") { p.moveTo(c[1] + c[3] + q, c[2] + q); p.arc(c[1] + q, c[2] + q, c[3], 0, Math.PI * 2); p.closePath(); }
                  else {
                     var rx = Math.min(c[5] / 2, c[3] / 2), ry = Math.min(c[6] / 2, c[4] / 2);
                     var x = c[1] + q, y = c[2] + q, w = c[3], h = c[4];
                     p.moveTo(x + rx, y);
                     p.lineTo(x + w - rx, y); p.quadraticCurveTo(x + w, y, x + w, y + ry);
                     p.lineTo(x + w, y + h - ry); p.quadraticCurveTo(x + w, y + h, x + w - rx, y + h);
                     p.lineTo(x + rx, y + h); p.quadraticCurveTo(x, y + h, x, y + h - ry);
                     p.lineTo(x, y + ry); p.quadraticCurveTo(x, y, x + rx, y);
                     p.closePath();
                  }
               }
               break;
         }
      }
      flushFill(); flushStroke();
      return inside;
   }
}
flash.Graphics = Graphics;

// ---------------------------------------------------------------------------
// Display list
// ---------------------------------------------------------------------------

class DisplayObject extends EventDispatcher {
   constructor() {
      super();
      this.$x = 0; this.$y = 0; this._z = 0;
      this._rotationX = 0; this._rotationY = 0; this._rotationZ = 0;
      this.$alpha = 1;
      this.$visible = true;
      this._filters = [];
      this._blendMode = "normal";
      this._mask = null;
      this._scrollRect = null;
      this.parent = null;
      this.name = "";
      this._dirty = true;
      this._cache = null;
      this.isMask = false;
      this.transform = { perspectiveProjection: null };
   }
   get x() { return this.$x; }
   set x(v) { if (v !== this.$x) { this.$x = +v; this._invalidateParent(); } }
   get y() { return this.$y; }
   set y(v) { if (v !== this.$y) { this.$y = +v; this._invalidateParent(); } }
   get z() { return this._z; }
   set z(v) { this._z = +v; this._invalidateParent(); }
   get rotationX() { return this._rotationX; }
   set rotationX(v) { this._rotationX = +v; this._invalidateParent(); }
   get rotationY() { return this._rotationY; }
   set rotationY(v) { this._rotationY = +v; this._invalidateParent(); }
   get rotationZ() { return this._rotationZ; }
   set rotationZ(v) { this._rotationZ = +v; this._invalidateParent(); }
   get alpha() { return this.$alpha; }
   set alpha(v) { if (v !== this.$alpha) { this.$alpha = +v; this._invalidateParent(); } }
   get visible() { return this.$visible; }
   set visible(v) { v = !!v; if (v !== this.$visible) { this.$visible = v; this._invalidateParent(); } }
   get filters() { return this._filters.slice(); }
   set filters(v) { this._filters = v ? v.slice() : []; this._invalidate(); }
   get blendMode() { return this._blendMode; }
   set blendMode(v) { this._blendMode = v; this._invalidateParent(); }
   get mask() { return this._mask; }
   set mask(m) {
      if (this._mask) this._mask.isMask = false;
      this._mask = m;
      if (m) m.isMask = true;
      this._invalidateParent();
   }
   get scrollRect() { return this._scrollRect; }
   set scrollRect(r) { this._scrollRect = r; this._invalidate(); }
   get stage() { var p = this; while (p.parent) p = p.parent; return p instanceof Stage ? p : null; }
   get root() { return this.stage; }
   get is3D() { return this._z !== 0 || this._rotationX !== 0 || this._rotationY !== 0 || this._rotationZ !== 0; }

   get mouseX() { return this._globalToLocal(Stage.mouse.x, Stage.mouse.y).x; }
   get mouseY() { return this._globalToLocal(Stage.mouse.x, Stage.mouse.y).y; }
   _globalToLocal(x, y) {
      var chain = [], p = this;
      while (p) { chain.push(p); p = p.parent; }
      for (var i = chain.length - 1; i >= 0; i--) {
         x -= chain[i].$x; y -= chain[i].$y;
         if (chain[i]._scrollRect) { x += chain[i]._scrollRect.x; y += chain[i]._scrollRect.y; }
      }
      return { x: x, y: y };
   }

   // Marks this object's rendered content (and that of every ancestor) stale.
   _invalidate() {
      for (var p = this; p; p = p.parent) p._dirty = true;
      Stage.requestRender();
   }
   _invalidateParent() {
      if (this.parent) this.parent._invalidate(); else Stage.requestRender();
   }
}
flash.DisplayObject = DisplayObject;

class DisplayObjectContainer extends DisplayObject {
   constructor() { super(); this.children = []; this.mouseEnabled = true; this.mouseChildren = true; }
   get numChildren() { return this.children.length; }
   addChild(c) { return this.addChildAt(c, this.children.length); }
   addChildAt(c, i) {
      if (c.parent) c.parent.removeChild(c);
      this.children.splice(i, 0, c);
      c.parent = this;
      this._invalidate();
      c.dispatchEvent(new Event(Event.ADDED, true));
      return c;
   }
   removeChild(c) {
      var i = this.children.indexOf(c);
      if (i < 0) return c;
      c.dispatchEvent(new Event(Event.REMOVED, true));
      this.children.splice(i, 1);
      c.parent = null;
      this._invalidate();
      return c;
   }
   contains(c) { while (c) { if (c === this) return true; c = c.parent; } return false; }
   getChildIndex(c) { return this.children.indexOf(c); }
   setChildIndex(c, i) {
      var j = this.children.indexOf(c);
      if (j < 0) return;
      this.children.splice(j, 1);
      this.children.splice(Math.min(i, this.children.length), 0, c);
      this._invalidate();
   }
}
flash.DisplayObjectContainer = DisplayObjectContainer;

class Sprite extends DisplayObjectContainer {
   constructor() { super(); this.graphics = new Graphics(this); this.buttonMode = false; }
   get width() { var b = Renderer.bounds(this); return b ? b.width : 0; }
   set width(v) {}
   get height() { var b = Renderer.bounds(this); return b ? b.height : 0; }
   set height(v) {}
}
flash.Sprite = Sprite;

class Shape extends Sprite {}
flash.Shape = Shape;

// Generic image-like display object (Bitmap, video, loaded images). `source`
// is anything drawImage accepts; it is stretched to width x height.
class MediaDisplay extends DisplayObject {
   constructor(source, w, h) {
      super();
      this.source = source;
      this._w = w; this._h = h;
      this.live = false;
      this.smoothing = true;
   }
   get width() { return this._w; }
   set width(v) { this._w = v; this._invalidateParent(); }
   get height() { return this._h; }
   set height(v) { this._h = v; this._invalidateParent(); }
}
flash.MediaDisplay = MediaDisplay;

// ---------------------------------------------------------------------------
// Text
// ---------------------------------------------------------------------------

class TextFormat {
   constructor(font, size, color, bold) {
      this.font = font == null ? null : font;
      this.size = size == null ? null : size;
      this.color = color == null ? null : color;
      this.bold = bold == null ? null : bold;
   }
}
flash.TextFormat = TextFormat;

var measureCtx = null;
function fontString(fmt) {
   return (fmt.bold ? "bold " : "") + fmt.size + "px \"" + fmt.font + "\", \"Lucida Sans Unicode\", \"Lucida Sans\", Verdana, sans-serif";
}

// TextField with Flash's 2px gutter, autoSize LEFT and word wrapping.
class TextField extends DisplayObject {
   constructor() {
      super();
      this._text = "";
      this._fmt = { font: "Times New Roman", size: 12, color: 0, bold: false };
      this.selectable = true;
      this.multiline = false;
      this.wordWrap = false;
      this.autoSize = "none";
      this._w = 100; this._h = 100;
      this._lines = [""];
      this._tw = 0; this._th = 0;
   }
   get text() { return this._text; }
   set text(v) { this._text = v == null ? "" : String(v); this._layout(); }
   setTextFormat(f) {
      if (!f) return;
      if (f.font != null) this._fmt.font = f.font;
      if (f.size != null) this._fmt.size = f.size;
      if (f.color != null) this._fmt.color = f.color;
      if (f.bold != null) this._fmt.bold = f.bold;
      this._layout();
   }
   get width() { return this._w; }
   set width(v) { this._w = v; this._layout(); }
   get height() { return this._h; }
   set height(v) { if (this.autoSize === "none") { this._h = v; this._invalidateParent(); } }
   get textWidth() { return this._tw; }
   get textHeight() { return this._th; }
   get lineHeight() { return Math.round(this._fmt.size * 1.2); }
   _layout() {
      if (!measureCtx) measureCtx = makeCanvas(1, 1).getContext("2d");
      measureCtx.font = fontString(this._fmt);
      var paras = this._text.split(/\r\n|\r|\n/);
      var lines = [];
      var maxW = this._w - 4;
      for (var i = 0; i < paras.length; i++) {
         if (!this.wordWrap) { lines.push(paras[i]); continue; }
         var words = paras[i].split(" "), cur = "";
         for (var j = 0; j < words.length; j++) {
            var t = cur ? cur + " " + words[j] : words[j];
            if (cur && measureCtx.measureText(t).width > maxW) { lines.push(cur); cur = words[j]; }
            else cur = t;
            // A word wider than the field is broken between characters.
            while (measureCtx.measureText(cur).width > maxW && cur.length > 1) {
               var n = cur.length - 1;
               while (n > 1 && measureCtx.measureText(cur.slice(0, n)).width > maxW) n--;
               lines.push(cur.slice(0, n));
               cur = cur.slice(n);
            }
         }
         lines.push(cur);
      }
      this._lines = lines;
      var tw = 0;
      for (var k = 0; k < lines.length; k++) tw = Math.max(tw, measureCtx.measureText(lines[k]).width);
      this._tw = Math.ceil(tw);
      this._th = this._text === "" ? 0 : lines.length * this.lineHeight;
      if (this.autoSize !== "none") {
         if (!this.wordWrap) this._w = this._tw + 4;
         this._h = this._th + 4;
      }
      this._invalidateParent();
   }
}
flash.TextField = TextField;
flash.TextFieldAutoSize = { LEFT: "left", NONE: "none" };

// ---------------------------------------------------------------------------
// BitmapData (canvas backed)
// ---------------------------------------------------------------------------

class BitmapData {
   constructor(w, h, transparent, fill) {
      this.canvas = makeCanvas(w, h);
      this.width = this.canvas.width;
      this.height = this.canvas.height;
      this.transparent = transparent !== false;
      this.ctx = this.canvas.getContext("2d", { willReadFrequently: false });
      if (fill === undefined) fill = 0xFFFFFFFF;
      this.fillRect(this.rect, fill);
   }
   static fromImage(img) {
      var b = new BitmapData(img.naturalWidth || img.width, img.naturalHeight || img.height, true, 0);
      b.ctx.drawImage(img, 0, 0);
      return b;
   }
   get rect() { return new Rectangle(0, 0, this.width, this.height); }
   _touch() { this.version = (this.version || 0) + 1; Stage.requestRender(); }
   clone() {
      var b = new BitmapData(this.width, this.height, this.transparent, 0);
      b.ctx.drawImage(this.canvas, 0, 0);
      return b;
   }
   fillRect(r, color) {
      color = color >>> 0;
      var a = this.transparent ? ((color >>> 24) & 255) / 255 : 1;
      this.ctx.clearRect(r.x, r.y, r.width, r.height);
      if (a > 0) {
         this.ctx.fillStyle = rgba(color, a);
         this.ctx.fillRect(r.x, r.y, r.width, r.height);
      }
      this._touch();
   }
   floodFill(x, y, color) { this.fillRect(this.rect, color); }
   setPixel32(x, y, color) { this.fillRect(new Rectangle(x, y, 1, 1), color); }
   getPixel32(x, y) {
      var d = this.ctx.getImageData(x, y, 1, 1).data;
      return ((d[3] << 24) | (d[0] << 16) | (d[1] << 8) | d[2]) >>> 0;
   }
   getPixel(x, y) { return this.getPixel32(x, y) & 0xFFFFFF; }
   copyPixels(src, r, p) {
      this.ctx.clearRect(p.x, p.y, r.width, r.height);
      this.ctx.drawImage(src.canvas, r.x, r.y, r.width, r.height, p.x, p.y, r.width, r.height);
      this._touch();
   }
   // draw(source, matrix, colorTransform, blendMode)
   draw(source, matrix, ct, blendMode) {
      var ctx = this.ctx;
      ctx.save();
      if (matrix) ctx.setTransform(matrix.a, matrix.b, matrix.c, matrix.d, matrix.tx, matrix.ty);
      if (blendMode && blendMode !== "normal") ctx.globalCompositeOperation = blendMode;
      if (source instanceof BitmapData) ctx.drawImage(source.canvas, 0, 0);
      else if (source instanceof MediaDisplay) {
         ctx.imageSmoothingEnabled = source.smoothing;
         Renderer.drawMedia(ctx, source);
      } else if (source instanceof DisplayObject) {
         // Like Flash, the source's own transform is ignored but its filters apply.
         Renderer.renderContent(ctx, source, true);
      }
      ctx.restore();
      this._touch();
   }
   // paletteMap: out = red[r] + green[g] + blue[b] (+ alpha passthrough).
   paletteMap(src, r, p, red, green, blue, alpha) {
      var s = src.ctx.getImageData(r.x, r.y, r.width, r.height);
      var d = s.data, n = d.length;
      var out = this.ctx.createImageData(r.width, r.height), o = out.data;
      for (var i = 0; i < n; i += 4) {
         var v = (red ? red[d[i]] : d[i] << 16) + (green ? green[d[i + 1]] : d[i + 1] << 8) + (blue ? blue[d[i + 2]] : d[i + 2]);
         o[i] = (v >> 16) & 255; o[i + 1] = (v >> 8) & 255; o[i + 2] = v & 255;
         o[i + 3] = alpha ? alpha[d[i + 3]] >>> 24 : d[i + 3];
      }
      this.ctx.putImageData(out, p.x, p.y);
      this._touch();
   }
   // threshold with operation ">" only (all the app uses). copySource=false.
   threshold(src, r, p, op, thresholdValue, color, mask) {
      var img = src.ctx.getImageData(r.x, r.y, r.width, r.height), d = img.data;
      var t = (thresholdValue & mask) >>> 0;
      var cr = (color >> 16) & 255, cg = (color >> 8) & 255, cb = color & 255, ca = (color >>> 24) & 255;
      for (var i = 0; i < d.length; i += 4) {
         var px = ((d[i + 3] << 24) | (d[i] << 16) | (d[i + 1] << 8) | d[i + 2]) >>> 0;
         if (((px & mask) >>> 0) > t) { d[i] = cr; d[i + 1] = cg; d[i + 2] = cb; d[i + 3] = ca; }
      }
      // putImageData does not premultiply, so alpha-0 pixels keep their RGB
      // for the caller's getPixel reads; we keep the raw array for that.
      this._raw = d;
      this.ctx.putImageData(img, p.x, p.y);
      this._touch();
   }
   dispose() {}
}
flash.BitmapData = BitmapData;

// ---------------------------------------------------------------------------
// Filters (applied by Renderer through the WebGL FilterEngine)
// ---------------------------------------------------------------------------

class BlurFilter { constructor(bx, by, q) { this.blurX = bx == null ? 4 : bx; this.blurY = by == null ? 4 : by; this.quality = q == null ? 1 : q; } }
class DropShadowFilter {
   constructor(distance, angle, color, alpha, blurX, blurY, strength, quality, inner, knockout, hideObject) {
      this.distance = distance == null ? 4 : distance; this.angle = angle == null ? 45 : angle;
      this.color = color || 0; this.alpha = alpha == null ? 1 : alpha;
      this.blurX = blurX == null ? 4 : blurX; this.blurY = blurY == null ? 4 : blurY;
      this.strength = strength == null ? 1 : strength; this.quality = quality == null ? 1 : quality;
      this.inner = !!inner; this.knockout = !!knockout; this.hideObject = !!hideObject;
   }
}
class GlowFilter {
   constructor(color, alpha, blurX, blurY, strength, quality, inner, knockout) {
      this.distance = 0; this.angle = 0;
      this.color = color == null ? 0xFF0000 : color; this.alpha = alpha == null ? 1 : alpha;
      this.blurX = blurX == null ? 6 : blurX; this.blurY = blurY == null ? 6 : blurY;
      this.strength = strength == null ? 2 : strength; this.quality = quality == null ? 1 : quality;
      this.inner = !!inner; this.knockout = !!knockout; this.hideObject = false;
   }
}
class ColorMatrixFilter { constructor(m) { this.matrix = m || [1,0,0,0,0, 0,1,0,0,0, 0,0,1,0,0, 0,0,0,1,0]; } }
// ShaderFilter wraps a Shader whose `data` holds parameters and inputs.
class Shader {
   constructor(kernel) {
      this.kernel = kernel;          // name of a GLSL kernel registered with FilterEngine
      this.data = {};
      var params = (FilterEngine.kernels[kernel] || {}).params || {};
      for (var k in params) this.data[k] = { value: [params[k]] };   // PBJ defaultValue
      var inputs = (FilterEngine.kernels[kernel] || {}).inputs || [];
      for (var i = 0; i < inputs.length; i++) this.data[inputs[i]] = { input: null };
   }
}
class ShaderFilter { constructor(shader) { this.shader = shader; } }
flash.BlurFilter = BlurFilter;
flash.DropShadowFilter = DropShadowFilter;
flash.GlowFilter = GlowFilter;
flash.ColorMatrixFilter = ColorMatrixFilter;
flash.Shader = Shader;
flash.ShaderFilter = ShaderFilter;
flash.BlendMode = { NORMAL: "normal", HARDLIGHT: "hard-light", DIFFERENCE: "difference" };
flash.GradientType = { LINEAR: "linear", RADIAL: "radial" };
flash.SpreadMethod = { PAD: "pad" };

// ---------------------------------------------------------------------------
// FilterEngine: one WebGL canvas that runs filters on 2D canvases.
// Intermediate textures hold premultiplied colour with row 0 at the top.
// ---------------------------------------------------------------------------

var VS = "attribute vec2 p; void main(){ gl_Position = vec4(p, 0.0, 1.0); }";
var FS_HEAD = "precision highp float;\n" +
   "uniform vec2 u_size; uniform float u_flip;\n" +
   "vec2 outCoord(){ return vec2(gl_FragCoord.x, u_flip > 0.5 ? u_size.y - gl_FragCoord.y : gl_FragCoord.y); }\n" +
   // Texture access in pixel units; outside the image is transparent, as in Flash.
   "vec4 texel(sampler2D t, vec2 sz, vec2 c){ if (c.x < 0.0 || c.y < 0.0 || c.x > sz.x || c.y > sz.y) return vec4(0.0); return texture2D(t, c / sz); }\n" +
   "vec4 unpre(vec4 c){ return c.a > 0.0 ? vec4(c.rgb / c.a, c.a) : vec4(0.0); }\n" +
   "vec4 pre(vec4 c){ return vec4(c.rgb * c.a, c.a); }\n";

var BUILTIN = {
   copy: "uniform sampler2D u_tex; uniform vec2 u_texSize; uniform vec2 u_offset;\n" +
      "void main(){ gl_FragColor = texel(u_tex, u_texSize, outCoord() - u_offset); }",
   // Canvas uploads arrive unpremultiplied; convert to premultiplied.
   load: "uniform sampler2D u_tex; uniform vec2 u_texSize; uniform vec2 u_offset;\n" +
      "void main(){ gl_FragColor = pre(texel(u_tex, u_texSize, outCoord() - u_offset)); }",
   // One box-blur pass of width u_box along u_dir (premultiplied).
   blur: "uniform sampler2D u_tex; uniform vec2 u_texSize; uniform vec2 u_dir; uniform float u_box;\n" +
      "void main(){ vec2 c = outCoord(); vec4 s = vec4(0.0); float n = 0.0; float h = (u_box - 1.0) * 0.5;\n" +
      " for (int i = 0; i < 256; i++){ float f = float(i) - h; if (f > h) break; s += texel(u_tex, u_texSize, c + u_dir * f); n += 1.0; }\n" +
      " gl_FragColor = s / max(n, 1.0); }",
   colorMatrix: "uniform sampler2D u_tex; uniform vec2 u_texSize; uniform mat4 u_m; uniform vec4 u_o;\n" +
      "void main(){ vec4 c = unpre(texel(u_tex, u_texSize, outCoord()));\n" +
      " vec4 r = clamp(u_m * c + u_o, 0.0, 1.0); gl_FragColor = pre(r); }",
   // Shadow/glow: tint the (blurred) alpha of u_shadow and composite with u_tex.
   shadow: "uniform sampler2D u_tex; uniform sampler2D u_shadow; uniform vec2 u_texSize; uniform vec2 u_offset;\n" +
      "uniform vec3 u_color; uniform float u_alpha; uniform float u_strength; uniform float u_inner;\n" +
      "void main(){ vec2 c = outCoord(); vec4 src = texel(u_tex, u_texSize, c);\n" +
      " float a = texel(u_shadow, u_texSize, c - u_offset).a;\n" +
      " if (u_inner > 0.5) { a = clamp((1.0 - a) * u_strength, 0.0, 1.0) * u_alpha * src.a;\n" +
      "   gl_FragColor = vec4(src.rgb * (1.0 - a) + u_color * a, src.a); }\n" +
      " else { a = clamp(a * u_strength, 0.0, 1.0) * u_alpha;\n" +
      "   gl_FragColor = src + vec4(u_color * a, a) * (1.0 - src.a); } }",
   // Scales a texture: destination pixel c samples source pixel c * u_scale.
   resample: "uniform sampler2D u_tex; uniform vec2 u_texSize; uniform vec2 u_scale;\n" +
      "void main(){ gl_FragColor = texture2D(u_tex, outCoord() * u_scale / u_texSize); }",
   // Draws a texture through a projective (3x3) mapping: dst pixel -> src pixel.
   project: "uniform sampler2D u_tex; uniform vec2 u_texSize; uniform mat3 u_h;\n" +
      "void main(){ vec3 q = u_h * vec3(outCoord(), 1.0); if (q.z <= 0.0) { gl_FragColor = vec4(0.0); return; }\n" +
      " gl_FragColor = texel(u_tex, u_texSize, q.xy / q.z); }"
};

var FilterEngine = {
   kernels: {},       // name -> { src, params, inputs }
   gl: null,
   canvas: null,
   programs: {},
   failed: false,

   registerKernel: function (name, def) { this.kernels[name] = def; },

   init: function () {
      if (this.gl || this.failed) return !!this.gl;
      this.canvas = makeCanvas(1, 1);
      var gl = this.canvas.getContext("webgl", { premultipliedAlpha: true, alpha: true, preserveDrawingBuffer: true, antialias: false });
      if (!gl) { this.failed = true; return false; }
      this.gl = gl;
      var buf = gl.createBuffer();
      gl.bindBuffer(gl.ARRAY_BUFFER, buf);
      gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1, -1, 1, -1, -1, 1, 1, 1]), gl.STATIC_DRAW);
      gl.pixelStorei(gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL, false);
      gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, false);
      return true;
   },

   program: function (name) {
      if (this.programs[name]) return this.programs[name];
      var gl = this.gl;
      var src = BUILTIN[name] || this.kernels[name].src;
      function sh(type, s) {
         var o = gl.createShader(type);
         gl.shaderSource(o, s);
         gl.compileShader(o);
         if (!gl.getShaderParameter(o, gl.COMPILE_STATUS)) throw new Error(name + ": " + gl.getShaderInfoLog(o));
         return o;
      }
      var p = gl.createProgram();
      gl.attachShader(p, sh(gl.VERTEX_SHADER, VS));
      gl.attachShader(p, sh(gl.FRAGMENT_SHADER, FS_HEAD + src));
      gl.bindAttribLocation(p, 0, "p");
      gl.linkProgram(p);
      if (!gl.getProgramParameter(p, gl.LINK_STATUS)) throw new Error(name + ": " + gl.getProgramInfoLog(p));
      p.uniforms = {};
      return (this.programs[name] = p);
   },

   texture: function (source, w, h) {
      var gl = this.gl, t = gl.createTexture();
      gl.bindTexture(gl.TEXTURE_2D, t);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
      if (source) gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, source);
      else gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, w, h, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);
      t.w = source ? source.width : w;
      t.h = source ? source.height : h;
      return t;
   },

   target: function (w, h) {
      var gl = this.gl, t = this.texture(null, w, h);
      t.fb = gl.createFramebuffer();
      gl.bindFramebuffer(gl.FRAMEBUFFER, t.fb);
      gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, t, 0);
      return t;
   },

   // Runs program `name` into `dst` (a target texture, or null for the canvas).
   pass: function (name, dst, w, h, uniforms, textures) {
      var gl = this.gl, p = this.program(name);
      gl.useProgram(p);
      gl.bindFramebuffer(gl.FRAMEBUFFER, dst ? dst.fb : null);
      gl.viewport(0, 0, w, h);
      gl.disable(gl.BLEND);
      gl.enableVertexAttribArray(0);
      gl.vertexAttribPointer(0, 2, gl.FLOAT, false, 0, 0);
      function loc(n) { if (!(n in p.uniforms)) p.uniforms[n] = gl.getUniformLocation(p, n); return p.uniforms[n]; }
      gl.uniform2f(loc("u_size"), w, h);
      gl.uniform1f(loc("u_flip"), dst ? 0 : 1);
      var unit = 0;
      for (var tn in textures) {
         gl.activeTexture(gl.TEXTURE0 + unit);
         gl.bindTexture(gl.TEXTURE_2D, textures[tn]);
         gl.uniform1i(loc(tn), unit);
         unit++;
      }
      for (var un in uniforms) {
         var v = uniforms[un], l = loc(un);
         if (l == null) continue;
         if (typeof v === "number") gl.uniform1f(l, v);
         else if (v.length === 2) gl.uniform2fv(l, v);
         else if (v.length === 3) gl.uniform3fv(l, v);
         else if (v.length === 4) gl.uniform4fv(l, v);
         else if (v.length === 9) gl.uniformMatrix3fv(l, false, v);
         else if (v.length === 16) gl.uniformMatrix4fv(l, false, v);
      }
      gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
   },

   _resize: function (w, h) {
      if (this.canvas.width !== w || this.canvas.height !== h) { this.canvas.width = w; this.canvas.height = h; }
   },

   // Applies a filter list to `src` (canvas). `pad` extra pixels have already
   // been reserved around the content. Returns a new canvas of the same size.
   apply: function (src, filters, scale) {
      if (!this.init()) return src;
      var gl = this.gl, w = src.width, h = src.height, self = this;
      var created = [];
      function tgt(tw, th) { var t = self.target(tw || w, th || h); created.push(t); return t; }
      var srcTex = this.texture(src); created.push(srcTex);
      var cur = tgt();
      this.pass("load", cur, w, h, { u_texSize: [w, h], u_offset: [0, 0] }, { u_tex: srcTex });

      // Box blur repeated `q` times (Flash's quality). Wide blurs run on a
      // downsampled copy so the cost stays bounded; the result is smooth
      // enough that this is not visible.
      function blur(tex, bx, by, q) {
         var k = Math.max(1, Math.ceil(Math.max(bx, by) / 16));
         var bw = Math.ceil(w / k), bh = Math.ceil(h / k), a = tex;
         if (k > 1) {
            a = tgt(bw, bh);
            self.pass("resample", a, bw, bh, { u_texSize: [w, h], u_scale: [w / bw, h / bh] }, { u_tex: tex });
         }
         for (var i = 0; i < q; i++) {
            if (bx > 1) { var t1 = tgt(bw, bh); self.pass("blur", t1, bw, bh, { u_texSize: [bw, bh], u_dir: [1, 0], u_box: Math.max(1, Math.round(bx / k)) }, { u_tex: a }); a = t1; }
            if (by > 1) { var t2 = tgt(bw, bh); self.pass("blur", t2, bw, bh, { u_texSize: [bw, bh], u_dir: [0, 1], u_box: Math.max(1, Math.round(by / k)) }, { u_tex: a }); a = t2; }
         }
         if (k > 1) {
            var up = tgt();
            self.pass("resample", up, w, h, { u_texSize: [bw, bh], u_scale: [bw / w, bh / h] }, { u_tex: a });
            a = up;
         }
         return a;
      }

      for (var i = 0; i < filters.length; i++) {
         var f = filters[i], next;
         if (f instanceof BlurFilter) {
            cur = blur(cur, f.blurX * scale, f.blurY * scale, f.quality);
         } else if (f instanceof ColorMatrixFilter) {
            var m = f.matrix;
            next = tgt();
            // GLSL mat4 is column major: column j holds input channel j.
            this.pass("colorMatrix", next, w, h, {
               u_texSize: [w, h],
               u_m: [m[0], m[5], m[10], m[15], m[1], m[6], m[11], m[16], m[2], m[7], m[12], m[17], m[3], m[8], m[13], m[18]],
               u_o: [m[4] / 255, m[9] / 255, m[14] / 255, m[19] / 255]
            }, { u_tex: cur });
            cur = next;
         } else if (f instanceof DropShadowFilter || f instanceof GlowFilter) {
            var sh = blur(cur, Math.max(1, f.blurX * scale), Math.max(1, f.blurY * scale), f.quality);
            var rad = f.angle * Math.PI / 180;
            next = tgt();
            var col = f.color >>> 0;
            this.pass("shadow", next, w, h, {
               u_texSize: [w, h],
               u_offset: [Math.cos(rad) * f.distance * scale, Math.sin(rad) * f.distance * scale],
               u_color: [((col >> 16) & 255) / 255, ((col >> 8) & 255) / 255, (col & 255) / 255],
               u_alpha: f.alpha, u_strength: f.strength, u_inner: f.inner ? 1 : 0
            }, { u_tex: cur, u_shadow: sh });
            cur = next;
         } else if (f instanceof ShaderFilter) {
            var k = this.kernels[f.shader.kernel], uni = { u_texSize: [w, h] }, texs = { src: cur };
            for (var pn in k.params) {
               var d = f.shader.data[pn];
               uni[pn] = (d && d.value ? d.value[0] : k.params[pn]) * (k.pixelParams && k.pixelParams[pn] ? scale : 1);
            }
            for (var j = 0; j < (k.inputs || []).length; j++) {
               var inName = k.inputs[j], inp = f.shader.data[inName].input;
               var it = inp ? this.texture(inp.canvas || inp) : this.texture(null, 1, 1);
               created.push(it);
               var lt = this.target(it.w, it.h); created.push(lt);
               this.pass("load", lt, it.w, it.h, { u_texSize: [it.w, it.h], u_offset: [0, 0] }, { u_tex: it });
               texs[inName] = lt;
               uni[inName + "Size"] = [it.w, it.h];
            }
            next = tgt();
            this.pass(f.shader.kernel, next, w, h, uni, texs);
            cur = next;
         }
      }
      this._resize(w, h);
      this.pass("copy", null, w, h, { u_texSize: [w, h], u_offset: [0, 0] }, { u_tex: cur });
      var out = makeCanvas(w, h);
      out.getContext("2d").drawImage(this.canvas, 0, 0);
      for (var c = 0; c < created.length; c++) {
         if (created[c].fb) gl.deleteFramebuffer(created[c].fb);
         gl.deleteTexture(created[c]);
      }
      return out;
   },

   // Draws `src` into a w x h canvas through homography `hm` (dst -> src).
   // The uploaded texture is kept on `src` for the next frame.
   project: function (src, w, h, hm) {
      if (!this.init()) return null;
      var lt = src._glTex;
      if (!lt) {
         var t = this.texture(src);
         lt = this.target(src.width, src.height);
         this.pass("load", lt, src.width, src.height, { u_texSize: [src.width, src.height], u_offset: [0, 0] }, { u_tex: t });
         this.gl.deleteTexture(t);
         src._glTex = lt;
      }
      this._resize(w, h);
      this.pass("project", null, w, h, { u_texSize: [src.width, src.height], u_h: hm }, { u_tex: lt });
      var out = makeCanvas(w, h);
      out.getContext("2d").drawImage(this.canvas, 0, 0);
      return out;
   },

   release: function (src) {
      if (src && src._glTex && this.gl) {
         this.gl.deleteFramebuffer(src._glTex.fb);
         this.gl.deleteTexture(src._glTex);
         src._glTex = null;
      }
   }
};
flash.FilterEngine = FilterEngine;

// ---------------------------------------------------------------------------
// Renderer
// ---------------------------------------------------------------------------

function filterPad(filters, scale) {
   var pad = 0;
   for (var i = 0; i < filters.length; i++) {
      var f = filters[i];
      if (f instanceof ShaderFilter || f instanceof ColorMatrixFilter) continue;
      if (f.inner) continue;
      var q = f.quality || 1;
      pad = Math.max(pad, (Math.max(f.blurX, f.blurY) * q) / 2 + (f.distance || 0) + 2);
   }
   return Math.ceil(pad * scale);
}

var Renderer = {
   // Pixel density used for cached/filtered layers.
   scale: 1,

   drawMedia: function (ctx, m) {
      var s = m.source;
      if (!s) return;
      if (s instanceof BitmapData) s = s.canvas;
      if (s.readyState !== undefined && s.readyState < 2) return;
      if (m.crop) ctx.drawImage(s, m.crop.x, m.crop.y, m.crop.w, m.crop.h, 0, 0, m._w, m._h);
      else ctx.drawImage(s, 0, 0, m._w, m._h);
   },

   // Local content bounds (graphics + children), ignoring filters.
   bounds: function (o) {
      var r = null;
      function union(b) {
         if (!b) return;
         if (!r) { r = b.clone(); return; }
         var x1 = Math.min(r.x, b.x), y1 = Math.min(r.y, b.y);
         r.width = Math.max(r.x + r.width, b.x + b.width) - x1;
         r.height = Math.max(r.y + r.height, b.y + b.height) - y1;
         r.x = x1; r.y = y1;
      }
      if (o._scrollRect) return new Rectangle(0, 0, o._scrollRect.width, o._scrollRect.height);
      if (o.graphics) union(o.graphics.bounds());
      if (o instanceof MediaDisplay) union(new Rectangle(0, 0, o._w, o._h));
      if (o instanceof TextField) union(new Rectangle(0, 0, o._w, o._h));
      if (o.children) {
         for (var i = 0; i < o.children.length; i++) {
            var c = o.children[i];
            if (!c.$visible || c.isMask) continue;
            var b = this.bounds(c);
            if (!b) continue;
            var fp = filterPad(c._filters, 1);
            union(new Rectangle(b.x + c.$x - fp, b.y + c.$y - fp, b.width + 2 * fp, b.height + 2 * fp));
         }
      }
      return r;
   },

   drawText: function (ctx, t) {
      if (!t._text) return;
      ctx.font = fontString(t._fmt);
      ctx.fillStyle = rgba(t._fmt.color, 1);
      ctx.textBaseline = "alphabetic";
      var lh = t.lineHeight, asc = Math.round(t._fmt.size * 0.95);
      for (var i = 0; i < t._lines.length; i++) ctx.fillText(t._lines[i], 2, 2 + asc + i * lh);
   },

   // Renders o's own graphics and children in o's local space.
   renderContent: function (ctx, o, applyFilters) {
      if (applyFilters && o._filters.length) { this.renderFiltered(ctx, o, 0, 0); return; }
      if (o._scrollRect) {
         ctx.save();
         ctx.beginPath();
         ctx.rect(0, 0, o._scrollRect.width, o._scrollRect.height);
         ctx.clip();
         ctx.translate(-o._scrollRect.x, -o._scrollRect.y);
      }
      if (o.graphics && o.graphics.cmds.length) o.graphics.render(ctx);
      if (o instanceof MediaDisplay) this.drawMedia(ctx, o);
      if (o instanceof TextField) this.drawText(ctx, o);
      if (o.children) {
         for (var i = 0; i < o.children.length; i++) {
            var c = o.children[i];
            if (c.is3D) this.render3D(ctx, c, o);
            else this.renderObject(ctx, c);
         }
      }
      if (o._scrollRect) ctx.restore();
      o._dirty = false;
   },

   renderObject: function (ctx, o) {
      if (!o.$visible || o.isMask || o.$alpha <= 0) { o._dirty = false; return; }
      ctx.save();
      if (o._mask) {
         // Masks here are siblings drawn with filled shapes: clip to them.
         var m = o._mask;
         ctx.translate(m.$x, m.$y);
         this.maskPath(ctx, m);
         ctx.translate(-m.$x, -m.$y);
      }
      ctx.translate(o.$x, o.$y);
      ctx.globalAlpha *= o.$alpha;
      if (o._blendMode && o._blendMode !== "normal") ctx.globalCompositeOperation = o._blendMode;
      if (o._filters.length) this.renderFiltered(ctx, o, 0, 0);
      else this.renderContent(ctx, o, false);
      ctx.restore();
   },

   maskPath: function (ctx, m) {
      // Build a clip path from the mask's fill commands.
      var path = new Path2D(), g = m.graphics;
      var fake = {
         isPointInPath: function () { return false; },
         fill: function (p) { path.addPath(p); },
         stroke: function () {}, createPattern: function () { return null; },
         createLinearGradient: function () { return { addColorStop: function () {} }; },
         set fillStyle(v) {}, set strokeStyle(v) {}, set lineWidth(v) {}, set lineJoin(v) {}, set lineCap(v) {},
         imageSmoothingEnabled: true
      };
      g.render(fake);
      ctx.clip(path, "evenodd");
   },

   // Renders o (with its filters) into a cached layer and draws it at (dx,dy).
   renderFiltered: function (ctx, o, dx, dy) {
      var hasShader = o._filters.some(function (f) { return f instanceof ShaderFilter; });
      var s = hasShader ? 1 : this.scale;
      if (o._dirty || !o._cache || o._cache.scale !== s) {
         var b = this.bounds(o);
         if (!b || b.width <= 0 || b.height <= 0) { o._dirty = false; o._cache = null; return; }
         var pad = filterPad(o._filters, 1);
         var bx = Math.floor(b.x - pad), by = Math.floor(b.y - pad);
         var bw = Math.ceil(b.width + 2 * pad + (b.x - pad - bx)), bh = Math.ceil(b.height + 2 * pad + (b.y - pad - by));
         var layer = makeCanvas(bw * s, bh * s);
         var lctx = layer.getContext("2d");
         lctx.scale(s, s);
         lctx.translate(-bx, -by);
         this.renderContent(lctx, o, false);
         var out = FilterEngine.apply(layer, o._filters, s);
         o._cache = { canvas: out, x: bx, y: by, w: bw, h: bh, scale: s };
         o._dirty = false;
      }
      var cch = o._cache;
      ctx.drawImage(cch.canvas, dx + cch.x, dy + cch.y, cch.w, cch.h);
   },

   // --- 2.5D (View4Pic only): perspective projection of flat layers -------

   mat3D: function (o) {
      // Flash order: rotate X, then Y, then Z, then translate.
      var rx = o._rotationX * Math.PI / 180, ry = o._rotationY * Math.PI / 180, rz = o._rotationZ * Math.PI / 180;
      function mul(a, b) {
         var r = new Array(16);
         for (var i = 0; i < 4; i++) for (var j = 0; j < 4; j++) {
            var s = 0;
            for (var k = 0; k < 4; k++) s += a[i * 4 + k] * b[k * 4 + j];
            r[i * 4 + j] = s;
         }
         return r;
      }
      var cx = Math.cos(rx), sx = Math.sin(rx), cy = Math.cos(ry), sy = Math.sin(ry), cz = Math.cos(rz), sz = Math.sin(rz);
      var X = [1, 0, 0, 0, 0, cx, -sx, 0, 0, sx, cx, 0, 0, 0, 0, 1];
      var Y = [cy, 0, sy, 0, 0, 1, 0, 0, -sy, 0, cy, 0, 0, 0, 0, 1];
      var Z = [cz, -sz, 0, 0, sz, cz, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];
      var T = [1, 0, 0, o.$x, 0, 1, 0, o.$y, 0, 0, 1, o._z, 0, 0, 0, 1];
      return mul(T, mul(Z, mul(Y, X)));
   },
   mul4: function (a, b) {
      var r = new Array(16);
      for (var i = 0; i < 4; i++) for (var j = 0; j < 4; j++) {
         var s = 0;
         for (var k = 0; k < 4; k++) s += a[i * 4 + k] * b[k * 4 + j];
         r[i * 4 + j] = s;
      }
      return r;
   },

   // Perspective projection used by `container` (View4Pic): object point
   // (x, y) under 3D matrix M -> container coordinates.
   projector: function (container) {
      var pp = container.transform.perspectiveProjection;
      var focal = pp ? pp.focalLength : 1200;
      // PerspectiveProjection's centre: the middle of the container.
      var cx = pp && pp.projectionCenter ? pp.projectionCenter.x : container.width / 2;
      var cy = pp && pp.projectionCenter ? pp.projectionCenter.y : container.height / 2;
      return function (M, x, y) {
         var X = M[0] * x + M[1] * y + M[3], Y = M[4] * x + M[5] * y + M[7], Z = M[8] * x + M[9] * y + M[11];
         var k = focal / (focal + Z);
         return { x: cx + (X - cx) * k, y: cy + (Y - cy) * k };
      };
   },

   // Calls fn(o, M) for every visible object in a 3D subtree, in paint order.
   walk3D: function (root, fn) {
      var self = this;
      (function walk(o, Mparent) {
         if (!o.$visible) return;
         var M = self.mul4(Mparent, self.mat3D(o));
         fn(o, M);
         if (o.children) for (var i = 0; i < o.children.length; i++) walk(o.children[i], M);
      })(root, [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]);
   },

   // Flat (un-projected) raster of an object's own graphics plus filters.
   flatLayer: function (o) {
      if (o._flat && !o._dirty) return o._flat;
      if (o._flat) FilterEngine.release(o._flat.canvas);
      var b = o.graphics.bounds();
      if (!b) return null;
      var pad = filterPad(o._filters, 1);
      var bx = Math.floor(b.x - pad), by = Math.floor(b.y - pad);
      var bw = Math.ceil(b.width + 2 * pad), bh = Math.ceil(b.height + 2 * pad);
      var layer = makeCanvas(bw, bh), lctx = layer.getContext("2d");
      lctx.translate(-bx, -by);
      o.graphics.render(lctx);
      if (o._filters.length) layer = FilterEngine.apply(layer, o._filters, 1);
      return (o._flat = { canvas: layer, x: bx, y: by, w: bw, h: bh });
   },

   render3D: function (ctx, root, container) {
      if (!root.$visible) return;
      var project = this.projector(container);
      var W = Math.ceil(container.width), H = Math.ceil(container.height);
      var self = this;
      this.walk3D(root, function (o, M) {
         if (o.graphics && o.graphics.cmds.length) {
            var f = self.flatLayer(o);
            if (f) {
               var p0 = project(M, f.x, f.y), p1 = project(M, f.x + f.w, f.y), p2 = project(M, f.x + f.w, f.y + f.h), p3 = project(M, f.x, f.y + f.h);
               var hm = homography([p0, p1, p2, p3], [{ x: 0, y: 0 }, { x: f.w, y: 0 }, { x: f.w, y: f.h }, { x: 0, y: f.h }]);
               var img = FilterEngine.project(f.canvas, W, H, hm);
               if (img) {
                  ctx.save();
                  ctx.globalAlpha *= o.$alpha;
                  ctx.drawImage(img, 0, 0);
                  ctx.restore();
               }
            }
         }
         o._dirty = false;
      });
   },

   // Hit test inside a 3D subtree: maps the container point back onto each
   // layer's plane. Returns { obj, x, y } in that layer's coordinates.
   hit3D: function (root, container, px, py, hitCtx) {
      var project = this.projector(container), found = null;
      this.walk3D(root, function (o, M) {
         if (o.mouseEnabled === false || !o.graphics || !o.graphics.cmds.length) return;
         var b = o.graphics.bounds();
         if (!b) return;
         var c = [project(M, b.x, b.y), project(M, b.x + b.width, b.y), project(M, b.x + b.width, b.y + b.height), project(M, b.x, b.y + b.height)];
         var h = homography(c, [{ x: b.x, y: b.y }, { x: b.x + b.width, y: b.y }, { x: b.x + b.width, y: b.y + b.height }, { x: b.x, y: b.y + b.height }]);
         var w = h[2] * px + h[5] * py + h[8];
         if (w <= 0) return;
         var u = (h[0] * px + h[3] * py + h[6]) / w, v = (h[1] * px + h[4] * py + h[7]) / w;
         if (o.graphics.render(hitCtx, { x: u, y: v })) found = { obj: o, x: u, y: v, local: true };
      });
      return found;
   }
};
flash.Renderer = Renderer;

// Homography mapping 4 dst points to 4 src points, as a column-major mat3.
function homography(dst, src) {
   var A = [], B = [];
   for (var i = 0; i < 4; i++) {
      var x = dst[i].x, y = dst[i].y, u = src[i].x, v = src[i].y;
      A.push([x, y, 1, 0, 0, 0, -u * x, -u * y]); B.push(u);
      A.push([0, 0, 0, x, y, 1, -v * x, -v * y]); B.push(v);
   }
   // Gaussian elimination.
   for (var c = 0; c < 8; c++) {
      var piv = c;
      for (var r = c + 1; r < 8; r++) if (Math.abs(A[r][c]) > Math.abs(A[piv][c])) piv = r;
      var t = A[c]; A[c] = A[piv]; A[piv] = t; t = B[c]; B[c] = B[piv]; B[piv] = t;
      for (var r2 = 0; r2 < 8; r2++) {
         if (r2 === c) continue;
         var f = A[r2][c] / A[c][c];
         for (var k = c; k < 8; k++) A[r2][k] -= f * A[c][k];
         B[r2] -= f * B[c];
      }
   }
   var h = [];
   for (var j = 0; j < 8; j++) h.push(B[j] / A[j][j]);
   // Row-major [h0 h1 h2; h3 h4 h5; h6 h7 1] -> column-major.
   return [h[0], h[3], h[6], h[1], h[4], h[7], h[2], h[5], 1];
}

// ---------------------------------------------------------------------------
// Stage: owns the canvas, the frame loop and mouse input.
// ---------------------------------------------------------------------------

class Stage extends DisplayObjectContainer {
   constructor(canvas, frameRate) {
      super();
      this.canvas = canvas;
      this.ctx = canvas.getContext("2d");
      this.frameRate = frameRate || 24;
      this.stageWidth = 500;
      this.stageHeight = 375;
      this.viewScale = 1;
      this.align = "TL";
      this.scaleMode = "noScale";
      Stage.current = this;
      this._hoverChain = [];
      this._downTarget = null;
      this._setupInput();
      var self = this, last = performance.now(), acc = 0;
      function loop(now) {
         acc += now - last; last = now;
         var frame = 1000 / self.frameRate;
         if (acc >= frame) {
            acc = acc % frame;
            var e = new Event(Event.ENTER_FRAME);
            enterFrameListeners.forEach(function (d) { e.target = d; d._invoke(e); });
            if (Stage._needsRender || self._liveMedia()) self.render();
         }
         requestAnimationFrame(loop);
      }
      requestAnimationFrame(loop);
   }
   static requestRender() { Stage._needsRender = true; }

   // Video-backed objects keep the stage redrawing while they play.
   _liveMedia() {
      var live = false;
      (function walk(o) {
         if (!o.$visible) return;
         if (o instanceof MediaDisplay && o.live) { o._invalidate(); live = true; }
         if (o.children) for (var i = 0; i < o.children.length; i++) walk(o.children[i]);
      })(this);
      return live;
   }

   // Sets the logical stage size and the CSS-pixel scale it is shown at.
   setSize(w, h, viewScale) {
      this.stageWidth = w;
      this.stageHeight = h;
      this.viewScale = viewScale;
      var dpr = global.devicePixelRatio || 1;
      this.canvas.width = Math.round(w * viewScale * dpr);
      this.canvas.height = Math.round(h * viewScale * dpr);
      this.canvas.style.width = (w * viewScale) + "px";
      this.canvas.style.height = (h * viewScale) + "px";
      Renderer.scale = Math.min(2, viewScale * dpr);
      this._invalidate();
      this.dispatchEvent(new Event(Event.RESIZE));
      this.render();
   }

   render() {
      Stage._needsRender = false;
      var ctx = this.ctx, s = this.canvas.width / this.stageWidth;
      ctx.setTransform(1, 0, 0, 1, 0, 0);
      ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
      ctx.setTransform(s, 0, 0, s, 0, 0);
      ctx.imageSmoothingEnabled = true;
      Renderer.renderContent(ctx, this, false);
   }

   // --- input --------------------------------------------------------------

   _toStage(e) {
      var r = this.canvas.getBoundingClientRect();
      return { x: (e.clientX - r.left) / r.width * this.stageWidth, y: (e.clientY - r.top) / r.height * this.stageHeight };
   }

   // Deepest interactive object under (x, y), testing shapes like Flash does.
   hitTest(x, y) {
      var hitCtx = Stage._hitCtx || (Stage._hitCtx = makeCanvas(1, 1).getContext("2d"));
      function test(o, lx, ly) {
         if (!o.$visible || o.isMask) return null;
         lx -= o.$x; ly -= o.$y;
         if (o._scrollRect) {
            if (lx < 0 || ly < 0 || lx >= o._scrollRect.width || ly >= o._scrollRect.height) return null;
            lx += o._scrollRect.x; ly += o._scrollRect.y;
         }
         if (o._mask) {
            var m = o._mask, mb = m.graphics.bounds();
            if (!mb || !m.graphics.render(hitCtx, { x: lx + o.$x - m.$x, y: ly + o.$y - m.$y })) return null;
         }
         if (o.is3D) return Renderer.hit3D(o, o.parent, lx + o.$x, ly + o.$y, hitCtx);
         if (o.children && o.mouseChildren !== false) {
            for (var i = o.children.length - 1; i >= 0; i--) {
               var r = test(o.children[i], lx, ly);
               if (r) {
                  if (o.mouseChildren === false) return { obj: o, x: lx, y: ly };
                  return r;
               }
            }
         }
         var hit = false;
         if (o.graphics && o.graphics.cmds.length) hit = o.graphics.render(hitCtx, { x: lx, y: ly });
         if (!hit && o instanceof MediaDisplay) hit = lx >= 0 && ly >= 0 && lx < o._w && ly < o._h;
         if (!hit && o instanceof TextField) hit = lx >= 0 && ly >= 0 && lx < o._w && ly < o._h;
         if (hit) {
            // Non-interactive leaves (text, bitmaps) report their parent.
            var t = o;
            while (t && (t instanceof TextField || t instanceof MediaDisplay || t.mouseEnabled === false)) t = t.parent;
            return t ? { obj: t, x: lx, y: ly } : null;
         }
         return null;
      }
      for (var i = this.children.length - 1; i >= 0; i--) {
         var r = test(this.children[i], x, y);
         if (r) return r;
      }
      return null;
   }

   _mouse(type, target, pt, bubbles, hit) {
      var e = new MouseEvent(type, bubbles !== false);
      e.stageX = pt.x; e.stageY = pt.y;
      var l = hit && hit.local && hit.obj === target ? hit : target._globalToLocal(pt.x, pt.y);
      e.localX = l.x; e.localY = l.y;
      target.dispatchEvent(e);
   }

   _updateHover(pt) {
      var hit = this.hitTest(pt.x, pt.y);
      var chain = [];
      for (var o = hit ? hit.obj : null; o && o !== this; o = o.parent) chain.unshift(o);
      var old = this._hoverChain, i;
      for (i = old.length - 1; i >= 0; i--) {
         if (chain.indexOf(old[i]) < 0) this._mouse(MouseEvent.ROLL_OUT, old[i], pt, false);
      }
      for (i = 0; i < chain.length; i++) {
         if (old.indexOf(chain[i]) < 0) this._mouse(MouseEvent.ROLL_OVER, chain[i], pt, false);
      }
      this._hoverChain = chain;
      this.canvas.style.cursor = "default";
      return hit;
   }

   _setupInput() {
      var self = this, c = this.canvas;
      c.style.touchAction = "none";
      c.addEventListener("pointermove", function (ev) {
         var pt = self._toStage(ev);
         Stage.mouse = pt;
         var hit = self._updateHover(pt);
         if (hit) self._mouse(MouseEvent.MOUSE_MOVE, hit.obj, pt);
         self._invoke(Object.assign(new MouseEvent(MouseEvent.MOUSE_MOVE), { stageX: pt.x, stageY: pt.y, target: self }));
      });
      c.addEventListener("pointerdown", function (ev) {
         if (ev.button > 0) return;
         c.setPointerCapture && c.setPointerCapture(ev.pointerId);
         var pt = self._toStage(ev);
         Stage.mouse = pt;
         var hit = self._updateHover(pt);
         self._downTarget = hit ? hit.obj : null;
         if (hit) self._mouse(MouseEvent.MOUSE_DOWN, hit.obj, pt);
         else self._invoke(Object.assign(new MouseEvent(MouseEvent.MOUSE_DOWN), { target: self }));
         ev.preventDefault();
      });
      c.addEventListener("pointerup", function (ev) {
         if (ev.button > 0) return;
         var pt = self._toStage(ev);
         Stage.mouse = pt;
         var hit = self.hitTest(pt.x, pt.y);
         var obj = hit ? hit.obj : null;
         if (obj) self._mouse(MouseEvent.MOUSE_UP, obj, pt);
         else self._invoke(Object.assign(new MouseEvent(MouseEvent.MOUSE_UP), { target: self }));
         // Flash sends MOUSE_UP to the stage's listeners even when over a child.
         if (obj) self._invoke(Object.assign(new MouseEvent(MouseEvent.MOUSE_UP), { target: obj, stageX: pt.x, stageY: pt.y }));
         if (obj && obj === self._downTarget) self._mouse(MouseEvent.CLICK, obj, pt, true, hit);
         self._downTarget = null;
         if (ev.pointerType !== "mouse") {
            // Touch has no hover: leave everything after the tap.
            self._updateHover({ x: -1e6, y: -1e6 });
         }
      });
      c.addEventListener("pointerleave", function (ev) {
         if (ev.pointerType !== "mouse") return;
         self._updateHover({ x: -1e6, y: -1e6 });
         self._invoke(Object.assign(new MouseEvent(MouseEvent.ROLL_OUT), { target: self }));
      });
   }
}
Stage.mouse = { x: 0, y: 0 };
Stage._needsRender = true;
flash.Stage = Stage;

// ---------------------------------------------------------------------------
// flash.utils.Timer-like helper and misc.
// ---------------------------------------------------------------------------

class Timer extends EventDispatcher {
   constructor(delay) { super(); this.delay = delay; this.running = false; this._id = 0; }
   start() {
      if (this.running) return;
      this.running = true;
      var self = this;
      this._id = setInterval(function () { self.dispatchEvent(new Event("timer")); }, this.delay);
   }
   stop() { if (!this.running) return; this.running = false; clearInterval(this._id); }
}
flash.Timer = Timer;

flash.homography = homography;

})(window);
