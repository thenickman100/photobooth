package com.karthik.photobooth.popups
{
   import com.karthik.components.Button;
   import com.karthik.components.Label;
   import com.karthik.lang.HashUtil;
   import com.karthik.managers.Singletons;
   import com.karthik.photobooth.skins.control_bar.MacButtonSkin;
   
   public class TextButton extends Button
   {
      
      protected var _labelText:String;
      
      protected var labelTextChanged:Boolean = true;
      
      private var label:Label;
      
      public function TextButton(param1:Object = null)
      {
         super(HashUtil.mergeHash({
            "width":70,
            "height":22,
            "skin":Singletons.getInstance(MacButtonSkin)
         },param1));
      }
      
      override protected function update() : void
      {
         super.update();
         if(this.labelTextChanged)
         {
            this.labelTextChanged = false;
            this.label.text = this.labelText;
            this.positionLabel();
         }
         if(disabled)
         {
            this.label.fontColor = 6710886;
         }
         else
         {
            this.label.fontColor = 3487029;
         }
         if(wasResized)
         {
            this.label.validateNow();
            this.positionLabel();
         }
      }
      
      public function get labelText() : String
      {
         return this._labelText;
      }
      
      public function set labelText(param1:String) : void
      {
         if(param1 == this.labelText)
         {
            return;
         }
         this._labelText = param1;
         this.labelTextChanged = true;
         invalidate();
      }
      
      override protected function createChildren() : void
      {
         super.createChildren();
         this.label = new Label();
         this.label.fontSize = 11;
         this.label.fontColor = 3487029;
         addChild(this.label);
      }
      
      private function positionLabel() : void
      {
         var _loc1_:Number = this.label.getMeasuredWidth();
         var _loc2_:Number = this.label.getMeasuredHeight();
         this.label.move((width - _loc1_) / 2,(height - _loc2_) / 2 - 2);
         this.label.setActualSize(_loc1_,_loc2_);
      }
   }
}

