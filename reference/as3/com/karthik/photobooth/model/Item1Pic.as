package com.karthik.photobooth.model
{
   import flash.display.BitmapData;
   
   public class Item1Pic implements IPhotoItem
   {
      
      private var _bmp:BitmapData;
      
      public function Item1Pic(param1:BitmapData)
      {
         super();
         this._bmp = param1;
      }
      
      public function get type() : String
      {
         return ItemTypes.TYPE_1PIC;
      }
      
      public function get dateTaken() : Date
      {
         return new Date();
      }
      
      public function get itemData() : Array
      {
         return [this._bmp];
      }
   }
}

