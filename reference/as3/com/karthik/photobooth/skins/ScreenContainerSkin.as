package com.karthik.photobooth.skins
{
   import com.karthik.core.KSkin;
   import com.karthik.core.KSprite;
   
   public class ScreenContainerSkin extends KSkin
   {
      
      public function ScreenContainerSkin()
      {
         super();
      }
      
      override public function draw(param1:KSprite, param2:Object = null) : void
      {
         clear(param1.graphics);
         drawRect({
            "target":param1,
            "width":param1.width,
            "height":param1.height,
            "lineStyle":null,
            "fillStyle":{
               "color":0,
               "alpha":1
            }
         });
      }
   }
}

