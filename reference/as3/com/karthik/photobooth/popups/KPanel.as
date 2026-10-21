package com.karthik.photobooth.popups
{
   import com.karthik.core.KComponent;
   import com.karthik.core.KSkin;
   import com.karthik.lang.HashUtil;
   import com.karthik.managers.Singletons;
   import com.karthik.photobooth.skins.SimpleWindowSkin;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;
   
   public class KPanel extends KComponent
   {
      
      protected var _titleTextFormat:TextFormat;
      
      protected var _titleText:String = "Panel title";
      
      protected var titleTextChanged:Boolean = true;
      
      protected var title:TextField;
      
      public var skin:KSkin;
      
      public function KPanel(param1:Object = null)
      {
         super(HashUtil.mergeHash({
            "width":300,
            "height":150,
            "skin":Singletons.getInstance(SimpleWindowSkin)
         },param1));
         this._titleTextFormat = new TextFormat("Lucida Grande",12,3355443);
      }
      
      public function get titleText() : String
      {
         return this._titleText;
      }
      
      override protected function update() : void
      {
         super.update();
         if(wasResized)
         {
            this.skin.draw(this);
            this.positionText();
         }
         if(this.titleTextChanged)
         {
            this.titleTextChanged = false;
            this.title.text = this._titleText;
            this.title.setTextFormat(this._titleTextFormat);
            this.positionText();
         }
      }
      
      public function set titleText(param1:String) : void
      {
         if(param1 == this.titleText)
         {
            return;
         }
         this._titleText = param1;
         this.titleTextChanged = true;
         invalidate();
      }
      
      private function positionText() : void
      {
         this.title.x = (width - this.title.textWidth) / 2;
         this.title.y = (20 - this.title.textHeight) / 2;
      }
      
      override protected function createChildren() : void
      {
         this.title = new TextField();
         this.title.multiline = false;
         this.title.selectable = false;
         this.title.autoSize = TextFieldAutoSize.LEFT;
         addChild(this.title);
      }
      
      public function get titleTextFormat() : TextFormat
      {
         return this._titleTextFormat;
      }
      
      public function set titleTextFormat(param1:TextFormat) : void
      {
         if(param1 == this.titleTextFormat)
         {
            return;
         }
         this._titleTextFormat = param1;
         this.titleTextChanged = true;
         invalidate();
      }
   }
}

