package com.karthik.photobooth
{
   import com.karthik.core.KComponent;
   import com.karthik.core.KSkin;
   import com.karthik.data.ArrayCollection;
   import com.karthik.data.ClassFactory;
   import com.karthik.data.IDataRenderer;
   import com.karthik.data.arraycollection_events.CollectionEvent;
   import com.karthik.managers.AnimationEvent;
   import com.karthik.managers.KState;
   import com.karthik.managers.LayoutAnimator;
   import com.karthik.managers.Singletons;
   import com.karthik.managers.TimerManager;
   import com.karthik.photobooth.events.PhotoItemEvent;
   import com.karthik.photobooth.photo_list_item.ISelectable;
   import com.karthik.photobooth.photo_list_item.ItemFactory;
   import com.karthik.photobooth.photo_list_item.PhotoItem;
   import com.karthik.photobooth.skins.PhotoListSkin;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.filters.BitmapFilter;
   import flash.filters.DropShadowFilter;
   import flash.geom.Rectangle;
   import flash.utils.Dictionary;
   
   public class PhotoList extends KComponent
   {
      
      private var renderers:Dictionary = new Dictionary(true);
      
      private var _dataProvider:ArrayCollection;
      
      private var defaultOptions:Object = {
         "skin":Singletons.getInstance(PhotoListSkin),
         "itemFilter":new DropShadowFilter(0,0,0,0.8,8,8,1,1),
         "padLeft":5,
         "width":588,
         "height":98,
         "padTop":4,
         "itemWidth":86,
         "itemHeight":88,
         "itemFactory":Singletons.getInstance(ItemFactory),
         "hGap":6
      };
      
      public var itemHeight:Number;
      
      private var renderersDirty:Boolean = false;
      
      private var _itemFactory:ClassFactory;
      
      private var _maxHScrollPosition:Number = 0;
      
      public var padLeft:Number;
      
      public var padTop:Number;
      
      private var dataDirty:Boolean = false;
      
      public var hGap:Number;
      
      private var selectedItem:KComponent;
      
      private var _hScrollPosition:Number = 0;
      
      private var animator:LayoutAnimator = new LayoutAnimator(this);
      
      private var pendingItems:ArrayCollection;
      
      public var itemFilter:BitmapFilter;
      
      public var itemWidth:Number;
      
      private var _selectedIndex:Number;
      
      public var skin:KSkin;
      
      public function PhotoList(param1:Object = null)
      {
         this.animator.animationSpeed = 0.05;
         this.animator.positionFunc = this.positionItems;
         super(param1);
      }
      
      private function removeRenderer(param1:KComponent) : void
      {
         param1.removeEventListener(MouseEvent.CLICK,this.itemClickListener);
         removeChild(param1);
         this.animator.removeChild(param1);
         this.renderers[param1] = null;
         delete this.renderers[param1];
      }
      
      private function addRenderer(param1:KComponent, param2:int) : void
      {
         param1.addEventListener(MouseEvent.CLICK,this.itemClickListener);
         param1.addEventListener("delete",this.itemDeleteListener);
         if(this.itemFilter)
         {
            param1.filters = [this.itemFilter];
         }
         (param1 as PhotoItem).index = param2 + 1;
         this.renderers[param1] = param2;
         addChild(param1);
         this.animator.addChild(param1);
      }
      
      private function itemClickListener(param1:MouseEvent) : void
      {
         var _loc2_:KComponent = param1.currentTarget as KComponent;
         this.selectedIndex = this.renderers[_loc2_];
      }
      
      private function getLeftGap() : Number
      {
         var _loc1_:Number = width - (this.padLeft + (this.hGap + this.itemWidth) * this.numRenderers());
         if(_loc1_ < this.padLeft)
         {
            _loc1_ = 0;
         }
         return _loc1_;
      }
      
      private function positionItems() : void
      {
         var _loc2_:Object = null;
         var _loc3_:KComponent = null;
         var _loc4_:Number = NaN;
         var _loc5_:Number = NaN;
         var _loc1_:Number = this.getLeftGap();
         for(_loc2_ in this.renderers)
         {
            _loc3_ = _loc2_ as KComponent;
            _loc4_ = Number(this.renderers[_loc3_]);
            _loc5_ = _loc1_ + this.padLeft + (this.hGap + this.itemWidth) * _loc4_ - this._hScrollPosition;
            this.animator.setTargets(_loc3_,_loc5_,this.padTop,this.itemWidth,this.itemHeight);
         }
      }
      
      public function get hScrollPosition() : Number
      {
         return this._hScrollPosition;
      }
      
      private function numRenderers() : Number
      {
         if(this._dataProvider)
         {
            return this._dataProvider.length;
         }
         if(this.pendingItems)
         {
            return this.pendingItems.length;
         }
         return 0;
      }
      
      private function rendererAtIndex(param1:Number) : KComponent
      {
         var _loc2_:Object = null;
         for(_loc2_ in this.renderers)
         {
            if(this.renderers[_loc2_] == param1)
            {
               return _loc2_ as KComponent;
            }
         }
         return null;
      }
      
      private function scrollTillLeftMostIs(param1:KComponent) : void
      {
         var _loc2_:KState = this.rendererAtIndexState(this.renderers[param1]);
         var _loc3_:Number = this._hScrollPosition + (_loc2_.x - this.padLeft);
         var _loc4_:Number = this.maxHScroll;
         this.hScrollPosition = _loc3_ > _loc4_ ? _loc4_ : _loc3_;
      }
      
      public function get dataProvider() : ArrayCollection
      {
         return this._dataProvider;
      }
      
      public function set hScrollPosition(param1:Number) : void
      {
         if(this._hScrollPosition == param1)
         {
            return;
         }
         this._hScrollPosition = param1;
         dispatchEvent(new Event("hScrollChanged"));
         this.animator.invalidate();
         invalidate();
      }
      
      private function scrollTillRightMostIs(param1:KComponent) : void
      {
         var _loc2_:KState = this.rendererAtIndexState(this.renderers[param1]);
         var _loc3_:Number = this._hScrollPosition - (width - (_loc2_.x + _loc2_.width + this.padLeft));
         this.hScrollPosition = _loc3_ < 0 ? 0 : _loc3_;
      }
      
      override protected function update() : void
      {
         super.update();
         if(wasResized)
         {
            scrollRect = new Rectangle(0,0,width,height);
            this.skin.draw(this);
         }
         this.animator.validate();
      }
      
      override protected function commitProperties() : void
      {
         var _loc1_:KComponent = null;
         var _loc2_:Object = null;
         var _loc3_:int = 0;
         if(this.dataDirty)
         {
            this.dataDirty = false;
            if(this._dataProvider)
            {
               this._dataProvider.removeEventListener(CollectionEvent.COLLECTION_CHANGE,this.itemChangeListener);
            }
            this._dataProvider = this.pendingItems;
            this.pendingItems = null;
            this.renderersDirty = true;
         }
         if(this.renderersDirty)
         {
            if(this._dataProvider == null)
            {
               return;
            }
            this.renderersDirty = false;
            for(_loc2_ in this.renderers)
            {
               _loc1_ = _loc2_ as KComponent;
               this.removeRenderer(_loc1_);
            }
            if(!this._itemFactory)
            {
               return;
            }
            _loc3_ = 0;
            while(_loc3_ < this._dataProvider.length)
            {
               _loc1_ = this._itemFactory.newInstance() as KComponent;
               (_loc1_ as IDataRenderer).data = this._dataProvider.getItemAt(_loc3_);
               this.addRenderer(_loc1_,_loc3_);
               _loc3_++;
            }
            this.animator.invalidate();
            invalidate();
            this.computeMaxHScroll();
         }
      }
      
      public function scrollRight() : void
      {
         var _loc1_:Number = Math.min(this.maxHScroll,this.hScrollPosition + width);
         this.hScrollPosition = _loc1_;
      }
      
      public function get maxHScroll() : Number
      {
         return this._maxHScrollPosition;
      }
      
      private function rendererAtIndexState(param1:Number) : KState
      {
         return new KState(this.getLeftGap() + this.padLeft + (this.hGap + this.itemWidth) * param1 - this._hScrollPosition,this.padTop,this.itemWidth,this.itemHeight,1);
      }
      
      override protected function getDefaultOption() : Object
      {
         return this.defaultOptions;
      }
      
      private function dispatchDropComplete() : void
      {
         dispatchEvent(new Event("dropComplete"));
      }
      
      private function computeMaxHScroll() : Number
      {
         var _loc1_:Number = 0;
         if(this._dataProvider == null || this._dataProvider.length == 0)
         {
            _loc1_ = 0;
         }
         else if(this.getLeftGap() > 0)
         {
            _loc1_ = 0;
         }
         else
         {
            _loc1_ = 2 * this.padLeft + (this.hGap + this.itemWidth) * this.numRenderers() - this.hGap - width;
         }
         if(_loc1_ != this._maxHScrollPosition)
         {
            this._maxHScrollPosition = _loc1_;
            dispatchEvent(new Event("maxHScrollChanged"));
         }
         return this._maxHScrollPosition;
      }
      
      public function set selectedIndex(param1:Number) : void
      {
         if(param1 == -1 && this._selectedIndex == -1)
         {
            return;
         }
         if(param1 == -1 && this.selectedItem != null)
         {
            (this.selectedItem as ISelectable).selected = false;
            this._selectedIndex = -1;
            this.selectedItem = null;
            return;
         }
         var _loc2_:KComponent = this.rendererAtIndex(param1);
         if(_loc2_ == this.selectedItem)
         {
            this._selectedIndex = param1;
            return;
         }
         if(this.selectedItem)
         {
            (this.selectedItem as ISelectable).selected = false;
         }
         (_loc2_ as ISelectable).selected = true;
         this.selectedItem = _loc2_;
         this._selectedIndex = param1;
         var _loc3_:PhotoItemEvent = new PhotoItemEvent(PhotoItemEvent.TYPE_PHOTO_SELECT);
         _loc3_.index = this.renderers[_loc2_];
         dispatchEvent(_loc3_);
         if(_loc2_.x < this.padLeft)
         {
            this.scrollTillRightMostIs(_loc2_);
         }
         if(_loc2_.x + _loc2_.width + this.padLeft > width)
         {
            this.scrollTillLeftMostIs(_loc2_);
         }
      }
      
      public function set itemFactory(param1:ClassFactory) : void
      {
         if(this._itemFactory == param1)
         {
            return;
         }
         this._itemFactory = param1;
         this.renderersDirty = true;
         invalidate();
         this.animator.invalidate();
      }
      
      public function set dataProvider(param1:ArrayCollection) : void
      {
         if(param1 == this._dataProvider)
         {
            return;
         }
         param1.addEventListener(CollectionEvent.COLLECTION_CHANGE,this.itemChangeListener,false,-10,true);
         this.pendingItems = param1;
         this.renderersDirty = true;
         this.dataDirty = true;
         invalidate();
         this.animator.invalidate();
      }
      
      public function get selectedIndex() : Number
      {
         return this.renderers[this.selectedItem];
      }
      
      private function itemDeleteListener(param1:Event) : void
      {
         var _loc2_:KComponent = param1.currentTarget as KComponent;
         var _loc3_:int = int(this.renderers[_loc2_]);
         var _loc4_:PhotoItemEvent = new PhotoItemEvent(PhotoItemEvent.TYPE_PHOTO_DELETE);
         _loc4_.index = _loc3_;
         dispatchEvent(_loc4_);
      }
      
      public function scrollLeft() : void
      {
         var _loc1_:Number = Math.max(0,this.hScrollPosition - width);
         this.hScrollPosition = _loc1_;
      }
      
      private function itemChangeListener(param1:CollectionEvent) : void
      {
         var index:int = 0;
         var r:KComponent = null;
         var item:Object = null;
         var self:Object = null;
         var onComplete:Function = null;
         var firstR:KComponent = null;
         var pos:KState = null;
         var o:Object = null;
         var i:Number = NaN;
         var e:CollectionEvent = param1;
         if(e.kind == CollectionEvent.TYPE_ADD)
         {
            index = e.index;
            item = e.item;
            r = this._itemFactory.newInstance() as KComponent;
            (r as IDataRenderer).data = item;
            self = this;
            onComplete = function(param1:AnimationEvent):void
            {
               TimerManager.getInstance().addCallBack(dispatchDropComplete,1.3,true,self);
               computeMaxHScroll();
               if(param1)
               {
                  param1.currentTarget.removeEventListener(AnimationEvent.ANIMATION_COMPLETE,onComplete);
               }
               var _loc2_:KState = rendererAtIndexState(index);
               addRenderer(r,index);
               r.move(_loc2_.x,-_loc2_.height);
               r.setActualSize(_loc2_.width,_loc2_.height);
               animator.targetFor(r).jumptoPosAfterAdded = false;
               animator.invalidate();
               invalidate();
            };
            if(this._dataProvider.length == 1)
            {
               onComplete(null);
            }
            else
            {
               firstR = this.rendererAtIndex(0);
               this.animator.targetFor(firstR).addEventListener(AnimationEvent.ANIMATION_COMPLETE,onComplete);
               pos = this.rendererAtIndexState(index);
               if(pos.x + pos.width + this.padLeft > width)
               {
                  this.hScrollPosition += pos.x + pos.width + this.padLeft - width;
               }
               this.animator.invalidate();
               invalidate();
            }
         }
         else if(e.kind == CollectionEvent.TYPE_REMOVE)
         {
            index = e.index;
            r = this.rendererAtIndex(index);
            this.removeRenderer(r);
            if(index < this._dataProvider.length)
            {
               for(o in this.renderers)
               {
                  i = Number(this.renderers[o]);
                  if(i > index)
                  {
                     this.renderers[o] = i - 1;
                     (o as PhotoItem).index = i - 1 + 1;
                  }
               }
            }
            this.computeMaxHScroll();
            if(this.hScrollPosition > this.maxHScroll)
            {
               this.hScrollPosition = this.maxHScroll;
            }
            this.animator.invalidate();
            invalidate();
         }
         else
         {
            this.renderersDirty = true;
            this.dataDirty = true;
            this.animator.invalidate();
            invalidate();
         }
      }
   }
}

