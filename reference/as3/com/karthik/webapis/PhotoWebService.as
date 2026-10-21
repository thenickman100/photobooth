package com.karthik.webapis
{
   import flash.events.EventDispatcher;
   import flash.net.URLRequest;
   import flash.net.navigateToURL;
   
   public class PhotoWebService extends EventDispatcher
   {
      
      public function PhotoWebService()
      {
         super();
      }
      
      public function openAuthWindow(param1:String) : void
      {
         navigateToURL(new URLRequest(param1),"_blank");
      }
   }
}

