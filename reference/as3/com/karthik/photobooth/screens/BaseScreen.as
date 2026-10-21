package com.karthik.photobooth.screens
{
   import com.karthik.components.Label;
   import com.karthik.core.KComponent;
   import com.karthik.core.KSprite;
   import flash.display.BitmapData;
   import flash.filters.DropShadowFilter;
   import flash.geom.Matrix;
   
   public class BaseScreen extends KComponent
   {
      
      protected var _bgBmp:BitmapData;
      
      protected var lastBmp:BitmapData;
      
      protected var _magnitude:Number = 0.5;
      
      protected var _usePosition:Boolean = false;
      
      protected var matr:Matrix = new Matrix();
      
      protected var screenName:String = "Normal";
      
      protected var _useBgBmp:Boolean = false;
      
      protected var drawBmp:BitmapData;
      
      protected var _useMsg:Boolean;
      
      protected var bmpInvalid:Boolean = false;
      
      protected var wasBmpResized:Boolean = true;
      
      private var _labelVisible:Boolean = true;
      
      protected var bgBitmapChanged:Boolean = false;
      
      protected var effectDirty:Boolean = true;
      
      protected var _useSlider:Boolean = false;
      
      protected var canvas:KSprite;
      
      protected var _centerX:Number = 0.5;
      
      protected var _centerY:Number = 0.5;
      
      protected var label:Label;
      
      public function BaseScreen()
      {
         super();
      }
      
      public function get bgBmp() : BitmapData
      {
         return this._bgBmp;
      }
      
      public function get magnitude() : Number
      {
         return this._magnitude;
      }
      
      public function forceUpdate(param1:BitmapData) : void
      {
         if(!visible)
         {
            return;
         }
         this.lastBmp = param1;
         this.bmpDraw();
      }
      
      public function set useSlider(param1:Boolean) : void
      {
         if(this._useSlider == param1)
         {
            return;
         }
         this._useSlider = param1;
      }
      
      override protected function createChildren() : void
      {
         super.createChildren();
         this.canvas = new KSprite();
         addChild(this.canvas);
         this.createLabel();
      }
      
      public function get useMsg() : Boolean
      {
         return this._useMsg;
      }
      
      public function set usePosition(param1:Boolean) : void
      {
         if(this._usePosition == param1)
         {
            return;
         }
         this._usePosition = param1;
      }
      
      public function get centerX() : Number
      {
         return this._centerX;
      }
      
      public function get centerY() : Number
      {
         return this._centerY;
      }
      
      public function set magnitude(param1:Number) : void
      {
         if(this._magnitude == param1)
         {
            return;
         }
         this._magnitude = param1;
         this.effectDirty = true;
         invalidate();
      }
      
      public function set bgBmp(param1:BitmapData) : void
      {
         if(param1 == this.bgBmp)
         {
            return;
         }
         this._bgBmp = param1;
      }
      
      public function set labelVisible(param1:Boolean) : void
      {
         if(this._labelVisible == param1)
         {
            return;
         }
         this._labelVisible = param1;
         this.label.visible = param1;
         invalidate();
      }
      
      protected function bmpTransformations() : void
      {
      }
      
      public function set centerX(param1:Number) : void
      {
         if(this._centerX == param1)
         {
            return;
         }
         this._centerX = param1;
         this.effectDirty = true;
         invalidate();
      }
      
      protected function positionLabel() : void
      {
         this.label.validateNow();
         var _loc1_:Number = this.label.getMeasuredWidth();
         var _loc2_:Number = this.label.getMeasuredHeight();
         this.label.move((width - _loc1_) / 2,height - _loc2_ - 10);
      }
      
      public function set centerY(param1:Number) : void
      {
         if(this._centerY == param1)
         {
            return;
         }
         this._centerY = param1;
         this.effectDirty = true;
         invalidate();
      }
      
      public function get usePosition() : Boolean
      {
         return this._usePosition;
      }
      
      public function get useBgBmp() : Boolean
      {
         return this._useBgBmp;
      }
      
      public function get useSlider() : Boolean
      {
         return this._useSlider;
      }
      
      public function get labelVisible() : Boolean
      {
         return this._labelVisible;
      }
      
      protected function createLabel() : void
      {
         this.label = new Label();
         this.label.filters = [new DropShadowFilter(0,0,0,0.6,5,5,1,2)];
         this.label.text = this.screenName;
         this.label.fontSize = 14;
         this.label.fontColor = 16777215;
         this.label.visible = this._labelVisible;
         addChild(this.label);
      }
      
      override protected function update() : void
      {
         if((wasResized || this.wasBmpResized) && Boolean(this.lastBmp))
         {
            graphics.clear();
            graphics.beginFill(0,0.5);
            graphics.drawRect(0,0,width,height);
            graphics.endFill();
            this.wasBmpResized = false;
            this.matr.a = width / this.lastBmp.width;
            this.matr.d = height / this.lastBmp.height;
         }
         if(this.lastBmp)
         {
            this.bmpDraw();
         }
         if(wasResized)
         {
            this.positionLabel();
         }
      }
      
      protected function bmpDraw() : void
      {
         this.drawBmp = this.lastBmp;
         this.bmpTransformations();
         this.canvas.graphics.clear();
         this.matr.a = width / this.lastBmp.width;
         this.matr.d = height / this.lastBmp.height;
         this.canvas.graphics.beginBitmapFill(this.drawBmp,this.matr);
         this.canvas.graphics.drawRect(0,0,width,height);
      }
      
      public function set useBgBmp(param1:Boolean) : void
      {
         if(param1 == this.useBgBmp)
         {
            return;
         }
         this._useBgBmp = param1;
      }
      
      public function set useMsg(param1:Boolean) : void
      {
         if(param1 == this.useMsg)
         {
            return;
         }
         this._useMsg = param1;
      }
   }
}

