package com.karthik.components
{
   import com.karthik.core.KComponent;
   import com.karthik.core.KSkin;
   import com.karthik.managers.LayoutAnimator;
   import com.karthik.managers.Singletons;
   import com.karthik.photobooth.skins.slider.PBSliderSkin;
   import flash.events.Event;
   import flash.events.MouseEvent;
   
   public class Slider extends KComponent
   {
      
      public static const HORIZONTAL:int = 1;
      
      public static const VERTICLE:int = 2;
      
      public var padRight:Number;
      
      protected var track:KComponent;
      
      public var thumbWidth:Number;
      
      protected var _orientation:int;
      
      public var min:Number;
      
      protected var thumb:KComponent;
      
      public var trackHeight:Number;
      
      public var thumbHeight:Number;
      
      private var defaultOptions:Object = {
         "skin":Singletons.getInstance(PBSliderSkin),
         "thumbWidth":10,
         "thumbHeight":10,
         "trackHeight":4,
         "padLeft":10,
         "padRight":10,
         "width":100,
         "height":30,
         "min":0,
         "max":1,
         "value":0.5
      };
      
      private var animator:LayoutAnimator = new LayoutAnimator(this);
      
      protected var _value:Number = 0;
      
      public var padLeft:Number;
      
      public var max:Number;
      
      public var skin:KSkin;
      
      public function Slider(param1:Object = null)
      {
         this.animator.positionFunc = this.positionFunc;
         this.animator.animationSpeed = 0.1;
         super(param1);
      }
      
      protected function thumb_mouseDown(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         this.addthumbListeners();
      }
      
      protected function positionFunc() : void
      {
         var _loc1_:Number = width - this.padLeft - this.padRight;
         var _loc2_:Number = this.padLeft + this.value / (this.max - this.min) * _loc1_ - this.thumbWidth / 2;
         var _loc3_:Number = (height - this.thumbHeight) / 2;
         this.animator.setTargets(this.thumb,_loc2_,_loc3_,this.thumbWidth,this.thumbHeight);
         _loc2_ = this.padLeft;
         _loc3_ = (height - this.trackHeight) / 2;
         this.animator.setTargets(this.track,_loc2_,_loc3_,_loc1_,this.trackHeight);
      }
      
      protected function stage_mouseUpListener(param1:MouseEvent) : void
      {
         this.removeThumbListeners();
      }
      
      override protected function update() : void
      {
         super.update();
         this.animator.validate();
         if(wasResized)
         {
            this.skin.draw(this,{
               "thumb":this.thumb,
               "track":this.track
            });
         }
      }
      
      override protected function createChildren() : void
      {
         super.createChildren();
         this.track = new KComponent();
         this.track.addEventListener(MouseEvent.CLICK,this.trackClickListener,false,-5,true);
         this.thumb = new KComponent();
         this.thumb.addEventListener(MouseEvent.MOUSE_DOWN,this.thumb_mouseDown,false,-5,true);
         this.animator.addChild(this.track);
         this.animator.addChild(this.thumb);
         addChild(this.track);
         addChild(this.thumb);
      }
      
      protected function stage_mouseOutListener(param1:MouseEvent) : void
      {
         this.removeThumbListeners();
      }
      
      public function set value(param1:Number) : void
      {
         if(param1 == this._value)
         {
            return;
         }
         this._value = param1;
         dispatchEvent(new Event("changeValue"));
         this.animator.invalidate();
         invalidate();
      }
      
      protected function addthumbListeners() : void
      {
         stage.addEventListener(MouseEvent.MOUSE_MOVE,this.stage_mouseMoveListener);
         stage.addEventListener(MouseEvent.MOUSE_UP,this.stage_mouseUpListener);
         stage.addEventListener(MouseEvent.ROLL_OUT,this.stage_mouseOutListener);
      }
      
      protected function removeThumbListeners() : void
      {
         stage.removeEventListener(MouseEvent.MOUSE_MOVE,this.stage_mouseMoveListener);
         stage.removeEventListener(MouseEvent.MOUSE_UP,this.stage_mouseUpListener);
         stage.removeEventListener(MouseEvent.ROLL_OUT,this.stage_mouseOutListener);
      }
      
      override protected function getDefaultOption() : Object
      {
         return this.defaultOptions;
      }
      
      protected function stage_mouseMoveListener(param1:MouseEvent) : void
      {
         var _loc2_:Number = mouseX;
         var _loc3_:Number = width - this.padLeft - this.padRight;
         this.animator.targetFor(this.thumb).jumpNext = true;
         if(_loc2_ < this.padLeft)
         {
            this.value = this.min;
         }
         else if(_loc2_ > width - this.padRight)
         {
            this.value = this.max;
         }
         else
         {
            this.value = this.min + (_loc2_ - this.padLeft) / _loc3_ * (this.max - this.min);
         }
      }
      
      public function get value() : Number
      {
         return this._value;
      }
      
      protected function trackClickListener(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         var _loc2_:Number = width - this.padLeft - this.padRight;
         this.value = this.min + (mouseX - this.padLeft) / _loc2_ * (this.max - this.min);
      }
   }
}

