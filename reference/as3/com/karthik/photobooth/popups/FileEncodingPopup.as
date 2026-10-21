package com.karthik.photobooth.popups
{
   import com.karthik.photobooth.managers.GrowlBox;
   import com.karthik.photobooth.screens.bg_removed.SimpleProgressBar;
   
   public class FileEncodingPopup extends GrowlBox
   {
      
      protected var spb:SimpleProgressBar;
      
      protected var _progress:Number = 0;
      
      public function FileEncodingPopup()
      {
         super(GrowlBox.downloadIconBmp);
      }
      
      public function set progress(param1:Number) : void
      {
         if(param1 == this.progress)
         {
            return;
         }
         this._progress = param1;
         this.spb.progress = param1;
      }
      
      override protected function update() : void
      {
         super.update();
         if(wasResized)
         {
            this.spb.setActualSize(120,7);
            this.spb.move((width - 120) / 2,height / 2 + 10);
         }
      }
      
      override protected function createChildren() : void
      {
         super.createChildren();
         this.spb = new SimpleProgressBar();
         addChild(this.spb);
         headerText = "Encoding";
         bodyText = "please wait";
         explicitHeight = 65;
      }
      
      public function get progress() : Number
      {
         return this._progress;
      }
   }
}

