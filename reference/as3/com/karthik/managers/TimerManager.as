package com.karthik.managers
{
   import flash.events.TimerEvent;
   import flash.utils.Timer;
   
   public class TimerManager
   {
      
      private static var _timerManager:TimerManager = null;
      
      public static var defaultDelay:Number = 50;
      
      private var queue:Array;
      
      private var timer:Timer;
      
      public function TimerManager(param1:Cls)
      {
         super();
         this.timer = new Timer(defaultDelay);
         this.queue = new Array();
         this.timer.addEventListener(TimerEvent.TIMER,this.timerEventListener);
         this.timer.start();
      }
      
      public static function getInstance() : TimerManager
      {
         if(_timerManager == null)
         {
            _timerManager = new TimerManager(new Cls());
         }
         return _timerManager;
      }
      
      private function timerEventListener(param1:TimerEvent) : void
      {
         var _loc4_:TimerQueueItem = null;
         var _loc5_:Number = NaN;
         var _loc6_:Function = null;
         var _loc7_:Object = null;
         var _loc8_:Array = null;
         var _loc2_:Boolean = false;
         var _loc3_:int = int(this.queue.length - 1);
         while(_loc3_ >= 0)
         {
            _loc4_ = this.queue[_loc3_] as TimerQueueItem;
            if(_loc4_.enabled)
            {
               _loc2_ = true;
               _loc5_ = 1 / _loc4_.frequency * 1000;
               _loc4_.currentCount += defaultDelay;
               if(_loc4_.currentCount >= _loc5_)
               {
                  _loc4_.currentCount = 0;
                  _loc6_ = _loc4_.dic["callback"] as Function;
                  _loc7_ = _loc4_.dic["this"];
                  _loc8_ = _loc4_.args;
                  if(_loc6_ != null)
                  {
                     _loc6_.apply(_loc7_,_loc8_);
                  }
                  else
                  {
                     this.queue.splice(_loc3_,1);
                  }
                  if(_loc4_.callOnce)
                  {
                     this.queue.splice(_loc3_,1);
                  }
               }
            }
            _loc3_--;
         }
         if(!_loc2_)
         {
            this.timer.stop();
         }
      }
      
      public function resumeCallBack(param1:Function) : void
      {
         var _loc2_:TimerQueueItem = this.getItemForFunc(param1);
         _loc2_.enabled = true;
         if(!this.timer.running)
         {
            this.timer.start();
         }
      }
      
      public function addCallBack(param1:Function, param2:Number, param3:Boolean = false, param4:Object = null, param5:Array = null, param6:Boolean = true) : void
      {
         var _loc7_:TimerQueueItem = new TimerQueueItem();
         _loc7_.dic["callback"] = param1;
         _loc7_.frequency = param2;
         _loc7_.callOnce = param3;
         _loc7_.enabled = param6;
         _loc7_.dic["this"] = param4;
         _loc7_.args = param5;
         this.queue.push(_loc7_);
         if(!this.timer.running)
         {
            this.timer.start();
         }
      }
      
      public function removeCallBack(param1:Function) : void
      {
         var _loc3_:TimerQueueItem = null;
         var _loc2_:int = int(this.queue.length - 1);
         while(_loc2_ >= 0)
         {
            _loc3_ = this.queue[_loc2_] as TimerQueueItem;
            if(_loc3_.dic["callback"] == param1)
            {
               this.queue.splice(_loc2_,1);
            }
            _loc2_--;
         }
      }
      
      public function pauseCallBack(param1:Function) : void
      {
         var _loc2_:TimerQueueItem = this.getItemForFunc(param1);
         _loc2_.enabled = false;
      }
      
      private function getItemForFunc(param1:Function) : TimerQueueItem
      {
         var _loc3_:TimerQueueItem = null;
         var _loc2_:int = int(this.queue.length - 1);
         while(_loc2_ >= 0)
         {
            _loc3_ = this.queue[_loc2_] as TimerQueueItem;
            if(_loc3_.dic["callback"] == param1)
            {
               return _loc3_;
            }
            _loc2_--;
         }
         return null;
      }
      
      public function hasCallBack(param1:Function) : Boolean
      {
         var _loc3_:TimerQueueItem = null;
         var _loc2_:int = int(this.queue.length - 1);
         while(_loc2_ >= 0)
         {
            _loc3_ = this.queue[_loc2_] as TimerQueueItem;
            if(_loc3_.dic["callback"] == param1)
            {
               return true;
            }
            _loc2_--;
         }
         return false;
      }
   }
}

import flash.utils.Dictionary;

class Cls
{
   
   public function Cls()
   {
      super();
   }
}

class TimerQueueItem
{
   
   public var enabled:Boolean = true;
   
   public var dic:Dictionary = new Dictionary(true);
   
   public var currentCount:Number = 0;
   
   public var frequency:Number;
   
   public var args:Array = null;
   
   public var callOnce:Boolean = false;
   
   public function TimerQueueItem()
   {
      super();
   }
}
