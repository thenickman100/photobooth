package com.karthik.core
{
   import flash.display.Sprite;
   
   public class KSprite extends Sprite
   {
      
      protected var _height:Number;
      
      protected var _width:Number;
      
      public function KSprite()
      {
         super();
      }
      
      override public function set height(param1:Number) : void
      {
         if(this._height == param1)
         {
            return;
         }
         this._height = param1;
      }
      
      override public function get height() : Number
      {
         return this._height;
      }
      
      override public function set width(param1:Number) : void
      {
         if(this._width == param1)
         {
            return;
         }
         this._width = param1;
      }
      
      override public function get width() : Number
      {
         return this._width;
      }
   }
}

