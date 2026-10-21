package com.karthik.core
{
   import flash.display.Sprite;
   import flash.display.StageAlign;
   import flash.display.StageScaleMode;
   import flash.events.Event;
   import flash.events.EventDispatcher;
   
   public class KComponentGlobals extends EventDispatcher
   {
      
      private static var APP:Sprite;
      
      private static var instance:KComponentGlobals;
      
      private var added:Boolean = false;
      
      private var invalidateQueue:Array = [];
      
      private var noneCount:int = 0;
      
      public function KComponentGlobals()
      {
         super();
      }
      
      public static function initialize(param1:Sprite) : void
      {
         APP = param1;
         param1.stage.align = StageAlign.TOP_LEFT;
         param1.stage.scaleMode = StageScaleMode.NO_SCALE;
      }
      
      public static function getInstance() : KComponentGlobals
      {
         if(!instance)
         {
            instance = new KComponentGlobals();
         }
         return instance;
      }
      
      private function eventEnterFrame(param1:Event) : void
      {
         var _loc2_:KComponent = null;
         if(this.invalidateQueue.length == 0)
         {
            ++this.noneCount;
            if(this.noneCount >= 1)
            {
               this.noneCount = 0;
               APP.removeEventListener(Event.ENTER_FRAME,this.eventEnterFrame);
               this.added = false;
            }
            return;
         }
         while(this.invalidateQueue.length > 0)
         {
            _loc2_ = this.invalidateQueue.shift();
            _loc2_.validateNow();
         }
      }
      
      public function invalidateThis(param1:KComponent) : void
      {
         if(this.invalidateQueue.indexOf(param1) != -1)
         {
            return;
         }
         this.invalidateQueue.push(param1);
         if(!this.added)
         {
            APP.addEventListener(Event.ENTER_FRAME,this.eventEnterFrame);
            this.added = true;
         }
      }
   }
}

