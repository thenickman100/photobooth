package com.karthik.photobooth.screens.bg_removed
{
   import com.karthik.managers.TimerManager;
   import flash.display.BitmapData;
   import flash.display.BlendMode;
   import flash.events.Event;
   import flash.events.EventDispatcher;
   import flash.geom.Matrix;
   import flash.media.Video;
   
   public class BackgroundRemover extends EventDispatcher
   {
      
      private var threshHoldMap:BitmapData;
      
      private var thisBmp:BitmapData;
      
      public var debugMap:BitmapData;
      
      private var lastBmp:BitmapData;
      
      public var detectedBackground:BitmapData;
      
      private var matr:Matrix;
      
      private var debug:Boolean = true;
      
      private var video:Video;
      
      public function BackgroundRemover(param1:Video)
      {
         super();
         this.video = param1;
      }
      
      public function stopDetection() : void
      {
         TimerManager.getInstance().removeCallBack(this.startDetection);
      }
      
      public function startDetection() : void
      {
         var _loc4_:int = 0;
         var _loc5_:uint = 0;
         var _loc6_:uint = 0;
         if(this.lastBmp == null)
         {
            if(this.video.width > 400)
            {
               this.matr = new Matrix(0.5,0,0,0.5);
            }
            else
            {
               this.matr = new Matrix(1,0,0,1);
            }
            this.lastBmp = new BitmapData(this.video.width * this.matr.a,this.video.height * this.matr.a);
            this.thisBmp = new BitmapData(this.video.width * this.matr.a,this.video.height * this.matr.a);
            this.lastBmp.draw(this.video,this.matr);
            TimerManager.getInstance().addCallBack(this.startDetection,0.5,true,this);
            return;
         }
         this.thisBmp.draw(this.video,this.matr);
         var _loc1_:BitmapData = this.thisBmp.clone();
         this.thisBmp.draw(this.lastBmp,new Matrix(),null,BlendMode.DIFFERENCE);
         this.thisBmp.threshold(this.thisBmp,this.thisBmp.rect,this.thisBmp.rect.topLeft,">",4279308561,4294901760,16777215,false);
         if(this.debug)
         {
            this.debugMap = this.thisBmp;
         }
         var _loc2_:uint = 0;
         var _loc3_:int = 0;
         while(_loc3_ < this.thisBmp.width)
         {
            _loc4_ = 0;
            while(_loc4_ < this.thisBmp.height)
            {
               _loc5_ = this.thisBmp.getPixel(_loc3_,_loc4_);
               _loc6_ = uint(_loc5_ >> 16);
               _loc2_ += _loc6_;
               _loc4_++;
            }
            _loc3_++;
         }
         if(_loc2_ > 0 && _loc2_ < 2200000 * this.matr.a * this.matr.a)
         {
            this.detectedBackground = new BitmapData(this.video.width,this.video.height);
            this.detectedBackground.draw(this.video);
            dispatchEvent(new Event("backgroundDetected"));
         }
         else
         {
            this.lastBmp = _loc1_;
            TimerManager.getInstance().addCallBack(this.startDetection,0.5,true,this);
         }
      }
      
      public function resetDetector() : void
      {
         this.lastBmp = null;
         this.thisBmp = null;
      }
   }
}

