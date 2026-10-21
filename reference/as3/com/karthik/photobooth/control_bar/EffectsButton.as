package com.karthik.photobooth.control_bar
{
   import com.karthik.components.Button;
   import com.karthik.components.Label;
   import com.karthik.managers.LayoutAnimator;
   import com.karthik.managers.Singletons;
   import com.karthik.photobooth.events.ModeChangeEvent;
   import com.karthik.photobooth.skins.control_bar.effects_button.EBSkinNormal;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   
   public class EffectsButton extends Button
   {
      
      public static const MODE_NORMAL:int = 1;
      
      public static const MODE_EFFECTS:int = 2;
      
      protected var _maskLB:Sprite;
      
      protected var _mode:int = 1;
      
      protected var _maskRB:Sprite;
      
      protected var modeChanged:Boolean = true;
      
      protected var leftBtn:Button;
      
      protected var rightBtn:Button;
      
      protected var _rightEnabled:Boolean = true;
      
      protected var animator:LayoutAnimator;
      
      protected var label:Label;
      
      protected var _leftEnabled:Boolean = true;
      
      public function EffectsButton()
      {
         super({
            "width":125,
            "height":25,
            "skin":Singletons.getInstance(EBSkinNormal)
         });
         this.animator = new LayoutAnimator(this);
         this.animator.positionFunc = this.positionFunc;
         addEventListener(MouseEvent.CLICK,this.clickListener);
      }
      
      public function set leftEnabled(param1:Boolean) : void
      {
         if(param1 == this.leftEnabled)
         {
            return;
         }
         this._leftEnabled = param1;
         stateChanged = true;
         invalidate();
      }
      
      public function get rightEnabled() : Boolean
      {
         return this._rightEnabled;
      }
      
      public function set mode(param1:int) : void
      {
         if(param1 == this.mode)
         {
            return;
         }
         this._mode = param1;
         stateChanged = true;
         this.animator.invalidate();
         invalidate();
      }
      
      private function positionFunc() : void
      {
         var _loc1_:Number = 30;
         var _loc2_:Number = 22;
         if(this.mode == MODE_EFFECTS)
         {
            this.animator.setTargets(this.leftBtn,1,1,_loc1_ + 1,_loc2_);
            this.animator.setTargets(this.rightBtn,width - 1 - _loc1_,1,_loc1_,_loc2_);
         }
         else
         {
            this.animator.setTargets(this.leftBtn,-_loc1_ - 1,1,_loc1_ + 1,_loc2_);
            this.animator.setTargets(this.rightBtn,width,1,_loc1_,_loc2_);
         }
      }
      
      override protected function update() : void
      {
         var _loc1_:Number = NaN;
         var _loc2_:Number = NaN;
         if(wasResized || stateChanged)
         {
            stateChanged = false;
            this.leftBtn.disabled = !this._leftEnabled;
            this.rightBtn.disabled = !this._rightEnabled;
            skin.draw(this,{
               "left":this.leftBtn,
               "right":this.rightBtn,
               "mask1":this._maskLB,
               "mask2":this._maskRB,
               "label":this.label
            });
            this.label.text = "Effects";
            this.label.fontSize = 12;
            this.label.validateNow();
            _loc1_ = this.label.getMeasuredWidth();
            _loc2_ = this.label.getMeasuredHeight();
            this.label.move((width - _loc1_) / 2,(height - _loc2_) / 2 - 2);
         }
         this.animator.validate();
      }
      
      private function lb_clickListener(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         dispatchEvent(new Event("leftScroll",true));
      }
      
      private function rb_clickListener(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         dispatchEvent(new Event("rightScroll",true));
      }
      
      public function set rightEnabled(param1:Boolean) : void
      {
         if(param1 == this.rightEnabled)
         {
            return;
         }
         this._rightEnabled = param1;
         stateChanged = true;
         invalidate();
      }
      
      override protected function createChildren() : void
      {
         super.createChildren();
         this.leftBtn = new Button();
         this.rightBtn = new Button();
         this.leftBtn.addEventListener(MouseEvent.CLICK,this.lb_clickListener);
         this.rightBtn.addEventListener(MouseEvent.CLICK,this.rb_clickListener);
         this.label = new Label();
         addChild(this.label);
         addChild(this.leftBtn);
         addChild(this.rightBtn);
         this.animator.addChild(this.leftBtn);
         this.animator.addChild(this.rightBtn);
         this._maskLB = new Sprite();
         addChild(this._maskLB);
         this._maskRB = new Sprite();
         addChild(this._maskRB);
         this.leftBtn.mask = this._maskLB;
         this.rightBtn.mask = this._maskRB;
      }
      
      private function clickListener(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         this.mode = this.mode == MODE_EFFECTS ? MODE_NORMAL : MODE_EFFECTS;
         var _loc2_:ModeChangeEvent = new ModeChangeEvent();
         if(this.mode == MODE_EFFECTS)
         {
            _loc2_.targetMode = MODE_EFFECTS;
         }
         else
         {
            _loc2_.targetMode = MODE_NORMAL;
         }
         dispatchEvent(_loc2_);
      }
      
      public function get mode() : int
      {
         return this._mode;
      }
      
      override protected function mouseOver(param1:MouseEvent) : void
      {
      }
      
      public function get leftEnabled() : Boolean
      {
         return this._leftEnabled;
      }
   }
}

