package com.karthik.photobooth.events
{
   import flash.events.Event;
   
   public class PhotoItemEvent extends Event
   {
      
      public static const TYPE_PHOTO_SELECT:String = "photoSelect";
      
      public static const TYPE_PHOTO_DELETE:String = "photoDelete";
      
      public var index:int;
      
      public function PhotoItemEvent(param1:String)
      {
         super(param1);
      }
   }
}

