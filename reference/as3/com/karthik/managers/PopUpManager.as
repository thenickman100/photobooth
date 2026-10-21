package com.karthik.managers
{
   import com.karthik.core.KComponent;
   import flash.display.Sprite;
   
   public class PopUpManager extends KComponent
   {
      
      protected var _root:Sprite;
      
      protected var blurred:Boolean = false;
      
      public function PopUpManager()
      {
         super();
      }
      
      public function initialize(param1:Sprite) : void
      {
         this._root = param1;
         param1.addChild(this);
      }
      
      protected function makeSureOnTop() : void
      {
         if(this._root.getChildIndex(this) < this._root.numChildren - 1)
         {
            this._root.setChildIndex(this,this._root.numChildren - 1);
         }
      }
      
      protected function blurBeneath() : void
      {
         graphics.clear();
         graphics.beginFill(16777215,0.4);
         graphics.drawRect(0,0,root.stage.stageWidth,root.stage.stageHeight);
         this.blurred = true;
      }
      
      protected function unblurBeneath() : void
      {
         graphics.clear();
         this.blurred = false;
      }
   }
}

