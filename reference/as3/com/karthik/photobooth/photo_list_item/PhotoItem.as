package com.karthik.photobooth.photo_list_item
{
   import com.karthik.components.Button;
   import com.karthik.components.Label;
   import com.karthik.core.KComponent;
   import com.karthik.core.KSprite;
   import com.karthik.data.IDataRenderer;
   import com.karthik.managers.Singletons;
   import com.karthik.photobooth.skins.list_item.PhotoItemRendererSkin;
   import com.karthik.photobooth.skins.list_item.PhotoItemSkin;
   import flash.events.Event;
   import flash.events.MouseEvent;
   
   public class PhotoItem extends KComponent implements IDataRenderer, ISelectable
   {
      
      private var _selected:Boolean = false;
      
      public var renderSkin:PhotoItemRendererSkin = Singletons.getInstance(PhotoItemRendererSkin);
      
      public var skin:PhotoItemSkin = Singletons.getInstance(PhotoItemSkin);
      
      private var dataDirty:Boolean = false;
      
      private var _data:Object;
      
      private var _index:int = 1;
      
      private var render:KSprite;
      
      private var stateChanged:Boolean = true;
      
      public var button:Button;
      
      public var label:Label;
      
      public function PhotoItem()
      {
         super();
      }
      
      public function set data(param1:*) : void
      {
         if(this._data == param1)
         {
            return;
         }
         this._data = param1;
         this.dataDirty = true;
         invalidate();
      }
      
      override protected function update() : void
      {
         if(this.stateChanged || wasResized)
         {
            this.stateChanged = false;
            this.skin.draw(this);
            this.render.x = 3;
            this.render.y = 3;
            this.render.width = 80;
            this.render.height = 60;
         }
         if(this.dataDirty)
         {
            this.dataDirty = false;
            this.renderSkin.draw(this.render,{"data":this._data});
         }
      }
      
      public function get index() : int
      {
         return this._index;
      }
      
      public function get selected() : Boolean
      {
         return this._selected;
      }
      
      private function btnClickListener(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         dispatchEvent(new Event("delete",true));
      }
      
      override protected function createChildren() : void
      {
         super.createChildren();
         this.button = new Button();
         this.button.addEventListener(MouseEvent.CLICK,this.btnClickListener,false,-40,true);
         this.label = new Label();
         this.render = new KSprite();
         addChild(this.button);
         addChild(this.label);
         addChild(this.render);
      }
      
      public function set index(param1:int) : void
      {
         if(this._index == param1)
         {
            return;
         }
         this._index = param1;
         this.stateChanged = true;
         invalidate();
      }
      
      public function get data() : *
      {
         return this._data;
      }
      
      public function set selected(param1:Boolean) : void
      {
         if(this._selected == param1)
         {
            return;
         }
         this._selected = param1;
         this.stateChanged = true;
         invalidate();
      }
   }
}

