package com.karthik.photobooth.skins.growl
{
   import com.karthik.core.KSkin;
   import com.karthik.core.KSprite;
   
   public class GrowlBoxSkin extends KSkin
   {
      
      public function GrowlBoxSkin()
      {
         super();
      }
      
      override public function draw(param1:KSprite, param2:Object = null) : void
      {
         clear(param1);
         drawKRoundRect({
            "target":param1,
            "lineStyle":{
               "thickness":4,
               "color":0,
               "alpha":0.4
            },
            "fillStyle":{
               "type":"gradient",
               "colors":[15332089,11785200]
            },
            "radius":5
         });
      }
   }
}

