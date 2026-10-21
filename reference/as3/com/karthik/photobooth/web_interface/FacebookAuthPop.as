package com.karthik.photobooth.web_interface
{
   import com.karthik.photobooth.popups.KPanel;
   import com.karthik.photobooth.popups.TextButton;
   import com.karthik.photobooth.popups.TextFieldMultiLine;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import flash.text.TextFormat;
   
   public class FacebookAuthPop extends KPanel
   {
      
      public var btnAuth:TextButton;
      
      protected var bodyTextFormat:TextFormat;
      
      protected var text:TextField;
      
      public var btnLogin:TextButton;
      
      public function FacebookAuthPop()
      {
         super({
            "width":300,
            "height":255
         });
         this.bodyTextFormat = new TextFormat("Lucida Grande",11,15658734);
      }
      
      private function loginClickListener(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         dispatchEvent(new Event("loginClick"));
         this.btnAuth.disabled = false;
      }
      
      private function authClickListener(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         dispatchEvent(new Event("authClick"));
      }
      
      override protected function update() : void
      {
         super.update();
         if(wasResized)
         {
            this.text.x = 10;
            this.text.y = 30;
            this.btnLogin.move(70,height - 32);
            this.btnAuth.move(130,height - 32);
         }
      }
      
      override protected function createChildren() : void
      {
         super.createChildren();
         titleText = "Please login to facebook";
         this.text = new TextFieldMultiLine();
         this.text.width = 280;
         this.text.htmlText = "<b>Step 1: </b>" + "Click on the \'Login\' button below to login to facebook in the popup, make sure your browser doesn\'t block the popup." + "<br><br>" + "<b>Step 2: </b>" + "After you have logged in, come back to this page and click on the \'Authenticate\' button to authenticate yourself against facebook" + "<br><br>" + "<b>Step 3: </b>" + "When authentication is complete, click on the \'Upload\' button in the upload dialogue to upload your photo " + "<br><br>Don\'t worry, you only have to do this once each time you use this app";
         this.text.setTextFormat(this.bodyTextFormat);
         addChild(this.text);
         this.btnLogin = new TextButton();
         this.btnLogin.labelText = "Login";
         this.btnLogin.addEventListener(MouseEvent.CLICK,this.loginClickListener);
         addChild(this.btnLogin);
         this.btnLogin.width = 50;
         this.btnAuth = new TextButton();
         this.btnAuth.labelText = "Authenticate";
         this.btnAuth.addEventListener(MouseEvent.CLICK,this.authClickListener);
         addChild(this.btnAuth);
         this.btnAuth.width = 100;
         this.btnAuth.disabled = true;
      }
   }
}

