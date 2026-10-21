package com.karthik.photobooth.screens.bg_removed
{
   import com.karthik.core.KSkin;
   import com.karthik.managers.Singletons;
   import com.karthik.photobooth.screens.PBJScreen;
   import flash.display.*;
   import flash.filters.ShaderFilter;
   import flash.utils.ByteArray;
   
   public class BGRemovedScreen extends PBJScreen
   {
      
      public static const TYPE:String = "background_remove";
      
      protected var resourceName:String;
      
      protected var background:LoaderScreen;
      
      protected var PbjSource:Class = BGRemovedScreen_PbjSource;
      
      private var isMaxed:Boolean = false;
      
      private var prevWidth:Number = 0;
      
      public var skin:KSkin;
      
      public function BGRemovedScreen(param1:String, param2:String = "background remove")
      {
         super();
         useBgBmp = true;
         this.resourceName = param1;
         effectDirty = false;
         screenName = param2;
         this.skin = Singletons.getInstance(FigureSkin);
      }
      
      override public function set bgBmp(param1:BitmapData) : void
      {
         super.bgBmp = param1;
         bgBitmapChanged = true;
         effectDirty = true;
         invalidate();
      }
      
      override protected function update() : void
      {
         if(width == 640)
         {
            this.isMaxed = true;
         }
         else
         {
            this.isMaxed = false;
         }
         super.update();
         if(effectDirty)
         {
            effectDirty = false;
            this.initBGRemove();
         }
         if(wasResized)
         {
            if(this.background)
            {
               this.background.setActualSize(width,height);
            }
            this.prevWidth = width;
            if(this.isMaxed)
            {
               this.background.playContentMovie();
               canvas.alpha = 1;
            }
            else
            {
               this.background.stopContentMovie();
               this.drawManniquin();
            }
         }
      }
      
      override protected function bmpDraw() : void
      {
         if(this.isMaxed)
         {
            super.bmpDraw();
         }
      }
      
      protected function initBGRemove() : void
      {
         shader.data.bg.input = bgBmp;
         shaderFilter = new ShaderFilter(shader);
         canvas.filters = [shaderFilter];
      }
      
      override protected function createChildren() : void
      {
         this.background = new LoaderScreen(this.resourceName);
         addChild(this.background);
         shader = new Shader(new this.PbjSource() as ByteArray);
         super.createChildren();
      }
      
      protected function drawManniquin() : void
      {
         this.skin.draw(canvas,{
            "width":width,
            "height":height
         });
      }
   }
}

import com.karthik.core.KSkin;
import com.karthik.core.KSprite;

class FigureSkin extends KSkin
{
   
   public function FigureSkin()
   {
      super();
   }
   
   override public function draw(param1:KSprite, param2:Object = null) : void
   {
      var _loc6_:int = 0;
      var _loc7_:int = 0;
      var _loc8_:Array = null;
      var _loc9_:int = 0;
      var _loc10_:int = 0;
      var _loc3_:int = int(param2.width);
      var _loc4_:int = int(param2.height);
      clear(param1);
      var _loc5_:Array = [[12,143],[22,134],[28,131],[34,129],[40,127],[48,124],[57,121],[64,118],[67,116],[70,113],[73,110],[75,107],[74,99],[72,95],[70,91],[69,88],[69,77],[65,77],[64,74],[63,71],[62,68],[62,58],[63,56],[62,54],[61,48],[61,42],[62,36],[63,30],[65,26],[67,22],[69,19],[74,15],[78,13],[83,11],[88,10],[92,9]];
      _loc6_ = int(_loc5_.length);
      _loc7_ = _loc6_ - 1;
      while(_loc7_ >= 0)
      {
         _loc8_ = _loc5_[_loc7_] as Array;
         _loc5_[_loc7_][1] += 1;
         _loc9_ = 193 - _loc8_[0];
         _loc10_ = int(_loc8_[1]);
         _loc5_.push([_loc9_,_loc10_]);
         _loc7_--;
      }
      _loc6_ = int(_loc5_.length);
      var _loc11_:Array = [];
      _loc7_ = 0;
      while(_loc7_ < _loc6_)
      {
         _loc8_ = _loc5_[_loc7_] as Array;
         _loc9_ = int(_loc8_[0]);
         _loc10_ = int(_loc8_[1]);
         _loc9_ = Math.round(_loc3_ / 194 * _loc9_);
         _loc10_ = Math.round(_loc4_ / 144 * _loc10_);
         _loc11_.push([_loc9_,_loc10_]);
         _loc7_++;
      }
      drawPath({
         "target":param1,
         "lineStyle":{"alpha":0},
         "fillStyle":{
            "color":0,
            "alpha":0.7
         },
         "pts":_loc11_,
         "closed":true
      });
   }
}
