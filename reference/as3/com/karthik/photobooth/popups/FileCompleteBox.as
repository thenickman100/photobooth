package com.karthik.photobooth.popups
{
   import com.karthik.managers.Singletons;
   import com.karthik.photobooth.skins.SimpleWindowSkin;
   import flash.text.TextField;
   import flash.text.TextFormat;
   
   public class FileCompleteBox extends KPanel
   {
      
      public var button:TextButton;
      
      protected var text:TextField;
      
      public function FileCompleteBox()
      {
         super({
            "width":200,
            "height":100,
            "skin":Singletons.getInstance(SimpleWindowSkin)
         });
      }
      
      override protected function update() : void
      {
         super.update();
         if(wasResized)
         {
            skin.draw(this);
            this.text.x = 10;
            this.text.y = 30;
            this.button.move((width - 120) / 2,height - 30);
         }
      }
      
      override protected function createChildren() : void
      {
         super.createChildren();
         titleText = "Complete";
         this.text = new TextFieldMultiLine();
         this.text.width = 180;
         this.text.text = "Encoding complete. Click the button below to save your image";
         this.text.setTextFormat(new TextFormat("Lucida Grande",11,15658734));
         addChild(this.text);
         this.button = new TextButton({
            "width":120,
            "height":22
         });
         this.button.labelText = "Download";
         addChild(this.button);
      }
   }
}

