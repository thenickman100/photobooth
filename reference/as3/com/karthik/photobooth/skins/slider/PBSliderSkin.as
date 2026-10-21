package com.karthik.photobooth.skins.slider
{
   import com.karthik.core.KSkin;
   import com.karthik.core.KSprite;
   
   public class PBSliderSkin extends KSkin
   {
      
      public function PBSliderSkin()
      {
         super();
      }
      
      override public function draw(param1:KSprite, param2:Object = null) : void
      {
         var _loc3_:KSprite = param2.track;
         var _loc4_:KSprite = param2.thumb;
         clear(param1,_loc3_,_loc4_);
         var _loc5_:Object = {
            "target":param1,
            "lineStyle":null,
            "fillStyle":{"type":"color"}
         };
         drawRoundRect(_loc5_,{
            "width":param1.width,
            "height":param1.height,
            "radius":8,
            "fillStyle":{
               "color":0,
               "alpha":0.6
            }
         });
         drawCircle(_loc5_,{
            "x":39,
            "y":param1.height / 2,
            "radius":4,
            "fillStyle":{
               "color":16777215,
               "alpha":1
            }
         });
         drawCircle(_loc5_,{
            "x":param1.width - 36,
            "y":param1.height / 2,
            "radius":7,
            "fillStyle":{
               "color":16777215,
               "alpha":1
            }
         });
         drawCircle({
            "target":_loc4_,
            "x":_loc4_.width / 2,
            "y":_loc4_.height / 2,
            "radius":Math.min(_loc4_.width,_loc4_.height) / 2,
            "lineStyle":{
               "thickness":1,
               "color":14342617,
               "alpha":1
            },
            "fillStyle":{
               "type":"gradient",
               "box":{
                  "width":_loc4_.width,
                  "height":_loc4_.height
               },
               "colors":[4737098,2960685]
            }
         });
         drawRoundRect({
            "target":_loc3_,
            "lineStyle":{"color":10065814},
            "fillStyle":{
               "color":5722448,
               "alpha":1
            },
            "width":_loc3_.width,
            "height":_loc3_.height,
            "radius":2
         });
      }
   }
}

