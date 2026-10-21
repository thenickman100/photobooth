package com.karthik.webapis.events
{
   public class WSConnectionEvent extends WSEvent
   {
      
      public static const TYPE_CONNECTION:String = "ws_connection_event";
      
      public function WSConnectionEvent()
      {
         super(TYPE_CONNECTION);
      }
   }
}

