package com.karthik.managers
{
   import com.karthik.core.KComponent;
   import flash.utils.Dictionary;
   
   public class LayoutAnimator
   {
      
      public var refreshFrequency:Number = 20;
      
      public var animationSpeed:Number = 0.1;
      
      public var positionFunc:Function;
      
      public var positionFuncCalled:Boolean = false;
      
      private var positionsInvalid:Boolean = true;
      
      private var _stateCache:KState = new KState(0,0,0,0,0);
      
      private var owner:KComponent;
      
      private var doClipping:Boolean = true;
      
      private var children:Dictionary;
      
      public function LayoutAnimator(param1:KComponent)
      {
         super();
         this.owner = param1;
         this.children = new Dictionary();
      }
      
      public function targetFor(param1:KComponent) : LayoutTarget
      {
         return this.children[param1];
      }
      
      public function validate() : void
      {
         var _loc1_:KState = null;
         var _loc2_:Object = null;
         var _loc3_:LayoutTarget = null;
         var _loc4_:KState = null;
         var _loc5_:KState = null;
         if(!this.positionsInvalid)
         {
            return;
         }
         this.positionsInvalid = false;
         if(!this.positionFuncCalled)
         {
            this.positionFunc.apply(this.owner);
         }
         this.positionFuncCalled = false;
         if(this.doClipping)
         {
            _loc1_ = KState.stateFromKComponent(this.owner,this._stateCache);
            _loc1_.x = 0;
            _loc1_.y = 0;
         }
         for each(_loc2_ in this.children)
         {
            if(_loc2_ == null)
            {
               trace("RED ALERT, NULL DETECTED");
            }
            _loc3_ = _loc2_ as LayoutTarget;
            if(_loc3_.isDirty)
            {
               _loc4_ = _loc3_.getNextBounds(this.animationSpeed);
               _loc3_.animationProgress += this.animationSpeed;
               if(_loc3_.justAdded && _loc3_.jumptoPosAfterAdded)
               {
                  _loc3_.jumpToTarget();
               }
               else if(_loc3_.jumpNext)
               {
                  _loc3_.jumpNext = false;
                  _loc3_.jumpToTarget();
               }
               else
               {
                  _loc3_.updateTo(_loc4_);
               }
               _loc3_.justAdded = false;
               if(_loc3_.isDirty)
               {
                  this.positionsInvalid = true;
               }
            }
            if(this.doClipping && !_loc3_.doNotManageVisibility)
            {
               _loc5_ = _loc3_.currentState;
               if(!_loc1_.intersect(_loc5_))
               {
                  _loc3_.enabled = false;
               }
               else
               {
                  _loc3_.enabled = true;
               }
            }
         }
         if(this.positionsInvalid)
         {
            TimerManager.getInstance().addCallBack(this.validate,this.refreshFrequency,true,this);
         }
      }
      
      public function removeChild(param1:KComponent) : void
      {
         this.children[param1] = null;
         delete this.children[param1];
      }
      
      public function setTargets(param1:KComponent, param2:Number, param3:Number, param4:Number, param5:Number, param6:Number = 1) : void
      {
         var _loc7_:LayoutTarget = this.targetFor(param1);
         _loc7_.targetX = param2;
         _loc7_.targetY = param3;
         _loc7_.targetWidth = param4;
         _loc7_.targetHeight = param5;
         _loc7_.targetAlpha = param6;
      }
      
      public function addChild(param1:KComponent) : void
      {
         this.children[param1] = new LayoutTarget(param1);
      }
      
      public function invalidate() : void
      {
         this.positionsInvalid = true;
      }
   }
}

