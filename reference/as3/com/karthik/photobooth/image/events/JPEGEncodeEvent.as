package com.karthik.photobooth.image.events
{
   import flash.events.Event;
   import flash.utils.ByteArray;
   
   public class JPEGEncodeEvent extends Event
   {
      
      public static const EVENT_PROGRESS:String = "encode_progress";
      
      public static const EVENT_COMPLETE:String = "encode_complete";
      
      public var completedEncode:ByteArray;
      
      public var progress:Number = 0;
      
      public function JPEGEncodeEvent(param1:String)
      {
         super(param1);
      }
   }
}

