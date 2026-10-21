package com.karthik.photobooth.skins.control_bar.shutter_button
{
   import com.karthik.lang.HashUtil;
   import com.karthik.photobooth.control_bar.ShutterButton;
   import com.karthik.skins.KButtonSkin;
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.filters.DropShadowFilter;
   
   public class ShutterButtonSkinNormal extends KButtonSkin
   {
      
      private var normBmpI:BitmapData = (new this.NormI() as Bitmap).bitmapData;
      
      private var normBmp:BitmapData = (new this.Norm() as Bitmap).bitmapData;
      
      private var NormI:Class = ShutterButtonSkinNormal_NormI;
      
      private var Norm:Class = ShutterButtonSkinNormal_Norm;
      
      public function ShutterButtonSkinNormal()
      {
         super();
      }
      
      override protected function opSet() : void
      {
         opt = HashUtil.mergeHash(opt,{
            "lineStyle":null,
            "fillStyle":{"type":"bmp"}
         });
      }
      
      override protected function drawDown() : void
      {
         this.drawNormal();
         btn.filters = [new DropShadowFilter(0,0,0,0.8,10,10,1,2,true)];
      }
      
      override protected function drawNormal() : void
      {
         var _loc1_:ShutterButton = btn as ShutterButton;
         var _loc2_:BitmapData = _loc1_.inactive ? this.normBmpI : this.normBmp;
         drawRect(opt,{"fillStyle":{"bmp":_loc2_}});
         btn.filters = [];
      }
      
      override protected function drawOver() : void
      {
         this.drawNormal();
      }
   }
}

