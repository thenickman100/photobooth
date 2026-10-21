package com.karthik.webapis.api_util
{
   import flash.utils.ByteArray;
   import flash.utils.Endian;
   
   public class MIMEConstructor
   {
      
      private var boundary:String = "karthiktharavaad";
      
      private var postData:ByteArray;
      
      public function MIMEConstructor()
      {
         super();
         this.initPostData();
      }
      
      public function getBoundary() : String
      {
         return this.boundary;
      }
      
      private function writeQuotationMark() : void
      {
         this.postData.writeByte(34);
      }
      
      private function writeDoubleDash() : void
      {
         this.postData.writeShort(11565);
      }
      
      private function writeLineBreak() : void
      {
         this.postData.writeShort(3338);
      }
      
      public function writeFileData(param1:String, param2:ByteArray) : void
      {
         var _loc3_:String = null;
         this.writeBoundary();
         this.writeLineBreak();
         _loc3_ = "Content-Disposition: form-data; name=\"photo\"; filename=\"";
         var _loc4_:Number = 0;
         while(_loc4_ < _loc3_.length)
         {
            this.postData.writeByte(_loc3_.charCodeAt(_loc4_));
            _loc4_++;
         }
         this.postData.writeUTFBytes(param1);
         this.writeQuotationMark();
         this.writeLineBreak();
         _loc3_ = "Content-Type: image/jpeg";
         _loc4_ = 0;
         while(_loc4_ < _loc3_.length)
         {
            this.postData.writeByte(_loc3_.charCodeAt(_loc4_));
            _loc4_++;
         }
         this.writeLineBreak();
         this.writeLineBreak();
         param2.position = 0;
         this.postData.writeBytes(param2,0,param2.length);
         this.writeLineBreak();
      }
      
      public function getPostData() : ByteArray
      {
         this.postData.position = 0;
         return this.postData;
      }
      
      private function writeBoundary() : void
      {
         this.writeDoubleDash();
         var _loc1_:Number = 0;
         while(_loc1_ < this.boundary.length)
         {
            this.postData.writeByte(this.boundary.charCodeAt(_loc1_));
            _loc1_++;
         }
      }
      
      public function setBoundary(param1:String) : void
      {
         this.boundary = param1;
      }
      
      public function closePostData() : void
      {
         this.writeBoundary();
         this.writeDoubleDash();
      }
      
      public function writePostData(param1:String, param2:String) : void
      {
         var _loc3_:* = null;
         this.writeBoundary();
         this.writeLineBreak();
         _loc3_ = "Content-Disposition: form-data; name=\"" + param1 + "\"";
         var _loc4_:Number = 0;
         while(_loc4_ < _loc3_.length)
         {
            this.postData.writeByte(_loc3_.charCodeAt(_loc4_));
            _loc4_++;
         }
         this.writeLineBreak();
         this.writeLineBreak();
         this.postData.writeUTFBytes(param2);
         this.writeLineBreak();
      }
      
      public function initPostData() : void
      {
         this.postData = new ByteArray();
         this.postData.endian = Endian.BIG_ENDIAN;
      }
   }
}

