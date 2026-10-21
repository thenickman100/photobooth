package com.karthik.photobooth.skins.list_item
{
   import com.karthik.core.KSkin;
   import com.karthik.core.KSprite;
   import com.karthik.photobooth.model.IPhotoItem;
   import com.karthik.photobooth.model.Item1Pic;
   import com.karthik.photobooth.model.Item4Pic;
   import flash.display.*;
   import flash.geom.Matrix;
   import flash.geom.Point;
   
   public class PhotoItemRendererSkin extends KSkin
   {
      
      public function PhotoItemRendererSkin()
      {
         super();
      }
      
      override public function draw(param1:KSprite, param2:Object = null) : void
      {
         var _loc5_:BitmapData = null;
         var _loc3_:IPhotoItem = param2.data as IPhotoItem;
         if(!_loc3_)
         {
            return;
         }
         clear(param1);
         var _loc4_:BitmapData = new BitmapData(80,60);
         if(_loc3_ is Item1Pic)
         {
            _loc4_.draw(_loc3_.itemData[0] as BitmapData,new Matrix(80 / 640,0,0,60 / 480));
         }
         else if(_loc3_ is Item4Pic)
         {
            _loc5_ = new BitmapData(40,30);
            _loc5_.draw(_loc3_.itemData[0] as BitmapData,new Matrix(40 / 640,0,0,30 / 480));
            _loc4_.copyPixels(_loc5_,_loc5_.rect,new Point(0,0));
            _loc5_.draw(_loc3_.itemData[1] as BitmapData,new Matrix(40 / 640,0,0,30 / 480));
            _loc4_.copyPixels(_loc5_,_loc5_.rect,new Point(40,0));
            _loc5_.draw(_loc3_.itemData[2] as BitmapData,new Matrix(40 / 640,0,0,30 / 480));
            _loc4_.copyPixels(_loc5_,_loc5_.rect,new Point(0,30));
            _loc5_.draw(_loc3_.itemData[3] as BitmapData,new Matrix(40 / 640,0,0,30 / 480));
            _loc4_.copyPixels(_loc5_,_loc5_.rect,new Point(40,30));
         }
         drawRect({
            "target":param1,
            "lineStyle":{"alpha":0},
            "fillStyle":{
               "type":"bmp",
               "bmp":_loc4_
            },
            "width":80,
            "height":60
         });
      }
   }
}

