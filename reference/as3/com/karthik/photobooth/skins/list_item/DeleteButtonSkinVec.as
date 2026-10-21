package com.karthik.photobooth.skins.list_item
{
   import com.karthik.skins.KButtonSkin;
   
   public class DeleteButtonSkinVec extends KButtonSkin
   {
      
      public function DeleteButtonSkinVec()
      {
         super();
      }
      
      override protected function drawOver() : void
      {
         this.drawDeleteBtn(6710886,13948116,1048575);
      }
      
      override protected function drawNormal() : void
      {
         this.drawDeleteBtn(11711154,15329769,16777215);
      }
      
      protected function drawDeleteBtn(param1:uint, param2:uint, param3:uint) : void
      {
         drawCircle({
            "target":btn,
            "radius":5.5,
            "x":5.5,
            "y":6.5,
            "lineStyle":{"alpha":0},
            "fillStyle":{
               "color":param2,
               "alpha":1
            }
         });
         drawCircle({
            "target":btn,
            "radius":5.5,
            "x":5.5,
            "y":5.5,
            "lineStyle":{"alpha":0},
            "fillStyle":{
               "color":param1,
               "alpha":1
            }
         });
         drawPath({
            "target":btn,
            "lineStyle":{
               "thickness":1,
               "color":param3,
               "alpha":1
            },
            "fillStyle":null,
            "pts":[[3,3],[7,7]]
         });
         drawPath({
            "target":btn,
            "lineStyle":{
               "thickness":1,
               "color":param3,
               "alpha":1
            },
            "fillStyle":null,
            "pts":[[3,7],[7,3]]
         });
      }
      
      override protected function drawDown() : void
      {
         this.drawDeleteBtn(3289650,13092807,11382189);
      }
   }
}

