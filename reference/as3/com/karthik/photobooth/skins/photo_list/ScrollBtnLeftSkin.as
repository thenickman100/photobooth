package com.karthik.photobooth.skins.photo_list
{
   import com.karthik.core.KSprite;
   import com.karthik.skins.KButtonSkin;
   import flash.filters.DropShadowFilter;
   
   public class ScrollBtnLeftSkin extends KButtonSkin
   {
      
      public function ScrollBtnLeftSkin()
      {
         super();
      }
      
      override protected function drawDisabled() : void
      {
         drawRect({
            "lineStyle":{"alpha":0},
            "fillStyle":{
               "color":14342874,
               "alpha":1
            },
            "target":btn
         });
         this.drawLines(9013641);
         btn.filters = [];
      }
      
      override protected function drawNormal() : void
      {
         drawRect({
            "lineStyle":{"alpha":0},
            "fillStyle":{
               "color":13553358,
               "alpha":1
            },
            "target":btn
         });
         this.drawLines(4605510);
         btn.filters = [];
      }
      
      override public function draw(param1:KSprite, param2:Object = null) : void
      {
         super.draw(param1,param2);
      }
      
      override protected function drawDown() : void
      {
         this.drawNormal();
         this.drawLines(0);
         btn.filters = [new DropShadowFilter(0,0,0,0.8,20,30,1,2,true)];
      }
      
      override protected function drawOver() : void
      {
         this.drawNormal();
      }
      
      private function drawLines(param1:uint) : void
      {
         drawPath({
            "target":btn,
            "lineStyle":{
               "color":15198183,
               "alpha":1,
               "thickness":1
            },
            "fillStyle":null,
            "pts":[[0,0],[btn.width - 1,0]]
         });
         drawPath({
            "target":btn,
            "lineStyle":{
               "color":12171705,
               "alpha":1,
               "thickness":1
            },
            "fillStyle":null,
            "pts":[[0,0],[0,btn.height - 1],[btn.width - 1,btn.height - 1]],
            "closed":false
         });
         drawPath({
            "target":btn,
            "lineStyle":{
               "color":4210752,
               "alpha":1,
               "thickness":1
            },
            "fillStyle":null,
            "pts":[[btn.width - 1,0],[btn.width - 1,btn.height - 1]]
         });
         drawPath({
            "target":btn,
            "lineStyle":{
               "color":4210752,
               "alpha":0,
               "thickness":1
            },
            "fillStyle":{
               "color":param1,
               "alpha":1
            },
            "pts":[[15,42],[15,55],[9,48],[15,42]],
            "closed":true
         });
      }
   }
}

