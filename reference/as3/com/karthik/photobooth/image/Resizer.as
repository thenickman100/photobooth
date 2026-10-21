package com.karthik.photobooth.image
{
   import flash.display.BitmapData;
   import flash.geom.Matrix;
   
   public class Resizer
   {
      
      public static const FACEBOOK_MAX_WIDTH:Number = 600;
      
      public static const FACEBOOK_MAX_HEIGHT:Number = 450;
      
      public function Resizer()
      {
         super();
      }
      
      public static function resizeToFacebook(param1:BitmapData) : BitmapData
      {
         var _loc2_:BitmapData = new BitmapData(FACEBOOK_MAX_WIDTH,FACEBOOK_MAX_HEIGHT);
         _loc2_.draw(param1,new Matrix(_loc2_.width / param1.width,0,0,_loc2_.height / param1.height));
         return _loc2_;
      }
   }
}

