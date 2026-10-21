package com.karthik.photobooth.screens.bg_removed
{
   import com.karthik.components.Label;
   import com.karthik.core.KComponent;
   import com.karthik.core.KSkin;
   import com.karthik.managers.Singletons;
   
   public class MsgBox extends KComponent
   {
      
      protected var _text:String = "Your Msg";
      
      protected var textChagned:Boolean = true;
      
      private var lbl:Label;
      
      public var skin:KSkin;
      
      public function MsgBox()
      {
         super({"skin":Singletons.getInstance(MsgBoxSkin)});
      }
      
      public function set text(param1:String) : void
      {
         if(param1 == this.text)
         {
            return;
         }
         this._text = param1;
         this.textChagned = true;
         invalidate();
      }
      
      public function autoCenter() : void
      {
         if(!parent)
         {
         }
      }
      
      override protected function update() : void
      {
         var _loc1_:Number = NaN;
         var _loc2_:Number = NaN;
         if(this.textChagned)
         {
            this.textChagned = false;
            this.lbl.text = this.text;
            this.lbl.validateNow();
            _loc1_ = this.lbl.getMeasuredWidth() + 20;
            _loc2_ = this.lbl.getMeasuredHeight() + 10;
            setActualSize(_loc1_,_loc2_);
            this.lbl.move(6,3);
            this.skin.draw(this);
            this.autoCenter();
         }
      }
      
      public function get text() : String
      {
         return this._text;
      }
      
      override protected function createChildren() : void
      {
         super.createChildren();
         this.lbl = new Label();
         this.lbl.fontSize = 26;
         this.lbl.fontColor = 16777215;
         addChild(this.lbl);
      }
   }
}

import com.karthik.core.KSkin;
import com.karthik.core.KSprite;

class MsgBoxSkin extends KSkin
{
   
   public function MsgBoxSkin()
   {
      super();
   }
   
   override public function draw(param1:KSprite, param2:Object = null) : void
   {
      clear(param1);
      drawKRoundRect({
         "radius":4,
         "target":param1,
         "lineStyle":{"alpha":0},
         "fillStyle":{
            "alpha":0.5,
            "color":0
         }
      });
   }
}
