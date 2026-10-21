package com.karthik.managers
{
   import com.karthik.core.KComponent;
   import flash.events.EventDispatcher;
   
   public class LayoutTarget extends EventDispatcher
   {
      
      private var _enabled:Boolean = true;
      
      private var _targetAlpha:Number = 1;
      
      private var _stateCache:KState = new KState(0,0,0,0,0);
      
      private var _targetX:Number = 0;
      
      private var _targetY:Number = 0;
      
      private var listeners:int = 0;
      
      public var jumpNext:Boolean = false;
      
      public var doNotManageVisibility:Boolean = false;
      
      public var jumptoPosAfterAdded:Boolean = true;
      
      private var _animationProgress:Number = 0;
      
      private var goalSet:Boolean = true;
      
      private var _item:KComponent;
      
      public var justAdded:Boolean = true;
      
      private var doNotDispatchNext:Boolean = false;
      
      private var _targetWidth:Number = 0;
      
      private var _targetHeight:Number = 0;
      
      public function LayoutTarget(param1:KComponent)
      {
         super();
         this._item = param1;
      }
      
      public function getNextBounds(param1:Number) : KState
      {
         this._stateCache.update(this.item.x + (this.targetX - this.item.x) * this.animationProgress,this.item.y + (this.targetY - this.item.y) * this.animationProgress,this.item.width + (this.targetWidth - this.item.width) * this.animationProgress,this.item.height + (this.targetHeight - this.item.height) * this.animationProgress,this.item.alpha + (this.targetAlpha - this.item.alpha) * this.animationProgress);
         return this._stateCache;
      }
      
      public function set enabled(param1:Boolean) : void
      {
         if(this.doNotManageVisibility)
         {
            return;
         }
         if(this._enabled == param1)
         {
            return;
         }
         this._enabled = param1;
         this.item.visible = param1;
      }
      
      public function get item() : KComponent
      {
         return this._item;
      }
      
      public function get currentState() : KState
      {
         return KState.stateFromKComponent(this._item,this._stateCache);
      }
      
      public function set targetAlpha(param1:Number) : void
      {
         if(this._targetAlpha == param1)
         {
            return;
         }
         this._targetAlpha = param1;
         this.animationProgress = 0;
         this.dispatchComplete(true);
      }
      
      public function get targetHeight() : Number
      {
         return this._targetHeight;
      }
      
      public function set animationProgress(param1:Number) : void
      {
         if(this._animationProgress == param1)
         {
            return;
         }
         if(param1 > 1)
         {
            param1 = 1;
         }
         this._animationProgress = param1;
      }
      
      public function set item(param1:KComponent) : void
      {
         if(this._item == param1)
         {
            return;
         }
         param1.move(this._item.x,this._item.y);
         param1.setActualSize(this._item.width,this._item.height);
         this._item = param1;
      }
      
      public function get height() : Number
      {
         return this.item.height;
      }
      
      public function updateTo(param1:KState) : void
      {
         if(!this.goalSet)
         {
            this.goalSet = true;
         }
         if(this.isWithinTolerance(param1))
         {
            this.item.alpha = this._targetAlpha;
            this.item.move(this._targetX,this._targetY);
            this.item.setActualSize(this._targetWidth,this._targetHeight);
            this.dispatchComplete(false);
         }
         else
         {
            this._item.alpha = param1.alpha;
            this._item.move(param1.x,param1.y);
            this._item.setActualSize(param1.width,param1.height);
         }
      }
      
      public function set targetHeight(param1:Number) : void
      {
         if(this._targetHeight == param1)
         {
            return;
         }
         this._targetHeight = param1;
         this.animationProgress = 0;
         this.dispatchComplete(true);
      }
      
      public function get targetWidth() : Number
      {
         return this._targetWidth;
      }
      
      public function jumpToTarget() : void
      {
         this.updateTo(new KState(this._targetX,this._targetY,this._targetWidth,this._targetHeight,this._targetAlpha));
      }
      
      public function get isDirty() : Boolean
      {
         return !this.isWithinTolerance(this.currentState);
      }
      
      override public function removeEventListener(param1:String, param2:Function, param3:Boolean = false) : void
      {
         super.removeEventListener(param1,param2,param3);
         --this.listeners;
      }
      
      override public function addEventListener(param1:String, param2:Function, param3:Boolean = false, param4:int = 0, param5:Boolean = false) : void
      {
         super.addEventListener(param1,param2,param3,param4,param5);
         if(param1 == AnimationEvent.ANIMATION_COMPLETE)
         {
            this.goalSet = false;
         }
         ++this.listeners;
      }
      
      public function set targetX(param1:Number) : void
      {
         if(this._targetX == param1)
         {
            return;
         }
         this._targetX = param1;
         this.animationProgress = 0;
         this.dispatchComplete(true);
      }
      
      private function dispatchComplete(param1:Boolean) : void
      {
         if(this.listeners == 0)
         {
            return;
         }
         if(!this.goalSet)
         {
            return;
         }
         var _loc2_:AnimationEvent = new AnimationEvent();
         _loc2_.interrupted = param1;
         dispatchEvent(_loc2_);
      }
      
      public function get width() : Number
      {
         return this.item.width;
      }
      
      public function set targetY(param1:Number) : void
      {
         if(this._targetY == param1)
         {
            return;
         }
         this._targetY = param1;
         this.animationProgress = 0;
         this.dispatchComplete(true);
      }
      
      public function get animationProgress() : Number
      {
         return this._animationProgress;
      }
      
      public function get targetAlpha() : Number
      {
         return this._targetAlpha;
      }
      
      private function isWithinTolerance(param1:KState) : Boolean
      {
         if(Math.abs(param1.x - this.targetX) <= 1 && Math.abs(param1.y - this.targetY) <= 1 && Math.abs(param1.width - this.targetWidth) < 0.5 && Math.abs(param1.height - this.targetHeight) < 0.5 && Math.abs(param1.alpha - this.targetAlpha) < 0.1)
         {
            return true;
         }
         return false;
      }
      
      public function get enabled() : Boolean
      {
         return this._enabled;
      }
      
      public function get targetX() : Number
      {
         return this._targetX;
      }
      
      public function get targetY() : Number
      {
         return this._targetY;
      }
      
      public function set targetWidth(param1:Number) : void
      {
         if(this._targetWidth == param1)
         {
            return;
         }
         this._targetWidth = param1;
         this.animationProgress = 0;
         this.dispatchComplete(true);
      }
      
      public function get x() : Number
      {
         return this.item.x;
      }
      
      public function get y() : Number
      {
         return this.item.y;
      }
   }
}

