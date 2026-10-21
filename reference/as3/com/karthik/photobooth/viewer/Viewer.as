package com.karthik.photobooth.viewer
{
   import com.karthik.core.KComponent;
   import com.karthik.data.IDataRenderer;
   import com.karthik.photobooth.model.IPhotoItem;
   import com.karthik.photobooth.model.Item1Pic;
   import com.karthik.photobooth.model.Item4Pic;
   
   public class Viewer extends KComponent implements IDataRenderer
   {
      
      protected var _data:IPhotoItem;
      
      protected var view1:View1Pic;
      
      protected var view4:View4Pic;
      
      protected var dataChanged:Boolean = false;
      
      public function Viewer()
      {
         super({
            "width":640,
            "height":480
         });
      }
      
      override protected function createChildren() : void
      {
         this.view4 = new View4Pic();
         this.view1 = new View1Pic();
         addChild(this.view4);
         addChild(this.view1);
         this.view1.visible = false;
         this.view4.visible = false;
      }
      
      public function getViewer4Index() : int
      {
         if(this.view4)
         {
            return this.view4.getStateIndex();
         }
         return -1;
      }
      
      public function get data() : *
      {
         return this._data;
      }
      
      override protected function update() : void
      {
         if(wasResized)
         {
            this.view1.setActualSize(width,height);
            this.view4.setActualSize(width,height);
         }
         if(this.dataChanged)
         {
            this.dataChanged = false;
            if(this.data is Item1Pic)
            {
               this.view1.data = this.data;
               this.view1.visible = true;
               this.view4.visible = false;
            }
            else
            {
               if(!(this.data is Item4Pic))
               {
                  throw new Error("viewer, unsupported data type");
               }
               this.resetViewer4();
               this.view4.data = this.data;
               this.view4.visible = true;
               this.view1.visible = false;
            }
         }
      }
      
      private function resetViewer4() : void
      {
         this.view4.targetState = View4Pic.state_out;
         this.view4.progress = 1;
      }
      
      public function set data(param1:*) : void
      {
         if(param1 == this.data)
         {
            return;
         }
         if(param1 is IPhotoItem)
         {
            this._data = param1 as IPhotoItem;
            this.dataChanged = true;
            invalidate();
            return;
         }
         throw new Error("viewer, data is not an iphotoItem");
      }
   }
}

