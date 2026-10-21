package com.karthik.photobooth.skins.control_bar.services
{
   import com.karthik.skins.KButtonSkin;
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.filters.GlowFilter;
   
   public class FlickrBtnSkin extends KButtonSkin
   {
      
      private var normBmp:BitmapData = (new this.Norm() as Bitmap).bitmapData;
      
      private var Norm:Class = FlickrBtnSkin_Norm;
      
      public function FlickrBtnSkin()
      {
         super();
      }
      
      override protected function drawDown() : void
      {
         this.drawNormal();
         btn.filters = [new GlowFilter(0,0.3,30,30,2,1,true)];
      }
      
      override protected function drawNormal() : void
      {
         drawRect({
            "target":btn,
            "lineStyle":{"alpha":0},
            "fillStyle":{
               "type":"bmp",
               "bmp":this.normBmp
            }
         });
         btn.filters = [];
      }
      
      override protected function drawOver() : void
      {
         this.drawNormal();
      }
   }
}

