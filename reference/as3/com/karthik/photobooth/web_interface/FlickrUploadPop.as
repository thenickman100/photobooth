package com.karthik.photobooth.web_interface
{
   public class FlickrUploadPop extends FacebookUploadPop
   {
      
      public function FlickrUploadPop()
      {
         super();
      }
      
      override protected function createChildren() : void
      {
         super.createChildren();
         text.htmlText = "Click the button below to upload your photo to Flickr";
         text.setTextFormat(bodyTextFormat);
      }
   }
}

