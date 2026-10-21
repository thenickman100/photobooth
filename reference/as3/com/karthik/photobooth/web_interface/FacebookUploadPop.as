package com.karthik.photobooth.web_interface
{
   import com.karthik.photobooth.popups.KPanel;
   import com.karthik.photobooth.popups.TextButton;
   import com.karthik.photobooth.popups.TextFieldMultiLine;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import flash.text.TextFormat;
   
   public class FacebookUploadPop extends KPanel
   {
      
      protected var btnUpload:TextButton;
      
      protected var bodyTextFormat:TextFormat;
      
      protected var text:TextField;
      
      public function FacebookUploadPop()
      {
         super({
            "width":200,
            "height":100
         });
         this.bodyTextFormat = new TextFormat("Lucida Grande",11,15658734);
      }
      
      private function uploadClickListener(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         dispatchEvent(new Event("uploadClick"));
      }
      
      override protected function update() : void
      {
         super.update();
         if(wasResized)
         {
            this.btnUpload.move((width - 80) / 2,height - 32);
            this.text.x = 10;
            this.text.y = 30;
         }
      }
      
      override protected function createChildren() : void
      {
         super.createChildren();
         titleText = "Ready to upload";
         this.text = new TextFieldMultiLine();
         this.text.width = 280;
         this.text.htmlText = "Click the button below to upload your photo to facebook";
         this.text.width = 180;
         this.text.setTextFormat(this.bodyTextFormat);
         addChild(this.text);
         this.btnUpload = new TextButton();
         this.btnUpload.labelText = "Upload";
         this.btnUpload.width = 80;
         this.btnUpload.addEventListener(MouseEvent.CLICK,this.uploadClickListener);
         addChild(this.btnUpload);
      }
   }
}

