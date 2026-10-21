package com.karthik.webapis.facebook
{
   import com.karthik.lang.HashUtil;
   import com.karthik.webapis.PhotoWebService;
   import com.karthik.webapis.events.WSConnectionEvent;
   import com.karthik.webapis.events.WSLoginEvent;
   import com.karthik.webapis.events.WSUploadEvent;
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.net.URLLoader;
   import flash.net.URLLoaderDataFormat;
   import flash.net.URLRequest;
   import flash.utils.ByteArray;
   
   public class Facebook extends PhotoWebService
   {
      
      public namespace facebook = "http://api.facebook.com/1.0/";
      
      public static const AUTH_CREATETOKEN:String = "facebook.auth.createToken";
      
      public static const AUTH_GETSESSION:String = "facebook.auth.getSession";
      
      default xml namespace = "http://api.facebook.com/1.0/";
      
      public var util:FBUtil;
      
      protected var _sessionKey:String;
      
      public var lastCallId:uint = 0;
      
      public var _hasAuthToken:Boolean = false;
      
      public var version:String = "1.0";
      
      private var urlLoader:URLLoader;
      
      public var apiKey:String = "";
      
      private var req:URLRequest;
      
      protected var _authToken:String;
      
      public var endPoint:String = "http://api.facebook.com/restserver.php?";
      
      public var secret:String;
      
      public var _hasSession:Boolean = false;
      
      public var authEndPoint:String = "http://www.facebook.com/login.php?api_key={API_KEY}&v={VERSION}&auth_token={AUTH_TOKEN}";
      
      public function Facebook(param1:Object)
      {
         default xml namespace = "http://api.facebook.com/1.0/";
         super();
         HashUtil.transferProperties(param1,this);
         this.util = new FBUtil(this);
      }
      
      public function auth_createToken() : void
      {
         var authCompleteListener:Function;
         var req:URLRequest;
         default xml namespace = "http://api.facebook.com/1.0/";
         this.refreshLoader();
         req = this.util.makeGetReq({"method":AUTH_CREATETOKEN});
         authCompleteListener = function(param1:Event):void
         {
            default xml namespace = "http://api.facebook.com/1.0/";
            var _loc2_:XML = util.parseRequest(param1.currentTarget as URLLoader);
            var _loc3_:WSConnectionEvent = new WSConnectionEvent();
            if(_loc2_)
            {
               authToken = _loc2_.toString();
               trace("auth token is: " + authToken);
            }
            else
            {
               _loc3_.success = false;
            }
            dispatchEvent(_loc3_);
         };
         this.urlLoader.addEventListener(Event.COMPLETE,authCompleteListener);
         this.urlLoader.load(req);
      }
      
      private function ioError(param1:IOErrorEvent) : void
      {
         default xml namespace = "http://api.facebook.com/1.0/";
      }
      
      public function auth_loginURL() : String
      {
         default xml namespace = "http://api.facebook.com/1.0/";
         return this.authEndPoint.replace("{API_KEY}",this.apiKey).replace("{VERSION}",this.version).replace("{AUTH_TOKEN}",this._authToken);
      }
      
      private function refreshLoader() : void
      {
         default xml namespace = "http://api.facebook.com/1.0/";
         this.urlLoader = new URLLoader();
         this.urlLoader.dataFormat = URLLoaderDataFormat.TEXT;
      }
      
      public function set sessionKey(param1:String) : void
      {
         default xml namespace = "http://api.facebook.com/1.0/";
         if(param1 == this.sessionKey)
         {
            return;
         }
         this._sessionKey = param1;
         this._hasSession = true;
      }
      
      public function auth_getSession() : void
      {
         var getSessionCompleteListener:Function;
         var req:URLRequest;
         default xml namespace = "http://api.facebook.com/1.0/";
         this.refreshLoader();
         req = this.util.makeGetReq({"method":AUTH_GETSESSION});
         getSessionCompleteListener = function(param1:Event):void
         {
            default xml namespace = "http://api.facebook.com/1.0/";
            var _loc2_:XML = util.parseRequest(param1.currentTarget as URLLoader);
            var _loc3_:WSLoginEvent = new WSLoginEvent();
            if(_loc2_)
            {
               sessionKey = _loc2_.session_key.toString();
               secret = _loc2_.secret;
               trace("got session key: " + sessionKey + " got new secret: " + secret);
            }
            else
            {
               _loc3_.success = false;
            }
            dispatchEvent(_loc3_);
         };
         this.urlLoader.addEventListener(Event.COMPLETE,getSessionCompleteListener);
         this.urlLoader.load(req);
      }
      
      public function invalidateSession() : void
      {
         default xml namespace = "http://api.facebook.com/1.0/";
         this._hasSession = false;
      }
      
      public function get hasSession() : Boolean
      {
         default xml namespace = "http://api.facebook.com/1.0/";
         return this._hasSession;
      }
      
      public function getCallId() : int
      {
         default xml namespace = "http://api.facebook.com/1.0/";
         ++this.lastCallId;
         return this.lastCallId;
      }
      
      public function set authToken(param1:String) : void
      {
         default xml namespace = "http://api.facebook.com/1.0/";
         if(param1 == this._authToken)
         {
            return;
         }
         this._authToken = param1;
         this._hasAuthToken = true;
      }
      
      public function get sessionKey() : String
      {
         default xml namespace = "http://api.facebook.com/1.0/";
         return this._sessionKey;
      }
      
      public function get authToken() : String
      {
         default xml namespace = "http://api.facebook.com/1.0/";
         return this._authToken;
      }
      
      public function uploadPhoto(param1:String, param2:ByteArray) : void
      {
         var uploadCompleteListener:Function;
         var req:URLRequest;
         var filename:String = param1;
         var fileData:ByteArray = param2;
         default xml namespace = "http://api.facebook.com/1.0/";
         req = this.util.makePostData({
            "method":"facebook.photos.upload",
            "data":fileData
         });
         this.refreshLoader();
         uploadCompleteListener = function(param1:Event):void
         {
            default xml namespace = "http://api.facebook.com/1.0/";
            var _loc2_:XML = util.parseRequest(param1.currentTarget as URLLoader);
            var _loc3_:WSUploadEvent = new WSUploadEvent();
            if(!_loc2_)
            {
               _loc3_.success = false;
            }
            dispatchEvent(_loc3_);
         };
         this.urlLoader.addEventListener(Event.COMPLETE,uploadCompleteListener);
         this.urlLoader.addEventListener(IOErrorEvent.IO_ERROR,this.ioError);
         this.urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
         this.urlLoader.load(req);
      }
      
      public function get hasAuthToken() : Boolean
      {
         default xml namespace = "http://api.facebook.com/1.0/";
         return this._hasAuthToken;
      }
   }
}

