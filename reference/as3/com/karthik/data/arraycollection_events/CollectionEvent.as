package com.karthik.data.arraycollection_events
{
   import flash.events.Event;
   
   public class CollectionEvent extends Event
   {
      
      public static const COLLECTION_CHANGE:String = "collection_event";
      
      public static const TYPE_ADD:String = "type_add";
      
      public static const TYPE_REMOVE:String = "type_remove";
      
      public static const TYPE_OTHER:String = "other";
      
      public var index:int;
      
      public var item:Object;
      
      public var kind:String;
      
      public function CollectionEvent()
      {
         super(COLLECTION_CHANGE);
      }
   }
}

