package com.karthik.photobooth.screens.effects
{
   import com.karthik.photobooth.screens.BaseScreen;
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.BlendMode;
   import flash.display.Sprite;
   import flash.filters.ColorMatrixFilter;
   
   public class SketchScreen extends BaseScreen
   {
      
      public static const TYPE:String = "sketch";
      
      private var sketchOverlay:Sprite;
      
      private var sketchBmp:BitmapData;
      
      private var Sketch:Class = SketchScreen_Sketch;
      
      public function SketchScreen()
      {
         super();
         screenName = "Sketch";
         this.sketchBmp = (new this.Sketch() as Bitmap).bitmapData;
      }
      
      override protected function update() : void
      {
         super.update();
         if(wasResized)
         {
            this.sketchOverlay.graphics.clear();
            this.sketchOverlay.graphics.beginBitmapFill(this.sketchBmp,matr);
            this.sketchOverlay.graphics.drawRect(0,0,width,height);
         }
      }
      
      override protected function createChildren() : void
      {
         this.sketchOverlay = new Sprite();
         var _loc1_:ColorMatrixFilter = new ColorMatrixFilter([1.03204,0.85316,0.1148,0,-3.5,0.43204,1.45316,0.1148,0,-3.5,0.43204,0.85316,0.7148,0,-3.5,0,0,0,1,0]);
         this.filters = [_loc1_];
         addChild(this.sketchOverlay);
         super.createChildren();
         canvas.blendMode = BlendMode.HARDLIGHT;
      }
   }
}

