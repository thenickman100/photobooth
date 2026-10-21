package com.karthik.photobooth.events
{
   import flash.events.Event;
   
   public class ModeChangeEvent extends Event
   {
      
      public static const MODE_CHANGE:String = "modeChange";
      
      public var targetMode:int;
      
      public function ModeChangeEvent()
      {
         super(MODE_CHANGE,true);
      }
   }
}

