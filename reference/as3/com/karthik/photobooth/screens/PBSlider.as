package com.karthik.photobooth.screens
{
   import com.karthik.components.Slider;
   import com.karthik.managers.Singletons;
   import com.karthik.photobooth.skins.slider.PBSliderSkin;
   import flash.events.MouseEvent;
   
   public class PBSlider extends Slider
   {
      
      public function PBSlider()
      {
         super({
            "skin":Singletons.getInstance(PBSliderSkin),
            "thumbWidth":14,
            "thumbHeight":14,
            "trackHeight":5,
            "padLeft":53,
            "padRight":53,
            "width":240,
            "height":49,
            "min":0,
            "max":1,
            "value":0.5
         });
         addEventListener(MouseEvent.MOUSE_DOWN,this.listener);
      }
      
      private function listener(param1:MouseEvent) : void
      {
         param1.stopPropagation();
      }
   }
}

