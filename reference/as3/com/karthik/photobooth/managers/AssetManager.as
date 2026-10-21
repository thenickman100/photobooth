package com.karthik.photobooth.managers
{
   import flash.display.Loader;
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.net.URLRequest;
   
   public class AssetManager
   {
      
      public static var lucidaGrande:Class = AssetManager_lucidaGrande;
      
      private static var loaderQueue:Array = [];
      
      private static var isLoading:Boolean = false;
      
      public function AssetManager()
      {
         super();
      }
      
      private static function startLoading() : void
      {
         var completeListener:Function = null;
         var loaderError:Function = null;
         var qItem:LoaderQueueItem = null;
         if(loaderQueue.length == 0)
         {
            isLoading = false;
            return;
         }
         completeListener = function(param1:Event):void
         {
            qItem.loader.contentLoaderInfo.removeEventListener(Event.INIT,completeListener);
            qItem.loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR,loaderError);
            isLoading = false;
            startLoading();
         };
         loaderError = function(param1:IOErrorEvent):void
         {
            qItem.loader.contentLoaderInfo.removeEventListener(Event.INIT,completeListener);
            qItem.loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR,loaderError);
            trace("ERROR in LOAD");
            isLoading = false;
            startLoading();
         };
         isLoading = true;
         qItem = loaderQueue.shift();
         qItem.loader.contentLoaderInfo.addEventListener(Event.INIT,completeListener);
         qItem.loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,loaderError);
         qItem.loader.load(qItem.req);
      }
      
      public static function loadThis(param1:Loader, param2:URLRequest) : void
      {
         loaderQueue.push(new LoaderQueueItem(param1,param2));
         if(isLoading)
         {
            startLoading();
         }
      }
   }
}

import flash.display.Loader;
import flash.net.URLRequest;

class LoaderQueueItem
{
   
   public var loader:Loader;
   
   public var req:URLRequest;
   
   public function LoaderQueueItem(param1:Loader, param2:URLRequest)
   {
      super();
      this.loader = param1;
      this.req = param2;
   }
}
