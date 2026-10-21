package com.karthik.photobooth.screens.effects
{
   import com.karthik.photobooth.screens.BaseScreen;
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.geom.Matrix;
   import flash.geom.Point;
   
   public class PopArtScreen extends BaseScreen
   {
      
      public static const TYPE:String = "popart";
      
      private var Pallette:Class = PopArtScreen_Pallette;
      
      private var pallets:Array;
      
      private var _cacheMatr:Matrix = new Matrix(0.5,0,0,0.5);
      
      public function PopArtScreen()
      {
         var _loc1_:BitmapData = (new this.Pallette() as Bitmap).bitmapData;
         this.makePallets(_loc1_);
         super();
         screenName = "Pop Art";
      }
      
      private function makePallets(param1:BitmapData) : void
      {
         this.pallets = new Array();
         this.pallets.push(this.palletize(param1,0));
         this.pallets.push(this.palletize(param1,1));
         this.pallets.push(this.palletize(param1,2));
         this.pallets.push(this.palletize(param1,3));
      }
      
      override protected function bmpTransformations() : void
      {
         drawBmp = lastBmp.clone();
         var _loc1_:BitmapData = new BitmapData(drawBmp.width / 2,drawBmp.height / 2);
         _loc1_.draw(drawBmp,this._cacheMatr);
         drawBmp.paletteMap(_loc1_,_loc1_.rect,_loc1_.rect.topLeft,this.pallets[0][0],this.pallets[0][1],this.pallets[0][2]);
         drawBmp.paletteMap(_loc1_,_loc1_.rect,new Point(_loc1_.rect.width,0),this.pallets[1][0],this.pallets[1][1],this.pallets[1][2]);
         drawBmp.paletteMap(_loc1_,_loc1_.rect,new Point(0,_loc1_.rect.height),this.pallets[2][0],this.pallets[2][1],this.pallets[2][2]);
         drawBmp.paletteMap(_loc1_,_loc1_.rect,new Point(_loc1_.rect.width,_loc1_.rect.height),this.pallets[3][0],this.pallets[3][1],this.pallets[3][2]);
      }
      
      private function palletize(param1:BitmapData, param2:int) : Array
      {
         var _loc3_:Array = [];
         var _loc4_:Array = [];
         var _loc5_:Array = [];
         var _loc6_:int = 0;
         while(_loc6_ < param1.width)
         {
            _loc3_[_loc6_] = (param1.getPixel32(_loc6_,param2) >> 16 & 0xFF) << 16;
            _loc4_[_loc6_] = (param1.getPixel32(_loc6_,param2) >> 8 & 0xFF) << 8;
            _loc5_[_loc6_] = param1.getPixel32(_loc6_,param2) & 0xFF;
            _loc6_++;
         }
         return [_loc3_,_loc4_,_loc5_];
      }
   }
}

