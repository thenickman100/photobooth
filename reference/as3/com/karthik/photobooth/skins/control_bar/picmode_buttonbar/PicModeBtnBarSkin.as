package com.karthik.photobooth.skins.control_bar.picmode_buttonbar
{
   import com.karthik.core.KSkin;
   import com.karthik.core.KSprite;
   import flash.display.*;
   
   public class PicModeBtnBarSkin extends KSkin
   {
      
      public function PicModeBtnBarSkin()
      {
         super();
      }
      
      override public function draw(param1:KSprite, param2:Object = null) : void
      {
         var _loc3_:KSprite = param2.maskL;
         var _loc4_:KSprite = param2.maskR;
         clear(_loc3_);
         clear(param1);
         clear(_loc4_);
         drawKRoundRect({
            "lineStyle":{"alpha":0},
            "target":_loc3_,
            "fillStyle":{
               "color":5460819,
               "alpha":1
            },
            "height":param1.height - 3,
            "width":param1.width - 2,
            "radius":3,
            "x":1,
            "y":1
         });
         drawKRoundRect({
            "lineStyle":{"alpha":0},
            "target":_loc4_,
            "fillStyle":{
               "color":5460819,
               "alpha":1
            },
            "height":param1.height - 3,
            "width":param1.width - 2,
            "radius":3,
            "x":1,
            "y":1
         });
         drawKRoundRect({
            "lineStyle":{"alpha":0},
            "target":param1,
            "fillStyle":{
               "color":5460819,
               "alpha":1
            },
            "height":param1.height - 1,
            "radius":3
         });
         drawPath({
            "target":param1,
            "lineStyle":{
               "color":13158600,
               "thickness":1,
               "alpha":1
            },
            "pts":[[3,param1.height - 1],[param1.width - 2,param1.height - 1]]
         });
      }
   }
}

