package com.karthik.photobooth.screens.bg_removed
{
   import com.karthik.core.KComponent;
   import com.karthik.core.KSkin;
   import com.karthik.managers.Singletons;
   
   public class SimpleProgressBar extends KComponent
   {
      
      public var outLineColor:uint;
      
      protected var progressChanged:Boolean = true;
      
      protected var _progress:Number = 0;
      
      public var barColor:uint;
      
      public var skin:KSkin;
      
      public function SimpleProgressBar()
      {
         super({
            "outLineColor":6710886,
            "barColor":6710886,
            "skin":Singletons.getInstance(ProgressBarSkin)
         });
      }
      
      public function set progress(param1:Number) : void
      {
         if(param1 == this._progress)
         {
            return;
         }
         this._progress = param1;
         this.progressChanged = true;
         invalidate();
      }
      
      override protected function update() : void
      {
         if(this.progressChanged)
         {
            this.progressChanged = false;
            this.skin.draw(this);
         }
      }
      
      public function get progress() : Number
      {
         return this._progress;
      }
   }
}

import com.karthik.core.KSkin;
import com.karthik.core.KSprite;

class ProgressBarSkin extends KSkin
{
   
   public function ProgressBarSkin()
   {
      super();
   }
   
   override public function draw(param1:KSprite, param2:Object = null) : void
   {
      var _loc3_:SimpleProgressBar = param1 as SimpleProgressBar;
      drawRect({
         "target":_loc3_,
         "lineStyle":{
            "thickness":1,
            "alpha":1,
            "color":_loc3_.outLineColor
         },
         "fillStyle":null
      });
      var _loc4_:int = Math.round(_loc3_.progress * (_loc3_.width - 2));
      drawRect({
         "target":_loc3_,
         "lineStyle":{"alpha":0},
         "fillStyle":{
            "alpha":1,
            "color":_loc3_.barColor
         },
         "x":1,
         "y":1,
         "width":_loc4_,
         "height":_loc3_.height - 1
      });
   }
}
