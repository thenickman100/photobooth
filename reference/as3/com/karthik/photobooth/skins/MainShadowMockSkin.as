package com.karthik.photobooth.skins
{
   import com.karthik.core.KSkin;
   import com.karthik.core.KSprite;
   
   public class MainShadowMockSkin extends KSkin
   {
      
      public function MainShadowMockSkin()
      {
         super();
      }
      
      override public function draw(param1:KSprite, param2:Object = null) : void
      {
         drawKRoundRect({
            "target":param1,
            "width":param1.width,
            "height":param1.height,
            "lineStyle":{
               "thickness":1,
               "color":8947848,
               "alpha":0
            },
            "fillStyle":{
               "color":4210752,
               "alpha":0.5
            },
            "radius":8
         });
      }
   }
}

