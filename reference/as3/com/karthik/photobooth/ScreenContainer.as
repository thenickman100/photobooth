package com.karthik.photobooth
{
   import com.karthik.components.Slider;
   import com.karthik.core.KComponent;
   import com.karthik.managers.AnimationEvent;
   import com.karthik.managers.LayoutAnimator;
   import com.karthik.managers.LayoutTarget;
   import com.karthik.managers.Singletons;
   import com.karthik.managers.TimerManager;
   import com.karthik.photobooth.screens.BaseScreen;
   import com.karthik.photobooth.screens.PBSlider;
   import com.karthik.photobooth.screens.ScreenFactory;
   import com.karthik.photobooth.screens.bg_removed.BackgroundRemover;
   import com.karthik.photobooth.screens.bg_removed.MsgBox;
   import com.karthik.photobooth.skins.ScreenContainerSkin;
   import flash.display.*;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.geom.Matrix;
   import flash.geom.Rectangle;
   import flash.media.Camera;
   import flash.media.Video;
   import flash.utils.Dictionary;
   
   public class ScreenContainer extends KComponent
   {
      
      public static const MSG_BG_DETECTED:String = "Background Detected";
      
      public static const MSG_STEP_OUT_FRAME:String = "Please step out of the Frame";
      
      private var renderers:Dictionary = new Dictionary(true);
      
      protected var magnitude:Number = 0.5;
      
      private var defaultOptions:Object = {
         "hGap":16,
         "vGap":12,
         "width":640,
         "height":480,
         "screenWidth":192,
         "screenHeight":144,
         "paddingLeft":16,
         "paddingTop":16,
         "rows":3,
         "cols":3,
         "factory":new ScreenFactory(),
         "skin":Singletons.getInstance(ScreenContainerSkin)
      };
      
      private var sliderVisibleChanged:Boolean = false;
      
      protected var _visible:Boolean = true;
      
      private var _camera:Camera;
      
      private var dataDirty:Boolean = true;
      
      private var beingAdjusted:BaseScreen;
      
      public var hGap:Number;
      
      protected var _sliderVisible:Boolean;
      
      private var indexRenderers:Dictionary = new Dictionary(true);
      
      protected var _hScrollPosition:Number = 0;
      
      private var backgroundRemover:BackgroundRemover;
      
      protected var _msgBoxText:String = "Your Msg";
      
      private var updateMatr:Matrix = new Matrix(-1,0,0,1,640);
      
      public var vGap:Number;
      
      private var _lastSelectedIndex:Number = 4;
      
      private var _video:Video;
      
      public var paddingTop:Number;
      
      private var bmp:BitmapData;
      
      private var lastMouseX:Number = 0;
      
      private var lastMouseY:Number = 0;
      
      public var skin:ScreenContainerSkin;
      
      protected var msgBox:MsgBox;
      
      protected var _msgBoxVisible:Boolean = false;
      
      protected var _dataProvider:Array;
      
      protected var centerChanged:Boolean = false;
      
      protected var centerX:Number = 0;
      
      protected var centerY:Number = 0;
      
      public var screenHeight:Number;
      
      private var visibleScreens:Array = [0,1,2,3,4,5,6,7,8];
      
      private var doSliderAlphaCheck:Boolean = false;
      
      public var paddingLeft:Number;
      
      public var screenWidth:Number;
      
      protected var _factory:ScreenFactory;
      
      public var rows:Number;
      
      private var slider:Slider;
      
      private var animator:LayoutAnimator = new LayoutAnimator(this);
      
      protected var magChanged:Boolean = false;
      
      public var cols:Number;
      
      protected var msgBoxPropChanged:Boolean = true;
      
      private var _selectedIndex:Number = 4;
      
      public function ScreenContainer(param1:Object = null)
      {
         this.animator.positionFunc = this.positionFunc;
         TimerManager.getInstance().addCallBack(this.updateScreens,20,false,this);
         addEventListener(MouseEvent.ROLL_OUT,this.mouseRollOutListener);
         super(param1);
      }
      
      public function get lastSelectedIndex() : Number
      {
         return this._lastSelectedIndex;
      }
      
      private function mouseRollOutListener(param1:MouseEvent) : void
      {
         if(!this.sliderVisible)
         {
            return;
         }
         this.animator.targetFor(this.slider).targetAlpha = 0;
         this.animator.invalidate();
         this.animator.positionFuncCalled = true;
         invalidate();
         addEventListener(MouseEvent.ROLL_OVER,this.mouseRollOverListener);
      }
      
      private function sliderAlphaCheck() : void
      {
         if(!this.doSliderAlphaCheck)
         {
            return;
         }
      }
      
      public function get factory() : ScreenFactory
      {
         return this._factory;
      }
      
      private function showMsgListener(param1:Event) : void
      {
      }
      
      public function set msgBoxVisible(param1:Boolean) : void
      {
         if(param1 == this.msgBoxVisible)
         {
            return;
         }
         this._msgBoxVisible = param1;
         this.msgBoxPropChanged = true;
         invalidate();
      }
      
      override protected function createChildren() : void
      {
         super.createChildren();
         this.slider = new PBSlider();
         addChild(this.slider);
         this.slider.visible = false;
         this.slider.addEventListener("changeValue",this.sliderChangeListener);
         this.animator.addChild(this.slider);
         addEventListener(MouseEvent.MOUSE_DOWN,this.mouseDownListener);
         this.msgBox = new MsgBox();
         addChild(this.msgBox);
      }
      
      public function get camera() : Camera
      {
         return this._camera;
      }
      
      private function addMouseListeners() : void
      {
         stage.addEventListener(MouseEvent.MOUSE_MOVE,this.systemManager_mouseMoveListenr,false,-50,true);
         stage.addEventListener(MouseEvent.MOUSE_UP,this.systemManager_mouseUpListener,false,-50,true);
         addEventListener(MouseEvent.ROLL_OUT,this.mouseRolloutListener,false,-50,true);
      }
      
      public function set factory(param1:ScreenFactory) : void
      {
         if(param1 == this.factory)
         {
            return;
         }
         this._factory = param1;
         this.dataDirty = true;
         invalidate();
      }
      
      private function mouseRolloutListener(param1:MouseEvent) : void
      {
         this.removeMouseListeners();
      }
      
      private function systemManager_mouseMoveListenr(param1:MouseEvent) : void
      {
         this.beingAdjusted.centerX = mouseX / width;
         this.beingAdjusted.centerY = mouseY / height;
         this.centerX = this.beingAdjusted.centerX;
         this.centerY = this.beingAdjusted.centerY;
      }
      
      public function set hScrollPosition(param1:Number) : void
      {
         if(param1 == this.hScrollPosition)
         {
            return;
         }
         this._hScrollPosition = param1;
         trace("set hscroll: " + param1);
         this.recalculateVisibles();
         this.animator.invalidate();
         invalidate();
      }
      
      public function set camera(param1:Camera) : void
      {
         this._camera = param1;
         this._camera.setMode(640,480,100);
         this._camera.setQuality(0,100);
         this._video = new Video(640,480);
         this._video.attachCamera(this.camera);
         this.backgroundRemover = new BackgroundRemover(this._video);
         this.bmp = new BitmapData(640,480);
      }
      
      private function systemManager_mouseUpListener(param1:MouseEvent) : void
      {
         this.centerChanged = true;
         invalidate();
         this.removeMouseListeners();
      }
      
      public function get sliderVisible() : Boolean
      {
         return this._sliderVisible;
      }
      
      override protected function getDefaultOption() : Object
      {
         return this.defaultOptions;
      }
      
      private function hideMsgBox() : void
      {
         this.msgBoxVisible = false;
      }
      
      public function getScreenShot() : BitmapData
      {
         if(this.selectedIndex == -1)
         {
            return null;
         }
         var _loc1_:KComponent = this.indexRenderers[this.selectedIndex];
         var _loc2_:BitmapData = new BitmapData(width,height);
         _loc2_.draw(_loc1_);
         return _loc2_;
      }
      
      public function set dataProvider(param1:Array) : void
      {
         if(param1 == this.dataProvider || param1 == null)
         {
            return;
         }
         this._dataProvider = param1;
         this.dataDirty = true;
         invalidate();
      }
      
      private function updateScreens() : void
      {
         var _loc1_:BaseScreen = null;
         var _loc2_:Object = null;
         if(Boolean(this._video) && Boolean(this.bmp))
         {
            this.bmp.draw(this._video,this.updateMatr);
            if(this._selectedIndex != -1)
            {
               _loc1_ = this.indexRenderers[this._selectedIndex];
               _loc1_.forceUpdate(this.bmp);
               return;
            }
            for(_loc2_ in this.renderers)
            {
               BaseScreen(_loc2_).forceUpdate(this.bmp);
            }
         }
         else
         {
            TimerManager.getInstance().pauseCallBack(this.updateScreens);
         }
      }
      
      private function moveRendererToTop(param1:BaseScreen) : void
      {
         var _loc2_:BaseScreen = null;
         var _loc4_:int = 0;
         var _loc5_:Object = null;
         var _loc3_:int = 0;
         for(_loc5_ in this.renderers)
         {
            _loc2_ = _loc5_ as BaseScreen;
            _loc4_ = getChildIndex(_loc2_);
            _loc3_ = Math.max(_loc4_,_loc3_);
         }
         setChildIndex(param1,_loc3_);
      }
      
      private function positionFunc() : void
      {
         var _loc2_:Object = null;
         var _loc3_:LayoutTarget = null;
         var _loc4_:BaseScreen = null;
         var _loc5_:Number = NaN;
         var _loc6_:Number = NaN;
         var _loc7_:Number = NaN;
         var _loc8_:Number = NaN;
         var _loc9_:Number = NaN;
         var _loc1_:Number = this._hScrollPosition * (this.hGap + this.screenWidth) * this.cols;
         for(_loc2_ in this.renderers)
         {
            _loc4_ = _loc2_ as BaseScreen;
            _loc5_ = Number(this.renderers[_loc4_]);
            _loc6_ = Math.floor(_loc5_ / this.rows);
            _loc7_ = _loc5_ - _loc6_ * this.rows;
            _loc8_ = this.paddingLeft + (this.hGap + this.screenWidth) * _loc6_;
            _loc9_ = this.paddingTop + (this.vGap + this.screenHeight) * _loc7_;
            if(_loc5_ == this._selectedIndex)
            {
               this.animator.setTargets(_loc4_,0,0,width,height);
            }
            else
            {
               this.animator.setTargets(_loc4_,_loc8_ - _loc1_,_loc9_,this.screenWidth,this.screenHeight);
            }
         }
         _loc3_ = this.animator.targetFor(this.slider);
         _loc3_.targetX = (width - this.slider.width) / 2;
         _loc3_.targetY = height - this.slider.height - 10;
         _loc3_.targetWidth = this.slider.width;
         _loc3_.targetHeight = this.slider.height;
      }
      
      public function get msgBoxVisible() : Boolean
      {
         return this._msgBoxVisible;
      }
      
      private function mouseRollOverListener(param1:MouseEvent) : void
      {
         if(!this.sliderVisible)
         {
            return;
         }
         this.animator.targetFor(this.slider).targetAlpha = 1;
         this.animator.invalidate();
         this.animator.positionFuncCalled = true;
         invalidate();
         removeEventListener(MouseEvent.ROLL_OVER,this.mouseRollOverListener);
      }
      
      public function get hScrollPosition() : Number
      {
         return this._hScrollPosition;
      }
      
      public function set sliderVisible(param1:Boolean) : void
      {
         if(param1 == this.sliderVisible)
         {
            return;
         }
         this._sliderVisible = param1;
         this.sliderVisibleChanged = true;
         invalidate();
      }
      
      public function set msgBoxText(param1:String) : void
      {
         if(param1 == this.msgBoxText)
         {
            return;
         }
         this._msgBoxText = param1;
         this.msgBoxPropChanged = true;
         invalidate();
      }
      
      public function get dataProvider() : Array
      {
         return this._dataProvider;
      }
      
      private function moveItemToTop(param1:KComponent) : void
      {
         setChildIndex(param1,numChildren - 1);
      }
      
      private function updateSelection(param1:MouseEvent) : void
      {
         var _loc2_:BaseScreen = param1.currentTarget as BaseScreen;
         param1.stopPropagation();
         var _loc3_:Number = Number(this.renderers[_loc2_]);
         if(isNaN(_loc3_))
         {
            trace("screen container,error out, NaN index, updateSelection");
            return;
         }
         var _loc4_:Boolean = true;
         if(_loc3_ == this._selectedIndex)
         {
            _loc4_ = false;
         }
         this.selectedIndex = _loc3_;
         if(_loc4_)
         {
            dispatchEvent(new Event("modeChange"));
         }
      }
      
      private function removeMouseListeners() : void
      {
         stage.removeEventListener(MouseEvent.MOUSE_MOVE,this.systemManager_mouseMoveListenr);
         stage.removeEventListener(MouseEvent.MOUSE_UP,this.systemManager_mouseUpListener);
         removeEventListener(MouseEvent.ROLL_OUT,this.mouseRolloutListener);
      }
      
      override protected function commitProperties() : void
      {
         var _loc1_:int = 0;
         var _loc2_:BaseScreen = null;
         var _loc3_:Object = null;
         if(this.dataDirty)
         {
            this.dataDirty = false;
            if(this._dataProvider == null)
            {
               return;
            }
            for(_loc3_ in this.renderers)
            {
               _loc2_ = _loc3_ as BaseScreen;
               removeChild(_loc2_);
               this.animator.removeChild(_loc2_);
               _loc2_.removeEventListener(MouseEvent.CLICK,this.updateSelection);
               this.indexRenderers[this.renderers[_loc2_]] = null;
               this.renderers[_loc2_] = null;
            }
            _loc1_ = 0;
            while(_loc1_ < this._dataProvider.length)
            {
               _loc2_ = this.factory.newScreenInstance(this._dataProvider[_loc1_]);
               this.renderers[_loc2_] = _loc1_;
               this.indexRenderers[_loc1_] = _loc2_;
               addChild(_loc2_);
               this.animator.addChild(_loc2_);
               _loc2_.addEventListener(MouseEvent.CLICK,this.updateSelection);
               if(_loc2_.useMsg)
               {
                  _loc2_.addEventListener("showMsg",this.showMsgListener);
               }
               _loc1_++;
            }
            if(this._selectedIndex != -1)
            {
               _loc2_ = this.indexRenderers[this._selectedIndex];
               this.moveRendererToTop(_loc2_);
               _loc2_.labelVisible = false;
            }
            this.animator.invalidate();
         }
      }
      
      private function sliderChangeListener(param1:Event) : void
      {
         var _loc2_:BaseScreen = null;
         this.magnitude = this.slider.value;
         this.magChanged = true;
         if(this.selectedIndex != -1)
         {
            _loc2_ = this.indexRenderers[this._selectedIndex];
            _loc2_.magnitude = this.magnitude;
         }
      }
      
      override protected function update() : void
      {
         var _loc1_:Object = null;
         var _loc2_:BaseScreen = null;
         if(wasResized)
         {
            this.skin.draw(this);
            scrollRect = new Rectangle(0,0,width,height);
         }
         if(this.centerChanged)
         {
            this.centerChanged = false;
            for(_loc1_ in this.renderers)
            {
               _loc2_ = _loc1_ as BaseScreen;
               if(_loc2_.usePosition)
               {
                  _loc2_.centerX = this.centerX;
                  _loc2_.centerY = this.centerY;
               }
            }
         }
         if(this.magChanged)
         {
            this.magChanged = false;
            for(_loc1_ in this.renderers)
            {
               _loc2_ = _loc1_ as BaseScreen;
               if(_loc2_.useSlider)
               {
                  _loc2_.magnitude = this.magnitude;
               }
            }
         }
         if(this.sliderVisibleChanged)
         {
            this.sliderVisibleChanged = false;
            this.slider.visible = this.sliderVisible;
            if(this.sliderVisible)
            {
               this.doSliderAlphaCheck = true;
               this.animator.targetFor(this.slider).targetAlpha = 1;
               this.animator.invalidate();
               this.sliderAlphaCheck();
            }
            else
            {
               this.doSliderAlphaCheck = false;
            }
         }
         if(this.msgBoxPropChanged)
         {
            this.msgBoxPropChanged = false;
            this.msgBox.visible = this.msgBoxVisible;
            this.msgBox.text = this.msgBoxText;
            if(this.msgBox.visible)
            {
               this.msgBox.validateNow();
               this.msgBox.move((width - this.msgBox.width) / 2,height - this.msgBox.height - 10);
               this.moveItemToTop(this.msgBox);
            }
         }
         this.animator.validate();
      }
      
      private function mouseDownListener(param1:MouseEvent) : void
      {
         if(this._selectedIndex == -1)
         {
            return;
         }
         var _loc2_:BaseScreen = this.indexRenderers[this._selectedIndex];
         if(!_loc2_.usePosition)
         {
            return;
         }
         this.beingAdjusted = _loc2_;
         this.addMouseListeners();
         this.systemManager_mouseMoveListenr(null);
      }
      
      public function get msgBoxText() : String
      {
         return this._msgBoxText;
      }
      
      private function bgDetectedListener(param1:Event) : void
      {
         var _loc3_:Object = null;
         var _loc2_:BitmapData = new BitmapData(this._video.width,this._video.height);
         _loc2_.draw(this.backgroundRemover.detectedBackground,this.updateMatr);
         for(_loc3_ in this.renderers)
         {
            BaseScreen(_loc3_).bgBmp = _loc2_;
         }
         this.msgBoxText = MSG_BG_DETECTED;
         TimerManager.getInstance().addCallBack(this.hideMsgBox,0.3,true,this);
      }
      
      override public function set visible(param1:Boolean) : void
      {
         if(param1 == this._visible)
         {
            return;
         }
         this._visible = param1;
         super.visible = param1;
         if(param1)
         {
            this.camera = this._camera;
            TimerManager.getInstance().resumeCallBack(this.updateScreens);
         }
         else
         {
            TimerManager.getInstance().pauseCallBack(this.updateScreens);
         }
      }
      
      public function set selectedIndex(param1:Number) : void
      {
         var item:BaseScreen = null;
         var labelSet:Function = null;
         var value:Number = param1;
         if(value == this._selectedIndex)
         {
            return;
         }
         if(!intialized)
         {
            this._selectedIndex = value;
            return;
         }
         this._lastSelectedIndex = this._selectedIndex;
         if(value == -1)
         {
            this._selectedIndex = -1;
            this.sliderVisible = false;
            if(this.msgBoxVisible && this._lastSelectedIndex != -1)
            {
               if(Boolean(this.backgroundRemover) && !this.backgroundRemover.detectedBackground)
               {
                  this.backgroundRemover.stopDetection();
                  trace("STOP DETCTION");
               }
            }
            this.msgBoxVisible = false;
         }
         else
         {
            item = this.indexRenderers[value];
            item.labelVisible = false;
            this._selectedIndex = value;
            if(item.useSlider)
            {
               this.sliderVisible = true;
               this.moveItemToTop(this.slider);
            }
            if(item.useBgBmp && !this.backgroundRemover.detectedBackground)
            {
               this.msgBoxVisible = true;
               if(this.backgroundRemover)
               {
                  this.msgBoxText = MSG_STEP_OUT_FRAME;
                  this.backgroundRemover.addEventListener("backgroundDetected",this.bgDetectedListener);
                  this.backgroundRemover.startDetection();
                  trace("STARTING DETECTION");
               }
               this.moveItemToTop(this.msgBox);
            }
            this.moveRendererToTop(item);
         }
         if(this._lastSelectedIndex != -1)
         {
            item = this.indexRenderers[this._lastSelectedIndex];
            labelSet = function(param1:AnimationEvent):void
            {
               (param1.currentTarget as LayoutTarget).removeEventListener(AnimationEvent.ANIMATION_COMPLETE,labelSet);
               if(!param1.interrupted)
               {
                  item.labelVisible = true;
               }
            };
            this.animator.targetFor(item).addEventListener(AnimationEvent.ANIMATION_COMPLETE,labelSet,false,0,false);
         }
         this.animator.invalidate();
         invalidate();
      }
      
      private function recalculateVisibles() : void
      {
         this.visibleScreens = [];
         var _loc1_:int = 9 * this._hScrollPosition;
         var _loc2_:int = 0;
         while(_loc2_ < 9)
         {
            this.visibleScreens.push(_loc1_);
            _loc2_++;
            _loc1_++;
         }
      }
      
      public function get selectedIndex() : Number
      {
         return this._selectedIndex;
      }
   }
}

