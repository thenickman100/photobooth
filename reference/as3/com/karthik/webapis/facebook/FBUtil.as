package com.karthik.webapis.facebook
{
   import com.karthik.lang.HashUtil;
   import com.karthik.webapis.api_util.MD5;
   import com.karthik.webapis.api_util.MIMEConstructor;
   import flash.net.URLLoader;
   import flash.net.URLRequest;
   import flash.net.URLRequestMethod;
   import flash.xml.XMLDocument;
   import flash.xml.XMLNode;
   
   public class FBUtil
   {
      
      public static const BOUNDARY:String = "shtifmimeboundary";
      
      public static const LINEBREAK:uint = 3338;
      
      public static const QUOTATION:uint = 34;
      
      public static const DBL_SLASH:uint = 11565;
      
      private var fb:Facebook;
      
      public function FBUtil(param1:Facebook)
      {
         super();
         this.fb = param1;
      }
      
      public function parseRequest(param1:URLLoader) : XML
      {
         var _loc2_:XMLDocument = new XMLDocument();
         _loc2_.ignoreWhite = true;
         _loc2_.parseXML(param1.data);
         var _loc3_:XMLNode = _loc2_.firstChild;
         if(!_loc3_)
         {
            return null;
         }
         if(_loc3_.nodeName == "error_response")
         {
            return null;
         }
         return XML(_loc3_);
      }
      
      public function makeGetReq(param1:Object) : URLRequest
      {
         var _loc2_:Object = null;
         var _loc3_:Object = null;
         var _loc5_:URLRequest = null;
         param1 = HashUtil.mergeHash(this.getAPIOptions(),param1);
         param1.sig = this.getSig(param1);
         var _loc4_:String = "";
         for(_loc2_ in param1)
         {
            _loc3_ = param1[_loc2_];
            _loc4_ += _loc2_.toString() + "=" + escape(_loc3_.toString()) + "&";
         }
         _loc4_ = _loc4_.substr(0,_loc4_.length - 1);
         _loc5_ = new URLRequest(this.fb.endPoint + _loc4_);
         _loc5_.method = URLRequestMethod.GET;
         return _loc5_;
      }
      
      public function getAPIOptions() : Object
      {
         var _loc1_:Object = {
            "api_key":this.fb.apiKey,
            "call_id":this.fb.getCallId(),
            "v":this.fb.version
         };
         if(this.fb.hasSession)
         {
            _loc1_.session_key = this.fb.sessionKey;
         }
         else if(this.fb.hasAuthToken)
         {
            _loc1_.auth_token = this.fb.authToken;
         }
         return _loc1_;
      }
      
      private function getSig(param1:Object) : String
      {
         var _loc2_:int = 0;
         var _loc3_:Object = null;
         var _loc4_:Object = null;
         var _loc5_:Object = null;
         var _loc7_:String = null;
         var _loc6_:Array = [];
         for(_loc3_ in param1)
         {
            _loc4_ = param1[_loc3_];
            if(_loc3_ != "data")
            {
               _loc6_.push({
                  "key":_loc3_.toString(),
                  "value":_loc4_.toString()
               });
            }
         }
         _loc6_.sortOn("key");
         _loc7_ = "";
         _loc2_ = 0;
         while(_loc2_ < _loc6_.length)
         {
            _loc7_ += _loc6_[_loc2_].key + "=" + _loc6_[_loc2_].value;
            _loc2_++;
         }
         _loc7_ += this.fb.secret;
         return MD5.hash(_loc7_);
      }
      
      public function makePostData(param1:Object) : URLRequest
      {
         var _loc2_:Object = null;
         var _loc3_:Object = null;
         var _loc5_:URLRequest = null;
         var _loc4_:MIMEConstructor = new MIMEConstructor();
         param1 = HashUtil.mergeHash(this.getAPIOptions(),param1);
         param1["sig"] = this.getSig(param1);
         for(_loc2_ in param1)
         {
            _loc3_ = param1[_loc2_];
            if(_loc2_ != "data")
            {
               _loc4_.writePostData(_loc2_.toString(),_loc3_.toString());
            }
         }
         _loc4_.writeFileData("fn" + param1.call_id + ".jpg",param1["data"]);
         _loc4_.closePostData();
         _loc5_ = new URLRequest();
         _loc5_.method = URLRequestMethod.POST;
         _loc5_.contentType = "multipart/form-data; boundary=" + _loc4_.getBoundary();
         _loc5_.data = _loc4_.getPostData();
         trace("post data is: \n" + _loc4_.getPostData().toString());
         _loc5_.url = "http://api.facebook.com/restserver.php";
         return _loc5_;
      }
   }
}

