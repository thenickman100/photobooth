package com.karthik.photobooth.popups
{
   import com.karthik.core.KComponent;
   import flash.display.Sprite;
   
   public class Flasher extends KComponent
   {
      
      protected var _root:Sprite;
      
      protected var _value:Number = 0;
      
      protected var valueChanged:Boolean = false;
      
      public function Flasher(param1:Sprite)
      {
         this._root = param1;
         super();
      }
      
      override protected function update() : void
      {
         super.update();
         if(this.valueChanged)
         {
            this.valueChanged = false;
            graphics.clear();
            graphics.beginFill(16777215,this.value);
            graphics.drawRect(0,0,this._root.stage.stageWidth,this._root.stage.stageHeight);
            if(this.value <= 0)
            {
               graphics.clear();
            }
         }
      }
      
      public function get value() : Number
      {
         return this._value;
      }
      
      public function set value(param1:Number) : void
      {
         if(this.value == param1)
         {
            return;
         }
         this._value = param1;
         this.valueChanged = true;
         invalidate();
      }
   }
}

