package com.karthik.photobooth.screens.bg_removed
{
   import com.karthik.components.Label;
   import com.karthik.core.KComponent;
   import flash.display.DisplayObject;
   import flash.display.Loader;
   import flash.display.MovieClip;
   import flash.events.Event;
   import flash.events.ProgressEvent;
   import flash.net.URLRequest;
   import flash.utils.ByteArray;
   
   public class LoaderScreen extends KComponent
   {
      
      private var imgSrc:String;
      
      protected var _showProgress:Boolean = true;
      
      protected var showProgressChanged:Boolean = true;
      
      private var loaderContent:DisplayObject = null;
      
      private var loader:Loader;
      
      private var lbl:Label;
      
      private var pgBar:SimpleProgressBar;
      
      public function LoaderScreen(param1:String = "")
      {
         super();
         this.imgSrc = param1;
      }
      
      public function loadResource(param1:String) : void
      {
         this.loader = new Loader();
         this.loader.contentLoaderInfo.addEventListener(Event.INIT,this.doneLoading);
         this.loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS,this.loadProgress);
         this.loader.load(new URLRequest(param1));
      }
      
      public function loadBytes(param1:ByteArray) : void
      {
         this.loader = new Loader();
         this.loader.contentLoaderInfo.addEventListener(Event.INIT,this.doneLoading);
         this.loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS,this.loadProgress);
         this.loader.loadBytes(param1);
      }
      
      private function doneLoading(param1:Event) : void
      {
         if(this.loaderContent)
         {
            return;
         }
         this.loaderContent = this.loader.content;
         this.loader.contentLoaderInfo.removeEventListener(Event.INIT,this.doneLoading);
         this.loader.unload();
         addChild(this.loaderContent);
         this.loaderContent.width = width;
         this.loaderContent.height = height;
         this.stopContentMovie();
         dispatchEvent(new Event("loadComplete"));
      }
      
      public function set showProgress(param1:Boolean) : void
      {
         if(param1 == this.showProgress)
         {
            return;
         }
         this._showProgress = param1;
         this.showProgressChanged = true;
         invalidate();
      }
      
      public function playContentMovie() : void
      {
         var _loc1_:MovieClip = null;
         if(this.loaderContent is MovieClip)
         {
            _loc1_ = MovieClip(this.loaderContent);
            _loc1_.gotoAndPlay(1);
         }
      }
      
      override protected function update() : void
      {
         super.update();
         if(this.showProgressChanged)
         {
            this.showProgressChanged = false;
            this.lbl.visible = this.pgBar.visible = this.showProgress;
         }
         if(wasResized)
         {
            graphics.clear();
            graphics.beginFill(3355443);
            graphics.drawRect(0,0,width,height);
            this.lbl.fontColor = 16777215;
            this.lbl.fontSize = 11;
            this.lbl.validateNow();
            this.lbl.move((width - this.lbl.width) / 2 + 18,(height - this.lbl.height) / 2 + 20);
            this.pgBar.setActualSize(120,10);
            this.pgBar.move((width - 120) / 2,(height - 10) / 2);
            if(this.loaderContent)
            {
               this.loaderContent.width = width;
               this.loaderContent.height = height;
            }
         }
      }
      
      public function get showProgress() : Boolean
      {
         return this._showProgress;
      }
      
      private function loadProgress(param1:ProgressEvent) : void
      {
         var _loc2_:Number = param1.bytesLoaded / param1.bytesTotal;
         this.pgBar.progress = _loc2_;
      }
      
      public function stopContentMovie() : void
      {
         var _loc1_:MovieClip = null;
         if(this.loaderContent is MovieClip)
         {
            _loc1_ = MovieClip(this.loaderContent);
            _loc1_.gotoAndStop(1);
         }
      }
      
      override protected function createChildren() : void
      {
         this.lbl = new Label();
         this.lbl.text = "Loading...";
         addChild(this.lbl);
         this.pgBar = new SimpleProgressBar();
         addChild(this.pgBar);
         if(this.imgSrc != "")
         {
            this.loadResource(this.imgSrc);
         }
      }
   }
}

