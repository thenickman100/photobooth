package com.karthik.photobooth.skins.growl
{
   import com.karthik.skins.KButtonSkin;
   import flash.filters.DropShadowFilter;
   
   public class GrowBoxCloseButtonSkin extends KButtonSkin
   {
      
      public function GrowBoxCloseButtonSkin()
      {
         super();
      }
      
      override protected function drawOver() : void
      {
         this.drawNormal();
      }
      
      override protected function drawNormal() : void
      {
         drawCircle({
            "target":btn,
            "x":11,
            "y":11,
            "radius":11,
            "lineStyle":{
               "thickness":2,
               "color":16777215,
               "alpha":1
            },
            "fillStyle":{
               "color":0,
               "alpha":0.6
            }
         });
         drawPath({
            "target":btn,
            "lineStyle":{
               "thickness":2,
               "color":16777215,
               "alpha":1
            },
            "pts":[[7,7],[15,15]]
         });
         drawPath({
            "target":btn,
            "lineStyle":{
               "thickness":2,
               "color":16777215,
               "alpha":1
            },
            "pts":[[15,7],[7,15]]
         });
         btn.filters = [];
      }
      
      override protected function drawDown() : void
      {
         this.drawNormal();
         btn.filters = [new DropShadowFilter(0,0,0,0.8,10,10,1,2,true)];
      }
   }
}

