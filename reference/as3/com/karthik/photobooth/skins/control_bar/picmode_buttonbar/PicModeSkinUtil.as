package com.karthik.photobooth.skins.control_bar.picmode_buttonbar
{
   import flash.display.BitmapData;
   import flash.geom.Rectangle;
   
   public class PicModeSkinUtil
   {
      
      public static const TRANSPARENT:uint = 0;
      
      private var rect:Rectangle = new Rectangle(0,0,0,0);
      
      public function PicModeSkinUtil()
      {
         super();
      }
      
      public function make1PicIcon(param1:uint, param2:uint) : BitmapData
      {
         var _loc3_:BitmapData = this.baseBmp();
         _loc3_.fillRect(this.setRect(0,0,14,12),param1);
         _loc3_.fillRect(this.setRect(2,2,10,8),TRANSPARENT);
         _loc3_.fillRect(this.setRect(0,12,14,1),param2);
         return _loc3_;
      }
      
      private function setRect(param1:Number, param2:Number, param3:Number, param4:Number) : Rectangle
      {
         this.rect.x = param1;
         this.rect.y = param2;
         this.rect.width = param3;
         this.rect.height = param4;
         return this.rect;
      }
      
      private function baseBmp() : BitmapData
      {
         return new BitmapData(14,13,true,0);
      }
      
      public function makeVidIcon(param1:uint, param2:uint) : BitmapData
      {
         var _loc3_:BitmapData = this.baseBmp();
         _loc3_.fillRect(this.setRect(0,0,14,12),param1);
         _loc3_.fillRect(this.setRect(4,2,6,3),TRANSPARENT);
         _loc3_.fillRect(this.setRect(4,7,6,3),TRANSPARENT);
         _loc3_.setPixel32(1,1,TRANSPARENT);
         _loc3_.setPixel32(1,4,TRANSPARENT);
         _loc3_.setPixel32(1,7,TRANSPARENT);
         _loc3_.setPixel32(1,10,TRANSPARENT);
         _loc3_.setPixel32(12,1,TRANSPARENT);
         _loc3_.setPixel32(12,4,TRANSPARENT);
         _loc3_.setPixel32(12,7,TRANSPARENT);
         _loc3_.setPixel32(12,10,TRANSPARENT);
         _loc3_.fillRect(this.setRect(0,12,14,1),param2);
         return _loc3_;
      }
      
      public function make4PicIcon(param1:uint, param2:uint) : BitmapData
      {
         var _loc3_:BitmapData = this.baseBmp();
         _loc3_.fillRect(this.setRect(0,0,14,12),param1);
         _loc3_.fillRect(this.setRect(2,2,4,3),TRANSPARENT);
         _loc3_.fillRect(this.setRect(8,2,4,3),TRANSPARENT);
         _loc3_.fillRect(this.setRect(2,7,4,3),TRANSPARENT);
         _loc3_.fillRect(this.setRect(8,7,4,3),TRANSPARENT);
         _loc3_.fillRect(this.setRect(0,12,14,1),param2);
         return _loc3_;
      }
   }
}

