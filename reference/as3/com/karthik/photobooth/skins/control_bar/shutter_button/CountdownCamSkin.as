package com.karthik.photobooth.skins.control_bar.shutter_button
{
   import com.karthik.core.KSkin;
   import com.karthik.core.KSprite;
   import com.karthik.photobooth.control_bar.CountDownCam;
   import flash.display.*;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   
   public class CountdownCamSkin extends KSkin
   {
      
      private var alphaLess:BitmapData;
      
      private var alphaMore:BitmapData;
      
      public function CountdownCamSkin()
      {
         super();
         var _loc1_:Sprite = new Sprite();
         this.drawCam(_loc1_.graphics,0.2);
         this.alphaLess = this.bmpFromSprite(_loc1_);
         this.drawCam(_loc1_.graphics,1);
         this.alphaMore = this.bmpFromSprite(_loc1_);
      }
      
      private function fillPixelIfNotNull(param1:int, param2:int, param3:uint) : void
      {
      }
      
      private function drawCam(param1:Graphics, param2:Number) : void
      {
         var _loc7_:Number = NaN;
         var _loc8_:Number = NaN;
         var _loc9_:Number = NaN;
         var _loc10_:Number = NaN;
         var _loc3_:Number = 19;
         param1.clear();
         var _loc4_:Number = Math.PI / 180;
         param1.beginFill(16777215,param2);
         param1.lineStyle(0,0,0);
         param1.moveTo(19,19);
         param1.lineTo(38,19);
         var _loc5_:Number = 0.268;
         var _loc6_:int = 0;
         while(_loc6_ < 12)
         {
            _loc7_ = _loc3_ * Math.cos((_loc6_ + 1) * 30 * _loc4_);
            _loc8_ = _loc3_ * Math.sin((_loc6_ + 1) * 30 * _loc4_);
            _loc9_ = _loc7_ + _loc3_ * _loc5_ * Math.cos(((_loc6_ + 1) * 30 - 90) * _loc4_);
            _loc10_ = _loc8_ + _loc3_ * _loc5_ * Math.sin(((_loc6_ + 1) * 30 - 90) * _loc4_);
            param1.curveTo(_loc9_ + _loc3_,_loc10_ + _loc3_,_loc7_ + _loc3_,_loc8_ + _loc3_);
            _loc6_++;
         }
         param1.moveTo(8,10);
         param1.lineTo(11,10);
         param1.lineTo(13,8);
         param1.lineTo(24,8);
         param1.lineTo(26,10);
         param1.lineTo(29,10);
         param1.lineTo(31,12);
         param1.lineTo(31,26);
         param1.lineTo(29,28);
         param1.lineTo(8,28);
         param1.lineTo(6,26);
         param1.lineTo(6,12);
         param1.lineTo(8,10);
         param1.endFill();
         param1.lineStyle(2,16777215,param2);
         param1.drawCircle(_loc3_,_loc3_,5);
         param1.endFill();
      }
      
      override public function draw(param1:KSprite, param2:Object = null) : void
      {
         var _loc3_:BitmapData = this.alphaLess;
         var _loc4_:Sprite = param2.glowMask;
         clear(param1);
         clear(_loc4_);
         switch((param1 as CountDownCam).state)
         {
            case CountDownCam.STATE_DIM:
               this.drawSprite(param1,this.alphaLess);
               break;
            case CountDownCam.STATE_BRIGHT:
               this.drawSprite(_loc4_,this.alphaMore);
               break;
            case CountDownCam.STATE_1QUAD:
               this.drawSprite(param1,this.alphaLess);
               this.drawSprite(_loc4_,this.makeComp(1));
               break;
            case CountDownCam.STATE_2QUAD:
               this.drawSprite(param1,this.alphaLess);
               this.drawSprite(_loc4_,this.makeComp(2));
               break;
            case CountDownCam.STATE_3QUAD:
               this.drawSprite(param1,this.alphaLess);
               this.drawSprite(_loc4_,this.makeComp(3));
         }
      }
      
      private function getAlpha(param1:uint) : uint
      {
         return param1 >> 24;
      }
      
      private function drawSprite(param1:Sprite, param2:BitmapData) : void
      {
         drawRect({
            "target":param1,
            "width":38,
            "height":38,
            "lineStyle":{"alpha":0},
            "fillStyle":{
               "type":"bmp",
               "bmp":param2
            }
         });
      }
      
      private function bmpFromSprite(param1:Sprite) : BitmapData
      {
         var _loc2_:BitmapData = new BitmapData(38,38,true,0);
         _loc2_.draw(param1);
         return _loc2_;
      }
      
      private function makeComp(param1:int) : BitmapData
      {
         var _loc2_:BitmapData = new BitmapData(38,38,true,0);
         switch(param1)
         {
            case 3:
               _loc2_.copyPixels(this.alphaMore,new Rectangle(19,19,19,19),new Point(19,19));
            case 2:
               _loc2_.copyPixels(this.alphaMore,new Rectangle(19,0,19,19),new Point(19,0));
            case 1:
               _loc2_.copyPixels(this.alphaMore,new Rectangle(0,0,19,19),new Point(0,0));
         }
         return _loc2_;
      }
   }
}

