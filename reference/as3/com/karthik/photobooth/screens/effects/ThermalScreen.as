package com.karthik.photobooth.screens.effects
{
   import com.karthik.photobooth.screens.BaseScreen;
   import flash.display.BitmapData;
   import mx.core.BitmapAsset;
   
   public class ThermalScreen extends BaseScreen
   {
      
      public static const TYPE:String = "thermal";
      
      private var Pallette:Class = ThermalScreen_Pallette;
      
      private var rgbPallete:Array;
      
      public function ThermalScreen()
      {
         super();
         var _loc1_:BitmapData = (new this.Pallette() as BitmapAsset).bitmapData;
         this.rgbPallete = this.palletize(_loc1_);
         screenName = "Thermal Camera";
      }
      
      private function palletize(param1:BitmapData) : Array
      {
         var _loc2_:Array = [];
         var _loc3_:Array = [];
         var _loc4_:Array = [];
         var _loc5_:int = 0;
         while(_loc5_ < param1.width)
         {
            _loc2_[_loc5_] = (param1.getPixel32(_loc5_,0) >> 16 & 0xFF) << 16;
            _loc3_[_loc5_] = (param1.getPixel32(_loc5_,0) >> 8 & 0xFF) << 8;
            _loc4_[_loc5_] = param1.getPixel32(_loc5_,0) & 0xFF;
            _loc5_++;
         }
         return [_loc2_,_loc3_,_loc4_];
      }
      
      override protected function bmpTransformations() : void
      {
         drawBmp = lastBmp.clone();
         drawBmp.paletteMap(lastBmp,lastBmp.rect,lastBmp.rect.topLeft,this.rgbPallete[0],this.rgbPallete[1],this.rgbPallete[2]);
      }
   }
}

