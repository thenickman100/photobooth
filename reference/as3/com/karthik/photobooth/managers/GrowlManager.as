package com.karthik.photobooth.managers
{
   import com.karthik.core.KComponent;
   import com.karthik.managers.AnimationEvent;
   import com.karthik.managers.LayoutAnimator;
   import com.karthik.managers.PopUpManager;
   import com.karthik.managers.TimerManager;
   import flash.display.*;
   import flash.events.Event;
   
   public class GrowlManager extends PopUpManager
   {
      
      private static var _manager:GrowlManager;
      
      private var vGap:Number = 5;
      
      private var boxesArr:Array;
      
      private var hGap:Number = 5;
      
      private var boxWidth:Number = 120;
      
      private var animator:LayoutAnimator;
      
      public function GrowlManager(param1:Sprite)
      {
         super();
         super.initialize(param1);
         this.boxesArr = [];
         TimerManager.getInstance().addCallBack(this.removeTimeoutBoxes,1,false,this);
         TimerManager.getInstance().pauseCallBack(this.removeTimeoutBoxes);
         this.animator = new LayoutAnimator(this);
         this.animator.positionFunc = this.positionFunc;
         this.animator.animationSpeed = 0.05;
      }
      
      public static function init(param1:Sprite) : void
      {
         _manager = new GrowlManager(param1);
      }
      
      public static function getInstance() : GrowlManager
      {
         return _manager;
      }
      
      private function removeTimeoutBoxes() : void
      {
         var _loc2_:BoxQueueItem = null;
         var _loc1_:int = int(this.boxesArr.length - 1);
         while(_loc1_ >= 0)
         {
            _loc2_ = this.boxesArr[_loc1_] as BoxQueueItem;
            ++_loc2_.currentTime;
            if(_loc2_.currentTime >= _loc2_.timeout)
            {
               this.removeBoxFromStage(_loc2_.box);
            }
            _loc1_--;
         }
         if(this.boxesArr.length == 0)
         {
            TimerManager.getInstance().pauseCallBack(this.removeTimeoutBoxes);
         }
      }
      
      private function closeBoxListener(param1:Event) : void
      {
         var _loc2_:GrowlBox = param1.currentTarget as GrowlBox;
         this.removeBoxFromStage(_loc2_);
      }
      
      public function showMessage(param1:String, param2:String, param3:BitmapData = null, param4:int = 6) : KComponent
      {
         var _loc5_:GrowlBox = new GrowlBox(param3);
         _loc5_.headerText = param1;
         _loc5_.bodyText = param2;
         this.addGrowBoxToStage(_loc5_,param4);
         return _loc5_;
      }
      
      public function addPopUp(param1:KComponent, param2:Boolean = false) : void
      {
         this.animator.animationSpeed = 0.01;
         param1.validateNow();
         param1.alpha = 0;
         if(!contains(param1))
         {
            addChild(param1);
            this.animator.addChild(param1);
         }
         param1.move((root.stage.stageWidth - param1.width) / 2,(root.stage.stageHeight - param1.height) / 2);
         this.animator.targetFor(param1).doNotManageVisibility = true;
         this.animator.targetFor(param1).jumptoPosAfterAdded = false;
         this.animator.setTargets(param1,param1.x,param1.y,param1.width,param1.height,1);
         this.animator.invalidate();
         this.animator.validate();
         if(param2)
         {
            blurBeneath();
         }
      }
      
      public function addGrowBoxToStage(param1:GrowlBox, param2:int = 8) : void
      {
         var _loc3_:Number = NaN;
         var _loc4_:Number = NaN;
         var _loc5_:GrowlBox = null;
         this.animator.animationSpeed = 0.05;
         if(this.boxesArr.length == 0)
         {
            _loc3_ = root.stage.stageWidth - (180 + this.hGap);
            _loc4_ = this.vGap;
         }
         else
         {
            _loc5_ = (this.boxesArr[this.boxesArr.length - 1] as BoxQueueItem).box;
            _loc5_.validateNow();
            if(_loc5_.y + _loc5_.height + (this.vGap + _loc5_.height) > root.stage.stageHeight)
            {
               _loc3_ = _loc5_.x - (this.boxWidth + this.hGap);
               _loc4_ = this.vGap;
            }
            else
            {
               _loc3_ = _loc5_.x;
               _loc4_ = _loc5_.y + _loc5_.height + this.vGap;
            }
         }
         this.boxesArr.push(new BoxQueueItem(param1,param2));
         param1.addEventListener("closeBox",this.closeBoxListener);
         this.addChild(param1);
         param1.alpha = 0;
         param1.move(_loc3_,_loc4_);
         this.animator.addChild(param1);
         this.animator.targetFor(param1).doNotManageVisibility = true;
         this.animator.targetFor(param1).jumptoPosAfterAdded = false;
         this.animator.setTargets(param1,param1.x,param1.y,param1.width,param1.height,1);
         this.animator.invalidate();
         this.animator.validate();
         makeSureOnTop();
         TimerManager.getInstance().resumeCallBack(this.removeTimeoutBoxes);
      }
      
      private function positionFunc() : void
      {
      }
      
      public function removePopUp(param1:KComponent) : void
      {
         removeChild(param1);
         this.animator.removeChild(param1);
         if(blurred)
         {
            unblurBeneath();
         }
      }
      
      public function removeBoxFromStage(param1:GrowlBox) : void
      {
         var i:int;
         var self:GrowlManager = null;
         var item:BoxQueueItem = null;
         var box:GrowlBox = param1;
         if(!box)
         {
            return;
         }
         i = int(this.boxesArr.length - 1);
         while(i >= 0)
         {
            item = this.boxesArr[i] as BoxQueueItem;
            if(item.box == box)
            {
               this.boxesArr.splice(i,1);
               break;
            }
            i--;
         }
         if(!this.animator.targetFor(box))
         {
            return;
         }
         this.animator.targetFor(box).targetAlpha = 0;
         self = this;
         this.animator.targetFor(box).addEventListener(AnimationEvent.ANIMATION_COMPLETE,function(param1:AnimationEvent):void
         {
            if(self.contains(box))
            {
               self.removeChild(box);
               animator.removeChild(box);
            }
         });
         this.animator.validate();
      }
   }
}

class BoxQueueItem
{
   
   public var timeout:int = 8;
   
   public var currentTime:int = 0;
   
   public var box:GrowlBox;
   
   public function BoxQueueItem(param1:GrowlBox, param2:int)
   {
      super();
      this.box = param1;
      this.timeout = param2;
   }
}
