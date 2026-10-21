package com.karthik.components
{
   import com.karthik.core.KComponent;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;
   
   public class Label extends KComponent
   {
      
      protected var styleChanged:Boolean = true;
      
      protected var textChanged:Boolean = false;
      
      protected var _text:String;
      
      protected var textField:TextField;
      
      protected var _fontSize:Number = 10;
      
      protected var _fontColor:uint = 16777215;
      
      protected var _multiLine:Boolean = false;
      
      protected var multiLineChanged:Boolean = false;
      
      protected var _fontFamily:String = "Lucida Grande";
      
      protected var format:TextFormat;
      
      public function Label()
      {
         super();
      }
      
      private function styleChange() : void
      {
         this.styleChanged = true;
         invalidate();
      }
      
      override protected function update() : void
      {
         super.update();
         if(this.textChanged)
         {
            this.textChanged = false;
            this.textField.text = this._text;
            this.styleChanged = true;
         }
         if(wasResized)
         {
            this.textField.height = height;
         }
         if(this.styleChanged)
         {
            this.styleChanged = false;
            this.format.size = this.fontSize;
            this.format.color = this.fontColor;
            this.format.font = this.fontFamily;
            this.textField.setTextFormat(this.format);
         }
      }
      
      public function getMeasuredHeight() : Number
      {
         return this.textField.textHeight;
      }
      
      public function get fontFamily() : String
      {
         return this._fontFamily;
      }
      
      public function get fontColor() : uint
      {
         return this._fontColor;
      }
      
      override protected function createChildren() : void
      {
         super.createChildren();
         this.format = new TextFormat("Lucida Grande",8,16777215);
         this.textField = new TextField();
         this.textField.selectable = false;
         this.textField.autoSize = TextFieldAutoSize.LEFT;
         addChild(this.textField);
      }
      
      public function set fontSize(param1:Number) : void
      {
         if(this._fontSize == param1)
         {
            return;
         }
         this._fontSize = param1;
         this.styleChange();
      }
      
      public function set text(param1:String) : void
      {
         if(this._text == param1)
         {
            return;
         }
         this._text = param1;
         this.textChanged = true;
         validateNow();
      }
      
      public function set fontFamily(param1:String) : void
      {
         if(this._fontFamily == param1)
         {
            return;
         }
         this._fontFamily = param1;
         this.styleChange();
      }
      
      public function set fontColor(param1:uint) : void
      {
         if(param1 == this.fontColor)
         {
            return;
         }
         this._fontColor = param1;
         this.styleChange();
      }
      
      public function get text() : String
      {
         return this._text;
      }
      
      public function get fontSize() : Number
      {
         return this._fontSize;
      }
      
      public function getMeasuredWidth() : Number
      {
         return this.textField.textWidth;
      }
   }
}

