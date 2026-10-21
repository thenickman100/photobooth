package com.karthik.photobooth.screens.bg_removed
{
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.net.FileFilter;
   import flash.net.FileReference;
   
   public class UploadBgScreen extends BGRemovedScreen
   {
      
      public static const TYPE:String = "upload";
      
      protected var file:FileReference;
      
      protected var bgLoaded:Boolean = false;
      
      public function UploadBgScreen()
      {
         addEventListener(MouseEvent.CLICK,this.clickListener);
         super("","Click to upload image");
      }
      
      protected function doneLoading(param1:Event) : void
      {
         this.bgLoaded = true;
         this.labelVisible = false;
      }
      
      override protected function positionLabel() : void
      {
         label.validateNow();
         label.move((width - label.getMeasuredWidth()) / 2,(height - label.getMeasuredHeight()) / 2);
      }
      
      protected function fileSelectListener(param1:Event) : void
      {
         this.file.addEventListener(Event.COMPLETE,this.fileOpenListener);
         this.file.load();
         trace("called FILE LOAD");
      }
      
      protected function fileOpenListener(param1:Event) : void
      {
         trace("in FILE OPEN HANDLER");
         background.loadBytes(this.file.data);
         background.addEventListener("loadComplete",this.doneLoading);
      }
      
      override protected function createChildren() : void
      {
         super.createChildren();
         background.showProgress = false;
      }
      
      protected function clickListener(param1:MouseEvent) : void
      {
         if(this.bgLoaded)
         {
            return;
         }
         param1.stopImmediatePropagation();
         this.file = new FileReference();
         this.file.addEventListener(Event.SELECT,this.fileSelectListener);
         this.file.browse([new FileFilter("All Formats (*.jpg,*.gif,*.png,*.swf)","*.jpg;*.gif;*.png;*.swf","JPEG;jp2_;GIFF;SWFL")]);
      }
      
      override public function set labelVisible(param1:Boolean) : void
      {
         if(this.bgLoaded)
         {
            super.labelVisible = false;
         }
         else
         {
            super.labelVisible = param1;
         }
      }
      
      override protected function createLabel() : void
      {
         super.createLabel();
      }
   }
}

