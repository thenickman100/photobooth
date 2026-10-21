package com.karthik.photobooth.skins.control_bar.picmode_buttonbar
{
   import com.karthik.managers.Singletons;
   import com.karthik.skins.KButtonSkin;
   import flash.display.BitmapData;
   import flash.geom.Matrix;
   
   public class PicModePic4Skin extends KButtonSkin
   {
      
      private var util:PicModeSkinUtil = Singletons.getInstance(PicModeSkinUtil);
      
      public function PicModePic4Skin()
      {
         super();
      }
      
      override protected function drawDown() : void
      {
         drawRect({
            "target":btn,
            "lineStyle":{"alpha":0},
            "fillStyle":{
               "type":"gradient",
               "colors":[2894892,6579300]
            }
         });
         var _loc1_:BitmapData = this.util.make4PicIcon(4294967295,4281413937);
         drawRect({
            "target":btn,
            "lineStyle":{"alpha":0},
            "fillStyle":{
               "type":"bmp",
               "bmp":_loc1_,
               "matr":new Matrix(1,0,0,1,8,5),
               "repeat":false
            },
            "x":8,
            "y":5,
            "width":_loc1_.width,
            "height":_loc1_.height
         });
      }
      
      override protected function drawOver() : void
      {
         this.drawNormal();
      }
      
      override protected function drawNormal() : void
      {
         drawRect({
            "target":btn,
            "lineStyle":{"alpha":0},
            "fillStyle":{
               "type":"gradient",
               "colors":[16645629,11382189]
            }
         });
         var _loc1_:BitmapData = this.util.make4PicIcon(4278190080,4292664540);
         drawRect({
            "target":btn,
            "lineStyle":{"alpha":0},
            "fillStyle":{
               "type":"bmp",
               "bmp":_loc1_,
               "matr":new Matrix(1,0,0,1,8,5),
               "repeat":false
            },
            "x":8,
            "y":5,
            "width":_loc1_.width,
            "height":_loc1_.height
         });
      }
   }
}

