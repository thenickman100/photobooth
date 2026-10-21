package com.karthik.photobooth.skins
{
   import com.karthik.core.KSkin;
   import com.karthik.core.KSprite;
   
   public class SimpleWindowSkin extends KSkin
   {
      
      public function SimpleWindowSkin()
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
               "alpha":0.5
            },
            "fillStyle":{
               "color":4210752,
               "alpha":1
            },
            "radius":8
         });
         drawKRoundRect({
            "target":param1,
            "x":1,
            "y":1,
            "width":param1.width - 1,
            "height":21,
            "lineStyle":{"alpha":0},
            "fillStyle":{
               "color":15197412,
               "alpha":1
            },
            "radius":8,
            "faceDown":true
         });
         drawKRoundRect({
            "target":param1,
            "x":1,
            "y":2,
            "width":param1.width - 1,
            "height":20,
            "lineStyle":{
               "thickness":0,
               "alpha":0
            },
            "fillStyle":{
               "type":"gradient",
               "colors":[12895428,9934743],
               "box":{
                  "width":param1.width - 2,
                  "height":20,
                  "x":1,
                  "y":2
               }
            },
            "radius":8,
            "faceDown":true
         });
      }
   }
}

