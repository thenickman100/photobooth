package com.karthik.core
{
   import com.karthik.lang.HashUtil;
   import flash.display.*;
   import flash.geom.Matrix;
   
   public class KSkin
   {
      
      private var bmpOpts:Object = {
         "bmp":new BitmapData(100,100),
         "matr":new Matrix(),
         "repeat":true
      };
      
      private var cirOpts:Object = {
         "x":0,
         "y":0
      };
      
      private var gradOpts:Object = {
         "type":"gradient",
         "kind":GradientType.LINEAR,
         "spread":SpreadMethod.PAD,
         "colors":[16777215,0],
         "alphas":[1,1],
         "ratios":[0,255],
         "box":{"rotation":Math.PI / 2}
      };
      
      private var rectOpts:Object = {
         "x":0,
         "y":0
      };
      
      private var roundRectOpts:Object = {
         "x":0,
         "y":0
      };
      
      private var drawOpts:Object = {
         "lineStyle":{
            "thickness":1,
            "color":0,
            "alpha":1,
            "hint":true
         },
         "fillStyle":{
            "type":"color",
            "color":0,
            "alpha":0.5
         }
      };
      
      private var ptsOpts:Object = {
         "pts":[[0,0],[10,0],[10,10],[0,10]],
         "closed":true
      };
      
      public function KSkin()
      {
         super();
      }
      
      public function draw(param1:KSprite, param2:Object = null) : void
      {
      }
      
      public function drawRect(... rest) : void
      {
         var _loc2_:Object = HashUtil.mergeHash(this.drawOpts,this.rectOpts,HashUtil.mergeHashArr(rest));
         var _loc3_:Sprite = _loc2_.target as Sprite;
         var _loc4_:Object = {
            "width":_loc3_.width,
            "height":_loc3_.height
         };
         _loc2_ = HashUtil.mergeHash(_loc4_,_loc2_);
         var _loc5_:Graphics = this.initializeGraphics(_loc2_);
         _loc5_.drawRect(_loc2_.x,_loc2_.y,_loc2_.width,_loc2_.height);
         _loc5_.endFill();
      }
      
      public function drawPath(... rest) : void
      {
         var _loc2_:Object = HashUtil.mergeHash(this.drawOpts,this.ptsOpts,HashUtil.mergeHashArr(rest));
         var _loc3_:Sprite = _loc2_.target as Sprite;
         var _loc4_:Graphics = this.initializeGraphics(_loc2_);
         var _loc5_:Array = _loc2_.pts;
         var _loc6_:Boolean = Boolean(_loc2_.closed);
         var _loc7_:Array = _loc5_[0] as Array;
         _loc4_.moveTo(_loc7_[0],_loc7_[1]);
         var _loc8_:int = 1;
         while(_loc8_ < _loc5_.length)
         {
            _loc4_.lineTo(_loc5_[_loc8_][0],_loc5_[_loc8_][1]);
            _loc8_++;
         }
         if(_loc6_)
         {
            _loc4_.lineTo(_loc7_[0],_loc7_[1]);
            _loc4_.endFill();
         }
      }
      
      public function drawKRoundRect(... rest) : void
      {
         var _loc2_:Object = HashUtil.mergeHash(this.drawOpts,this.roundRectOpts,HashUtil.mergeHashArr(rest));
         var _loc3_:Sprite = _loc2_.target as Sprite;
         var _loc4_:Object = {
            "width":_loc3_.width,
            "height":_loc3_.height
         };
         _loc2_ = HashUtil.mergeHash(_loc4_,_loc2_);
         var _loc5_:Graphics = this.initializeGraphics(_loc2_);
         var _loc6_:Number = Number(_loc2_.x);
         var _loc7_:Number = Number(_loc2_.y);
         var _loc8_:Number = Number(_loc2_.width);
         var _loc9_:Number = Number(_loc2_.height);
         var _loc10_:Number = Number(_loc2_.radius);
         _loc8_--;
         if(_loc2_.faceUp)
         {
            _loc5_.moveTo(_loc6_,_loc7_);
            _loc5_.lineTo(_loc6_ + _loc8_,_loc7_);
         }
         else
         {
            _loc5_.moveTo(_loc6_ + _loc10_,_loc7_);
            _loc5_.lineTo(_loc6_ + _loc8_ - _loc10_,_loc7_);
            _loc5_.curveTo(_loc6_ + _loc8_,_loc7_,_loc6_ + _loc8_,_loc7_ + _loc10_);
         }
         if(_loc2_.faceDown)
         {
            _loc5_.lineTo(_loc6_ + _loc8_,_loc7_ + _loc9_);
            _loc5_.lineTo(_loc6_,_loc7_ + _loc9_);
         }
         else
         {
            _loc5_.lineTo(_loc6_ + _loc8_,_loc7_ + _loc9_ - _loc10_);
            _loc5_.curveTo(_loc6_ + _loc8_,_loc7_ + _loc9_,_loc6_ + _loc8_ - _loc10_,_loc7_ + _loc9_);
            _loc5_.lineTo(_loc6_ + _loc10_,_loc7_ + _loc9_);
            _loc5_.curveTo(_loc6_,_loc7_ + _loc9_,_loc6_,_loc7_ + _loc9_ - _loc10_);
         }
         if(_loc2_.faceUp)
         {
            _loc5_.lineTo(_loc6_,_loc7_);
         }
         else
         {
            _loc5_.lineTo(_loc6_,_loc7_ + _loc10_);
            _loc5_.curveTo(_loc6_,_loc7_,_loc6_ + _loc10_,_loc7_);
         }
         _loc5_.endFill();
      }
      
      public function clear(... rest) : void
      {
         var _loc2_:Object = null;
         for each(_loc2_ in rest)
         {
            if(_loc2_ is Graphics)
            {
               (_loc2_ as Graphics).clear();
            }
            else if(_loc2_ is Sprite)
            {
               (_loc2_ as Sprite).graphics.clear();
            }
         }
      }
      
      public function drawCircle(... rest) : void
      {
         var _loc2_:Object = HashUtil.mergeHash(this.drawOpts,this.cirOpts,HashUtil.mergeHashArr(rest));
         var _loc3_:Sprite = _loc2_.target as Sprite;
         var _loc4_:Number = Math.min(_loc3_.width,_loc3_.height) / 2;
         var _loc5_:Object = {
            "radius":_loc4_,
            "x":_loc4_,
            "y":_loc4_
         };
         _loc2_ = HashUtil.mergeHash(_loc5_,_loc2_);
         var _loc6_:Graphics = this.initializeGraphics(_loc2_);
         _loc6_.drawCircle(_loc2_.x,_loc2_.y,_loc2_.radius);
      }
      
      public function drawRoundRect(... rest) : void
      {
         var _loc2_:Object = HashUtil.mergeHash(this.drawOpts,this.roundRectOpts,HashUtil.mergeHashArr(rest));
         var _loc3_:Sprite = _loc2_.target as Sprite;
         var _loc4_:Object = {
            "width":_loc3_.width,
            "height":_loc3_.height
         };
         _loc2_ = HashUtil.mergeHash(_loc4_,_loc2_);
         var _loc5_:Graphics = this.initializeGraphics(_loc2_);
         _loc5_.drawRoundRect(_loc2_.x,_loc2_.y,_loc2_.width,_loc2_.height,_loc2_.radius);
      }
      
      private function initializeGraphics(param1:Object) : Graphics
      {
         var _loc4_:Object = null;
         var _loc5_:Object = null;
         var _loc6_:Matrix = null;
         var _loc2_:Sprite = param1.target as Sprite;
         var _loc3_:Graphics = (param1.target as Sprite).graphics;
         if(param1.lineStyle)
         {
            _loc4_ = param1.lineStyle;
            _loc3_.lineStyle(_loc4_.thickness,_loc4_.color,_loc4_.alpha,_loc4_.hint);
         }
         if(param1.fillStyle)
         {
            _loc5_ = param1.fillStyle;
            switch(_loc5_.type)
            {
               case "gradient":
                  _loc5_ = HashUtil.mergeHash(this.gradOpts,{"box":{
                     "width":_loc2_.width,
                     "height":_loc2_.height,
                     "x":0,
                     "y":0
                  }},_loc5_);
                  _loc6_ = new Matrix();
                  _loc6_.createGradientBox(_loc5_.box.width,_loc5_.box.height,_loc5_.box.rotation,_loc5_.box.x,_loc5_.box.y);
                  _loc3_.beginGradientFill(_loc5_.kind,_loc5_.colors,_loc5_.alphas,_loc5_.ratios,_loc6_,_loc5_.spread);
                  break;
               case "bmp":
                  _loc5_ = HashUtil.mergeHash(this.bmpOpts,_loc5_);
                  _loc3_.beginBitmapFill(_loc5_.bmp,_loc5_.matr,_loc5_.repeat);
                  break;
               default:
                  _loc3_.beginFill(_loc5_.color,_loc5_.alpha);
            }
         }
         return _loc3_;
      }
   }
}

