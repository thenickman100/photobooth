package com.karthik.webapis.flickr
{
   import com.karthik.lang.HashUtil;
   import com.karthik.webapis.api_util.MD5;
   import com.karthik.webapis.api_util.MIMEConstructor;
   import flash.net.URLLoader;
   import flash.net.URLRequest;
   import flash.net.URLRequestMethod;
   import flash.xml.XMLDocument;
   import flash.xml.XMLNode;
   
   public class FlickrUtil
   {
      
      private var fk:Flickr;
      
      public function FlickrUtil(param1:Flickr)
      {
         super();
         this.fk = param1;
      }
      
      public function makeGetReq(param1:Object) : URLRequest
      {
         var _loc2_:Object = null;
         var _loc3_:Object = null;
         var _loc5_:URLRequest = null;
         param1 = HashUtil.mergeHash(this.getAPIOptions(),param1);
         param1.api_sig = this.getSig(param1);
         var _loc4_:String = "";
         for(_loc2_ in param1)
         {
            _loc3_ = param1[_loc2_];
            _loc4_ += _loc2_.toString() + "=" + escape(_loc3_.toString()) + "&";
         }
         _loc4_ = _loc4_.substr(0,_loc4_.length - 1);
         _loc5_ = new URLRequest(this.fk.endPoint + _loc4_);
         trace("made GET request: " + this.fk.endPoint + _loc4_);
         _loc5_.method = URLRequestMethod.GET;
         return _loc5_;
      }
      
      public function makePostData(param1:Object) : URLRequest
      {
         var _loc2_:Object = null;
         var _loc3_:Object = null;
         var _loc5_:URLRequest = null;
         var _loc4_:MIMEConstructor = new MIMEConstructor();
         param1 = HashUtil.mergeHash(this.getAPIOptions(),param1);
         param1.api_sig = this.getSig(param1);
         for(_loc2_ in param1)
         {
            _loc3_ = param1[_loc2_];
            if(_loc2_ != "data")
            {
               trace("writing key: " + _loc2_.toString() + " value: " + _loc3_.toString());
               _loc4_.writePostData(_loc2_.toString(),_loc3_.toString());
            }
         }
         _loc4_.writeFileData("photo.jpg",param1["data"]);
         _loc4_.closePostData();
         _loc5_ = new URLRequest(this.fk.uploadEndPoint);
         _loc5_.method = URLRequestMethod.POST;
         _loc5_.contentType = "multipart/form-data; boundary=" + _loc4_.getBoundary();
         _loc5_.data = _loc4_.getPostData();
         trace("post data is: \n" + _loc4_.getPostData().toString());
         return _loc5_;
      }
      
      public function getAPIOptions() : Object
      {
         var _loc1_:Object = {"api_key":this.fk.apiKey};
         if(this.fk.hasToken())
         {
            _loc1_.auth_token = this.fk.token;
         }
         else if(this.fk.hasFrob())
         {
            _loc1_.frob = this.fk.frob;
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
         _loc7_ = this.fk.secret;
         _loc2_ = 0;
         while(_loc2_ < _loc6_.length)
         {
            _loc7_ += _loc6_[_loc2_].key + _loc6_[_loc2_].value;
            _loc2_++;
         }
         return MD5.hash(_loc7_);
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
         if(_loc3_.attributes.stat != "ok")
         {
            return null;
         }
         return XML(_loc3_);
      }
   }
}

