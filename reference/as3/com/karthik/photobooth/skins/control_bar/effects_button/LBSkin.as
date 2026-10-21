package com.karthik.photobooth.skins.control_bar.effects_button
{
   import com.karthik.skins.KButtonSkin;
   
   public class LBSkin extends KButtonSkin
   {
      
      public function LBSkin()
      {
         super();
      }
      
      override protected function drawOver() : void
      {
         this.drawNormal();
      }
      
      override protected function drawNormal() : void
      {
         drawRect({
            "target":btn,
            "lineStyle":null,
            "fillStyle":{
               "type":"gradient",
               "colors":[16645629,11382189]
            }
         });
         drawPath({
            "target":btn,
            "fillStyle":null,
            "lineStyle":{
               "color":4473924,
               "thickness":1,
               "alpha":1
            },
            "pts":[[btn.width,0],[btn.width,btn.height]]
         });
         drawPath({
            "target":btn,
            "fillStyle":{
               "type":"color",
               "color":(btn.disabled ? 10395294 : 0),
               "alpha":1
            },
            "closed":true,
            "lineStyle":{
               "color":(btn.disabled ? 10395294 : 0),
               "thickness":1,
               "alpha":1
            },
            "pts":[[30 - 6,9],[30 - 13,9],[30 - 13,5],[30 - 21.5,10.5],[30 - 13,16],[30 - 13,12],[30 - 6,12]]
         });
      }
      
      override protected function drawDown() : void
      {
         this.drawNormal();
         if(btn.disabled)
         {
            return;
         }
         drawRect({
            "target":btn,
            "lineStyle":null,
            "fillStyle":{
               "color":0,
               "alpha":0.3
            }
         });
      }
   }
}

