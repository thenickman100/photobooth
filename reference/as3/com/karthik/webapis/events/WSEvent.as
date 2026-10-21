package com.karthik.webapis.events
{
   import flash.events.Event;
   
   public class WSEvent extends Event
   {
      
      public var data:Object = {};
      
      public var success:Boolean = true;
      
      public function WSEvent(param1:String)
      {
         super(param1);
      }
   }
}

