package com.karthik.photobooth.skins.control_bar
{
   import com.karthik.lang.HashUtil;
   import com.karthik.skins.KButtonSkin;
   import flash.filters.DropShadowFilter;
   
   public class MacButtonSkin extends KButtonSkin
   {
      
      public function MacButtonSkin()
      {
         super();
      }
      
      override protected function drawDisabled() : void
      {
         this.drawNormal();
      }
      
      override protected function opSet() : void
      {
         opt = HashUtil.mergeHash(opt,{
            "lineStyle":{
               "type":"color",
               "thickness":1,
               "alpha":1,
               "color":4934475,
               "hint":true
            },
            "fillStyle":{
               "type":"gradient",
               "colors":[16645629,11382189],
               "box":{
                  "x":0,
                  "y":1,
                  "width":btn.width,
                  "height":btn.height - 1
               }
            },
            "height":btn.height - 2,
            "width":btn.width - 2,
            "radius":3,
            "y":0,
            "x":1
         });
      }
      
      override protected function drawDown() : void
      {
         this.drawNormal();
         btn.filters = [new DropShadowFilter(0,0,0,0.7,btn.width / 2,btn.height / 2,1,2,true)];
      }
      
      override protected function drawOver() : void
      {
         this.drawNormal();
      }
      
      override protected function drawNormal() : void
      {
         drawKRoundRect(opt,{
            "fillStyle":null,
            "y":1,
            "lineStyle":{"color":2236962}
         });
         drawKRoundRect(opt);
         btn.filters = [];
      }
   }
}

