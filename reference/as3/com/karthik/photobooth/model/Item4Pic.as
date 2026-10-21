package com.karthik.photobooth.model
{
   import flash.display.BitmapData;
   import flash.geom.Matrix;
   import flash.geom.Point;
   
   public class Item4Pic implements IPhotoItem
   {
      
      public var bmpTR:BitmapData;
      
      public var bmpBL:BitmapData;
      
      public var bmpBR:BitmapData;
      
      public var bmpTL:BitmapData;
      
      public function Item4Pic(param1:BitmapData, param2:BitmapData, param3:BitmapData, param4:BitmapData)
      {
         super();
         this.bmpTL = param1;
         this.bmpTR = param2;
         this.bmpBL = param3;
         this.bmpBR = param4;
      }
      
      public function get itemData() : Array
      {
         return [this.bmpTL,this.bmpTR,this.bmpBL,this.bmpBR];
      }
      
      public function getComposite() : BitmapData
      {
         var _loc1_:BitmapData = new BitmapData(this.bmpTL.width / 2,this.bmpTL.height / 2);
         var _loc2_:BitmapData = new BitmapData(this.bmpTL.width,this.bmpTL.height);
         _loc1_.draw(this.bmpTL,new Matrix(0.5,0,0,0.5));
         _loc2_.copyPixels(_loc1_,_loc1_.rect,new Point(0,0));
         _loc1_.draw(this.bmpTR,new Matrix(0.5,0,0,0.5));
         _loc2_.copyPixels(_loc1_,_loc1_.rect,new Point(_loc1_.width,0));
         _loc1_.draw(this.bmpBL,new Matrix(0.5,0,0,0.5));
         _loc2_.copyPixels(_loc1_,_loc1_.rect,new Point(0,_loc1_.height));
         _loc1_.draw(this.bmpBR,new Matrix(0.5,0,0,0.5));
         _loc2_.copyPixels(_loc1_,_loc1_.rect,new Point(_loc1_.width,_loc1_.height));
         return _loc2_;
      }
      
      public function get dateTaken() : Date
      {
         return new Date();
      }
      
      public function get type() : String
      {
         return ItemTypes.TYPE_4PIC;
      }
   }
}

