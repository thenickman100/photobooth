package com.karthik.photobooth.managers
{
   import com.karthik.components.Button;
   import com.karthik.core.KComponent;
   import com.karthik.core.KSkin;
   import com.karthik.managers.LayoutAnimator;
   import com.karthik.managers.Singletons;
   import com.karthik.photobooth.skins.growl.GrowBoxCloseButtonSkin;
   import com.karthik.photobooth.skins.growl.GrowlBoxSkin;
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;
   
   public class GrowlBox extends KComponent
   {
      
      private static var Icon:Class = GrowlBox_Icon;
      
      public static var defIconBmp:BitmapData = (new Icon() as Bitmap).bitmapData;
      
      private static var IconDl:Class = GrowlBox_IconDl;
      
      public static var downloadIconBmp:BitmapData = (new IconDl() as Bitmap).bitmapData;
      
      protected var icon:Sprite;
      
      private var closeBtnAlpha:Number = 0;
      
      protected var bodyTf:TextFormat = new TextFormat("Lucida Grande",11,3355443);
      
      protected var closeBtn:Button;
      
      protected var textChanged:Boolean = false;
      
      protected var iconBmp:BitmapData = null;
      
      private var header:TextField;
      
      protected var _bodyText:String = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse quam magna, gravida i";
      
      protected var headerTf:TextFormat = new TextFormat("Lucida Grande",11,2236962,true);
      
      private var body:TextField;
      
      protected var outlineWidth:Number = 5;
      
      private var animator:LayoutAnimator;
      
      protected var margin:Number = 4;
      
      protected var headerBodySpace:Number = 1;
      
      protected var _headerText:String = "header text";
      
      public var explicitHeight:Number = NaN;
      
      public var skin:KSkin;
      
      public function GrowlBox(param1:BitmapData = null)
      {
         super({
            "skin":Singletons.getInstance(GrowlBoxSkin),
            "width":180
         });
         if(param1)
         {
            this.iconBmp = param1;
         }
         else
         {
            this.iconBmp = defIconBmp;
         }
         this.animator = new LayoutAnimator(this);
         this.animator.positionFunc = this.positionFunc;
         addEventListener(MouseEvent.ROLL_OVER,this.rollOverListener);
         addEventListener(MouseEvent.ROLL_OUT,this.rollOutListener);
      }
      
      private function rollOverListener(param1:MouseEvent) : void
      {
         if(this.animator)
         {
            this.closeBtnAlpha = 1;
            this.animator.invalidate();
            invalidate();
         }
      }
      
      override protected function update() : void
      {
         this.animator.validate();
         if(wasResized || this.textChanged)
         {
            this.textChanged = false;
            this.header.text = this._headerText;
            this.body.text = this._bodyText;
            this.header.setTextFormat(this.headerTf);
            this.body.setTextFormat(this.bodyTf);
            this.header.y = this.margin;
            this.header.x = this.iconBmp ? this.iconBmp.width + this.margin + 2 : this.margin;
            this.body.x = this.iconBmp ? this.iconBmp.width + this.margin + 2 : this.margin;
            this.body.y = this.header.y + this.header.height + this.headerBodySpace;
            this.body.width = width - 2 * this.margin - (this.iconBmp ? this.iconBmp.width + 2 : 0);
            if(isNaN(this.explicitHeight))
            {
               height = this.getMeasuredHeight();
            }
            else
            {
               height = this.explicitHeight;
            }
            this.skin.draw(this);
         }
      }
      
      public function getMeasuredHeight() : Number
      {
         if(this.body)
         {
            return this.body.y + this.body.height + this.margin;
         }
         return 100;
      }
      
      private function positionFunc() : void
      {
         this.animator.setTargets(this.closeBtn,5,5,22,22,this.closeBtnAlpha);
      }
      
      public function set headerText(param1:String) : void
      {
         if(param1 == this.headerText)
         {
            return;
         }
         this._headerText = param1;
         this.textChanged = true;
         invalidate();
      }
      
      override protected function createChildren() : void
      {
         this.body = new TextField();
         this.body.selectable = false;
         this.body.autoSize = TextFieldAutoSize.LEFT;
         this.body.wordWrap = true;
         this.body.multiline = true;
         this.body.setTextFormat(this.bodyTf);
         addChild(this.body);
         this.header = new TextField();
         this.header.selectable = false;
         this.header.autoSize = TextFieldAutoSize.LEFT;
         this.header.wordWrap = false;
         this.header.multiline = false;
         this.header.setTextFormat(this.headerTf);
         addChild(this.header);
         this.icon = new Sprite();
         this.icon.graphics.clear();
         this.icon.graphics.beginBitmapFill(this.iconBmp);
         this.icon.graphics.drawRect(0,0,this.iconBmp.width,this.iconBmp.height);
         addChild(this.icon);
         this.icon.x = this.icon.y = this.margin;
         this.closeBtn = new Button({
            "width":22,
            "height":22,
            "skin":Singletons.getInstance(GrowBoxCloseButtonSkin)
         });
         this.animator.addChild(this.closeBtn);
         this.animator.targetFor(this.closeBtn).doNotManageVisibility = true;
         this.animator.animationSpeed = 0.2;
         addChild(this.closeBtn);
         this.closeBtn.addEventListener(MouseEvent.CLICK,this.closeBtnClickListener);
      }
      
      public function set bodyText(param1:String) : void
      {
         if(param1 == this.bodyText)
         {
            return;
         }
         this._bodyText = param1;
         this.textChanged = true;
         invalidate();
      }
      
      public function get headerText() : String
      {
         return this._headerText;
      }
      
      private function rollOutListener(param1:MouseEvent) : void
      {
         if(this.animator)
         {
            this.closeBtnAlpha = 0;
            this.animator.invalidate();
            invalidate();
         }
      }
      
      public function get bodyText() : String
      {
         return this._bodyText;
      }
      
      private function closeBtnClickListener(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         dispatchEvent(new Event("closeBox"));
      }
   }
}

