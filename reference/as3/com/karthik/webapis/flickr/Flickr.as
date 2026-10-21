package com.karthik.webapis.flickr
{
   import com.karthik.lang.HashUtil;
   import com.karthik.webapis.PhotoWebService;
   import com.karthik.webapis.api_util.MD5;
   import com.karthik.webapis.events.WSConnectionEvent;
   import com.karthik.webapis.events.WSLoginEvent;
   import com.karthik.webapis.events.WSUploadEvent;
   import flash.events.Event;
   import flash.events.HTTPStatusEvent;
   import flash.events.IOErrorEvent;
   import flash.events.SecurityErrorEvent;
   import flash.net.URLLoader;
   import flash.net.URLLoaderDataFormat;
   import flash.net.URLRequest;
   import flash.utils.ByteArray;
   
   public class Flickr extends PhotoWebService
   {
      
      public static const PERMISSION_WRITE:String = "write";
      
      public static const AUTH_GET_FROB:String = "flickr.auth.getFrob";
      
      public static const AUTH_GET_TOKEN:String = "flickr.auth.getToken";
      
      private var util:FlickrUtil;
      
      public var user:FlickrUser;
      
      public var permission:String = "write";
      
      public var uploadEndPoint:String = "http://api.flickr.com/services/upload/";
      
      private var req:URLRequest;
      
      public var frob:String = "";
      
      private var urlLoader:URLLoader;
      
      public var apiKey:String = "";
      
      public var secret:String = "";
      
      public var endPoint:String = "http://api.flickr.com/services/rest/?";
      
      public var token:String = "";
      
      public var authEndPoint:String = "http://api.flickr.com/services/auth/?";
      
      public function Flickr(param1:Object)
      {
         super();
         HashUtil.transferProperties(param1,this);
         this.util = new FlickrUtil(this);
         this.user = new FlickrUser();
      }
      
      public function auth_getToken() : void
      {
         this.refreshLoader();
         var _loc1_:URLRequest = this.util.makeGetReq({"method":AUTH_GET_TOKEN});
         this.urlLoader.addEventListener(Event.COMPLETE,this.auth_getToken_listener);
         this.urlLoader.load(_loc1_);
      }
      
      public function auth_getFrob() : void
      {
         this.refreshLoader();
         var _loc1_:URLRequest = this.util.makeGetReq({"method":AUTH_GET_FROB});
         this.urlLoader.addEventListener(Event.COMPLETE,this.auth_getFrob_listener);
         this.urlLoader.load(_loc1_);
      }
      
      protected function uploadPhoto_listener(param1:Event) : void
      {
         var _loc2_:XML = this.util.parseRequest(param1.currentTarget as URLLoader);
         var _loc3_:WSUploadEvent = new WSUploadEvent();
         if(!_loc2_)
         {
            _loc3_.success = false;
         }
         dispatchEvent(_loc3_);
      }
      
      public function auth_loginURL() : String
      {
         var _loc1_:String = this.secret;
         _loc1_ += "api_key" + this.apiKey;
         _loc1_ += "frob" + this.frob;
         _loc1_ += "perms" + this.permission;
         var _loc2_:String = this.authEndPoint;
         _loc2_ += "api_key=" + this.apiKey;
         _loc2_ += "&frob=" + this.frob;
         _loc2_ += "&perms=" + this.permission;
         return _loc2_ + ("&api_sig=" + MD5.hash(_loc1_));
      }
      
      private function refreshLoader() : void
      {
         this.urlLoader = new URLLoader();
         this.urlLoader.dataFormat = URLLoaderDataFormat.TEXT;
      }
      
      private function ioError(param1:IOErrorEvent) : void
      {
         trace("IOERROR");
      }
      
      protected function auth_getFrob_listener(param1:Event) : void
      {
         var _loc2_:XML = this.util.parseRequest(param1.currentTarget as URLLoader);
         var _loc3_:WSConnectionEvent = new WSConnectionEvent();
         if(_loc2_)
         {
            this.frob = _loc2_.frob;
         }
         else
         {
            _loc3_.success = false;
         }
         dispatchEvent(_loc3_);
      }
      
      protected function auth_getToken_listener(param1:Event) : void
      {
         var _loc2_:XML = this.util.parseRequest(param1.currentTarget as URLLoader);
         var _loc3_:WSLoginEvent = new WSLoginEvent();
         if(_loc2_)
         {
            this.token = _loc2_.auth.token.toString();
            this.permission = _loc2_.auth.perms.toString();
            this.user.nsid = _loc2_.auth.user.@nsid.toString();
            this.user.username = _loc2_.auth.user.@username.toString();
            this.user.fullname = _loc2_.auth.user.@fullname.toString();
         }
         else
         {
            _loc3_.success = false;
         }
         dispatchEvent(_loc3_);
      }
      
      private function httpStatus(param1:HTTPStatusEvent) : void
      {
         trace("HTTPSTATUS: " + param1.status);
      }
      
      public function hasFrob() : Boolean
      {
         return this.frob != "";
      }
      
      private function securityError(param1:SecurityErrorEvent) : void
      {
         trace("SECURITYERROR");
      }
      
      public function uploadPhoto(param1:String, param2:ByteArray) : void
      {
         var _loc3_:URLRequest = this.util.makePostData({"data":param2});
         this.refreshLoader();
         this.urlLoader.addEventListener(Event.COMPLETE,this.uploadPhoto_listener);
         this.urlLoader.addEventListener(IOErrorEvent.IO_ERROR,this.ioError);
         this.urlLoader.addEventListener(HTTPStatusEvent.HTTP_STATUS,this.httpStatus);
         this.urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,this.securityError);
         this.urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
         this.urlLoader.load(_loc3_);
      }
      
      public function hasToken() : Boolean
      {
         return this.token != "";
      }
   }
}

