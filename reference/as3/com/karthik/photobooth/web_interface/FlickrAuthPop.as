package com.karthik.photobooth.web_interface
{
   public class FlickrAuthPop extends FacebookAuthPop
   {
      
      public function FlickrAuthPop()
      {
         super();
      }
      
      override protected function createChildren() : void
      {
         super.createChildren();
         text.htmlText = "<b>Step 1: </b>" + "Click on the \'Login\' button below to login to Flickr in the popup, make sure your browser doesn\'t block the popup." + "<br><br>" + "<b>Step 2: </b>" + "After you have logged in, come back to this page and click on the \'Authenticate\' button to authenticate yourself against Flickr" + "<br><br>" + "<b>Step 3: </b>" + "When authentication is complete, click on the \'Upload\' button in the upload dialogue to upload your photo " + "<br><br>Don\'t worry, you only have to do this once each time you use this app";
         text.setTextFormat(bodyTextFormat);
      }
   }
}

