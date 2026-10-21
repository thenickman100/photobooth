package com.karthik.components
{
   import com.karthik.core.KComponent;
   import com.karthik.lang.HashUtil;
   import com.karthik.managers.Singletons;
   import com.karthik.skins.KButtonSkin;
   import flash.events.MouseEvent;
   
   public class Button extends KComponent
   {
      
      private var _text:String;
      
      protected var _state:String = "normal";
      
      protected var _disabled:Boolean = false;
      
      protected var _skin:KButtonSkin;
      
      public var defaultOptions:Object = {
         "skin":Singletons.getInstance(KButtonSkin),
         "width":100,
         "height":20
      };
      
      protected var stateChanged:Boolean = true;
      
      public function Button(param1:Object = null)
      {
         super(HashUtil.mergeHash({
            "width":100,
            "height":30
         },param1));
         addEventListener(MouseEvent.ROLL_OVER,this.mouseOver,false,-50,false);
         addEventListener(MouseEvent.ROLL_OUT,this.mouseOut,false,-50,false);
         addEventListener(MouseEvent.MOUSE_DOWN,this.mouseDown,false,-50,false);
         addEventListener(MouseEvent.MOUSE_UP,this.mouseUp,false,-50,false);
      }
      
      override protected function update() : void
      {
         if(wasResized || this.stateChanged)
         {
            this.stateChanged = false;
            this.skin.draw(this);
         }
      }
      
      public function get state() : String
      {
         return this._state;
      }
      
      protected function invalidateState() : void
      {
         this.stateChanged = true;
         invalidate();
      }
      
      protected function mouseOver(param1:MouseEvent) : void
      {
         if(this.disabled)
         {
            return;
         }
         this._state = "over";
         this.invalidateState();
      }
      
      override protected function getDefaultOption() : Object
      {
         return this.defaultOptions;
      }
      
      protected function mouseDown(param1:MouseEvent) : void
      {
         if(this.disabled)
         {
            return;
         }
         this._state = "down";
         this.invalidateState();
      }
      
      protected function mouseOut(param1:MouseEvent) : void
      {
         if(this.disabled)
         {
            return;
         }
         this._state = "normal";
         this.invalidateState();
      }
      
      protected function mouseClick(param1:MouseEvent) : void
      {
         if(this.disabled)
         {
            param1.stopImmediatePropagation();
         }
      }
      
      protected function mouseUp(param1:MouseEvent) : void
      {
         if(this.disabled)
         {
            return;
         }
         this._state = "normal";
         this.invalidateState();
      }
      
      public function set disabled(param1:Boolean) : void
      {
         if(param1 == this._disabled)
         {
            return;
         }
         this._disabled = param1;
         this.invalidateState();
      }
      
      public function set skin(param1:KButtonSkin) : void
      {
         if(this._skin == param1)
         {
            return;
         }
         this._skin = param1;
         this.invalidateState();
      }
      
      public function get disabled() : Boolean
      {
         return this._disabled;
      }
      
      public function get skin() : KButtonSkin
      {
         return this._skin;
      }
   }
}

