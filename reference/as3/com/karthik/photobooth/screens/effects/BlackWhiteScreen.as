package com.karthik.photobooth.screens.effects
{
   import com.karthik.photobooth.screens.BaseScreen;
   import flash.filters.ColorMatrixFilter;
   
   public class BlackWhiteScreen extends BaseScreen
   {
      
      public static const TYPE:String = "black_white";
      
      public function BlackWhiteScreen()
      {
         super();
         screenName = "Black and White";
         var _loc1_:Number = 0.2225;
         var _loc2_:Number = 0.7169;
         var _loc3_:Number = 0.0606;
         var _loc4_:Array = [_loc1_,_loc2_,_loc3_,0,0,_loc1_,_loc2_,_loc3_,0,0,_loc1_,_loc2_,_loc3_,0,0,0,0,0,1,0];
         var _loc5_:ColorMatrixFilter = new ColorMatrixFilter(_loc4_);
         this.filters = [_loc5_];
      }
   }
}

