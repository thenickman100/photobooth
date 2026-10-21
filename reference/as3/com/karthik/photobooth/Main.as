package com.karthik.photobooth
{
   import com.karthik.components.Button;
   import com.karthik.components.Label;
   import com.karthik.core.KComponent;
   import com.karthik.core.KSkin;
   import com.karthik.data.arraycollection_events.CollectionEvent;
   import com.karthik.managers.Singletons;
   import com.karthik.managers.TimerManager;
   import com.karthik.photobooth.control_bar.ControlBar;
   import com.karthik.photobooth.control_bar.EffectsButton;
   import com.karthik.photobooth.events.ModeChangeEvent;
   import com.karthik.photobooth.events.PhotoItemEvent;
   import com.karthik.photobooth.image.ASJPEGEncoder;
   import com.karthik.photobooth.image.Resizer;
   import com.karthik.photobooth.image.events.JPEGEncodeEvent;
   import com.karthik.photobooth.managers.GrowlBox;
   import com.karthik.photobooth.managers.GrowlManager;
   import com.karthik.photobooth.model.IPhotoItem;
   import com.karthik.photobooth.model.Item1Pic;
   import com.karthik.photobooth.model.Item4Pic;
   import com.karthik.photobooth.photo_list_item.LeftScrollBtn;
   import com.karthik.photobooth.photo_list_item.RightScrollBtn;
   import com.karthik.photobooth.popups.FileCompleteBox;
   import com.karthik.photobooth.popups.FileEncodingPopup;
   import com.karthik.photobooth.popups.Flasher;
   import com.karthik.photobooth.skins.MainSkin;
   import com.karthik.photobooth.viewer.Viewer;
   import com.karthik.photobooth.web_interface.FacebookAuthPop;
   import com.karthik.photobooth.web_interface.FacebookUploadPop;
   import com.karthik.photobooth.web_interface.FlickrAuthPop;
   import com.karthik.photobooth.web_interface.FlickrUploadPop;
   import com.karthik.webapis.events.WSConnectionEvent;
   import com.karthik.webapis.events.WSLoginEvent;
   import com.karthik.webapis.events.WSUploadEvent;
   import com.karthik.webapis.facebook.Facebook;
   import com.karthik.webapis.flickr.Flickr;
   import flash.display.*;
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.events.MouseEvent;
   import flash.media.Camera;
   import flash.net.FileReference;
   import flash.utils.ByteArray;
   
   public class Main extends KComponent
   {
      
      public static const FLASHER_SPEED:Number = 0.2;
      
      public var scrollRightBtn:Button;
      
      public var viewer:Viewer;
      
      protected var numPhotosChanged:Boolean = false;
      
      private var encoder:ASJPEGEncoder;
      
      private var isEncoding:Boolean = false;
      
      protected var _numPhotos:int = 0;
      
      private var model:Model;
      
      public var flasher:Flasher;
      
      private var fileReference:FileReference;
      
      protected var fb:Facebook;
      
      protected var fk:Flickr;
      
      public var scrollLeftBtn:Button;
      
      protected var title:Label;
      
      public var photoSizeLabel:Label;
      
      public var photoList:PhotoList;
      
      public var screen:ScreenContainer;
      
      public var controlBar:ControlBar;
      
      private var skin:KSkin = Singletons.getInstance(MainSkin);
      
      public function Main()
      {
         super({
            "width":642,
            "height":684
         });
         this.encoder = new ASJPEGEncoder();
         this.model = Singletons.getInstance(Model);
         this.model.addEventListener("modeChange",this.model_modeChangeListener);
         this.model.addEventListener("screenHScrollChange",this.model_screenHScrollChangeListener);
         this.model.addEventListener("picModeChange",this.model_picModeChangeListener);
         this.model.addEventListener("selectedPhotoChange",this.model_selectedPhotoChangeListener);
         this.model.photos.addEventListener(CollectionEvent.COLLECTION_CHANGE,this.model_photos_collectionChangeListener);
         this.fileReference = new FileReference();
         this.fileReference.addEventListener(Event.COMPLETE,this.saveCompleteListener);
         this.fileReference.addEventListener(Event.CANCEL,this.saveCancelListener);
         this.fileReference.addEventListener(IOErrorEvent.IO_ERROR,this.saveIOErrorListener);
         this.fb = new Facebook({
            "apiKey":"02de8b14c885de9b97857bc314cabbf6",
            "secret":"REDACTED"
         });
         this.fk = new Flickr({
            "apiKey":"c38fef085c38ef41106be4cae81c1f7f",
            "secret":"REDACTED"
         });
      }
      
      private function ctrlbar_doFlashListener(param1:Event) : void
      {
         this.flasher.value = FLASHER_SPEED;
         this.flasherUp();
      }
      
      private function ctrlbar_changeScrollListener(param1:Event) : void
      {
         this.model.effectScreenHScroll = this.controlBar.scrollIndex;
      }
      
      private function photoList_photoDeleteListener(param1:PhotoItemEvent) : void
      {
         var _loc2_:int = param1.index;
         this.model.photos.removeItemAt(_loc2_);
         if(_loc2_ == this.model.selectedPhotoIndex)
         {
            this.model.selectedPhotoIndex = -1;
            if(this.model.photos.length > _loc2_)
            {
               this.model.selectedPhotoIndex = _loc2_;
               this.photoList.selectedIndex = _loc2_;
            }
            else if(this.model.photos.length > 0)
            {
               this.model.selectedPhotoIndex = this.model.photos.length - 1;
               this.photoList.selectedIndex = this.model.selectedPhotoIndex;
            }
            else
            {
               this.model.mainState = Model.MODE_PIC;
            }
         }
      }
      
      private function photoList_dropCompleteListener(param1:Event) : void
      {
         if(this.model.mainState == Model.MODE_VIEWER)
         {
            this.model.mainState = Model.MODE_PIC;
         }
      }
      
      private function startImageEncode(param1:SaveQueueItem, param2:Function) : void
      {
         var box:FileEncodingPopup = null;
         var progressListener:Function = null;
         var completeListener:Function = null;
         var item:SaveQueueItem = param1;
         var onComplete:Function = param2;
         this.isEncoding = true;
         box = new FileEncodingPopup();
         GrowlManager.getInstance().addGrowBoxToStage(box,int.MAX_VALUE);
         progressListener = function(param1:JPEGEncodeEvent):void
         {
            box.progress = param1.progress;
         };
         completeListener = function(param1:JPEGEncodeEvent):void
         {
            isEncoding = false;
            GrowlManager.getInstance().removeBoxFromStage(box);
            encoder.removeEventListener(JPEGEncodeEvent.EVENT_COMPLETE,completeListener);
            encoder.removeEventListener(JPEGEncodeEvent.EVENT_PROGRESS,progressListener);
            onComplete.call(this,param1.completedEncode);
         };
         this.encoder.addEventListener(JPEGEncodeEvent.EVENT_PROGRESS,progressListener);
         this.encoder.addEventListener(JPEGEncodeEvent.EVENT_COMPLETE,completeListener);
         this.encoder.startEncode(item.bmp);
      }
      
      private function getSaveQueuItemFromViewer() : SaveQueueItem
      {
         var _loc2_:SaveQueueItem = null;
         var _loc4_:BitmapData = null;
         var _loc7_:Item1Pic = null;
         var _loc8_:Item4Pic = null;
         var _loc1_:IPhotoItem = this.model.photos.getItemAt(this.model.selectedPhotoIndex) as IPhotoItem;
         var _loc3_:Date = new Date();
         var _loc5_:String = "";
         var _loc6_:* = _loc3_.fullYear + "-" + _loc3_.month + "-" + _loc3_.day + "(" + _loc3_.hours + "-" + _loc3_.minutes + "-" + _loc3_.seconds + ").jpg";
         _loc2_ = new SaveQueueItem();
         if(_loc1_ is Item1Pic)
         {
            _loc7_ = _loc1_ as Item1Pic;
            _loc4_ = _loc7_.itemData[0];
            _loc5_ = "YourPhoto_";
         }
         else if(_loc1_ is Item4Pic)
         {
            _loc8_ = _loc1_ as Item4Pic;
            if(this.viewer.getViewer4Index() == -1)
            {
               _loc5_ = "FourPic_";
               _loc4_ = _loc8_.getComposite();
            }
            else if(this.viewer.getViewer4Index() == 0)
            {
               _loc5_ = "TopLeft_";
               _loc4_ = _loc8_.itemData[0];
            }
            else if(this.viewer.getViewer4Index() == 1)
            {
               _loc5_ = "TopRight_";
               _loc4_ = _loc8_.itemData[1];
            }
            else if(this.viewer.getViewer4Index() == 2)
            {
               _loc5_ = "BottomLeft_";
               _loc4_ = _loc8_.itemData[2];
            }
            else
            {
               if(this.viewer.getViewer4Index() != 3)
               {
                  throw new Error("should not be here in ctrlbar_downloadPictureListener");
               }
               _loc5_ = "BottomRight_";
               _loc4_ = _loc8_.itemData[3];
            }
         }
         _loc2_.bmp = _loc4_;
         _loc2_.fileName = _loc5_ + _loc6_;
         return _loc2_;
      }
      
      private function scr_screenModeChangeListener(param1:Event) : void
      {
         if(this.screen.selectedIndex == -1)
         {
            this.model.mainState = Model.MODE_EFFECTS;
         }
         else
         {
            this.model.mainState = Model.MODE_PIC;
         }
      }
      
      private function flasherUp() : void
      {
         if(this.flasher.value != 0)
         {
            if(this.flasher.value < 1)
            {
               this.flasher.value += FLASHER_SPEED;
               TimerManager.getInstance().addCallBack(this.flasherUp,20,true,this);
            }
            else
            {
               TimerManager.getInstance().addCallBack(this.flasherDown,20,true,this);
            }
         }
      }
      
      override protected function createChildren() : void
      {
         this.title = new Label();
         this.title.text = "Karthik\'s PictureBooth";
         this.title.fontSize = 11;
         this.title.fontColor = 3355443;
         addChild(this.title);
         this.screen = new ScreenContainer();
         this.screen.dataProvider = this.model.screens;
         if(Camera.getCamera() != null)
         {
            this.screen.camera = Camera.getCamera();
         }
         this.screen.addEventListener("modeChange",this.scr_screenModeChangeListener);
         addChild(this.screen);
         this.screen.move(1,23);
         this.viewer = new Viewer();
         addChild(this.viewer);
         this.viewer.move(1,23);
         this.viewer.visible = false;
         this.controlBar = new ControlBar();
         addChild(this.controlBar);
         this.controlBar.move(1,504);
         this.controlBar.addEventListener("modeChange",this.ctrlbar_screenModeChangeListener);
         this.controlBar.addEventListener("leftScroll",this.ctrlbar_leftScrollListener);
         this.controlBar.addEventListener("rightScroll",this.ctrlbar_rightScrollListener);
         this.controlBar.addEventListener("changeScroll",this.ctrlbar_changeScrollListener);
         this.controlBar.addEventListener("doTakePic",this.ctlbar_takePicListener);
         this.controlBar.addEventListener("picModeChange",this.ctrlbar_picModeChangeListener);
         this.controlBar.addEventListener("goPicMode",this.ctrlbar_goPicModeListener);
         this.controlBar.addEventListener("downloadPicture",this.ctrlbar_downloadPictureListener);
         this.controlBar.addEventListener("facebookPicture",this.ctrlbar_facebookPictureListener);
         this.controlBar.addEventListener("flickrPicture",this.ctrlbar_flickrPictureListener);
         this.controlBar.addEventListener("doFlash",this.ctrlbar_doFlashListener);
         this.photoList = new PhotoList();
         addChild(this.photoList);
         this.photoList.move(27,564);
         this.photoList.addEventListener("dropComplete",this.photoList_dropCompleteListener);
         this.photoList.addEventListener("photoSelect",this.photoList_photoSelectListener);
         this.photoList.addEventListener("photoDelete",this.photoList_photoDeleteListener);
         this.photoList.addEventListener("hScrollChanged",this.photoList_scrollChangedListener);
         this.photoList.addEventListener("maxHScrollChanged",this.photoList_maxHScrollChangedListener);
         this.syncAllFromModel();
         this.scrollLeftBtn = new LeftScrollBtn();
         this.scrollRightBtn = new RightScrollBtn();
         addChild(this.scrollLeftBtn);
         addChild(this.scrollRightBtn);
         this.scrollLeftBtn.move(1,564);
         this.scrollRightBtn.move(640 - 25,564);
         this.scrollLeftBtn.addEventListener(MouseEvent.CLICK,this.photoList_scrollLeftClickListener);
         this.scrollRightBtn.addEventListener(MouseEvent.CLICK,this.photoList_scrollRightClickListener);
         this.photoSizeLabel = new Label();
         addChild(this.photoSizeLabel);
      }
      
      private function model_screenHScrollChangeListener(param1:Event) : void
      {
         this.screen.hScrollPosition = this.model.effectScreenHScroll;
         this.controlBar.scrollIndex = this.model.effectScreenHScroll;
      }
      
      private function model_picModeChangeListener(param1:Event) : void
      {
      }
      
      private function model_selectedPhotoChangeListener(param1:Event) : void
      {
         if(this.model.selectedPhotoIndex != -1)
         {
            this.viewer.data = this.model.photos.getItemAt(this.model.selectedPhotoIndex);
         }
      }
      
      public function get numPhotos() : int
      {
         return this._numPhotos;
      }
      
      private function ctrlbar_screenModeChangeListener(param1:ModeChangeEvent) : void
      {
         param1.stopPropagation();
         if(param1.targetMode == EffectsButton.MODE_EFFECTS)
         {
            this.model.mainState = Model.MODE_EFFECTS;
         }
         else
         {
            this.model.mainState = Model.MODE_PIC;
         }
      }
      
      private function saveCancelListener(param1:Event) : void
      {
         GrowlManager.getInstance().showMessage("Canceled","You canceled the save, but you can save again.",null,3);
         this.isEncoding = false;
      }
      
      private function saveCompleteListener(param1:Event) : void
      {
         GrowlManager.getInstance().showMessage("Save Complete","File Successfully saved.",null,3);
         this.isEncoding = false;
      }
      
      private function updateScrollBtnState() : void
      {
         if(this.photoList.hScrollPosition >= this.photoList.maxHScroll)
         {
            this.scrollRightBtn.disabled = true;
         }
         else
         {
            this.scrollRightBtn.disabled = false;
         }
         if(this.photoList.hScrollPosition == 0)
         {
            this.scrollLeftBtn.disabled = true;
         }
         else
         {
            this.scrollLeftBtn.disabled = false;
         }
      }
      
      private function ctrlbar_facebookPictureListener(param1:Event) : void
      {
         var fb_initiateUpload:Function;
         var encoding_CompleteListener:Function;
         var showUploadPopup:Function;
         var isUploading:Boolean;
         var item:SaveQueueItem = null;
         var popupAuth:FacebookAuthPop = null;
         var popupUpload:FacebookUploadPop = null;
         var loginBox:KComponent = null;
         var connectBox:KComponent = null;
         var getSessionBox:KComponent = null;
         var uploadBox:KComponent = null;
         var imageData:ByteArray = null;
         var popup_loginClickListener:Function = null;
         var popupUL_uploadClickListener:Function = null;
         var popup_authClickListener:Function = null;
         var fb_loginListener:Function = null;
         var fb_uploadCompleteListener:Function = null;
         var fb_connectListener:Function = null;
         var e:Event = param1;
         if(this.isEncoding)
         {
            this.showEncodingMsg();
            return;
         }
         item = this.getSaveQueuItemFromViewer();
         isUploading = false;
         popup_loginClickListener = function(param1:Event):void
         {
            fb.openAuthWindow(fb.auth_loginURL());
         };
         popupUL_uploadClickListener = function(param1:Event):void
         {
            if(getSessionBox)
            {
               GrowlManager.getInstance().removeBoxFromStage(getSessionBox as GrowlBox);
            }
            GrowlManager.getInstance().removePopUp(popupUpload);
            fb_initiateUpload();
         };
         popup_authClickListener = function(param1:Event):void
         {
            fb.addEventListener(WSLoginEvent.TYPE_LOGIN,fb_loginListener);
            fb.auth_getSession();
         };
         fb_loginListener = function(param1:WSLoginEvent):void
         {
            fb.removeEventListener(WSLoginEvent.TYPE_LOGIN,fb_loginListener);
            GrowlManager.getInstance().removePopUp(popupAuth);
            if(!param1.success)
            {
               GrowlManager.getInstance().showMessage("Authentication Failed","Seems to be a network problem or you disabled cookies");
               return;
            }
            if(loginBox)
            {
               GrowlManager.getInstance().removeBoxFromStage(loginBox as GrowlBox);
            }
            getSessionBox = GrowlManager.getInstance().showMessage("Authenticated","Now click on the Upload button to upload your photo");
            showUploadPopup();
         };
         showUploadPopup = function():void
         {
            popupUpload = new FacebookUploadPop();
            popupUpload.addEventListener("uploadClick",popupUL_uploadClickListener);
            GrowlManager.getInstance().addPopUp(popupUpload,true);
         };
         fb_initiateUpload = function():void
         {
            fb.addEventListener(WSUploadEvent.TYPE_UPLOAD,fb_uploadCompleteListener);
            uploadBox = GrowlManager.getInstance().showMessage("Uploading","Uploading your photo to facebook now, will take a while to complete");
            fb.uploadPhoto(item.fileName,imageData);
         };
         fb_uploadCompleteListener = function(param1:WSUploadEvent):void
         {
            GrowlManager.getInstance().removeBoxFromStage(uploadBox as GrowlBox);
            fb.removeEventListener(WSUploadEvent.TYPE_UPLOAD,fb_uploadCompleteListener);
            if(param1.success)
            {
               GrowlManager.getInstance().showMessage("Uploading Success","Your photo has been uploaded to facebook, its now under the \'pending albums\' section of your facebook photos.");
            }
            else
            {
               GrowlManager.getInstance().showMessage("Uploading Failed","An error occured during your upload, please check your network connection. If you are sure your network is fine, file a bug report with me");
            }
         };
         fb_connectListener = function(param1:WSConnectionEvent):void
         {
            fb.removeEventListener(WSConnectionEvent.TYPE_CONNECTION,fb_connectListener);
            GrowlManager.getInstance().removeBoxFromStage(connectBox as GrowlBox);
            loginBox = GrowlManager.getInstance().showMessage("Connected!","Connection to facebook established, please login!");
            popupAuth = new FacebookAuthPop();
            GrowlManager.getInstance().addPopUp(popupAuth,true);
            popupAuth.addEventListener("loginClick",popup_loginClickListener);
            popupAuth.addEventListener("authClick",popup_authClickListener);
         };
         encoding_CompleteListener = function(param1:Object):void
         {
            imageData = param1 as ByteArray;
            if(!fb.hasSession)
            {
               fb.addEventListener(WSConnectionEvent.TYPE_CONNECTION,fb_connectListener);
               fb.auth_createToken();
               connectBox = GrowlManager.getInstance().showMessage("Connecting","Connecting to facebook, please wait");
            }
            else
            {
               showUploadPopup();
            }
         };
         item.bmp = Resizer.resizeToFacebook(item.bmp);
         this.startImageEncode(item,encoding_CompleteListener);
      }
      
      private function ctlbar_takePicListener(param1:Event) : void
      {
         var _loc2_:BitmapData = null;
         var _loc3_:Item1Pic = null;
         var _loc4_:Item4Pic = null;
         if(this.model.picMode == Model.PIC_MODE_1PIC)
         {
            _loc2_ = this.screen.getScreenShot();
            _loc3_ = new Item1Pic(_loc2_);
            this.model.photos.addItem(_loc3_);
            this.model.selectedPhotoIndex = this.model.photos.length - 1;
            this.viewer.data = this.model.photos.getItemAt(this.model.selectedPhotoIndex);
            this.model.mainState = Model.MODE_VIEWER;
         }
         else
         {
            if(this.model.picMode != Model.PIC_MODE_4_PIC)
            {
               throw new Error("unknown pic mode, currently only support 1pic and 4pic");
            }
            _loc2_ = this.screen.getScreenShot();
            this.model.pic4Buffer.push(_loc2_);
            if(this.model.pic4Buffer.length == 4)
            {
               _loc4_ = new Item4Pic(this.model.pic4Buffer[0],this.model.pic4Buffer[1],this.model.pic4Buffer[2],this.model.pic4Buffer[3]);
               this.model.photos.addItem(_loc4_);
               this.model.pic4Buffer = [];
               this.model.selectedPhotoIndex = this.model.photos.length - 1;
               this.viewer.data = this.model.photos.getItemAt(this.model.selectedPhotoIndex);
               this.model.mainState = Model.MODE_VIEWER;
            }
         }
      }
      
      private function syncAllFromModel() : void
      {
         this.screen.dataProvider = this.model.screens;
         this.photoList.dataProvider = this.model.photos;
      }
      
      private function downloadItem(param1:SaveQueueItem) : void
      {
         var encodingCompleteListener:Function;
         var compBox:FileCompleteBox = null;
         var item:SaveQueueItem = param1;
         if(this.isEncoding)
         {
            return;
         }
         compBox = new FileCompleteBox();
         encodingCompleteListener = function(param1:Object):void
         {
            var data:Object = param1;
            GrowlManager.getInstance().addPopUp(compBox,true);
            compBox.button.addEventListener(MouseEvent.CLICK,function(param1:MouseEvent):void
            {
               fileReference.save(data,item.fileName);
               GrowlManager.getInstance().removePopUp(compBox);
            });
         };
         this.startImageEncode(item,encodingCompleteListener);
      }
      
      private function saveIOErrorListener(param1:IOErrorEvent) : void
      {
         GrowlManager.getInstance().showMessage("Error!","There seem to be an error writing the file, is your harddrive full? try filing a bug report or email me.");
         this.isEncoding = false;
      }
      
      private function photoList_scrollRightClickListener(param1:MouseEvent) : void
      {
         if(this.scrollRightBtn.disabled)
         {
            return;
         }
         if(this.photoList)
         {
            this.photoList.scrollRight();
         }
      }
      
      override protected function update() : void
      {
         if(wasResized)
         {
            this.skin.draw(this);
            this.title.validateNow();
            this.title.move((width - this.title.getMeasuredWidth()) / 2,2);
            this.positionLabel();
         }
         if(this.numPhotosChanged)
         {
            this.numPhotosChanged = false;
            this.positionLabel();
         }
      }
      
      private function ctrlbar_downloadPictureListener(param1:Event) : void
      {
         if(this.isEncoding)
         {
            this.showEncodingMsg();
            return;
         }
         this.downloadItem(this.getSaveQueuItemFromViewer());
      }
      
      private function model_photos_collectionChangeListener(param1:CollectionEvent) : void
      {
         this.numPhotos = this.model.photos.length;
      }
      
      public function set numPhotos(param1:int) : void
      {
         if(param1 == this._numPhotos)
         {
            return;
         }
         this._numPhotos = param1;
         this.numPhotosChanged = true;
         invalidate();
      }
      
      private function photoList_photoSelectListener(param1:PhotoItemEvent) : void
      {
         this.model.selectedPhotoIndex = param1.index;
         this.model.mainState = Model.MODE_VIEWER;
         this.updateScrollBtnState();
      }
      
      private function ctrlbar_flickrPictureListener(param1:Event) : void
      {
         var encoding_CompleteListener:Function;
         var showUploadPopup:Function;
         var isUploading:Boolean;
         var fk_initiateUpload:Function;
         var item:SaveQueueItem = null;
         var popupAuth:FlickrAuthPop = null;
         var popupUpload:FlickrUploadPop = null;
         var loginBox:KComponent = null;
         var connectBox:KComponent = null;
         var getSessionBox:KComponent = null;
         var uploadBox:KComponent = null;
         var imageData:ByteArray = null;
         var popup_loginClickListener:Function = null;
         var popupUL_uploadClickListener:Function = null;
         var popup_authClickListener:Function = null;
         var fk_loginListener:Function = null;
         var fk_uploadCompleteListener:Function = null;
         var fk_connectListener:Function = null;
         var e:Event = param1;
         if(this.isEncoding)
         {
            this.showEncodingMsg();
            return;
         }
         item = this.getSaveQueuItemFromViewer();
         isUploading = false;
         popup_loginClickListener = function(param1:Event):void
         {
            fk.openAuthWindow(fk.auth_loginURL());
         };
         popupUL_uploadClickListener = function(param1:Event):void
         {
            if(getSessionBox)
            {
               GrowlManager.getInstance().removeBoxFromStage(getSessionBox as GrowlBox);
            }
            GrowlManager.getInstance().removePopUp(popupUpload);
            fk_initiateUpload();
         };
         popup_authClickListener = function(param1:Event):void
         {
            fk.addEventListener(WSLoginEvent.TYPE_LOGIN,fk_loginListener);
            fk.auth_getToken();
         };
         fk_loginListener = function(param1:WSLoginEvent):void
         {
            fk.removeEventListener(WSLoginEvent.TYPE_LOGIN,fk_loginListener);
            GrowlManager.getInstance().removePopUp(popupAuth);
            if(!param1.success)
            {
               GrowlManager.getInstance().showMessage("Authentication Failed","Seems to be a network problem or you disabled cookies");
               return;
            }
            if(loginBox)
            {
               GrowlManager.getInstance().removeBoxFromStage(loginBox as GrowlBox);
            }
            getSessionBox = GrowlManager.getInstance().showMessage("Authenticated","Now click on the Upload button to upload your photo");
            showUploadPopup();
         };
         showUploadPopup = function():void
         {
            popupUpload = new FlickrUploadPop();
            popupUpload.addEventListener("uploadClick",popupUL_uploadClickListener);
            GrowlManager.getInstance().addPopUp(popupUpload,true);
         };
         fk_initiateUpload = function():void
         {
            fk.addEventListener(WSUploadEvent.TYPE_UPLOAD,fk_uploadCompleteListener);
            uploadBox = GrowlManager.getInstance().showMessage("Uploading","Uploading your photo to Flickr now, will take a while to complete");
            fk.uploadPhoto(item.fileName,imageData);
         };
         fk_uploadCompleteListener = function(param1:WSUploadEvent):void
         {
            GrowlManager.getInstance().removeBoxFromStage(uploadBox as GrowlBox);
            fk.removeEventListener(WSUploadEvent.TYPE_UPLOAD,fk_uploadCompleteListener);
            if(param1.success)
            {
               GrowlManager.getInstance().showMessage("Uploading Success","Your photo has been uploaded to Flickr, its now in your flickr album");
            }
            else
            {
               GrowlManager.getInstance().showMessage("Uploading Failed","An error occured during your upload, please check your network connection. If you are sure your network is fine, file a bug report with me");
            }
         };
         fk_connectListener = function(param1:WSConnectionEvent):void
         {
            fk.removeEventListener(WSConnectionEvent.TYPE_CONNECTION,fk_connectListener);
            GrowlManager.getInstance().removeBoxFromStage(connectBox as GrowlBox);
            loginBox = GrowlManager.getInstance().showMessage("Connected!","Connection to flickr established, please login!");
            popupAuth = new FlickrAuthPop();
            GrowlManager.getInstance().addPopUp(popupAuth,true);
            popupAuth.addEventListener("loginClick",popup_loginClickListener);
            popupAuth.addEventListener("authClick",popup_authClickListener);
         };
         encoding_CompleteListener = function(param1:Object):void
         {
            imageData = param1 as ByteArray;
            if(!fk.hasToken())
            {
               fk.addEventListener(WSConnectionEvent.TYPE_CONNECTION,fk_connectListener);
               fk.auth_getFrob();
               connectBox = GrowlManager.getInstance().showMessage("Connecting","Connecting to flickr, please wait");
            }
            else
            {
               showUploadPopup();
            }
         };
         this.startImageEncode(item,encoding_CompleteListener);
      }
      
      private function positionLabel() : void
      {
         var _loc1_:String = this.numPhotos > 1 ? "Photos" : "Photo";
         this.photoSizeLabel.text = this.numPhotos.toString() + " " + _loc1_;
         this.photoSizeLabel.fontSize = 10;
         this.photoSizeLabel.fontColor = 3750201;
         this.photoSizeLabel.validateNow();
         var _loc2_:Number = this.photoSizeLabel.getMeasuredWidth();
         var _loc3_:Number = this.photoSizeLabel.getMeasuredHeight();
         this.photoSizeLabel.setActualSize(_loc2_,_loc3_ + 3);
         this.photoSizeLabel.move((width - _loc2_) / 2,height - _loc3_ - 5);
      }
      
      private function model_modeChangeListener(param1:Event) : void
      {
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         if(this.model.mainState == Model.MODE_PIC)
         {
            this.screen.visible = true;
            this.viewer.visible = false;
            _loc2_ = this.model.effectScreenHScroll * 9;
            _loc3_ = _loc2_ + 8;
            if(this.screen.selectedIndex == -1)
            {
               _loc4_ = this.screen.lastSelectedIndex;
               if(_loc4_ < _loc2_ || _loc4_ > _loc3_)
               {
                  _loc4_ = _loc2_ + 4;
               }
               this.screen.selectedIndex = _loc4_;
            }
            this.controlBar.mode = ControlBar.MODE_PIC;
            this.photoList.selectedIndex = -1;
         }
         else if(this.model.mainState == Model.MODE_EFFECTS)
         {
            this.screen.visible = true;
            this.viewer.visible = false;
            this.screen.selectedIndex = -1;
            this.controlBar.mode = ControlBar.MODE_EFFECTS;
         }
         else if(this.model.mainState == Model.MODE_VIEWER)
         {
            this.viewer.visible = true;
            this.screen.visible = false;
            this.controlBar.mode = ControlBar.MODE_VIEWER;
         }
      }
      
      private function ctrlbar_goPicModeListener(param1:Event) : void
      {
         this.model.mainState = Model.MODE_PIC;
      }
      
      private function ctrlbar_leftScrollListener(param1:Event) : void
      {
         param1.stopPropagation();
         --this.model.effectScreenHScroll;
      }
      
      private function photoList_maxHScrollChangedListener(param1:Event) : void
      {
         this.updateScrollBtnState();
      }
      
      private function ctrlbar_rightScrollListener(param1:Event) : void
      {
         param1.stopPropagation();
         this.model.effectScreenHScroll += 1;
      }
      
      private function flasherDown() : void
      {
         if(this.flasher.value > 0)
         {
            this.flasher.value -= FLASHER_SPEED;
            TimerManager.getInstance().addCallBack(this.flasherDown,20,true,this);
         }
      }
      
      private function showEncodingMsg() : void
      {
         GrowlManager.getInstance().showMessage("Patience","Encoding the current image, please wait till this one is done first before initiating operations for the next image.",null,2);
      }
      
      private function photoList_scrollLeftClickListener(param1:MouseEvent) : void
      {
         if(this.scrollLeftBtn.disabled)
         {
            return;
         }
         if(this.photoList)
         {
            this.photoList.scrollLeft();
         }
      }
      
      private function ctrlbar_picModeChangeListener(param1:Event) : void
      {
         switch(this.controlBar.takingPicType)
         {
            case ControlBar.TAKING_PIC_1PIC:
               this.model.picMode = Model.PIC_MODE_1PIC;
               break;
            case ControlBar.TAKING_PIC_4PIC:
               this.model.picMode = Model.PIC_MODE_4_PIC;
         }
      }
      
      private function photoList_scrollChangedListener(param1:Event) : void
      {
         this.updateScrollBtnState();
      }
   }
}

import flash.display.BitmapData;

class SaveQueueItem
{
   
   public var bmp:BitmapData;
   
   public var fileName:String;
   
   public function SaveQueueItem()
   {
      super();
   }
}
