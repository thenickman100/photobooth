package com.karthik.photobooth.skins.list_item
{
   import com.karthik.core.KSkin;
   import com.karthik.core.KSprite;
   import com.karthik.managers.Singletons;
   import com.karthik.photobooth.model.IPhotoItem;
   import com.karthik.photobooth.photo_list_item.PhotoItem;
   import com.karthik.skins.KButtonSkin;
   import flash.display.*;
   import flash.geom.Matrix;
   
   public class PhotoItemSkin extends KSkin
   {
      
      protected var target:PhotoItem;
      
      public var normalSkin:KButtonSkin = Singletons.getInstance(DeleteButtonSkinVec);
      
      public var gradColor:Array = [16777215,15658734];
      
      public var selectSkin:KButtonSkin = Singletons.getInstance(DeleteButtonSelectedSkinVec);
      
      public function PhotoItemSkin()
      {
         super();
      }
      
      override public function draw(param1:KSprite, param2:Object = null) : void
      {
         this.target = param1 as PhotoItem;
         this.target.label.fontSize = 9;
         var _loc3_:Object = {
            "lineStyle":null,
            "target":this.target,
            "width":this.target.width,
            "height":this.target.height
         };
         clear(this.target.graphics);
         drawRect(_loc3_,{"fillStyle":{
            "type":"gradient",
            "colors":this.gradColor,
            "box":{"rotation":Math.PI / 2}
         }});
         if(this.target.selected)
         {
            drawRoundRect(_loc3_,{
               "fillStyle":{
                  "type":"color",
                  "color":2651099,
                  "alpha":1
               },
               "x":3,
               "y":this.target.height - 20,
               "width":this.target.width - 6,
               "height":15,
               "radius":15
            });
            this.target.button.skin = this.selectSkin;
            this.target.label.fontColor = 16777215;
         }
         else
         {
            this.target.button.skin = this.normalSkin;
            this.target.label.fontColor = 8421504;
         }
         this.target.button.setActualSize(11,12);
         this.target.button.move(5,this.target.height - 18);
         this.target.label.text = this.target.index.toString();
         var _loc4_:Number = this.target.label.getMeasuredWidth();
         var _loc5_:Number = this.target.label.getMeasuredHeight();
         this.target.label.move(this.target.width - _loc4_ - 10,this.target.height - 20);
         var _loc6_:IPhotoItem = this.target.data as IPhotoItem;
         if(!_loc6_)
         {
            return;
         }
         var _loc7_:Array = _loc6_.itemData;
         var _loc8_:BitmapData = new BitmapData(80,60);
         var _loc9_:Number = 80 / 640;
         if(_loc7_.length == 4)
         {
            _loc8_.draw(_loc7_[0] as BitmapData,new Matrix(_loc9_ / 2,0,_loc9_ / 2,0));
            _loc8_.draw(_loc7_[1] as BitmapData,new Matrix(_loc9_ / 2,0,_loc9_ / 2,0,40));
            _loc8_.draw(_loc7_[2] as BitmapData,new Matrix(_loc9_ / 2,0,_loc9_ / 2,0,0,30));
            _loc8_.draw(_loc7_[3] as BitmapData,new Matrix(_loc9_ / 2,0,_loc9_ / 2,0,40,30));
         }
         else
         {
            if(_loc7_.length != 1)
            {
               throw new Error("unkown data length assigned to the PhotoItem\'s data attribute");
            }
            if(!(_loc7_[0] is BitmapData))
            {
               throw new Error("video support not here yet...");
            }
            _loc8_.draw(_loc7_[0] as BitmapData,new Matrix(_loc9_,0,_loc9_,0));
         }
         this.target.graphics.beginBitmapFill(_loc8_);
         this.target.graphics.drawRect(3,3,80,60);
         this.target.graphics.endFill();
      }
   }
}

