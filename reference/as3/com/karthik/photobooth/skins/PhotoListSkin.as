package com.karthik.photobooth.skins
{
   import com.karthik.core.KSkin;
   import com.karthik.core.KSprite;
   
   public class PhotoListSkin extends KSkin
   {
      
      public function PhotoListSkin()
      {
         super();
      }
      
      override public function draw(param1:KSprite, param2:Object = null) : void
      {
         clear(param1);
         drawRect({
            "target":param1,
            "lineStyle":null,
            "fillStyle":{
               "type":"gradient",
               "colors":[5855577,8816006,10395294],
               "alphas":[1,1,1],
               "ratios":[0,127,255]
            }
         });
      }
   }
}

