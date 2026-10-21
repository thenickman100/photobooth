package com.karthik.webapis.events
{
   public class WSLoginEvent extends WSEvent
   {
      
      public static const TYPE_LOGIN:String = "ws_login_event";
      
      public function WSLoginEvent()
      {
         super(TYPE_LOGIN);
      }
   }
}

