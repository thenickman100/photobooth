package com.karthik.photobooth.viewer
{
   import com.karthik.core.KComponent;
   import com.karthik.core.KSkin;
   import com.karthik.data.IDataRenderer;
   import com.karthik.managers.Singletons;
   import com.karthik.managers.TimerManager;
   import com.karthik.photobooth.model.IPhotoItem;
   import flash.display.*;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.filters.BlurFilter;
   import flash.geom.Matrix;
   import flash.geom.PerspectiveProjection;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   
   public class View4Pic extends KComponent implements IDataRenderer
   {
      
      public static const STATE_ZOOMED_IN:Number = 1;
      
      public static const STATE_ZOOMED_OUT:Number = 0;
      
      public static const state_out:State3D = new State3D(400,200,2000,-10,0,-10);
      
      public static const state_br:State3D = new State3D(-10,-10,0,0,0,0);
      
      public static const state_tl:State3D = new State3D(640 + 10,480 + 10,0,0,0,0);
      
      public static const state_tr:State3D = new State3D(-10,480 + 10,0,0,0,0);
      
      public static const state_bl:State3D = new State3D(640 + 10,-10,0,0,0,0);
      
      public var vGap:Number = 20;
      
      private var _data:IPhotoItem;
      
      protected var bmpBL:BitmapData;
      
      private var card:Sprite;
      
      private var offset:Sprite;
      
      protected var bmpBR:BitmapData;
      
      private var shadow:Sprite;
      
      public var progress:Number = 0;
      
      private var rectBL:Rectangle;
      
      protected var dataChanged:Boolean = true;
      
      private var rectBR:Rectangle;
      
      private var needAnotherUpdate:Boolean = true;
      
      protected var bmpTL:BitmapData;
      
      private var jumpNext:Boolean = true;
      
      protected var bmpTR:BitmapData;
      
      protected var largeBmp:BitmapData;
      
      private var current_state:State3D;
      
      public var hGap:Number = 20;
      
      private var sc:Number = 1;
      
      protected var _isZoomed:Boolean;
      
      private var rectTL:Rectangle;
      
      private var rectTR:Rectangle;
      
      private var target_state:State3D;
      
      public var imgH:Number = 480;
      
      protected var _focalLength:Number;
      
      public var imgW:Number = 640;
      
      public var skin:KSkin = Singletons.getInstance(View4PicSkin);
      
      public function View4Pic()
      {
         super({
            "width":640,
            "height":480
         });
         this.rectTL = new Rectangle(20,20,640,480);
         this.rectTR = new Rectangle(640 + 40,20,640,480);
         this.rectBL = new Rectangle(20,480 + 40,640,480);
         this.rectBR = new Rectangle(640 + 40,480 + 40,640,480);
      }
      
      public function set targetState(param1:State3D) : void
      {
         if(param1.equals(this.target_state))
         {
            return;
         }
         this.target_state = param1;
         if(this.target_state.equals(state_out))
         {
            this.isZoomed = true;
         }
         else
         {
            this.isZoomed = false;
         }
         invalidate();
         this.progress = 0;
         this.needAnotherUpdate = true;
      }
      
      override protected function createChildren() : void
      {
         super.createChildren();
         this.card = new Sprite();
         this.shadow = new Sprite();
         this.offset = new Sprite();
         addChild(this.card);
         this.card.addChild(this.shadow);
         this.card.addChild(this.offset);
         this.shadow.mouseEnabled = false;
         this.card.addEventListener(MouseEvent.CLICK,this.cardClickListener);
         this.transform.perspectiveProjection = new PerspectiveProjection();
         this.transform.perspectiveProjection.focalLength = 1200;
         var _loc1_:State3D = state_out;
         this.current_state = _loc1_.clone();
         this.target_state = _loc1_.clone();
      }
      
      public function get targetState() : State3D
      {
         return this.target_state;
      }
      
      private function cardClickListener(param1:MouseEvent) : void
      {
         if(!this.target_state.equals(state_out))
         {
            this.targetState = state_out;
            return;
         }
         if(this.rectTL.contains(param1.localX,param1.localY))
         {
            this.targetState = state_tl;
         }
         else if(this.rectTR.contains(param1.localX,param1.localY))
         {
            this.targetState = state_tr;
         }
         else if(this.rectBL.contains(param1.localX,param1.localY))
         {
            this.targetState = state_bl;
         }
         else if(this.rectBR.contains(param1.localX,param1.localY))
         {
            this.targetState = state_br;
         }
      }
      
      public function getStateIndex() : int
      {
         if(this.targetState.equals(state_tl))
         {
            return 0;
         }
         if(this.targetState.equals(state_tr))
         {
            return 1;
         }
         if(this.targetState.equals(state_bl))
         {
            return 2;
         }
         if(this.targetState.equals(state_br))
         {
            return 3;
         }
         return -1;
      }
      
      public function get data() : *
      {
         return this._data;
      }
      
      override protected function update() : void
      {
         var _loc1_:Number = NaN;
         if(!this.largeBmp)
         {
            return;
         }
         if(wasResized || this.dataChanged)
         {
            this.dataChanged = false;
            this.skin.draw(this);
            scrollRect = new Rectangle(0,0,width,height);
            this.offset.x = -this.largeBmp.width * this.sc / 2;
            this.offset.y = -this.largeBmp.height * this.sc / 2;
            this.shadow.x = this.offset.x;
            this.shadow.y = -this.offset.y;
            this.offset.graphics.clear();
            this.offset.graphics.beginBitmapFill(this.largeBmp,new Matrix(this.sc,0,0,this.sc),false);
            this.offset.graphics.drawRect(0,0,this.largeBmp.width * this.sc,this.largeBmp.height * this.sc);
            this.offset.graphics.clear();
            this.offset.graphics.beginBitmapFill(this.largeBmp,new Matrix(this.sc,0,0,this.sc),false);
            this.offset.graphics.drawRect(0,0,this.largeBmp.width * this.sc,this.largeBmp.height * this.sc);
            _loc1_ = 0.95;
            this.shadow.graphics.clear();
            this.shadow.graphics.beginFill(0,0.5);
            this.shadow.graphics.drawRect(0,-this.largeBmp.height * this.sc * _loc1_,this.largeBmp.width * this.sc * _loc1_,this.largeBmp.height * this.sc * _loc1_);
            this.shadow.rotationZ = 6;
            this.shadow.filters = [new BlurFilter(50,200,1)];
            this.shadow.rotationX = -80;
            this.shadow.z = 10;
         }
         if(this.needAnotherUpdate)
         {
            this.progress += 0.07;
            if(this.progress > 1)
            {
               this.progress = 1;
            }
            this.current_state = this.current_state.interpolateTo(this.target_state,this.progress);
            this.current_state.updateWithState(this.card);
            if(this.current_state.equals(this.target_state))
            {
               this.needAnotherUpdate = false;
            }
         }
         if(this.needAnotherUpdate)
         {
            TimerManager.getInstance().addCallBack(invalidate,20,true,this);
         }
      }
      
      private function makeLarge() : BitmapData
      {
         this.bmpTL = this._data.itemData[0];
         this.bmpTR = this._data.itemData[1];
         this.bmpBL = this._data.itemData[2];
         this.bmpBR = this._data.itemData[3];
         var _loc1_:Number = 2 * this.imgW + 3 * this.hGap;
         var _loc2_:Number = 2 * this.imgH + 3 * this.vGap;
         var _loc3_:BitmapData = new BitmapData(_loc1_,_loc2_);
         _loc3_.floodFill(0,0,4294967295);
         _loc3_.copyPixels(this.bmpTL,this.bmpTL.rect,new Point(this.hGap,this.vGap));
         _loc3_.copyPixels(this.bmpTR,this.bmpTR.rect,new Point(this.hGap * 2 + this.imgW,this.vGap));
         _loc3_.copyPixels(this.bmpBL,this.bmpTL.rect,new Point(this.hGap,this.vGap * 2 + this.imgH));
         _loc3_.copyPixels(this.bmpBR,this.bmpTL.rect,new Point(this.hGap * 2 + this.imgW,this.vGap * 2 + this.imgH));
         return _loc3_;
      }
      
      public function set data(param1:*) : void
      {
         if(this._data == param1)
         {
            return;
         }
         if(!(param1 is IPhotoItem))
         {
            throw new Error("error, data not IPhotoItem");
         }
         this._data = param1;
         this.largeBmp = this.makeLarge();
         this.dataChanged = true;
         invalidate();
      }
      
      public function set isZoomed(param1:Boolean) : void
      {
         if(param1 == this.isZoomed)
         {
            return;
         }
         this._isZoomed = param1;
         dispatchEvent(new Event("zoomStateChange"));
      }
      
      public function get isZoomed() : Boolean
      {
         return this._isZoomed;
      }
   }
}

import com.karthik.core.KSkin;
import com.karthik.core.KSprite;
import flash.geom.Vector3D;

class View4PicSkin extends KSkin
{
   
   public function View4PicSkin()
   {
      super();
   }
   
   override public function draw(param1:KSprite, param2:Object = null) : void
   {
      drawRect({
         "target":param1,
         "lineStyle":null,
         "fillStyle":{
            "type":"gradient",
            "colors":[197379,5263712]
         }
      });
   }
}

class figure3D
{
   
   public var translation:Vector3D;
   
   public var rotation:Vector3D;
   
   public function figure3D(param1:Vector3D)
   {
      super();
   }
}
