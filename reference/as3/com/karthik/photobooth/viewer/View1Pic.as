package com.karthik.photobooth.viewer
{
   import com.karthik.core.KComponent;
   import com.karthik.data.IDataRenderer;
   import com.karthik.photobooth.model.IPhotoItem;
   import flash.display.*;
   import flash.geom.Matrix;
   
   public class View1Pic extends KComponent implements IDataRenderer
   {
      
      protected var _data:IPhotoItem;
      
      protected var dataChanged:Boolean = true;
      
      public function View1Pic()
      {
         super();
      }
      
      override protected function update() : void
      {
         var _loc1_:BitmapData = null;
         if(wasResized || this.dataChanged)
         {
            this.dataChanged = false;
            if(this._data)
            {
               _loc1_ = this._data.itemData[0];
               graphics.clear();
               graphics.beginBitmapFill(_loc1_,new Matrix(width / _loc1_.width,0,0,height / _loc1_.height));
               graphics.drawRect(0,0,width,height);
            }
         }
      }
      
      public function get data() : *
      {
         return this._data;
      }
      
      public function set data(param1:*) : void
      {
         if(param1 == this.data)
         {
            return;
         }
         if(!(param1 is IPhotoItem))
         {
            throw new Error("view1pic, this is not a IphotoItem");
         }
         this._data = param1 as IPhotoItem;
         this.dataChanged = true;
         invalidate();
      }
   }
}

