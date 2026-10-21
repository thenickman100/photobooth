package com.karthik.core
{
   import com.karthik.lang.HashUtil;
   import com.karthik.managers.TimerManager;
   import flash.events.Event;
   
   public class KComponent extends KSprite
   {
      
      protected var _x:Number = 0;
      
      protected var wasResized:Boolean = true;
      
      protected var wasMoved:Boolean = false;
      
      protected var pendingOptions:Object;
      
      protected var wasVisibilityChanged:Boolean = false;
      
      protected var intialized:Boolean = false;
      
      private var defaultOptions:Object = {
         "width":100,
         "height":100
      };
      
      protected var _alpha:Number = 1;
      
      private var global:KComponentGlobals;
      
      protected var isInvalid:Boolean = false;
      
      private var _visible:Boolean = true;
      
      protected var _y:Number = 0;
      
      protected var wasAlphaChanged:Boolean = false;
      
      public function KComponent(param1:Object = null)
      {
         super();
         this.global = KComponentGlobals.getInstance();
         addEventListener(Event.ADDED,this.addedListener,false,-1,true);
         this.pendingOptions = param1;
      }
      
      protected function removedListener(param1:Event) : void
      {
         if(param1.target != this)
         {
            return;
         }
         addEventListener(Event.ADDED,this.addedListener);
         this.intialized = false;
      }
      
      protected function update() : void
      {
      }
      
      override public function set width(param1:Number) : void
      {
         _width = param1;
         this.wasResized = true;
         this.invalidate();
      }
      
      protected function commitProperties() : void
      {
      }
      
      protected function callLater(... rest) : void
      {
         TimerManager.getInstance().addCallBack(this.callLaterExe,20,true,this,rest);
      }
      
      public function move(param1:int, param2:int) : void
      {
         if(this._x == param1 && this._y == param2)
         {
            return;
         }
         this.x = this._x = param1;
         this.y = this._y = param2;
      }
      
      protected function addedListener(param1:Event) : void
      {
         if(param1.target != this)
         {
            return;
         }
         this.setProperties(this.pendingOptions);
         removeEventListener(Event.ADDED,this.addedListener);
         addEventListener(Event.REMOVED,this.removedListener,false,-1,true);
         this.createChildren();
         this.invalidate();
         this.intialized = true;
      }
      
      protected function getDefaultOption() : Object
      {
         return this.defaultOptions;
      }
      
      protected function createChildren() : void
      {
      }
      
      private function callLaterExe(... rest) : void
      {
         var _loc3_:Function = null;
         var _loc2_:int = 0;
         while(_loc2_ < rest.length)
         {
            _loc3_ = rest[_loc2_];
            _loc3_.apply(this);
            _loc2_++;
         }
      }
      
      protected function validate(param1:Event) : void
      {
         this.validateNow();
      }
      
      public function validateNow() : void
      {
         if(!this.intialized)
         {
            return;
         }
         this.commitProperties();
         this.update();
         this.wasResized = false;
         this.isInvalid = false;
      }
      
      override public function set height(param1:Number) : void
      {
         _height = param1;
         this.wasResized = true;
         this.invalidate();
      }
      
      public function setActualSize(param1:int, param2:int) : void
      {
         if(_width == param1 && _height == param2)
         {
            return;
         }
         _width = param1;
         _height = param2;
         this.wasResized = true;
         this.validateNow();
      }
      
      protected function setProperties(param1:Object) : void
      {
         HashUtil.transferProperties(HashUtil.mergeHash(this.getDefaultOption(),param1),this);
      }
      
      public function invalidate() : void
      {
         if(this.isInvalid)
         {
            return;
         }
         this.isInvalid = true;
         this.global.invalidateThis(this);
      }
   }
}

