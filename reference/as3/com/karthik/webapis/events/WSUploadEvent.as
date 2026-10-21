package com.karthik.webapis.events
{
   public class WSUploadEvent extends WSEvent
   {
      
      public static const TYPE_UPLOAD:String = "ws_upload_event";
      
      public function WSUploadEvent()
      {
         super(TYPE_UPLOAD);
      }
   }
}

