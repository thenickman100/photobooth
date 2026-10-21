package com.karthik.photobooth.control_bar
{
   import com.karthik.managers.Singletons;
   import com.karthik.skins.KButtonSkin;
   
   public class DumbDotButton extends SelectableButton
   {
      
      protected var bSkin:KButtonSkin;
      
      public function DumbDotButton()
      {
         super({
            "width":16,
            "height":17
         });
         this.bSkin = Singletons.getInstance(DumbDotButtonSkin);
      }
      
      override protected function update() : void
      {
         if(stateChanged || wasResized)
         {
            stateChanged = false;
            this.bSkin.draw(this);
         }
      }
   }
}

import com.karthik.skins.KButtonSkin;

class DumbDotButtonSkin extends KButtonSkin
{
   
   public function DumbDotButtonSkin()
   {
      super();
   }
   
   override protected function drawOver() : void
   {
      this.drawNormal();
   }
   
   override protected function drawNormal() : void
   {
      this.drawBtn(6974058,13224393);
   }
   
   override protected function drawDown() : void
   {
      this.drawBtn(2302755,13224393);
   }
   
   private function drawBtn(param1:uint, param2:uint) : void
   {
      drawKRoundRect({
         "target":btn,
         "width":16,
         "height":16,
         "radius":2,
         "lineStyle":{
            "thickness":0,
            "alpha":0
         },
         "fillStyle":{
            "color":param1,
            "alpha":1
         }
      });
      drawPath({
         "target":btn,
         "fillStyle":null,
         "lineStyle":{
            "thickness":1,
            "color":param2,
            "alpha":1
         },
         "pts":[[0,16],[14,16]]
      });
   }
}
