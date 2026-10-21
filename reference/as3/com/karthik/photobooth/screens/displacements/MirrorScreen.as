package com.karthik.photobooth.screens.displacements
{
   import com.karthik.photobooth.screens.BaseScreen;
   import flash.geom.ColorTransform;
   import flash.geom.Matrix;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   
   public class MirrorScreen extends BaseScreen
   {
      
      public static const TYPE:String = "mirror";
      
      private var ct:ColorTransform;
      
      public function MirrorScreen()
      {
         super();
         screenName = "Mirror";
         this.ct = new ColorTransform();
      }
      
      override protected function bmpTransformations() : void
      {
         drawBmp = lastBmp.clone();
         drawBmp.draw(lastBmp,new Matrix(-1,0,0,1,lastBmp.width));
         drawBmp.copyPixels(lastBmp,new Rectangle(0,0,lastBmp.width / 2,lastBmp.height),new Point(0,0));
      }
   }
}

