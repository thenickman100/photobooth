package com.karthik.photobooth.screens.effects
{
   import com.karthik.photobooth.screens.BaseScreen;
   import flash.filters.ColorMatrixFilter;
   
   public class XrayScreen extends BaseScreen
   {
      
      public static const TYPE:String = "xray";
      
      public function XrayScreen()
      {
         super();
         screenName = "X-Ray";
      }
      
      override protected function createChildren() : void
      {
         super.createChildren();
         var _loc1_:ColorMatrixFilter = new ColorMatrixFilter([-1,0,0,0,255,0,-1,0,0,255,0,0,-1,0,255,0,0,0,1,0]);
         canvas.filters = [_loc1_];
      }
   }
}

