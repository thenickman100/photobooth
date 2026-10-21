/*
 * photobooth.js - port of com.karthik.photobooth's UI shell (Main, the
 * screen grid, control bar, photo strip, viewer, pop-ups) and the document
 * class PhotoBooth_AS_Port, plus the boot code that replaces the Flash
 * projector.
 *
 * Every class follows the decompiled ActionScript in reference/as3/.
 * Comments starting with "CHANGE:" mark where this port differs from the
 * original, and why.
 */
(function (global) {
"use strict";

var F = global.flash, K = global.karthik, PB = global.photobooth;
var Singletons = K.Singletons, HashUtil = K.HashUtil, TimerManager = K.TimerManager;
var KComponent = K.KComponent, KSprite = K.KSprite, Button = K.Button, Label = K.Label;
var LayoutAnimator = K.LayoutAnimator, AnimationEvent = K.AnimationEvent, KState = K.KState;
var CollectionEvent = K.CollectionEvent;
var Event = F.Event, MouseEvent = F.MouseEvent, Matrix = F.Matrix, Point = F.Point, Rectangle = F.Rectangle, BitmapData = F.BitmapData;
var Model = PB.Model, BaseScreen = PB.BaseScreen;
var skins = PB.skins;

// ---------------------------------------------------------------------------
// Growl notifications (com.karthik.photobooth.managers)
// ---------------------------------------------------------------------------

class GrowlBox extends KComponent {
   constructor(icon) {
      super({ skin: Singletons.getInstance(skins.GrowlBoxSkin), width: 180 });
      this.icon = null;
      this.closeBtnAlpha = 0;
      this.bodyTf = new F.TextFormat("Lucida Grande", 11, 3355443);
      this.closeBtn = null;
      this.textChanged = false;
      this.iconBmp = icon ? icon : GrowlBox.defIconBmp;
      this.header = null;
      this._bodyText = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse quam magna, gravida i";
      this.headerTf = new F.TextFormat("Lucida Grande", 11, 2236962, true);
      this.body = null;
      this.outlineWidth = 5;
      this.margin = 4;
      this.headerBodySpace = 1;
      this._headerText = "header text";
      this.explicitHeight = NaN;
      this.skin = null;
      this.animator = new LayoutAnimator(this);
      this.animator.positionFunc = this.positionFunc;
      this.addEventListener(MouseEvent.ROLL_OVER, this.b.rollOverListener);
      this.addEventListener(MouseEvent.ROLL_OUT, this.b.rollOutListener);
   }
   static get defIconBmp() { return PB.Assets.bitmaps.GrowlBox_Icon; }
   static get downloadIconBmp() { return PB.Assets.bitmaps.GrowlBox_IconDl; }
   rollOverListener(e) {
      if (this.animator) {
         this.closeBtnAlpha = 1;
         this.animator.invalidate();
         this.invalidate();
      }
   }
   update() {
      this.animator.validate();
      if (this.wasResized || this.textChanged) {
         this.textChanged = false;
         this.header.text = this._headerText;
         this.body.text = this._bodyText;
         this.header.setTextFormat(this.headerTf);
         this.body.setTextFormat(this.bodyTf);
         this.header.y = this.margin;
         this.header.x = this.iconBmp ? this.iconBmp.width + this.margin + 2 : this.margin;
         this.body.x = this.iconBmp ? this.iconBmp.width + this.margin + 2 : this.margin;
         this.body.y = this.header.y + this.header.height + this.headerBodySpace;
         this.body.width = this.width - 2 * this.margin - (this.iconBmp ? this.iconBmp.width + 2 : 0);
         if (isNaN(this.explicitHeight)) this.height = this.getMeasuredHeight();
         else this.height = this.explicitHeight;
         this.skin.draw(this);
      }
   }
   getMeasuredHeight() { return this.body ? this.body.y + this.body.height + this.margin : 100; }
   positionFunc() { this.animator.setTargets(this.closeBtn, 5, 5, 22, 22, this.closeBtnAlpha); }
   set headerText(v) { if (v === this.headerText) return; this._headerText = v; this.textChanged = true; this.invalidate(); }
   get headerText() { return this._headerText; }
   set bodyText(v) { if (v === this.bodyText) return; this._bodyText = v; this.textChanged = true; this.invalidate(); }
   get bodyText() { return this._bodyText; }
   createChildren() {
      this.body = new F.TextField();
      this.body.selectable = false;
      this.body.autoSize = F.TextFieldAutoSize.LEFT;
      this.body.wordWrap = true;
      this.body.multiline = true;
      this.body.setTextFormat(this.bodyTf);
      this.addChild(this.body);
      this.header = new F.TextField();
      this.header.selectable = false;
      this.header.autoSize = F.TextFieldAutoSize.LEFT;
      this.header.wordWrap = false;
      this.header.multiline = false;
      this.header.setTextFormat(this.headerTf);
      this.addChild(this.header);
      this.icon = new F.Sprite();
      this.icon.graphics.clear();
      this.icon.graphics.beginBitmapFill(this.iconBmp);
      this.icon.graphics.drawRect(0, 0, this.iconBmp.width, this.iconBmp.height);
      this.addChild(this.icon);
      this.icon.x = this.icon.y = this.margin;
      this.closeBtn = new Button({ width: 22, height: 22, skin: Singletons.getInstance(skins.GrowBoxCloseButtonSkin) });
      this.animator.addChild(this.closeBtn);
      this.animator.targetFor(this.closeBtn).doNotManageVisibility = true;
      this.animator.animationSpeed = 0.2;
      this.addChild(this.closeBtn);
      this.closeBtn.addEventListener(MouseEvent.CLICK, this.b.closeBtnClickListener);
   }
   rollOutListener(e) {
      if (this.animator) {
         this.closeBtnAlpha = 0;
         this.animator.invalidate();
         this.invalidate();
      }
   }
   closeBtnClickListener(e) { e.stopPropagation(); this.dispatchEvent(new Event("closeBox")); }
}
PB.GrowlBox = GrowlBox;

class BoxQueueItem {
   constructor(box, timeout) { this.timeout = timeout; this.currentTime = 0; this.box = box; }
}

class GrowlManager extends K.PopUpManager {
   constructor(root) {
      super();
      this.vGap = 5;
      this.hGap = 5;
      this.boxWidth = 120;
      this.boxesArr = [];
      this.animator = null;
      this.initialize(root);
      TimerManager.getInstance().addCallBack(this.removeTimeoutBoxes, 1, false, this);
      TimerManager.getInstance().pauseCallBack(this.removeTimeoutBoxes);
      this.animator = new LayoutAnimator(this);
      this.animator.positionFunc = this.positionFunc;
      this.animator.animationSpeed = 0.05;
   }
   static init(root) { GrowlManager._manager = new GrowlManager(root); }
   static getInstance() { return GrowlManager._manager; }
   removeTimeoutBoxes() {
      for (var i = this.boxesArr.length - 1; i >= 0; i--) {
         var item = this.boxesArr[i];
         if (!item) continue;
         ++item.currentTime;
         if (item.currentTime >= item.timeout) this.removeBoxFromStage(item.box);
      }
      if (this.boxesArr.length === 0) TimerManager.getInstance().pauseCallBack(this.removeTimeoutBoxes);
   }
   closeBoxListener(e) { this.removeBoxFromStage(e.currentTarget); }
   showMessage(header, body, icon, timeout) {
      var box = new GrowlBox(icon);
      box.headerText = header;
      box.bodyText = body;
      this.addGrowBoxToStage(box, timeout == null ? 6 : timeout);
      return box;
   }
   addPopUp(c, blur) {
      this.animator.animationSpeed = 0.01;
      c.validateNow();
      c.alpha = 0;
      if (!this.contains(c)) {
         this.addChild(c);
         this.animator.addChild(c);
      }
      c.move((this.root.stage.stageWidth - c.width) / 2, (this.root.stage.stageHeight - c.height) / 2);
      this.animator.targetFor(c).doNotManageVisibility = true;
      this.animator.targetFor(c).jumptoPosAfterAdded = false;
      this.animator.setTargets(c, c.x, c.y, c.width, c.height, 1);
      this.animator.invalidate();
      this.animator.validate();
      if (blur) this.blurBeneath();
   }
   addGrowBoxToStage(box, timeout) {
      if (timeout == null) timeout = 8;
      this.animator.animationSpeed = 0.05;
      var x, y;
      if (this.boxesArr.length === 0) {
         x = this.root.stage.stageWidth - (180 + this.hGap);
         y = this.vGap;
      } else {
         var last = this.boxesArr[this.boxesArr.length - 1].box;
         last.validateNow();
         if (last.y + last.height + (this.vGap + last.height) > this.root.stage.stageHeight) {
            x = last.x - (this.boxWidth + this.hGap);
            y = this.vGap;
         } else {
            x = last.x;
            y = last.y + last.height + this.vGap;
         }
      }
      this.boxesArr.push(new BoxQueueItem(box, timeout));
      box.addEventListener("closeBox", this.b.closeBoxListener);
      this.addChild(box);
      box.alpha = 0;
      box.move(x, y);
      this.animator.addChild(box);
      this.animator.targetFor(box).doNotManageVisibility = true;
      this.animator.targetFor(box).jumptoPosAfterAdded = false;
      this.animator.setTargets(box, box.x, box.y, box.width, box.height, 1);
      this.animator.invalidate();
      this.animator.validate();
      this.makeSureOnTop();
      TimerManager.getInstance().resumeCallBack(this.removeTimeoutBoxes);
   }
   positionFunc() {}
   removePopUp(c) {
      this.removeChild(c);
      this.animator.removeChild(c);
      if (this.blurred) this.unblurBeneath();
   }
   removeBoxFromStage(box) {
      if (!box) return;
      for (var i = this.boxesArr.length - 1; i >= 0; i--) {
         if (this.boxesArr[i].box === box) { this.boxesArr.splice(i, 1); break; }
      }
      if (!this.animator.targetFor(box)) return;
      this.animator.targetFor(box).targetAlpha = 0;
      var self = this;
      this.animator.targetFor(box).addEventListener(AnimationEvent.ANIMATION_COMPLETE, function () {
         if (self.contains(box)) {
            self.removeChild(box);
            self.animator.removeChild(box);
         }
      });
      this.animator.validate();
   }
}
GrowlManager._manager = null;
PB.GrowlManager = GrowlManager;

// ---------------------------------------------------------------------------
// Pop-ups (com.karthik.photobooth.popups)
// ---------------------------------------------------------------------------

class Flasher extends KComponent {
   constructor(root) { super(); this._root = root; this._value = 0; this.valueChanged = false; }
   update() {
      super.update();
      if (this.valueChanged) {
         this.valueChanged = false;
         this.graphics.clear();
         this.graphics.beginFill(16777215, this.value);
         this.graphics.drawRect(0, 0, this._root.stage.stageWidth, this._root.stage.stageHeight);
         if (this.value <= 0) this.graphics.clear();
      }
   }
   get value() { return this._value; }
   set value(v) { if (this.value === v) return; this._value = v; this.valueChanged = true; this.invalidate(); }
}
PB.Flasher = Flasher;

class KPanel extends KComponent {
   constructor(options) {
      super(HashUtil.mergeHash({ width: 300, height: 150, skin: Singletons.getInstance(PB.SimpleWindowSkin) }, options));
      this._titleTextFormat = new F.TextFormat("Lucida Grande", 12, 3355443);
      this._titleText = "Panel title";
      this.titleTextChanged = true;
      this.title = null;
      this.skin = null;
   }
   get titleText() { return this._titleText; }
   set titleText(v) { if (v === this.titleText) return; this._titleText = v; this.titleTextChanged = true; this.invalidate(); }
   update() {
      super.update();
      if (this.wasResized) {
         this.skin.draw(this);
         this.positionText();
      }
      if (this.titleTextChanged) {
         this.titleTextChanged = false;
         this.title.text = this._titleText;
         this.title.setTextFormat(this._titleTextFormat);
         this.positionText();
      }
   }
   positionText() {
      this.title.x = (this.width - this.title.textWidth) / 2;
      this.title.y = (20 - this.title.textHeight) / 2;
   }
   createChildren() {
      this.title = new F.TextField();
      this.title.multiline = false;
      this.title.selectable = false;
      this.title.autoSize = F.TextFieldAutoSize.LEFT;
      this.addChild(this.title);
   }
   get titleTextFormat() { return this._titleTextFormat; }
   set titleTextFormat(v) { if (v === this.titleTextFormat) return; this._titleTextFormat = v; this.titleTextChanged = true; this.invalidate(); }
}

class TextButton extends Button {
   constructor(options) {
      super(HashUtil.mergeHash({ width: 70, height: 22, skin: Singletons.getInstance(PB.MacButtonSkin) }, options));
      this._labelText = undefined;
      this.labelTextChanged = true;
      this.label = null;
   }
   update() {
      super.update();
      if (this.labelTextChanged) {
         this.labelTextChanged = false;
         this.label.text = this.labelText;
         this.positionLabel();
      }
      this.label.fontColor = this.disabled ? 6710886 : 3487029;
      if (this.wasResized) {
         this.label.validateNow();
         this.positionLabel();
      }
   }
   get labelText() { return this._labelText; }
   set labelText(v) { if (v === this.labelText) return; this._labelText = v; this.labelTextChanged = true; this.invalidate(); }
   createChildren() {
      super.createChildren();
      this.label = new Label();
      this.label.fontSize = 11;
      this.label.fontColor = 3487029;
      this.addChild(this.label);
   }
   positionLabel() {
      var w = this.label.getMeasuredWidth(), h = this.label.getMeasuredHeight();
      this.label.move((this.width - w) / 2, (this.height - h) / 2 - 2);
      this.label.setActualSize(w, h);
   }
}

class TextFieldMultiLine extends F.TextField {
   constructor() {
      super();
      this.selectable = false;
      this.multiline = true;
      this.autoSize = F.TextFieldAutoSize.LEFT;
      this.wordWrap = true;
   }
}

class FileCompleteBox extends KPanel {
   constructor() {
      super({ width: 200, height: 100, skin: Singletons.getInstance(PB.SimpleWindowSkin) });
      this.button = null;
      this.text = null;
   }
   update() {
      super.update();
      if (this.wasResized) {
         this.skin.draw(this);
         this.text.x = 10;
         this.text.y = 30;
         this.button.move((this.width - 120) / 2, this.height - 30);
      }
   }
   createChildren() {
      super.createChildren();
      this.titleText = "Complete";
      this.text = new TextFieldMultiLine();
      this.text.width = 180;
      this.text.text = "Encoding complete. Click the button below to save your image";
      this.text.setTextFormat(new F.TextFormat("Lucida Grande", 11, 15658734));
      this.addChild(this.text);
      this.button = new TextButton({ width: 120, height: 22 });
      this.button.labelText = "Download";
      this.addChild(this.button);
   }
}

class FileEncodingPopup extends GrowlBox {
   constructor() { super(GrowlBox.downloadIconBmp); this.spb = null; this._progress = 0; }
   set progress(v) { if (v === this.progress) return; this._progress = v; this.spb.progress = v; }
   get progress() { return this._progress; }
   update() {
      super.update();
      if (this.wasResized) {
         this.spb.setActualSize(120, 7);
         this.spb.move((this.width - 120) / 2, this.height / 2 + 10);
      }
   }
   createChildren() {
      super.createChildren();
      this.spb = new PB.SimpleProgressBar();
      this.addChild(this.spb);
      this.headerText = "Encoding";
      this.bodyText = "please wait";
      this.explicitHeight = 65;
   }
}

// ---------------------------------------------------------------------------
// JPEG encoding (com.karthik.photobooth.image)
// ---------------------------------------------------------------------------

class JPEGEncodeEvent extends Event {
   constructor(type) { super(type); this.progress = 0; this.completedEncode = null; }
}
JPEGEncodeEvent.EVENT_PROGRESS = "jpeg_progress";
JPEGEncodeEvent.EVENT_COMPLETE = "jpeg_complete";

// CHANGE: ASJPEGEncoder was a hand-written baseline JPEG encoder that worked
// in slices to report progress. The browser's own encoder replaces it, at
// the original's quality setting of 50.
class ASJPEGEncoder extends F.EventDispatcher {
   constructor(quality) { super(); this.quality = quality == null ? 50 : quality; }
   startEncode(bmp) {
      var self = this;
      var p = new JPEGEncodeEvent(JPEGEncodeEvent.EVENT_PROGRESS);
      p.progress = 0.1;
      this.dispatchEvent(p);
      bmp.canvas.toBlob(function (blob) {
         var pe = new JPEGEncodeEvent(JPEGEncodeEvent.EVENT_PROGRESS);
         pe.progress = 1;
         self.dispatchEvent(pe);
         // Let the progress bar show full before the pop-up closes.
         setTimeout(function () {
            var c = new JPEGEncodeEvent(JPEGEncodeEvent.EVENT_COMPLETE);
            c.progress = 1;
            c.completedEncode = blob;
            self.dispatchEvent(c);
         }, 250);
      }, "image/jpeg", this.quality / 100);
   }
}

var Resizer = {
   FACEBOOK_MAX_WIDTH: 600,
   FACEBOOK_MAX_HEIGHT: 450,
   resizeToFacebook: function (bmp) {
      var out = new BitmapData(Resizer.FACEBOOK_MAX_WIDTH, Resizer.FACEBOOK_MAX_HEIGHT);
      out.draw(bmp, new Matrix(out.width / bmp.width, 0, 0, out.height / bmp.height));
      return out;
   }
};

// ---------------------------------------------------------------------------
// Control bar (com.karthik.photobooth.control_bar)
// ---------------------------------------------------------------------------

class SelectableButton extends Button {
   constructor(options) { super(options); this._selected = false; }
   mouseUp(e) { if (this.selected) return; super.mouseUp(e); }
   set selected(v) {
      if (v === this._selected) return;
      this._selected = v;
      this._state = v ? "down" : "normal";
      this.stateChanged = true;
      this.invalidate();
   }
   get selected() { return this._selected; }
   mouseOver(e) { if (this.selected) return; super.mouseOver(e); }
   mouseOut(e) { if (this.selected) return; super.mouseOut(e); }
}

class DumbDotButtonSkin extends K.KButtonSkin {
   drawOver() { this.drawNormal(); }
   drawNormal() { this.drawBtn(6974058, 13224393); }
   drawDown() { this.drawBtn(2302755, 13224393); }
   drawBtn(fill, line) {
      this.drawKRoundRect({ target: this.btn, width: 16, height: 16, radius: 2, lineStyle: { thickness: 0, alpha: 0 }, fillStyle: { color: fill, alpha: 1 } });
      this.drawPath({ target: this.btn, fillStyle: null, lineStyle: { thickness: 1, color: line, alpha: 1 }, pts: [[0, 16], [14, 16]] });
   }
}

class DumbDotButton extends SelectableButton {
   constructor() { super({ width: 16, height: 17 }); this.bSkin = Singletons.getInstance(DumbDotButtonSkin); }
   update() {
      if (this.stateChanged || this.wasResized) {
         this.stateChanged = false;
         this.bSkin.draw(this);
      }
   }
}

class ShutterButton extends Button {
   constructor() {
      super({ skin: Singletons.getInstance(PB.ShutterButtonSkinNormal), width: 39, height: 38 });
      this._movieMode = true;
      this._inactive = false;
   }
   get movieMode() { return this._movieMode; }
   set movieMode(v) { if (v === this.movieMode) return; this._movieMode = v; this.stateChanged = true; this.invalidate(); }
   set inactive(v) { if (v === this.inactive) return; this._inactive = v; this.stateChanged = true; this.invalidate(); }
   get inactive() { return this._inactive; }
}

class CountDownCam extends KComponent {
   constructor() { super(); this.glowMask = null; this.stateChanged = false; this._state = 1; this.skin = Singletons.getInstance(PB.CountdownCamSkin); }
   set state(v) { if (v === this.state) return; this._state = v; this.stateChanged = true; this.invalidate(); }
   get state() { return this._state; }
   update() {
      if (this.wasResized || this.stateChanged) {
         this.stateChanged = false;
         this.skin.draw(this, { glowMask: this.glowMask });
      }
   }
   createChildren() {
      this.glowMask = new F.Sprite();
      this.glowMask.filters = [new F.GlowFilter(16777215, 0.7, 20, 20, 4, 3)];
      this.addChild(this.glowMask);
   }
}
CountDownCam.STATE_DIM = 1;
CountDownCam.STATE_BRIGHT = 2;
CountDownCam.STATE_1QUAD = 3;
CountDownCam.STATE_2QUAD = 4;
CountDownCam.STATE_3QUAD = 5;

class EffectsButton extends Button {
   constructor() {
      super({ width: 125, height: 25, skin: Singletons.getInstance(PB.EBSkinNormal) });
      this._maskLB = null;
      this._mode = 1;
      this._maskRB = null;
      this.modeChanged = true;
      this.leftBtn = null;
      this.rightBtn = null;
      this._rightEnabled = true;
      this.label = null;
      this._leftEnabled = true;
      this.animator = new LayoutAnimator(this);
      this.animator.positionFunc = this.positionFunc;
      this.addEventListener(MouseEvent.CLICK, this.b.clickListener);
   }
   set leftEnabled(v) { if (v === this.leftEnabled) return; this._leftEnabled = v; this.stateChanged = true; this.invalidate(); }
   get leftEnabled() { return this._leftEnabled; }
   set rightEnabled(v) { if (v === this.rightEnabled) return; this._rightEnabled = v; this.stateChanged = true; this.invalidate(); }
   get rightEnabled() { return this._rightEnabled; }
   set mode(v) { if (v === this.mode) return; this._mode = v; this.stateChanged = true; this.animator.invalidate(); this.invalidate(); }
   get mode() { return this._mode; }
   positionFunc() {
      var w = 30, h = 22;
      if (this.mode === EffectsButton.MODE_EFFECTS) {
         this.animator.setTargets(this.leftBtn, 1, 1, w + 1, h);
         this.animator.setTargets(this.rightBtn, this.width - 1 - w, 1, w, h);
      } else {
         this.animator.setTargets(this.leftBtn, -w - 1, 1, w + 1, h);
         this.animator.setTargets(this.rightBtn, this.width, 1, w, h);
      }
   }
   update() {
      if (this.wasResized || this.stateChanged) {
         this.stateChanged = false;
         this.leftBtn.disabled = !this._leftEnabled;
         this.rightBtn.disabled = !this._rightEnabled;
         this.skin.draw(this, { left: this.leftBtn, right: this.rightBtn, mask1: this._maskLB, mask2: this._maskRB, label: this.label });
         this.label.text = "Effects";
         this.label.fontSize = 12;
         this.label.validateNow();
         var w = this.label.getMeasuredWidth(), h = this.label.getMeasuredHeight();
         this.label.move((this.width - w) / 2, (this.height - h) / 2 - 2);
      }
      this.animator.validate();
   }
   lb_clickListener(e) { e.stopPropagation(); this.dispatchEvent(new Event("leftScroll", true)); }
   rb_clickListener(e) { e.stopPropagation(); this.dispatchEvent(new Event("rightScroll", true)); }
   createChildren() {
      super.createChildren();
      this.leftBtn = new Button();
      this.rightBtn = new Button();
      this.leftBtn.addEventListener(MouseEvent.CLICK, this.b.lb_clickListener);
      this.rightBtn.addEventListener(MouseEvent.CLICK, this.b.rb_clickListener);
      this.label = new Label();
      this.addChild(this.label);
      this.addChild(this.leftBtn);
      this.addChild(this.rightBtn);
      this.animator.addChild(this.leftBtn);
      this.animator.addChild(this.rightBtn);
      this._maskLB = new F.Sprite();
      this.addChild(this._maskLB);
      this._maskRB = new F.Sprite();
      this.addChild(this._maskRB);
      this.leftBtn.mask = this._maskLB;
      this.rightBtn.mask = this._maskRB;
   }
   clickListener(e) {
      e.stopPropagation();
      this.mode = this.mode === EffectsButton.MODE_EFFECTS ? EffectsButton.MODE_NORMAL : EffectsButton.MODE_EFFECTS;
      var ev = new PB.ModeChangeEvent();
      ev.targetMode = this.mode === EffectsButton.MODE_EFFECTS ? EffectsButton.MODE_EFFECTS : EffectsButton.MODE_NORMAL;
      this.dispatchEvent(ev);
   }
   mouseOver(e) {}
}
EffectsButton.MODE_NORMAL = 1;
EffectsButton.MODE_EFFECTS = 2;

class PicModeButtonBar extends KComponent {
   constructor() {
      super({ width: 92, height: 25 });
      this.maskL = null; this.maskR = null;
      this.stateChanged = true;
      this.btn4Pic = null; this.btn1Pic = null; this.btnVid = null;
      this._state = 1;
      this.skin = Singletons.getInstance(PB.PicModeBtnBarSkin);
   }
   set state(v) {
      if (v === this.state) return;
      this._state = v;
      this.dispatchEvent(new Event("picModeChange"));
      this.stateChanged = true;
      this.invalidate();
   }
   get state() { return this._state; }
   update() {
      if (this.wasResized || this.stateChanged) {
         this.btn1Pic.move(1, 1); this.btn1Pic.setActualSize(29, 22);
         this.btn4Pic.move(31, 1); this.btn4Pic.setActualSize(30, 22);
         this.btnVid.move(62, 1); this.btnVid.setActualSize(29, 22);
         this.stateChanged = false;
         this.skin.draw(this, { maskL: this.maskL, maskR: this.maskR, btn1: this.btn1Pic, btn2: this.btn4Pic, btn3: this.btnVid });
         switch (this.state) {
            case PicModeButtonBar.MODE_1PIC: this.btn1Pic.selected = true; this.btn4Pic.selected = false; this.btnVid.selected = false; break;
            case PicModeButtonBar.MODE_4PIC: this.btn1Pic.selected = false; this.btn4Pic.selected = true; this.btnVid.selected = false; break;
            case PicModeButtonBar.MODE_VID: this.btn1Pic.selected = false; this.btn4Pic.selected = false; this.btnVid.selected = true; break;
         }
      }
   }
   btn1PicClickListener(e) { this.state = PicModeButtonBar.MODE_1PIC; }
   // The original never implemented video mode: this handler is empty in the SWF.
   btnVidClickListener(e) {}
   btn4PicClickListener(e) { this.state = PicModeButtonBar.MODE_4PIC; }
   createChildren() {
      super.createChildren();
      this.maskL = new KSprite();
      this.maskR = new KSprite();
      this.addChild(this.maskL);
      this.addChild(this.maskR);
      this.btn1Pic = new SelectableButton({ skin: Singletons.getInstance(PB.PicModePic1Skin) });
      this.btn4Pic = new SelectableButton({ skin: Singletons.getInstance(PB.PicModePic4Skin) });
      this.btnVid = new SelectableButton({ skin: Singletons.getInstance(PB.PicModeVidSkin) });
      this.btn1Pic.mask = this.maskL;
      this.btnVid.mask = this.maskR;
      this.btn1Pic.addEventListener(MouseEvent.MOUSE_DOWN, this.b.btn1PicClickListener);
      this.btn4Pic.addEventListener(MouseEvent.MOUSE_DOWN, this.b.btn4PicClickListener);
      this.btnVid.addEventListener(MouseEvent.MOUSE_DOWN, this.b.btnVidClickListener);
      this.addChild(this.btn1Pic);
      this.addChild(this.btn4Pic);
      this.addChild(this.btnVid);
   }
}
PicModeButtonBar.MODE_1PIC = 1;
PicModeButtonBar.MODE_4PIC = 2;
PicModeButtonBar.MODE_VID = 3;

class ControlBar extends KComponent {
   constructor() {
      super({ width: 640, height: 59 });
      this._mode = 1;
      this.modeChanged = true;
      this.lblFacebook = null; this.lblFlickr = null; this.btnPicasa = null; this.btnDownload = null;
      this.scrollChanged = true;
      this.lblPicasa = null;
      this.shutterBtn = null;
      this.picModeButtonBar = null;
      this.wordGlow = new F.GlowFilter(16777215, 0.7, 20, 20, 4, 3);
      this.lbl1 = null; this.lbl2 = null; this.lbl3 = null;
      this.countDownCam = null;
      this._takeinPicStage = -1;
      this._takingPicType = 0;
      this.sb1 = null; this.sb2 = null; this.sb3 = null; this.sb4 = null;
      this._scrollIndex = 0;
      this.btnFacebook = null; this.btnFlickr = null;
      this.lblDownload = null;
      this.efBtn = null;
      this.skin = Singletons.getInstance(PB.ControlBarSkin);
   }
   set takingPicType(v) { if (v === this.takingPicType) return; this._takingPicType = v; this.dispatchEvent(new Event("picModeChange")); }
   get takingPicType() { return this._takingPicType; }
   get scrollIndex() { return this._scrollIndex; }
   set scrollIndex(v) { if (v === this.scrollIndex) return; this._scrollIndex = v; this.scrollChanged = true; this.invalidate(); }
   createChildren() {
      super.createChildren();
      this.efBtn = new EffectsButton();
      this.addChild(this.efBtn);
      this.shutterBtn = new ShutterButton();
      this.shutterBtn.addEventListener(MouseEvent.CLICK, this.b.shutterClickListener);
      this.addChild(this.shutterBtn);
      this.lbl1 = new Label(); this.lbl2 = new Label(); this.lbl3 = new Label();
      this.addChild(this.lbl1); this.addChild(this.lbl2); this.addChild(this.lbl3);
      this.configLabelInitState();
      this.countDownCam = new CountDownCam();
      this.countDownCam.visible = false;
      this.addChild(this.countDownCam);
      this.sb1 = new DumbDotButton(); this.sb2 = new DumbDotButton(); this.sb3 = new DumbDotButton(); this.sb4 = new DumbDotButton();
      this.sb1.addEventListener(MouseEvent.CLICK, this.b.scroll1Listener);
      this.sb2.addEventListener(MouseEvent.CLICK, this.b.scroll2Listener);
      this.sb3.addEventListener(MouseEvent.CLICK, this.b.scroll3Listener);
      this.sb4.addEventListener(MouseEvent.CLICK, this.b.scroll4Listener);
      this.sb1.visible = this.sb2.visible = this.sb3.visible = this.sb4.visible = false;
      this.addChild(this.sb1); this.addChild(this.sb2); this.addChild(this.sb3); this.addChild(this.sb4);
      this.picModeButtonBar = new PicModeButtonBar();
      this.picModeButtonBar.move(15, 17);
      this.picModeButtonBar.addEventListener("picModeChange", this.b.picModeChangeListener);
      this.addChild(this.picModeButtonBar);

      this.btnDownload = new Button({ skin: Singletons.getInstance(PB.DLBtnSkin), width: 32, height: 32 });
      this.btnDownload.addEventListener(MouseEvent.CLICK, this.b.downloadClickListener);
      this.addChild(this.btnDownload);
      this.lblDownload = new Label();
      this.addChild(this.lblDownload);
      this.lblDownload.fontSize = 9.5;
      this.lblDownload.fontColor = 3355443;
      this.lblDownload.text = "Download";
      this.btnDownload.visible = this.lblDownload.visible = false;

      this.btnFlickr = new Button({ skin: Singletons.getInstance(PB.FlickrBtnSkin), width: 32, height: 32 });
      this.btnFlickr.addEventListener(MouseEvent.CLICK, this.b.flickrClickListener);
      this.lblFlickr = new Label();
      this.addChild(this.lblFlickr);
      this.lblFlickr.fontSize = 9.5;
      this.lblFlickr.fontColor = 3355443;
      this.lblFlickr.text = "Flickr";
      this.addChild(this.btnFlickr);
      this.lblFlickr.visible = this.btnFlickr.visible = false;

      this.btnPicasa = new Button({ skin: Singletons.getInstance(PB.PicasaBtnSkin), width: 32, height: 32 });
      this.btnPicasa.addEventListener(MouseEvent.CLICK, this.b.picasaClickListener);
      this.lblPicasa = new Label();
      this.addChild(this.lblPicasa);
      this.lblPicasa.fontSize = 9.5;
      this.lblPicasa.fontColor = 3355443;
      this.lblPicasa.text = "Picasa";
      this.addChild(this.btnPicasa);
      // As in the original, the Picasa button is created but never shown.
      this.lblPicasa.visible = this.btnPicasa.visible = false;

      this.btnFacebook = new Button({ skin: Singletons.getInstance(PB.FBBtnSkin), width: 32, height: 32 });
      this.btnFacebook.addEventListener(MouseEvent.CLICK, this.b.facebookClickListener);
      this.addChild(this.btnFacebook);
      this.lblFacebook = new Label();
      this.addChild(this.lblFacebook);
      this.lblFacebook.fontSize = 9.5;
      this.lblFacebook.fontColor = 3355443;
      this.lblFacebook.text = "Facebook";
      this.btnFacebook.visible = this.lblFacebook.visible = false;

      // CHANGE: Facebook's REST API and Flickr's old auth/upload API were shut
      // down years ago, so these buttons stay where they were but are disabled
      // and dimmed. (Karthik's skins draw "disabled" the same as "normal", so
      // the dimming is what shows it.) See Main for the commented-out code.
      this.btnFacebook.disabled = this.btnFlickr.disabled = true;
      this.btnFacebook.alpha = this.lblFacebook.alpha = this.btnFlickr.alpha = this.lblFlickr.alpha = 0.35;
   }
   get takeinPicStage() { return this._takeinPicStage; }
   set takeinPicStage(v) { if (v === this.takeinPicStage) return; this._takeinPicStage = v; this.modeChanged = true; this.invalidate(); }
   get mode() { return this._mode; }
   set mode(v) {
      if (v === this.mode) return;
      this._mode = v;
      this.modeChanged = true;
      this.invalidate();
      if (this._mode === ControlBar.MODE_TAKING_PIC) {
         this._takeinPicStage = -1;
         this.startTakePic();
      }
   }
   picModeChangeListener(e) {
      switch (this.picModeButtonBar.state) {
         case PicModeButtonBar.MODE_1PIC: this.takingPicType = ControlBar.TAKING_PIC_1PIC; break;
         case PicModeButtonBar.MODE_4PIC: this.takingPicType = ControlBar.TAKING_PIC_4PIC; break;
      }
   }
   configLabelInitState() {
      this.lbl1.fontColor = this.lbl2.fontColor = this.lbl3.fontColor = 16777215;
      this.lbl1.fontSize = this.lbl2.fontSize = this.lbl3.fontSize = 40;
      this.lbl1.text = "1"; this.lbl2.text = "2"; this.lbl3.text = "3";
      this.lbl3.move(200, 3); this.lbl2.move(272, 3); this.lbl1.move(346, 3);
      this.lbl1.alpha = this.lbl2.alpha = this.lbl3.alpha = 0.2;
      this.lbl1.visible = this.lbl2.visible = this.lbl3.visible = false;
   }
   // Countdown: TimerManager at 1.2 calls/s, i.e. a step every 850 ms.
   startTakePic() {
      if (this.takingPicType === ControlBar.TAKING_PIC_1PIC) {
         if (this.takeinPicStage === 3) {
            this.dispatchEvent(new Event("doFlash"));
            this.dispatchEvent(new Event("doTakePic"));
            return;
         }
      } else if (this.takingPicType === ControlBar.TAKING_PIC_4PIC) {
         if (this.takeinPicStage >= 3 && this.takeinPicStage < 7) {
            this.dispatchEvent(new Event("doFlash"));
            this.dispatchEvent(new Event("doTakePic"));
         }
         if (this.takeinPicStage === 6) return;
      }
      this.takeinPicStage += 1;
      TimerManager.getInstance().addCallBack(this.startTakePic, 1.2, true, this);
   }
   downloadClickListener(e) { e.stopPropagation(); this.dispatchEvent(new Event("downloadPicture")); }
   picasaClickListener(e) { e.stopPropagation(); this.dispatchEvent(new Event("picasaPicture")); }
   update() {
      if (this.wasResized || this.modeChanged) {
         this.skin.draw(this);
         this.efBtn.move(this.width - 15 - this.efBtn.width, 17);
         this.shutterBtn.move(301, 12);
         this.countDownCam.move(411, 11);
         this.sb1.move(276, 21);
         this.sb2.move(276 + 24, 21);
         this.sb3.move(276 + 2 * 24, 21);
         this.sb4.move(276 + 3 * 24, 21);
         this.lblDownload.validateNow();
         this.btnDownload.move(20, 8);
         this.lblDownload.move(11, 40);
         this.lblFacebook.validateNow();
         this.btnFacebook.move(80, 8);
         this.lblFacebook.move(72, 40);
         this.lblPicasa.validateNow();
         this.btnPicasa.move(this.width - 52, 8);
         this.lblPicasa.move(this.width - 50, 40);
         this.lblFlickr.validateNow();
         this.btnFlickr.move(this.width - 52 - 60, 8);
         this.lblFlickr.move(this.width - 50 - 60, 40);
      }
      if (this.scrollChanged) {
         this.scrollChanged = false;
         this.efBtn.leftEnabled = this._scrollIndex !== 0;
         this.efBtn.rightEnabled = this._scrollIndex !== 3;
         this.sb1.selected = this.sb2.selected = this.sb3.selected = this.sb4.selected = false;
         switch (this._scrollIndex) {
            case 0: this.sb1.selected = true; break;
            case 1: this.sb2.selected = true; break;
            case 2: this.sb3.selected = true; break;
            case 3: this.sb4.selected = true; break;
         }
      }
      if (this.modeChanged) {
         this.modeChanged = false;
         switch (this.mode) {
            case ControlBar.MODE_EFFECTS:
               this.sb1.visible = this.sb2.visible = this.sb3.visible = this.sb4.visible = true;
               this.picModeButtonBar.visible = true;
               this.efBtn.visible = true;
               this.shutterBtn.visible = false;
               this.countDownCam.visible = false;
               this.lbl1.visible = this.lbl2.visible = this.lbl3.visible = false;
               this.efBtn.mode = EffectsButton.MODE_EFFECTS;
               break;
            case ControlBar.MODE_PIC:
               this.shutterBtn.inactive = false;
               this.btnDownload.visible = this.lblDownload.visible = this.btnFacebook.visible = this.lblFacebook.visible = this.btnFlickr.visible = this.lblFlickr.visible = false;
               this.picModeButtonBar.visible = true;
               this.sb1.visible = this.sb2.visible = this.sb3.visible = this.sb4.visible = false;
               this.efBtn.visible = true;
               this.shutterBtn.visible = true;
               this.shutterBtn.inactive = false;
               this.countDownCam.visible = false;
               this.lbl1.visible = this.lbl2.visible = this.lbl3.visible = false;
               this.efBtn.mode = EffectsButton.MODE_NORMAL;
               break;
            case ControlBar.MODE_TAKING_PIC:
               this.sb1.visible = this.sb2.visible = this.sb3.visible = this.sb4.visible = false;
               this.countDownCam.visible = true;
               this.efBtn.visible = false;
               this.shutterBtn.visible = false;
               this.picModeButtonBar.visible = false;
               this.lbl1.visible = this.lbl2.visible = this.lbl3.visible = true;
               switch (this._takeinPicStage) {
                  case 0:
                     this.lbl1.filters = this.lbl2.filters = this.lbl3.filters = [];
                     this.lbl1.alpha = this.lbl2.alpha = this.lbl3.alpha = 0.2;
                     this.countDownCam.state = CountDownCam.STATE_DIM;
                     break;
                  case 1:
                     this.lbl2.filters = this.lbl1.filters = [];
                     this.lbl2.alpha = this.lbl1.alpha = 0.2;
                     this.lbl3.filters = [this.wordGlow];
                     this.lbl3.alpha = 1;
                     this.countDownCam.state = CountDownCam.STATE_DIM;
                     break;
                  case 2:
                     this.lbl1.filters = this.lbl3.filters = [];
                     this.lbl1.alpha = this.lbl3.alpha = 0.2;
                     this.lbl2.filters = [this.wordGlow];
                     this.lbl2.alpha = 1;
                     this.countDownCam.state = CountDownCam.STATE_DIM;
                     break;
                  case 3:
                     this.lbl2.filters = this.lbl3.filters = [];
                     this.lbl2.alpha = this.lbl3.alpha = 0.2;
                     this.lbl1.filters = [this.wordGlow];
                     this.lbl1.alpha = 1;
                     this.countDownCam.state = CountDownCam.STATE_DIM;
                     break;
                  case 4:
                     this.lbl1.filters = this.lbl2.filters = this.lbl3.filters = [];
                     this.lbl1.alpha = this.lbl2.alpha = this.lbl3.alpha = 0.2;
                     if (this.takingPicType === ControlBar.TAKING_PIC_1PIC) this.countDownCam.state = CountDownCam.STATE_BRIGHT;
                     else if (this.takingPicType === ControlBar.TAKING_PIC_4PIC) this.countDownCam.state = CountDownCam.STATE_1QUAD;
                     break;
                  case 5: this.countDownCam.state = CountDownCam.STATE_2QUAD; break;
                  case 6: this.countDownCam.state = CountDownCam.STATE_3QUAD; break;
                  case 7: this.countDownCam.state = CountDownCam.STATE_BRIGHT; break;
               }
               break;
            case ControlBar.MODE_VIEWER:
               this.shutterBtn.inactive = true;
               this.interruptTakingPic();
               this.sb1.visible = this.sb2.visible = this.sb3.visible = this.sb4.visible = false;
               this.picModeButtonBar.visible = false;
               this.efBtn.visible = false;
               this.countDownCam.visible = false;
               this.lbl1.visible = this.lbl2.visible = this.lbl3.visible = false;
               this.shutterBtn.visible = true;
               this.shutterBtn.inactive = true;
               this.btnDownload.visible = this.lblDownload.visible = this.btnFacebook.visible = this.lblFacebook.visible = this.btnFlickr.visible = this.lblFlickr.visible = true;
               break;
         }
      }
   }
   interruptTakingPic() {
      if (TimerManager.getInstance().hasCallBack(this.startTakePic)) TimerManager.getInstance().removeCallBack(this.startTakePic);
   }
   flickrClickListener(e) { e.stopPropagation(); this.dispatchEvent(new Event("flickrPicture")); }
   scroll1Listener(e) { e.stopPropagation(); this.scrollIndex = 0; this.dispatchEvent(new Event("changeScroll")); }
   scroll2Listener(e) { e.stopPropagation(); this.scrollIndex = 1; this.dispatchEvent(new Event("changeScroll")); }
   scroll3Listener(e) { e.stopPropagation(); this.scrollIndex = 2; this.dispatchEvent(new Event("changeScroll")); }
   scroll4Listener(e) { e.stopPropagation(); this.scrollIndex = 3; this.dispatchEvent(new Event("changeScroll")); }
   facebookClickListener(e) { e.stopPropagation(); this.dispatchEvent(new Event("facebookPicture")); }
   shutterClickListener(e) {
      e.stopPropagation();
      if (this.shutterBtn.inactive) this.dispatchEvent(new Event("goPicMode"));
      else {
         this.dispatchEvent(new Event("startTakePic"));
         this.mode = ControlBar.MODE_TAKING_PIC;
      }
   }
}
ControlBar.MODE_PIC = 1;
ControlBar.MODE_EFFECTS = 2;
ControlBar.MODE_TAKING_PIC = 5;
ControlBar.MODE_VIEWER = 3;
ControlBar.MODE_TAKING_VIDEO = 4;
ControlBar.TAKING_PIC_1PIC = 0;
ControlBar.TAKING_PIC_4PIC = 1;
PB.ControlBar = ControlBar;

// ---------------------------------------------------------------------------
// Photo strip (com.karthik.photobooth.PhotoList, photo_list_item)
// ---------------------------------------------------------------------------

class PhotoItem extends KComponent {
   constructor() {
      super();
      this._selected = false;
      this.renderSkin = Singletons.getInstance(PB.PhotoItemRendererSkin);
      this.skin = Singletons.getInstance(PB.PhotoItemSkin);
      this.dataDirty = false;
      this._data = null;
      this._index = 1;
      this.render = null;
      this.stateChanged = true;
      this.button = null;
      this.label = null;
   }
   set data(v) { if (this._data === v) return; this._data = v; this.dataDirty = true; this.invalidate(); }
   get data() { return this._data; }
   update() {
      if (this.stateChanged || this.wasResized) {
         this.stateChanged = false;
         this.skin.draw(this);
         this.render.x = 3;
         this.render.y = 3;
         this.render.width = 80;
         this.render.height = 60;
      }
      if (this.dataDirty) {
         this.dataDirty = false;
         this.renderSkin.draw(this.render, { data: this._data });
      }
   }
   get index() { return this._index; }
   set index(v) { if (this._index === v) return; this._index = v; this.stateChanged = true; this.invalidate(); }
   get selected() { return this._selected; }
   set selected(v) { if (this._selected === v) return; this._selected = v; this.stateChanged = true; this.invalidate(); }
   btnClickListener(e) { e.stopPropagation(); this.dispatchEvent(new Event("delete", true)); }
   createChildren() {
      super.createChildren();
      this.button = new Button();
      this.button.addEventListener(MouseEvent.CLICK, this.b.btnClickListener, false, -40, true);
      this.label = new Label();
      this.render = new KSprite();
      this.addChild(this.button);
      this.addChild(this.label);
      this.addChild(this.render);
   }
}

class ItemFactory extends K.ClassFactory { newInstance() { return new PhotoItem(); } }

class LeftScrollBtn extends Button {
   constructor() {
      super({ width: 26, height: 98, skin: Singletons.getInstance(PB.ScrollBtnLeftSkin) });
      this.filters = [new F.DropShadowFilter(3, 0, 0, 0.4, 3, 0)];
   }
}
class RightScrollBtn extends Button {
   constructor() {
      super({ width: 26, height: 98, skin: Singletons.getInstance(PB.ScrollBtnRightSkin) });
      this.filters = [new F.DropShadowFilter(3, 180, 0, 0.3, 3)];
   }
}

class PhotoList extends KComponent {
   constructor(options) {
      super(options);
      this.renderers = new Map();
      this._dataProvider = null;
      this.listDefaults = {
         skin: Singletons.getInstance(skins.PhotoListSkin),
         itemFilter: new F.DropShadowFilter(0, 0, 0, 0.8, 8, 8, 1, 1),
         padLeft: 5, width: 588, height: 98, padTop: 4, itemWidth: 86, itemHeight: 88,
         itemFactory: Singletons.getInstance(ItemFactory), hGap: 6
      };
      this.itemHeight = 0;
      this.renderersDirty = false;
      this._itemFactory = null;
      this._maxHScrollPosition = 0;
      this.padLeft = 0;
      this.padTop = 0;
      this.dataDirty = false;
      this.hGap = 0;
      this.selectedItem = null;
      this._hScrollPosition = 0;
      this.animator = new LayoutAnimator(this);
      this.pendingItems = null;
      this.itemFilter = null;
      this.itemWidth = 0;
      this._selectedIndex = undefined;
      this.skin = null;
      this.animator.animationSpeed = 0.05;
      this.animator.positionFunc = this.positionItems;
   }
   removeRenderer(r) {
      r.removeEventListener(MouseEvent.CLICK, this.b.itemClickListener);
      this.removeChild(r);
      this.animator.removeChild(r);
      this.renderers.delete(r);
   }
   addRenderer(r, i) {
      r.addEventListener(MouseEvent.CLICK, this.b.itemClickListener);
      r.addEventListener("delete", this.b.itemDeleteListener);
      if (this.itemFilter) r.filters = [this.itemFilter];
      r.index = i + 1;
      this.renderers.set(r, i);
      this.addChild(r);
      this.animator.addChild(r);
   }
   itemClickListener(e) { this.selectedIndex = this.renderers.get(e.currentTarget); }
   getLeftGap() {
      var g = this.width - (this.padLeft + (this.hGap + this.itemWidth) * this.numRenderers());
      if (g < this.padLeft) g = 0;
      return g;
   }
   positionItems() {
      var left = this.getLeftGap(), self = this;
      this.renderers.forEach(function (i, r) {
         var x = left + self.padLeft + (self.hGap + self.itemWidth) * i - self._hScrollPosition;
         self.animator.setTargets(r, x, self.padTop, self.itemWidth, self.itemHeight);
      });
   }
   get hScrollPosition() { return this._hScrollPosition; }
   set hScrollPosition(v) {
      if (this._hScrollPosition === v) return;
      this._hScrollPosition = v;
      this.dispatchEvent(new Event("hScrollChanged"));
      this.animator.invalidate();
      this.invalidate();
   }
   numRenderers() {
      if (this._dataProvider) return this._dataProvider.length;
      if (this.pendingItems) return this.pendingItems.length;
      return 0;
   }
   rendererAtIndex(i) {
      var found = null;
      this.renderers.forEach(function (idx, r) { if (idx === i && !found) found = r; });
      return found;
   }
   scrollTillLeftMostIs(r) {
      var s = this.rendererAtIndexState(this.renderers.get(r));
      var v = this._hScrollPosition + (s.x - this.padLeft), max = this.maxHScroll;
      this.hScrollPosition = v > max ? max : v;
   }
   get dataProvider() { return this._dataProvider; }
   set dataProvider(v) {
      if (v === this._dataProvider) return;
      v.addEventListener(CollectionEvent.COLLECTION_CHANGE, this.b.itemChangeListener, false, -10, true);
      this.pendingItems = v;
      this.renderersDirty = true;
      this.dataDirty = true;
      this.invalidate();
      this.animator.invalidate();
   }
   scrollTillRightMostIs(r) {
      var s = this.rendererAtIndexState(this.renderers.get(r));
      var v = this._hScrollPosition - (this.width - (s.x + s.width + this.padLeft));
      this.hScrollPosition = v < 0 ? 0 : v;
   }
   update() {
      super.update();
      if (this.wasResized) {
         this.scrollRect = new Rectangle(0, 0, this.width, this.height);
         this.skin.draw(this);
      }
      this.animator.validate();
   }
   commitProperties() {
      if (this.dataDirty) {
         this.dataDirty = false;
         if (this._dataProvider) this._dataProvider.removeEventListener(CollectionEvent.COLLECTION_CHANGE, this.b.itemChangeListener);
         this._dataProvider = this.pendingItems;
         this.pendingItems = null;
         this.renderersDirty = true;
      }
      if (this.renderersDirty) {
         if (this._dataProvider == null) return;
         this.renderersDirty = false;
         var self = this;
         Array.from(this.renderers.keys()).forEach(function (r) { self.removeRenderer(r); });
         if (!this._itemFactory) return;
         for (var i = 0; i < this._dataProvider.length; i++) {
            var r = this._itemFactory.newInstance();
            r.data = this._dataProvider.getItemAt(i);
            this.addRenderer(r, i);
         }
         this.animator.invalidate();
         this.invalidate();
         this.computeMaxHScroll();
      }
   }
   scrollRight() { this.hScrollPosition = Math.min(this.maxHScroll, this.hScrollPosition + this.width); }
   get maxHScroll() { return this._maxHScrollPosition; }
   rendererAtIndexState(i) {
      return new KState(this.getLeftGap() + this.padLeft + (this.hGap + this.itemWidth) * i - this._hScrollPosition, this.padTop, this.itemWidth, this.itemHeight, 1);
   }
   getDefaultOption() { return this.listDefaults; }
   dispatchDropComplete() { this.dispatchEvent(new Event("dropComplete")); }
   computeMaxHScroll() {
      var v = 0;
      if (this._dataProvider == null || this._dataProvider.length === 0) v = 0;
      else if (this.getLeftGap() > 0) v = 0;
      else v = 2 * this.padLeft + (this.hGap + this.itemWidth) * this.numRenderers() - this.hGap - this.width;
      if (v !== this._maxHScrollPosition) {
         this._maxHScrollPosition = v;
         this.dispatchEvent(new Event("maxHScrollChanged"));
      }
      return this._maxHScrollPosition;
   }
   set selectedIndex(v) {
      if (v === -1 && this._selectedIndex === -1) return;
      if (v === -1 && this.selectedItem != null) {
         this.selectedItem.selected = false;
         this._selectedIndex = -1;
         this.selectedItem = null;
         return;
      }
      var r = this.rendererAtIndex(v);
      if (r === this.selectedItem) { this._selectedIndex = v; return; }
      if (this.selectedItem) this.selectedItem.selected = false;
      r.selected = true;
      this.selectedItem = r;
      this._selectedIndex = v;
      var ev = new PB.PhotoItemEvent(PB.PhotoItemEvent.TYPE_PHOTO_SELECT);
      ev.index = this.renderers.get(r);
      this.dispatchEvent(ev);
      if (r.x < this.padLeft) this.scrollTillRightMostIs(r);
      if (r.x + r.width + this.padLeft > this.width) this.scrollTillLeftMostIs(r);
   }
   get selectedIndex() { return this.renderers.get(this.selectedItem); }
   set itemFactory(v) {
      if (this._itemFactory === v) return;
      this._itemFactory = v;
      this.renderersDirty = true;
      this.invalidate();
      this.animator.invalidate();
   }
   itemDeleteListener(e) {
      var ev = new PB.PhotoItemEvent(PB.PhotoItemEvent.TYPE_PHOTO_DELETE);
      ev.index = this.renderers.get(e.currentTarget) | 0;
      this.dispatchEvent(ev);
   }
   scrollLeft() { this.hScrollPosition = Math.max(0, this.hScrollPosition - this.width); }
   itemChangeListener(e) {
      var self = this, index, r;
      if (e.kind === CollectionEvent.TYPE_ADD) {
         index = e.index;
         r = this._itemFactory.newInstance();
         r.data = e.item;
         var onComplete = function (ae) {
            TimerManager.getInstance().addCallBack(self.dispatchDropComplete, 1.3, true, self);
            self.computeMaxHScroll();
            if (ae) ae.currentTarget.removeEventListener(AnimationEvent.ANIMATION_COMPLETE, onComplete);
            var s = self.rendererAtIndexState(index);
            self.addRenderer(r, index);
            r.move(s.x, -s.height);
            r.setActualSize(s.width, s.height);
            self.animator.targetFor(r).jumptoPosAfterAdded = false;
            self.animator.invalidate();
            self.invalidate();
         };
         if (this._dataProvider.length === 1) onComplete(null);
         else {
            var first = this.rendererAtIndex(0);
            this.animator.targetFor(first).addEventListener(AnimationEvent.ANIMATION_COMPLETE, onComplete);
            var pos = this.rendererAtIndexState(index);
            if (pos.x + pos.width + this.padLeft > this.width) this.hScrollPosition += pos.x + pos.width + this.padLeft - this.width;
            this.animator.invalidate();
            this.invalidate();
         }
      } else if (e.kind === CollectionEvent.TYPE_REMOVE) {
         index = e.index;
         r = this.rendererAtIndex(index);
         this.removeRenderer(r);
         if (index < this._dataProvider.length) {
            Array.from(this.renderers.keys()).forEach(function (o) {
               var i = self.renderers.get(o);
               if (i > index) {
                  self.renderers.set(o, i - 1);
                  o.index = i - 1 + 1;
               }
            });
         }
         this.computeMaxHScroll();
         if (this.hScrollPosition > this.maxHScroll) this.hScrollPosition = this.maxHScroll;
         this.animator.invalidate();
         this.invalidate();
      } else {
         this.renderersDirty = true;
         this.dataDirty = true;
         this.animator.invalidate();
         this.invalidate();
      }
   }
}
PB.PhotoList = PhotoList;

// ---------------------------------------------------------------------------
// Viewer (com.karthik.photobooth.viewer)
// ---------------------------------------------------------------------------

class State3D {
   constructor(x, y, z, rx, ry, rz) { this.x = x; this.y = y; this.z = z; this.rx = rx; this.ry = ry; this.rz = rz; }
   updateWithState(s) { s.x = this.x; s.y = this.y; s.z = this.z; s.rotationX = this.rx; s.rotationY = this.ry; s.rotationZ = this.rz; }
   toString() { return "x: " + this.x + " y: " + this.y + " z: " + this.z + " rx: " + this.rx + " ry: " + this.ry + " rz: " + this.rz; }
   interpolateTo(t, p) {
      return new State3D(this.x + (t.x - this.x) * p, this.y + (t.y - this.y) * p, this.z + (t.z - this.z) * p,
         this.rx + (t.rx - this.rx) * p, this.ry + (t.ry - this.ry) * p, this.rz + (t.rz - this.rz) * p);
   }
   clone() { return new State3D(this.x, this.y, this.z, this.rx, this.ry, this.rz); }
   equals(o) { return this.x === o.x && this.y === o.y && this.z === o.z && this.rx === o.rx && this.ry === o.ry && this.rz === o.rz; }
}

class View1Pic extends KComponent {
   constructor() { super(); this._data = null; this.dataChanged = true; }
   update() {
      if (this.wasResized || this.dataChanged) {
         this.dataChanged = false;
         if (this._data) {
            var bmp = this._data.itemData[0];
            this.graphics.clear();
            this.graphics.beginBitmapFill(bmp, new Matrix(this.width / bmp.width, 0, 0, this.height / bmp.height));
            this.graphics.drawRect(0, 0, this.width, this.height);
         }
      }
   }
   get data() { return this._data; }
   set data(v) {
      if (v === this.data) return;
      if (!v || !v.itemData) throw new Error("view1pic, this is not a IphotoItem");
      this._data = v;
      this.dataChanged = true;
      this.invalidate();
   }
}

class View4Pic extends KComponent {
   constructor() {
      super({ width: 640, height: 480 });
      this.vGap = 20;
      this._data = null;
      this.bmpBL = null; this.card = null; this.offset = null; this.bmpBR = null; this.shadow = null;
      this.progress = 0;
      this.dataChanged = true;
      this.needAnotherUpdate = true;
      this.bmpTL = null; this.jumpNext = true; this.bmpTR = null; this.largeBmp = null;
      this.current_state = null;
      this.hGap = 20;
      this.sc = 1;
      this._isZoomed = false;
      this.target_state = null;
      this.imgH = 480;
      this._focalLength = 0;
      this.imgW = 640;
      this.skin = Singletons.getInstance(PB.View4PicSkin);
      this.rectTL = new Rectangle(20, 20, 640, 480);
      this.rectTR = new Rectangle(640 + 40, 20, 640, 480);
      this.rectBL = new Rectangle(20, 480 + 40, 640, 480);
      this.rectBR = new Rectangle(640 + 40, 480 + 40, 640, 480);
   }
   set targetState(s) {
      if (s.equals(this.target_state)) return;
      this.target_state = s;
      this.isZoomed = this.target_state.equals(View4Pic.state_out);
      this.invalidate();
      this.progress = 0;
      this.needAnotherUpdate = true;
   }
   get targetState() { return this.target_state; }
   createChildren() {
      super.createChildren();
      this.card = new F.Sprite();
      this.shadow = new F.Sprite();
      this.offset = new F.Sprite();
      this.addChild(this.card);
      this.card.addChild(this.shadow);
      this.card.addChild(this.offset);
      this.shadow.mouseEnabled = false;
      this.card.addEventListener(MouseEvent.CLICK, this.b.cardClickListener);
      this.transform.perspectiveProjection = new PB.PerspectiveProjection();
      this.transform.perspectiveProjection.focalLength = 1200;
      var s = View4Pic.state_out;
      this.current_state = s.clone();
      this.target_state = s.clone();
   }
   cardClickListener(e) {
      if (!this.target_state.equals(View4Pic.state_out)) { this.targetState = View4Pic.state_out; return; }
      if (this.rectTL.contains(e.localX, e.localY)) this.targetState = View4Pic.state_tl;
      else if (this.rectTR.contains(e.localX, e.localY)) this.targetState = View4Pic.state_tr;
      else if (this.rectBL.contains(e.localX, e.localY)) this.targetState = View4Pic.state_bl;
      else if (this.rectBR.contains(e.localX, e.localY)) this.targetState = View4Pic.state_br;
   }
   getStateIndex() {
      if (this.targetState.equals(View4Pic.state_tl)) return 0;
      if (this.targetState.equals(View4Pic.state_tr)) return 1;
      if (this.targetState.equals(View4Pic.state_bl)) return 2;
      if (this.targetState.equals(View4Pic.state_br)) return 3;
      return -1;
   }
   get data() { return this._data; }
   set data(v) {
      if (this._data === v) return;
      if (!v || !v.itemData) throw new Error("error, data not IPhotoItem");
      this._data = v;
      this.largeBmp = this.makeLarge();
      this.dataChanged = true;
      this.invalidate();
   }
   update() {
      if (!this.largeBmp) return;
      if (this.wasResized || this.dataChanged) {
         this.dataChanged = false;
         this.skin.draw(this);
         this.scrollRect = new Rectangle(0, 0, this.width, this.height);
         this.offset.x = -this.largeBmp.width * this.sc / 2;
         this.offset.y = -this.largeBmp.height * this.sc / 2;
         this.shadow.x = this.offset.x;
         this.shadow.y = -this.offset.y;
         this.offset.graphics.clear();
         this.offset.graphics.beginBitmapFill(this.largeBmp, new Matrix(this.sc, 0, 0, this.sc), false);
         this.offset.graphics.drawRect(0, 0, this.largeBmp.width * this.sc, this.largeBmp.height * this.sc);
         var k = 0.95;
         this.shadow.graphics.clear();
         this.shadow.graphics.beginFill(0, 0.5);
         this.shadow.graphics.drawRect(0, -this.largeBmp.height * this.sc * k, this.largeBmp.width * this.sc * k, this.largeBmp.height * this.sc * k);
         this.shadow.rotationZ = 6;
         this.shadow.filters = [new F.BlurFilter(50, 200, 1)];
         this.shadow.rotationX = -80;
         this.shadow.z = 10;
      }
      if (this.needAnotherUpdate) {
         this.progress += 0.07;
         if (this.progress > 1) this.progress = 1;
         this.current_state = this.current_state.interpolateTo(this.target_state, this.progress);
         this.current_state.updateWithState(this.card);
         if (this.current_state.equals(this.target_state)) this.needAnotherUpdate = false;
      }
      if (this.needAnotherUpdate) TimerManager.getInstance().addCallBack(this.invalidate, 20, true, this);
   }
   makeLarge() {
      this.bmpTL = this._data.itemData[0];
      this.bmpTR = this._data.itemData[1];
      this.bmpBL = this._data.itemData[2];
      this.bmpBR = this._data.itemData[3];
      var w = 2 * this.imgW + 3 * this.hGap, h = 2 * this.imgH + 3 * this.vGap;
      var b = new BitmapData(w, h);
      b.floodFill(0, 0, 4294967295);
      b.copyPixels(this.bmpTL, this.bmpTL.rect, new Point(this.hGap, this.vGap));
      b.copyPixels(this.bmpTR, this.bmpTR.rect, new Point(this.hGap * 2 + this.imgW, this.vGap));
      b.copyPixels(this.bmpBL, this.bmpTL.rect, new Point(this.hGap, this.vGap * 2 + this.imgH));
      b.copyPixels(this.bmpBR, this.bmpTL.rect, new Point(this.hGap * 2 + this.imgW, this.vGap * 2 + this.imgH));
      return b;
   }
   set isZoomed(v) { if (v === this.isZoomed) return; this._isZoomed = v; this.dispatchEvent(new Event("zoomStateChange")); }
   get isZoomed() { return this._isZoomed; }
}
View4Pic.STATE_ZOOMED_IN = 1;
View4Pic.STATE_ZOOMED_OUT = 0;
View4Pic.state_out = new State3D(400, 200, 2000, -10, 0, -10);
View4Pic.state_br = new State3D(-10, -10, 0, 0, 0, 0);
View4Pic.state_tl = new State3D(640 + 10, 480 + 10, 0, 0, 0, 0);
View4Pic.state_tr = new State3D(-10, 480 + 10, 0, 0, 0, 0);
View4Pic.state_bl = new State3D(640 + 10, -10, 0, 0, 0, 0);

class Viewer extends KComponent {
   constructor() { super({ width: 640, height: 480 }); this._data = null; this.view1 = null; this.view4 = null; this.dataChanged = false; }
   createChildren() {
      this.view4 = new View4Pic();
      this.view1 = new View1Pic();
      this.addChild(this.view4);
      this.addChild(this.view1);
      this.view1.visible = false;
      this.view4.visible = false;
   }
   getViewer4Index() { return this.view4 ? this.view4.getStateIndex() : -1; }
   get data() { return this._data; }
   set data(v) {
      if (v === this.data) return;
      if (v && v.itemData) {
         this._data = v;
         this.dataChanged = true;
         this.invalidate();
         return;
      }
      throw new Error("viewer, data is not an iphotoItem");
   }
   update() {
      if (this.wasResized) {
         this.view1.setActualSize(this.width, this.height);
         this.view4.setActualSize(this.width, this.height);
      }
      if (this.dataChanged) {
         this.dataChanged = false;
         if (this.data instanceof PB.Item1Pic) {
            this.view1.data = this.data;
            this.view1.visible = true;
            this.view4.visible = false;
         } else {
            if (!(this.data instanceof PB.Item4Pic)) throw new Error("viewer, unsupported data type");
            this.resetViewer4();
            this.view4.data = this.data;
            this.view4.visible = true;
            this.view1.visible = false;
         }
      }
   }
   resetViewer4() {
      this.view4.targetState = View4Pic.state_out;
      this.view4.progress = 1;
   }
}
PB.Viewer = Viewer;

// ---------------------------------------------------------------------------
// ScreenContainer: the 3 x 3 (x 4 pages) effect grid and the live preview.
// ---------------------------------------------------------------------------

class ScreenContainer extends KComponent {
   constructor(options) {
      super(options);
      this.renderers = new Map();          // BaseScreen -> index
      this.magnitude = 0.5;
      this.containerDefaults = {
         hGap: 16, vGap: 12, width: 640, height: 480, screenWidth: 192, screenHeight: 144,
         paddingLeft: 16, paddingTop: 16, rows: 3, cols: 3,
         factory: new PB.ScreenFactory(), skin: Singletons.getInstance(skins.ScreenContainerSkin)
      };
      this.sliderVisibleChanged = false;
      this._scVisible = true;
      this._camera = null;
      this.dataDirty = true;
      this.beingAdjusted = null;
      this.hGap = 0;
      this._sliderVisible = false;
      this.indexRenderers = new Map();     // index -> BaseScreen
      this._hScrollPosition = 0;
      this.backgroundRemover = null;
      this._msgBoxText = "Your Msg";
      this.updateMatr = new Matrix(-1, 0, 0, 1, 640);
      this.vGap = 0;
      this._lastSelectedIndex = 4;
      this._video = null;
      this.paddingTop = 0;
      this.bmp = null;
      this.lastMouseX = 0;
      this.lastMouseY = 0;
      this.skin = null;
      this.msgBox = null;
      this._msgBoxVisible = false;
      this._dataProvider = null;
      this.centerChanged = false;
      this.centerX = 0;
      this.centerY = 0;
      this.screenHeight = 0;
      this.visibleScreens = [0, 1, 2, 3, 4, 5, 6, 7, 8];
      this.doSliderAlphaCheck = false;
      this.paddingLeft = 0;
      this.screenWidth = 0;
      this._factory = null;
      this.rows = 0;
      this.slider = null;
      this.animator = new LayoutAnimator(this);
      this.magChanged = false;
      this.cols = 0;
      this.msgBoxPropChanged = true;
      this._selectedIndex = 4;
      this.animator.positionFunc = this.positionFunc;
      TimerManager.getInstance().addCallBack(this.updateScreens, 20, false, this);
      this.addEventListener(MouseEvent.ROLL_OUT, this.b.mouseRollOutListener);
   }
   get lastSelectedIndex() { return this._lastSelectedIndex; }
   mouseRollOutListener(e) {
      if (!this.sliderVisible) return;
      this.animator.targetFor(this.slider).targetAlpha = 0;
      this.animator.invalidate();
      this.animator.positionFuncCalled = true;
      this.invalidate();
      this.addEventListener(MouseEvent.ROLL_OVER, this.b.mouseRollOverListener);
   }
   sliderAlphaCheck() { if (!this.doSliderAlphaCheck) return; }
   get factory() { return this._factory; }
   set factory(v) { if (v === this.factory) return; this._factory = v; this.dataDirty = true; this.invalidate(); }
   showMsgListener(e) {}
   set msgBoxVisible(v) { if (v === this.msgBoxVisible) return; this._msgBoxVisible = v; this.msgBoxPropChanged = true; this.invalidate(); }
   get msgBoxVisible() { return this._msgBoxVisible; }
   createChildren() {
      super.createChildren();
      this.slider = new PB.PBSlider();
      this.addChild(this.slider);
      this.slider.visible = false;
      this.slider.addEventListener("changeValue", this.b.sliderChangeListener);
      this.animator.addChild(this.slider);
      this.addEventListener(MouseEvent.MOUSE_DOWN, this.b.mouseDownListener);
      this.msgBox = new PB.MsgBox();
      this.addChild(this.msgBox);
   }
   get camera() { return this._camera; }
   set camera(c) {
      this._camera = c;
      this._camera.setMode(640, 480, 100);
      this._camera.setQuality(0, 100);
      this._video = new PB.Video(640, 480);
      this._video.attachCamera(this.camera);
      this.backgroundRemover = new PB.BackgroundRemover(this._video);
      this.bmp = new BitmapData(640, 480);
   }
   addMouseListeners() {
      this.stage.addEventListener(MouseEvent.MOUSE_MOVE, this.b.systemManager_mouseMoveListenr, false, -50, true);
      this.stage.addEventListener(MouseEvent.MOUSE_UP, this.b.systemManager_mouseUpListener, false, -50, true);
      this.addEventListener(MouseEvent.ROLL_OUT, this.b.mouseRolloutListener, false, -50, true);
   }
   mouseRolloutListener(e) { this.removeMouseListeners(); }
   systemManager_mouseMoveListenr(e) {
      this.beingAdjusted.centerX = this.mouseX / this.width;
      this.beingAdjusted.centerY = this.mouseY / this.height;
      this.centerX = this.beingAdjusted.centerX;
      this.centerY = this.beingAdjusted.centerY;
   }
   set hScrollPosition(v) {
      if (v === this.hScrollPosition) return;
      this._hScrollPosition = v;
      this.recalculateVisibles();
      this.animator.invalidate();
      this.invalidate();
   }
   get hScrollPosition() { return this._hScrollPosition; }
   systemManager_mouseUpListener(e) {
      this.centerChanged = true;
      this.invalidate();
      this.removeMouseListeners();
   }
   get sliderVisible() { return this._sliderVisible; }
   set sliderVisible(v) { if (v === this.sliderVisible) return; this._sliderVisible = v; this.sliderVisibleChanged = true; this.invalidate(); }
   getDefaultOption() { return this.containerDefaults; }
   hideMsgBox() { this.msgBoxVisible = false; }
   getScreenShot() {
      if (this.selectedIndex === -1) return null;
      var r = this.indexRenderers.get(this.selectedIndex);
      var b = new BitmapData(this.width, this.height);
      b.draw(r);
      return b;
   }
   set dataProvider(v) { if (v === this.dataProvider || v == null) return; this._dataProvider = v; this.dataDirty = true; this.invalidate(); }
   get dataProvider() { return this._dataProvider; }
   updateScreens() {
      if (this._video && this.bmp) {
         this.bmp.draw(this._video, this.updateMatr);
         if (this._selectedIndex !== -1) {
            this.indexRenderers.get(this._selectedIndex).forceUpdate(this.bmp);
            return;
         }
         var self = this;
         this.renderers.forEach(function (i, s) { s.forceUpdate(self.bmp); });
      } else {
         TimerManager.getInstance().pauseCallBack(this.updateScreens);
      }
   }
   moveRendererToTop(item) {
      var top = 0, self = this;
      this.renderers.forEach(function (i, s) { top = Math.max(self.getChildIndex(s), top); });
      this.setChildIndex(item, top);
   }
   positionFunc() {
      var scroll = this._hScrollPosition * (this.hGap + this.screenWidth) * this.cols, self = this;
      this.renderers.forEach(function (i, s) {
         var col = Math.floor(i / self.rows);
         var row = i - col * self.rows;
         var x = self.paddingLeft + (self.hGap + self.screenWidth) * col;
         var y = self.paddingTop + (self.vGap + self.screenHeight) * row;
         if (i === self._selectedIndex) self.animator.setTargets(s, 0, 0, self.width, self.height);
         else self.animator.setTargets(s, x - scroll, y, self.screenWidth, self.screenHeight);
      });
      var t = this.animator.targetFor(this.slider);
      t.targetX = (this.width - this.slider.width) / 2;
      t.targetY = this.height - this.slider.height - 10;
      t.targetWidth = this.slider.width;
      t.targetHeight = this.slider.height;
   }
   mouseRollOverListener(e) {
      if (!this.sliderVisible) return;
      this.animator.targetFor(this.slider).targetAlpha = 1;
      this.animator.invalidate();
      this.animator.positionFuncCalled = true;
      this.invalidate();
      this.removeEventListener(MouseEvent.ROLL_OVER, this.b.mouseRollOverListener);
   }
   set msgBoxText(v) { if (v === this.msgBoxText) return; this._msgBoxText = v; this.msgBoxPropChanged = true; this.invalidate(); }
   get msgBoxText() { return this._msgBoxText; }
   moveItemToTop(item) { this.setChildIndex(item, this.numChildren - 1); }
   updateSelection(e) {
      var s = e.currentTarget;
      e.stopPropagation();
      var i = this.renderers.get(s);
      if (i === undefined || isNaN(i)) return;
      var changed = i !== this._selectedIndex;
      this.selectedIndex = i;
      if (changed) this.dispatchEvent(new Event("modeChange"));
   }
   removeMouseListeners() {
      this.stage.removeEventListener(MouseEvent.MOUSE_MOVE, this.b.systemManager_mouseMoveListenr);
      this.stage.removeEventListener(MouseEvent.MOUSE_UP, this.b.systemManager_mouseUpListener);
      this.removeEventListener(MouseEvent.ROLL_OUT, this.b.mouseRolloutListener);
   }
   commitProperties() {
      if (!this.dataDirty) return;
      this.dataDirty = false;
      if (this._dataProvider == null) return;
      var self = this;
      Array.from(this.renderers.keys()).forEach(function (s) {
         self.removeChild(s);
         self.animator.removeChild(s);
         s.removeEventListener(MouseEvent.CLICK, self.b.updateSelection);
         self.indexRenderers.delete(self.renderers.get(s));
         self.renderers.delete(s);
      });
      for (var i = 0; i < this._dataProvider.length; i++) {
         var s = this.factory.newScreenInstance(this._dataProvider[i]);
         this.renderers.set(s, i);
         this.indexRenderers.set(i, s);
         this.addChild(s);
         this.animator.addChild(s);
         s.addEventListener(MouseEvent.CLICK, this.b.updateSelection);
         if (s.useMsg) s.addEventListener("showMsg", this.b.showMsgListener);
      }
      if (this._selectedIndex !== -1) {
         var sel = this.indexRenderers.get(this._selectedIndex);
         this.moveRendererToTop(sel);
         sel.labelVisible = false;
      }
      this.animator.invalidate();
   }
   sliderChangeListener(e) {
      this.magnitude = this.slider.value;
      this.magChanged = true;
      if (this.selectedIndex !== -1) this.indexRenderers.get(this._selectedIndex).magnitude = this.magnitude;
   }
   update() {
      var self = this;
      if (this.wasResized) {
         this.skin.draw(this);
         this.scrollRect = new Rectangle(0, 0, this.width, this.height);
      }
      if (this.centerChanged) {
         this.centerChanged = false;
         this.renderers.forEach(function (i, s) {
            if (s.usePosition) { s.centerX = self.centerX; s.centerY = self.centerY; }
         });
      }
      if (this.magChanged) {
         this.magChanged = false;
         this.renderers.forEach(function (i, s) { if (s.useSlider) s.magnitude = self.magnitude; });
      }
      if (this.sliderVisibleChanged) {
         this.sliderVisibleChanged = false;
         this.slider.visible = this.sliderVisible;
         if (this.sliderVisible) {
            this.doSliderAlphaCheck = true;
            this.animator.targetFor(this.slider).targetAlpha = 1;
            this.animator.invalidate();
            this.sliderAlphaCheck();
         } else {
            this.doSliderAlphaCheck = false;
         }
      }
      if (this.msgBoxPropChanged) {
         this.msgBoxPropChanged = false;
         this.msgBox.visible = this.msgBoxVisible;
         this.msgBox.text = this.msgBoxText;
         if (this.msgBox.visible) {
            this.msgBox.validateNow();
            this.msgBox.move((this.width - this.msgBox.width) / 2, this.height - this.msgBox.height - 10);
            this.moveItemToTop(this.msgBox);
         }
      }
      this.animator.validate();
   }
   mouseDownListener(e) {
      if (this._selectedIndex === -1) return;
      var s = this.indexRenderers.get(this._selectedIndex);
      if (!s.usePosition) return;
      this.beingAdjusted = s;
      this.addMouseListeners();
      this.systemManager_mouseMoveListenr(null);
   }
   bgDetectedListener(e) {
      var bg = new BitmapData(this._video.width, this._video.height);
      bg.draw(this.backgroundRemover.detectedBackground, this.updateMatr);
      this.renderers.forEach(function (i, s) { s.bgBmp = bg; });
      this.msgBoxText = ScreenContainer.MSG_BG_DETECTED;
      TimerManager.getInstance().addCallBack(this.hideMsgBox, 0.3, true, this);
   }
   get visible() { return super.visible; }
   set visible(v) {
      if (v === this._scVisible) return;
      this._scVisible = v;
      super.visible = v;
      if (v) {
         this.camera = this._camera;
         TimerManager.getInstance().resumeCallBack(this.updateScreens);
      } else {
         TimerManager.getInstance().pauseCallBack(this.updateScreens);
      }
   }
   set selectedIndex(value) {
      var item = null, self = this;
      if (value === this._selectedIndex) return;
      if (!this.intialized) { this._selectedIndex = value; return; }
      this._lastSelectedIndex = this._selectedIndex;
      if (value === -1) {
         this._selectedIndex = -1;
         this.sliderVisible = false;
         if (this.msgBoxVisible && this._lastSelectedIndex !== -1) {
            if (this.backgroundRemover && !this.backgroundRemover.detectedBackground) this.backgroundRemover.stopDetection();
         }
         this.msgBoxVisible = false;
      } else {
         item = this.indexRenderers.get(value);
         item.labelVisible = false;
         this._selectedIndex = value;
         if (item.useSlider) {
            this.sliderVisible = true;
            this.moveItemToTop(this.slider);
         }
         if (item.useBgBmp && !this.backgroundRemover.detectedBackground) {
            this.msgBoxVisible = true;
            if (this.backgroundRemover) {
               this.msgBoxText = ScreenContainer.MSG_STEP_OUT_FRAME;
               this.backgroundRemover.addEventListener("backgroundDetected", this.b.bgDetectedListener);
               this.backgroundRemover.startDetection();
            }
            this.moveItemToTop(this.msgBox);
         }
         this.moveRendererToTop(item);
      }
      if (this._lastSelectedIndex !== -1) {
         var last = this.indexRenderers.get(this._lastSelectedIndex);
         var labelSet = function (ae) {
            ae.currentTarget.removeEventListener(AnimationEvent.ANIMATION_COMPLETE, labelSet);
            if (!ae.interrupted) last.labelVisible = true;
         };
         this.animator.targetFor(last).addEventListener(AnimationEvent.ANIMATION_COMPLETE, labelSet, false, 0, false);
      }
      this.animator.invalidate();
      this.invalidate();
   }
   get selectedIndex() { return this._selectedIndex; }
   recalculateVisibles() {
      this.visibleScreens = [];
      var start = 9 * this._hScrollPosition;
      for (var i = 0; i < 9; i++) this.visibleScreens.push(start + i);
   }
}
ScreenContainer.MSG_BG_DETECTED = "Background Detected";
ScreenContainer.MSG_STEP_OUT_FRAME = "Please step out of the Frame";
PB.ScreenContainer = ScreenContainer;

// ---------------------------------------------------------------------------
// Main: the 642 x 684 PhotoBooth window.
// ---------------------------------------------------------------------------

class MainShadowMock extends KComponent {
   constructor() {
      super({ width: 642, height: 684 });
      this.filters = [new F.DropShadowFilter(1, 0, 0, 1, 70, 70, 2, 3)];
      this.skin = Singletons.getInstance(skins.MainShadowMockSkin);
   }
   update() { if (this.wasResized) this.skin.draw(this); }
}

class SaveQueueItem { constructor() { this.bmp = null; this.fileName = null; } }

class Main extends KComponent {
   constructor() {
      super({ width: 642, height: 684 });
      this.scrollRightBtn = null;
      this.viewer = null;
      this.numPhotosChanged = false;
      this.isEncoding = false;
      this._numPhotos = 0;
      this.flasher = null;
      this.scrollLeftBtn = null;
      this.title = null;
      this.photoSizeLabel = null;
      this.photoList = null;
      this.screen = null;
      this.controlBar = null;
      this.skin = Singletons.getInstance(PB.MainSkin);
      this.encoder = new ASJPEGEncoder();
      this.model = Singletons.getInstance(Model);
      this.model.addEventListener("modeChange", this.b.model_modeChangeListener);
      this.model.addEventListener("screenHScrollChange", this.b.model_screenHScrollChangeListener);
      this.model.addEventListener("picModeChange", this.b.model_picModeChangeListener);
      this.model.addEventListener("selectedPhotoChange", this.b.model_selectedPhotoChangeListener);
      this.model.photos.addEventListener(CollectionEvent.COLLECTION_CHANGE, this.b.model_photos_collectionChangeListener);
      this.fileReference = new PB.FileReference();
      this.fileReference.addEventListener(Event.COMPLETE, this.b.saveCompleteListener);
      this.fileReference.addEventListener(Event.CANCEL, this.b.saveCancelListener);
      this.fileReference.addEventListener(F.IOErrorEvent.IO_ERROR, this.b.saveIOErrorListener);
      // CHANGE: the Facebook and Flickr clients are not ported (both APIs are
      // gone). The original created them here with Karthik's API keys:
      // this.fb = new Facebook({ apiKey: "02de8b14c885de9b97857bc314cabbf6", secret: "REDACTED" });
      // this.fk = new Flickr({ apiKey: "c38fef085c38ef41106be4cae81c1f7f", secret: "REDACTED" });
   }
   ctrlbar_doFlashListener(e) {
      this.flasher.value = Main.FLASHER_SPEED;
      this.flasherUp();
   }
   ctrlbar_changeScrollListener(e) { this.model.effectScreenHScroll = this.controlBar.scrollIndex; }
   photoList_photoDeleteListener(e) {
      var i = e.index;
      this.model.photos.removeItemAt(i);
      if (i === this.model.selectedPhotoIndex) {
         this.model.selectedPhotoIndex = -1;
         if (this.model.photos.length > i) {
            this.model.selectedPhotoIndex = i;
            this.photoList.selectedIndex = i;
         } else if (this.model.photos.length > 0) {
            this.model.selectedPhotoIndex = this.model.photos.length - 1;
            this.photoList.selectedIndex = this.model.selectedPhotoIndex;
         } else {
            this.model.mainState = Model.MODE_PIC;
         }
      }
   }
   photoList_dropCompleteListener(e) {
      if (this.model.mainState === Model.MODE_VIEWER) this.model.mainState = Model.MODE_PIC;
   }
   startImageEncode(item, onComplete) {
      var self = this;
      this.isEncoding = true;
      var box = new FileEncodingPopup();
      GrowlManager.getInstance().addGrowBoxToStage(box, 2147483647);
      var progressListener = function (e) { box.progress = e.progress; };
      var completeListener = function (e) {
         self.isEncoding = false;
         GrowlManager.getInstance().removeBoxFromStage(box);
         self.encoder.removeEventListener(JPEGEncodeEvent.EVENT_COMPLETE, completeListener);
         self.encoder.removeEventListener(JPEGEncodeEvent.EVENT_PROGRESS, progressListener);
         onComplete.call(self, e.completedEncode);
      };
      this.encoder.addEventListener(JPEGEncodeEvent.EVENT_PROGRESS, progressListener);
      this.encoder.addEventListener(JPEGEncodeEvent.EVENT_COMPLETE, completeListener);
      this.encoder.startEncode(item.bmp);
   }
   getSaveQueuItemFromViewer() {
      var item = this.model.photos.getItemAt(this.model.selectedPhotoIndex);
      var d = new Date(), prefix = "", bmp = null;
      // CHANGE: the original wrote Date.month (0-based) and Date.day (the day
      // of the week, 0-6), so June 20 came out as "2011-5-1". Same pattern,
      // with the real month and day of the month.
      var stamp = d.getFullYear() + "-" + (d.getMonth() + 1) + "-" + d.getDate() + "(" + d.getHours() + "-" + d.getMinutes() + "-" + d.getSeconds() + ").jpg";
      var q = new SaveQueueItem();
      if (item instanceof PB.Item1Pic) {
         bmp = item.itemData[0];
         prefix = "YourPhoto_";
      } else if (item instanceof PB.Item4Pic) {
         switch (this.viewer.getViewer4Index()) {
            case -1: prefix = "FourPic_"; bmp = item.getComposite(); break;
            case 0: prefix = "TopLeft_"; bmp = item.itemData[0]; break;
            case 1: prefix = "TopRight_"; bmp = item.itemData[1]; break;
            case 2: prefix = "BottomLeft_"; bmp = item.itemData[2]; break;
            case 3: prefix = "BottomRight_"; bmp = item.itemData[3]; break;
            default: throw new Error("should not be here in ctrlbar_downloadPictureListener");
         }
      }
      q.bmp = bmp;
      q.fileName = prefix + stamp;
      return q;
   }
   scr_screenModeChangeListener(e) {
      this.model.mainState = this.screen.selectedIndex === -1 ? Model.MODE_EFFECTS : Model.MODE_PIC;
   }
   flasherUp() {
      if (this.flasher.value !== 0) {
         if (this.flasher.value < 1) {
            this.flasher.value += Main.FLASHER_SPEED;
            TimerManager.getInstance().addCallBack(this.flasherUp, 20, true, this);
         } else {
            TimerManager.getInstance().addCallBack(this.flasherDown, 20, true, this);
         }
      }
   }
   createChildren() {
      this.title = new Label();
      this.title.text = "Karthik's PictureBooth";
      this.title.fontSize = 11;
      this.title.fontColor = 3355443;
      this.addChild(this.title);
      this.screen = new ScreenContainer();
      this.screen.dataProvider = this.model.screens;
      if (PB.Camera.getCamera() != null) this.screen.camera = PB.Camera.getCamera();
      this.screen.addEventListener("modeChange", this.b.scr_screenModeChangeListener);
      this.addChild(this.screen);
      this.screen.move(1, 23);
      this.viewer = new Viewer();
      this.addChild(this.viewer);
      this.viewer.move(1, 23);
      this.viewer.visible = false;
      this.controlBar = new ControlBar();
      this.addChild(this.controlBar);
      this.controlBar.move(1, 504);
      this.controlBar.addEventListener("modeChange", this.b.ctrlbar_screenModeChangeListener);
      this.controlBar.addEventListener("leftScroll", this.b.ctrlbar_leftScrollListener);
      this.controlBar.addEventListener("rightScroll", this.b.ctrlbar_rightScrollListener);
      this.controlBar.addEventListener("changeScroll", this.b.ctrlbar_changeScrollListener);
      this.controlBar.addEventListener("doTakePic", this.b.ctlbar_takePicListener);
      this.controlBar.addEventListener("picModeChange", this.b.ctrlbar_picModeChangeListener);
      this.controlBar.addEventListener("goPicMode", this.b.ctrlbar_goPicModeListener);
      this.controlBar.addEventListener("downloadPicture", this.b.ctrlbar_downloadPictureListener);
      // CHANGE: upload listeners disabled; Facebook and Flickr uploads no longer work.
      // this.controlBar.addEventListener("facebookPicture", this.b.ctrlbar_facebookPictureListener);
      // this.controlBar.addEventListener("flickrPicture", this.b.ctrlbar_flickrPictureListener);
      this.controlBar.addEventListener("doFlash", this.b.ctrlbar_doFlashListener);
      this.photoList = new PhotoList();
      this.addChild(this.photoList);
      this.photoList.move(27, 564);
      this.photoList.addEventListener("dropComplete", this.b.photoList_dropCompleteListener);
      this.photoList.addEventListener("photoSelect", this.b.photoList_photoSelectListener);
      this.photoList.addEventListener("photoDelete", this.b.photoList_photoDeleteListener);
      this.photoList.addEventListener("hScrollChanged", this.b.photoList_scrollChangedListener);
      this.photoList.addEventListener("maxHScrollChanged", this.b.photoList_maxHScrollChangedListener);
      this.syncAllFromModel();
      this.scrollLeftBtn = new LeftScrollBtn();
      this.scrollRightBtn = new RightScrollBtn();
      this.addChild(this.scrollLeftBtn);
      this.addChild(this.scrollRightBtn);
      this.scrollLeftBtn.move(1, 564);
      this.scrollRightBtn.move(640 - 25, 564);
      this.scrollLeftBtn.addEventListener(MouseEvent.CLICK, this.b.photoList_scrollLeftClickListener);
      this.scrollRightBtn.addEventListener(MouseEvent.CLICK, this.b.photoList_scrollRightClickListener);
      this.photoSizeLabel = new Label();
      this.addChild(this.photoSizeLabel);
   }
   model_screenHScrollChangeListener(e) {
      this.screen.hScrollPosition = this.model.effectScreenHScroll;
      this.controlBar.scrollIndex = this.model.effectScreenHScroll;
   }
   model_picModeChangeListener(e) {}
   model_selectedPhotoChangeListener(e) {
      if (this.model.selectedPhotoIndex !== -1) this.viewer.data = this.model.photos.getItemAt(this.model.selectedPhotoIndex);
   }
   get numPhotos() { return this._numPhotos; }
   set numPhotos(v) { if (v === this._numPhotos) return; this._numPhotos = v; this.numPhotosChanged = true; this.invalidate(); }
   ctrlbar_screenModeChangeListener(e) {
      e.stopPropagation();
      this.model.mainState = e.targetMode === EffectsButton.MODE_EFFECTS ? Model.MODE_EFFECTS : Model.MODE_PIC;
   }
   saveCancelListener(e) {
      GrowlManager.getInstance().showMessage("Canceled", "You canceled the save, but you can save again.", null, 3);
      this.isEncoding = false;
   }
   saveCompleteListener(e) {
      GrowlManager.getInstance().showMessage("Save Complete", "File Successfully saved.", null, 3);
      this.isEncoding = false;
   }
   updateScrollBtnState() {
      this.scrollRightBtn.disabled = this.photoList.hScrollPosition >= this.photoList.maxHScroll;
      this.scrollLeftBtn.disabled = this.photoList.hScrollPosition === 0;
   }
   ctlbar_takePicListener(e) {
      var shot;
      if (this.model.picMode === Model.PIC_MODE_1PIC) {
         shot = this.screen.getScreenShot();
         this.model.photos.addItem(new PB.Item1Pic(shot));
         this.model.selectedPhotoIndex = this.model.photos.length - 1;
         this.viewer.data = this.model.photos.getItemAt(this.model.selectedPhotoIndex);
         this.model.mainState = Model.MODE_VIEWER;
      } else {
         if (this.model.picMode !== Model.PIC_MODE_4_PIC) throw new Error("unknown pic mode, currently only support 1pic and 4pic");
         shot = this.screen.getScreenShot();
         this.model.pic4Buffer.push(shot);
         if (this.model.pic4Buffer.length === 4) {
            var b = this.model.pic4Buffer;
            this.model.photos.addItem(new PB.Item4Pic(b[0], b[1], b[2], b[3]));
            this.model.pic4Buffer = [];
            this.model.selectedPhotoIndex = this.model.photos.length - 1;
            this.viewer.data = this.model.photos.getItemAt(this.model.selectedPhotoIndex);
            this.model.mainState = Model.MODE_VIEWER;
         }
      }
   }
   syncAllFromModel() {
      this.screen.dataProvider = this.model.screens;
      this.photoList.dataProvider = this.model.photos;
   }
   downloadItem(item) {
      if (this.isEncoding) return;
      var self = this, box = new FileCompleteBox();
      this.startImageEncode(item, function (data) {
         GrowlManager.getInstance().addPopUp(box, true);
         box.button.addEventListener(MouseEvent.CLICK, function () {
            self.fileReference.save(data, item.fileName);
            GrowlManager.getInstance().removePopUp(box);
         });
      });
   }
   saveIOErrorListener(e) {
      GrowlManager.getInstance().showMessage("Error!", "There seem to be an error writing the file, is your harddrive full? try filing a bug report or email me.");
      this.isEncoding = false;
   }
   photoList_scrollRightClickListener(e) {
      if (this.scrollRightBtn.disabled) return;
      if (this.photoList) this.photoList.scrollRight();
   }
   update() {
      if (this.wasResized) {
         this.skin.draw(this);
         this.title.validateNow();
         this.title.move((this.width - this.title.getMeasuredWidth()) / 2, 2);
         this.positionLabel();
      }
      if (this.numPhotosChanged) {
         this.numPhotosChanged = false;
         this.positionLabel();
      }
   }
   ctrlbar_downloadPictureListener(e) {
      if (this.isEncoding) { this.showEncodingMsg(); return; }
      this.downloadItem(this.getSaveQueuItemFromViewer());
   }
   model_photos_collectionChangeListener(e) { this.numPhotos = this.model.photos.length; }
   photoList_photoSelectListener(e) {
      this.model.selectedPhotoIndex = e.index;
      this.model.mainState = Model.MODE_VIEWER;
      this.updateScrollBtnState();
   }

   /* CHANGE: Facebook and Flickr upload flows, kept for reference but not run.
    * Facebook's REST API (api.facebook.com/restserver.php) and Flickr's
    * frob-based auth were retired years ago. The original ActionScript is in
    * reference/as3/com/karthik/photobooth/Main.as, and the web-service
    * clients are in reference/as3/com/karthik/webapis/.
    *
   ctrlbar_facebookPictureListener(e) {
      if (this.isEncoding) { this.showEncodingMsg(); return; }
      var self = this, item = this.getSaveQueuItemFromViewer();
      var popupAuth = null, popupUpload = null, loginBox = null, connectBox = null, getSessionBox = null, uploadBox = null, imageData = null;
      var fb = this.fb;
      var popup_loginClickListener = function () { fb.openAuthWindow(fb.auth_loginURL()); };
      var popupUL_uploadClickListener = function () {
         if (getSessionBox) GrowlManager.getInstance().removeBoxFromStage(getSessionBox);
         GrowlManager.getInstance().removePopUp(popupUpload);
         fb_initiateUpload();
      };
      var popup_authClickListener = function () { fb.addEventListener(WSLoginEvent.TYPE_LOGIN, fb_loginListener); fb.auth_getSession(); };
      var fb_loginListener = function (ev) {
         fb.removeEventListener(WSLoginEvent.TYPE_LOGIN, fb_loginListener);
         GrowlManager.getInstance().removePopUp(popupAuth);
         if (!ev.success) { GrowlManager.getInstance().showMessage("Authentication Failed", "Seems to be a network problem or you disabled cookies"); return; }
         if (loginBox) GrowlManager.getInstance().removeBoxFromStage(loginBox);
         getSessionBox = GrowlManager.getInstance().showMessage("Authenticated", "Now click on the Upload button to upload your photo");
         showUploadPopup();
      };
      var showUploadPopup = function () {
         popupUpload = new FacebookUploadPop();
         popupUpload.addEventListener("uploadClick", popupUL_uploadClickListener);
         GrowlManager.getInstance().addPopUp(popupUpload, true);
      };
      var fb_initiateUpload = function () {
         fb.addEventListener(WSUploadEvent.TYPE_UPLOAD, fb_uploadCompleteListener);
         uploadBox = GrowlManager.getInstance().showMessage("Uploading", "Uploading your photo to facebook now, will take a while to complete");
         fb.uploadPhoto(item.fileName, imageData);
      };
      var fb_uploadCompleteListener = function (ev) {
         GrowlManager.getInstance().removeBoxFromStage(uploadBox);
         fb.removeEventListener(WSUploadEvent.TYPE_UPLOAD, fb_uploadCompleteListener);
         if (ev.success) GrowlManager.getInstance().showMessage("Uploading Success", "Your photo has been uploaded to facebook, its now under the 'pending albums' section of your facebook photos.");
         else GrowlManager.getInstance().showMessage("Uploading Failed", "An error occured during your upload, please check your network connection. If you are sure your network is fine, file a bug report with me");
      };
      var fb_connectListener = function () {
         fb.removeEventListener(WSConnectionEvent.TYPE_CONNECTION, fb_connectListener);
         GrowlManager.getInstance().removeBoxFromStage(connectBox);
         loginBox = GrowlManager.getInstance().showMessage("Connected!", "Connection to facebook established, please login!");
         popupAuth = new FacebookAuthPop();
         GrowlManager.getInstance().addPopUp(popupAuth, true);
         popupAuth.addEventListener("loginClick", popup_loginClickListener);
         popupAuth.addEventListener("authClick", popup_authClickListener);
      };
      item.bmp = Resizer.resizeToFacebook(item.bmp);
      this.startImageEncode(item, function (data) {
         imageData = data;
         if (!fb.hasSession) {
            fb.addEventListener(WSConnectionEvent.TYPE_CONNECTION, fb_connectListener);
            fb.auth_createToken();
            connectBox = GrowlManager.getInstance().showMessage("Connecting", "Connecting to facebook, please wait");
         } else showUploadPopup();
      });
   }
   ctrlbar_flickrPictureListener(e) {
      // Same flow as Facebook against Flickr (auth_getFrob, auth_getToken,
      // uploadPhoto), with "Connecting to flickr, please wait",
      // "Connection to flickr established, please login!" and
      // "Your photo has been uploaded to Flickr, its now in your flickr album".
   }
   */

   positionLabel() {
      var word = this.numPhotos > 1 ? "Photos" : "Photo";
      this.photoSizeLabel.text = this.numPhotos.toString() + " " + word;
      this.photoSizeLabel.fontSize = 10;
      this.photoSizeLabel.fontColor = 3750201;
      this.photoSizeLabel.validateNow();
      var w = this.photoSizeLabel.getMeasuredWidth(), h = this.photoSizeLabel.getMeasuredHeight();
      this.photoSizeLabel.setActualSize(w, h + 3);
      this.photoSizeLabel.move((this.width - w) / 2, this.height - h - 5);
   }
   model_modeChangeListener(e) {
      if (this.model.mainState === Model.MODE_PIC) {
         this.screen.visible = true;
         this.viewer.visible = false;
         var first = this.model.effectScreenHScroll * 9, last = first + 8;
         if (this.screen.selectedIndex === -1) {
            var idx = this.screen.lastSelectedIndex;
            if (idx < first || idx > last) idx = first + 4;
            this.screen.selectedIndex = idx;
         }
         this.controlBar.mode = ControlBar.MODE_PIC;
         this.photoList.selectedIndex = -1;
      } else if (this.model.mainState === Model.MODE_EFFECTS) {
         this.screen.visible = true;
         this.viewer.visible = false;
         this.screen.selectedIndex = -1;
         this.controlBar.mode = ControlBar.MODE_EFFECTS;
      } else if (this.model.mainState === Model.MODE_VIEWER) {
         this.viewer.visible = true;
         this.screen.visible = false;
         this.controlBar.mode = ControlBar.MODE_VIEWER;
      }
   }
   ctrlbar_goPicModeListener(e) { this.model.mainState = Model.MODE_PIC; }
   ctrlbar_leftScrollListener(e) { e.stopPropagation(); --this.model.effectScreenHScroll; }
   photoList_maxHScrollChangedListener(e) { this.updateScrollBtnState(); }
   ctrlbar_rightScrollListener(e) { e.stopPropagation(); this.model.effectScreenHScroll += 1; }
   flasherDown() {
      if (this.flasher.value > 0) {
         this.flasher.value -= Main.FLASHER_SPEED;
         TimerManager.getInstance().addCallBack(this.flasherDown, 20, true, this);
      }
   }
   showEncodingMsg() {
      GrowlManager.getInstance().showMessage("Patience", "Encoding the current image, please wait till this one is done first before initiating operations for the next image.", null, 2);
   }
   photoList_scrollLeftClickListener(e) {
      if (this.scrollLeftBtn.disabled) return;
      if (this.photoList) this.photoList.scrollLeft();
   }
   ctrlbar_picModeChangeListener(e) {
      switch (this.controlBar.takingPicType) {
         case ControlBar.TAKING_PIC_1PIC: this.model.picMode = Model.PIC_MODE_1PIC; break;
         case ControlBar.TAKING_PIC_4PIC: this.model.picMode = Model.PIC_MODE_4_PIC; break;
      }
   }
   photoList_scrollChangedListener(e) { this.updateScrollBtnState(); }
}
Main.FLASHER_SPEED = 0.2;
PB.Main = Main;

// ---------------------------------------------------------------------------
// PhotoBooth_AS_Port: the document class.
// ---------------------------------------------------------------------------

class AppSkin extends K.KSkin {
   constructor() { super(); this.bmpDat = PB.Assets.bitmaps.AppSkin_Bmp; }
   draw(t) {
      this.clear(t);
      this.drawRect({ target: t, lineStyle: null, width: t.stage.stageWidth, height: t.stage.stageHeight,
         fillStyle: { type: "bmp", bmp: this.bmpDat, matr: new Matrix(t.stage.stageWidth / this.bmpDat.width, 0, 0, t.stage.stageHeight / this.bmpDat.height) } });
   }
}

class PhotoBooth_AS_Port extends KSprite {
   constructor(stage) {
      super();
      // The document class is on the stage before its constructor runs.
      stage.addChild(this);
      this.skin = Singletons.getInstance(AppSkin);
      this.copyright = null;
      this.shadowMock = null;
      this.main = null;
      this.flasher = null;
      K.KComponentGlobals.initialize(this);
      GrowlManager.init(this);
      this.stage.addEventListener(Event.RESIZE, this.b.resizeListener);
      this.skin.draw(this);
      if (PB.Camera.getCamera() != null) {
         this.shadowMock = new MainShadowMock();
         this.addChild(this.shadowMock);
         this.copyright = new Label();
         this.copyright.text = "Created by Karthik Tharavaad, see http://tharavaad.wordpress.com/";
         this.copyright.fontSize = 10;
         this.copyright.fontColor = 14540253;
         this.addChild(this.copyright);
         this.main = new Main();
         this.addChild(this.main);
         this.positionMain();
         var flasher = new Flasher(this);
         this.addChild(flasher);
         this.main.flasher = flasher;
         TimerManager.getInstance().addCallBack(this.welcomeMSG, 1, true, this);
      } else {
         TimerManager.getInstance().addCallBack(this.needCameraMsg, 1, true, this);
      }
   }
   positionMain() {
      this.main.move((this.stage.stageWidth - this.main.width) / 2, (this.stage.stageHeight - this.main.height) / 2);
      this.shadowMock.move(this.main.x, this.main.y);
      this.copyright.validateNow();
      this.copyright.move(this.stage.stageWidth - this.copyright.getMeasuredWidth() - 10, this.stage.stageHeight - this.copyright.getMeasuredHeight() - 10);
   }
   needCameraMsg() {
      GrowlManager.getInstance().showMessage("No Camera", "No webcam was detected on your computer =( unfortunately, you can't use this application without one. You can get a cheap webcam off Ebay for around $15. Email me at karthik_tharavaad@yahoo.com if you any questions.", null, 2147483647);
   }
   resizeListener(e) {
      this.skin.draw(this);
      if (this.main) this.positionMain();
   }
   welcomeMSG() {
      GrowlManager.getInstance().showMessage("Welcome!", "welcome to PictureBooth. Feel free to email me at karthik_tharavaad@yahoo.com if you any questions or find any bugs, otherwise, enjoy!");
   }
}
PB.PhotoBooth_AS_Port = PhotoBooth_AS_Port;

// ---------------------------------------------------------------------------
// Boot: replaces the MDM Zinc projector.
// ---------------------------------------------------------------------------

var KERNELS = {
   // name: { params: PBJ defaultValue for each parameter, inputs: extra images }
   Sepia: { params: {} },
   ComicBook: { params: { dot_spacing: 12, max_dot_size: 10, gamma: 0.8 } },
   Bulge: { params: { x: 320, y: 240, image_width: 640, magnitude: 0.5 } },
   Pinch: { params: { x: 320, y: 240, image_width: 640, image_height: 480, magnitude: 0.5 } },
   Dent: { params: { x: 320, y: 240, image_width: 640, image_height: 480, magnitude: 0.5 } },
   Twirl: { params: { x: 320, y: 240, magnitude: 0.5, image_width: 640, image_height: 480, max_angle: 200 } },
   Fisheye: { params: { x: 320, y: 240, cutoff: 486, scale: 1.5 } },
   Stretch: { params: { x: 320, y: 240, scale: 0.67, image_width: 640, mag: 120 } },
   LightTunnel: { params: { x: 320, y: 240, magnitude: 0.5, image_width: 640, image_height: 480 } },
   BGRemoved: { params: { thresh: 3, weight_y: 0.48, weight_i: 0.56, weight_q: 0.48 }, inputs: ["bg"] }
};

var BITMAPS = ["AppSkin_Bmp.jpg", "SketchScreen_Sketch.jpg", "PopArtScreen_Pallette.png", "ThermalScreen_Pallette.png",
   "GrowlBox_Icon.png", "GrowlBox_IconDl.png", "FBBtnSkin_Norm.png", "FlickrBtnSkin_Norm.png", "PicasaBtnSkin_Norm.png",
   "DLBtnSkin_Norm.png", "ShutterButtonSkinNormal_Norm.png", "ShutterButtonSkinNormal_NormI.png"];

function loadImage(url) {
   return new Promise(function (resolve, reject) {
      var img = new Image();
      img.onload = function () { resolve(img); };
      img.onerror = function () { reject(new Error("failed to load " + url)); };
      img.src = url;
   });
}

// Asks for the webcam. Resolves to a Camera, or null when there is none or
// permission is refused (the original then shows its "No Camera" message).
function openCamera() {
   if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) return Promise.resolve(null);
   return navigator.mediaDevices.getUserMedia({
      video: { width: { ideal: 640 }, height: { ideal: 480 }, facingMode: "user" }, audio: false
   }).then(function (stream) {
      var v = document.createElement("video");
      v.muted = true; v.playsInline = true; v.autoplay = true;
      v.setAttribute("playsinline", ""); v.setAttribute("muted", "");
      v.srcObject = stream;
      return new Promise(function (resolve) {
         v.addEventListener("loadeddata", function () { resolve(new PB.Camera(v)); }, { once: true });
         var p = v.play();
         if (p && p.catch) p.catch(function () {});
      });
   }).catch(function (err) {
      console.warn("PhotoBooth: no camera", err);
      return null;
   });
}

// The window needs 642 x 684 plus margins for the shadow and the credit line.
var MIN_W = 682, MIN_H = 740;

PB.start = function (container, options) {
   options = options || {};
   var base = PB.baseUrl = options.baseUrl || "";
   var canvas = document.createElement("canvas");
   canvas.className = "photobooth-stage";
   container.appendChild(canvas);
   var stage = new F.Stage(canvas, 24);

   // CHANGE: the projector filled a desktop window at 1:1 (StageScaleMode
   // NO_SCALE). Embedded as an applet, the stage fills its container; when
   // the container is smaller than the window needs, everything scales down
   // to fit instead of being cut off.
   function fit() {
      var cw = container.clientWidth || MIN_W, ch = container.clientHeight || MIN_H;
      var s = Math.min(1, cw / MIN_W, ch / MIN_H);
      stage.setSize(Math.floor(cw / s), Math.floor(ch / s), s);
   }
   fit();
   if (global.ResizeObserver) new ResizeObserver(fit).observe(container);
   else global.addEventListener("resize", fit);

   var shaders = Promise.all(Object.keys(KERNELS).map(function (name) {
      return fetch(base + "shaders/" + name + ".frag").then(function (r) { return r.text(); }).then(function (src) {
         F.FilterEngine.registerKernel(name, { src: src, params: KERNELS[name].params, inputs: KERNELS[name].inputs || [] });
      });
   }));
   var bitmaps = Promise.all(BITMAPS.map(function (file) {
      return loadImage(base + "assets/" + file).then(function (img) {
         PB.Assets.bitmaps[file.replace(/\.\w+$/, "")] = BitmapData.fromImage(img);
      });
   }));
   var fonts = document.fonts ? document.fonts.load("10px \"Lucida Grande\"").catch(function () {}) : Promise.resolve();

   return Promise.all([shaders, bitmaps, fonts, openCamera()]).then(function (r) {
      PB.Camera._instance = r[3];
      PB.app = new PhotoBooth_AS_Port(stage);
      return PB.app;
   });
};

})(window);
