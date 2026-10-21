package com.karthik.photobooth.skins.control_bar
{
   import com.karthik.core.KSkin;
   import com.karthik.core.KSprite;
   import com.karthik.photobooth.control_bar.ControlBar;
   
   public class ControlBarSkin extends KSkin
   {
      
      public function ControlBarSkin()
      {
         super();
      }
      
      private function drawGreyBackground(param1:KSprite) : void
      {
         drawRect({
            "target":param1,
            "width":param1.width,
            "height":param1.height - 1,
            "y":1,
            "lineStyle":null,
            "fillStyle":{
               "type":"gradient",
               "colors":[12763842,9934743],
               "box":{
                  "x":0,
                  "y":1,
                  "width":param1.width,
                  "height":param1.height - 1
               }
            }
         });
         drawPath({
            "target":param1,
            "fillStyle":null,
            "lineStyle":{
               "color":14408667,
               "hint":false
            },
            "pts":[[0,0],[param1.width,0]]
         });
      }
      
      private function drawRedBackground(param1:KSprite) : void
      {
         drawRect({
            "target":param1,
            "width":param1.width,
            "height":param1.height - 1,
            "y":1,
            "lineStyle":null,
            "fillStyle":{
               "type":"gradient",
               "colors":[16729930,15990784],
               "box":{
                  "x":0,
                  "y":1,
                  "width":param1.width,
                  "height":param1.height - 1
               }
            }
         });
         drawPath({
            "target":param1,
            "fillStyle":null,
            "lineStyle":{
               "color":14408667,
               "hint":false
            },
            "pts":[[0,0],[param1.width,0]]
         });
      }
      
      override public function draw(param1:KSprite, param2:Object = null) : void
      {
         var _loc3_:ControlBar = param1 as ControlBar;
         clear(param1);
         if(_loc3_.mode == ControlBar.MODE_TAKING_PIC)
         {
            this.drawRedBackground(param1);
         }
         else
         {
            this.drawGreyBackground(param1);
         }
      }
   }
}

