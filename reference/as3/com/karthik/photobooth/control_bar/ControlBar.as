package com.karthik.photobooth.control_bar
{
   import com.karthik.components.Button;
   import com.karthik.components.Label;
   import com.karthik.core.KComponent;
   import com.karthik.core.KSkin;
   import com.karthik.managers.Singletons;
   import com.karthik.managers.TimerManager;
   import com.karthik.photobooth.skins.control_bar.ControlBarSkin;
   import com.karthik.photobooth.skins.control_bar.services.DLBtnSkin;
   import com.karthik.photobooth.skins.control_bar.services.FBBtnSkin;
   import com.karthik.photobooth.skins.control_bar.services.FlickrBtnSkin;
   import com.karthik.photobooth.skins.control_bar.services.PicasaBtnSkin;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.filters.GlowFilter;
   
   public class ControlBar extends KComponent
   {
      
      public static const MODE_PIC:int = 1;
      
      public static const MODE_EFFECTS:int = 2;
      
      public static const MODE_TAKING_PIC:int = 5;
      
      public static const MODE_VIEWER:int = 3;
      
      public static const MODE_TAKING_VIDEO:int = 4;
      
      public static const TAKING_PIC_1PIC:int = 0;
      
      public static const TAKING_PIC_4PIC:int = 1;
      
      protected var _mode:int = 1;
      
      protected var modeChanged:Boolean = true;
      
      private var lblFacebook:Label;
      
      private var lblFlickr:Label;
      
      private var btnPicasa:Button;
      
      private var btnDownload:Button;
      
      protected var scrollChanged:Boolean = true;
      
      private var lblPicasa:Label;
      
      public var shutterBtn:ShutterButton;
      
      public var picModeButtonBar:PicModeButtonBar;
      
      private const wordGlow:GlowFilter = new GlowFilter(16777215,0.7,20,20,4,3);
      
      public var lbl1:Label;
      
      public var lbl3:Label;
      
      public var countDownCam:CountDownCam;
      
      protected var _takeinPicStage:int = -1;
      
      protected var _takingPicType:int = 0;
      
      public var sb1:DumbDotButton;
      
      public var sb2:DumbDotButton;
      
      public var sb3:DumbDotButton;
      
      public var sb4:DumbDotButton;
      
      protected var _scrollIndex:int = 0;
      
      private var btnFacebook:Button;
      
      private var btnFlickr:Button;
      
      public var lbl2:Label;
      
      private var lblDownload:Label;
      
      public var efBtn:EffectsButton;
      
      public var skin:KSkin;
      
      public function ControlBar()
      {
         super({
            "width":640,
            "height":59
         });
         this.skin = Singletons.getInstance(ControlBarSkin);
      }
      
      public function set takingPicType(param1:int) : void
      {
         if(param1 == this.takingPicType)
         {
            return;
         }
         this._takingPicType = param1;
         dispatchEvent(new Event("picModeChange"));
      }
      
      public function get scrollIndex() : int
      {
         return this._scrollIndex;
      }
      
      public function set scrollIndex(param1:int) : void
      {
         if(param1 == this.scrollIndex)
         {
            return;
         }
         this._scrollIndex = param1;
         this.scrollChanged = true;
         invalidate();
      }
      
      override protected function createChildren() : void
      {
         super.createChildren();
         this.efBtn = new EffectsButton();
         addChild(this.efBtn);
         this.shutterBtn = new ShutterButton();
         this.shutterBtn.addEventListener(MouseEvent.CLICK,this.shutterClickListener);
         addChild(this.shutterBtn);
         this.lbl1 = new Label();
         this.lbl2 = new Label();
         this.lbl3 = new Label();
         addChild(this.lbl1);
         addChild(this.lbl2);
         addChild(this.lbl3);
         this.configLabelInitState();
         this.countDownCam = new CountDownCam();
         this.countDownCam.visible = false;
         addChild(this.countDownCam);
         this.sb1 = new DumbDotButton();
         this.sb2 = new DumbDotButton();
         this.sb3 = new DumbDotButton();
         this.sb4 = new DumbDotButton();
         this.sb1.addEventListener(MouseEvent.CLICK,this.scroll1Listener);
         this.sb2.addEventListener(MouseEvent.CLICK,this.scroll2Listener);
         this.sb3.addEventListener(MouseEvent.CLICK,this.scroll3Listener);
         this.sb4.addEventListener(MouseEvent.CLICK,this.scroll4Listener);
         this.sb1.visible = this.sb2.visible = this.sb3.visible = this.sb4.visible = false;
         addChild(this.sb1);
         addChild(this.sb2);
         addChild(this.sb3);
         addChild(this.sb4);
         this.picModeButtonBar = new PicModeButtonBar();
         this.picModeButtonBar.move(15,17);
         this.picModeButtonBar.addEventListener("picModeChange",this.picModeChangeListener);
         addChild(this.picModeButtonBar);
         this.btnDownload = new Button({
            "skin":Singletons.getInstance(DLBtnSkin),
            "width":32,
            "height":32
         });
         this.btnDownload.addEventListener(MouseEvent.CLICK,this.downloadClickListener);
         addChild(this.btnDownload);
         this.lblDownload = new Label();
         addChild(this.lblDownload);
         this.lblDownload.fontSize = 9.5;
         this.lblDownload.fontColor = 3355443;
         this.lblDownload.text = "Download";
         this.btnDownload.visible = this.lblDownload.visible = false;
         this.btnFlickr = new Button({
            "skin":Singletons.getInstance(FlickrBtnSkin),
            "width":32,
            "height":32
         });
         this.btnFlickr.addEventListener(MouseEvent.CLICK,this.flickrClickListener);
         this.lblFlickr = new Label();
         addChild(this.lblFlickr);
         this.lblFlickr.fontSize = 9.5;
         this.lblFlickr.fontColor = 3355443;
         this.lblFlickr.text = "Flickr";
         addChild(this.btnFlickr);
         this.lblFlickr.visible = this.btnFlickr.visible = false;
         this.btnPicasa = new Button({
            "skin":Singletons.getInstance(PicasaBtnSkin),
            "width":32,
            "height":32
         });
         this.btnPicasa.addEventListener(MouseEvent.CLICK,this.picasaClickListener);
         this.lblPicasa = new Label();
         addChild(this.lblPicasa);
         this.lblPicasa.fontSize = 9.5;
         this.lblPicasa.fontColor = 3355443;
         this.lblPicasa.text = "Picasa";
         addChild(this.btnPicasa);
         this.lblPicasa.visible = this.btnPicasa.visible = false;
         this.btnFacebook = new Button({
            "skin":Singletons.getInstance(FBBtnSkin),
            "width":32,
            "height":32
         });
         this.btnFacebook.addEventListener(MouseEvent.CLICK,this.facebookClickListener);
         addChild(this.btnFacebook);
         this.lblFacebook = new Label();
         addChild(this.lblFacebook);
         this.lblFacebook.fontSize = 9.5;
         this.lblFacebook.fontColor = 3355443;
         this.lblFacebook.text = "Facebook";
         this.btnFacebook.visible = this.lblFacebook.visible = false;
      }
      
      public function get takeinPicStage() : int
      {
         return this._takeinPicStage;
      }
      
      public function get mode() : int
      {
         return this._mode;
      }
      
      private function picModeChangeListener(param1:Event) : void
      {
         switch(this.picModeButtonBar.state)
         {
            case PicModeButtonBar.MODE_1PIC:
               this.takingPicType = TAKING_PIC_1PIC;
               break;
            case PicModeButtonBar.MODE_4PIC:
               this.takingPicType = TAKING_PIC_4PIC;
         }
      }
      
      private function configLabelInitState() : void
      {
         this.lbl1.fontColor = this.lbl2.fontColor = this.lbl3.fontColor = 16777215;
         this.lbl1.fontSize = this.lbl2.fontSize = this.lbl3.fontSize = 40;
         this.lbl1.text = "1";
         this.lbl2.text = "2";
         this.lbl3.text = "3";
         this.lbl3.move(200,3);
         this.lbl2.move(272,3);
         this.lbl1.move(346,3);
         this.lbl1.alpha = this.lbl2.alpha = this.lbl3.alpha = 0.2;
         this.lbl1.visible = this.lbl2.visible = this.lbl3.visible = false;
      }
      
      public function set takeinPicStage(param1:int) : void
      {
         if(param1 == this.takeinPicStage)
         {
            return;
         }
         this._takeinPicStage = param1;
         this.modeChanged = true;
         invalidate();
      }
      
      public function get takingPicType() : int
      {
         return this._takingPicType;
      }
      
      private function startTakePic() : void
      {
         if(this.takingPicType == TAKING_PIC_1PIC)
         {
            if(this.takeinPicStage == 3)
            {
               dispatchEvent(new Event("doFlash"));
               dispatchEvent(new Event("doTakePic"));
               return;
            }
         }
         else if(this.takingPicType == TAKING_PIC_4PIC)
         {
            if(this.takeinPicStage >= 3 && this.takeinPicStage < 7)
            {
               dispatchEvent(new Event("doFlash"));
               dispatchEvent(new Event("doTakePic"));
            }
            if(this.takeinPicStage == 6)
            {
               return;
            }
         }
         this.takeinPicStage += 1;
         TimerManager.getInstance().addCallBack(this.startTakePic,1.2,true,this);
      }
      
      private function downloadClickListener(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         dispatchEvent(new Event("downloadPicture"));
      }
      
      public function set mode(param1:int) : void
      {
         if(param1 == this.mode)
         {
            return;
         }
         this._mode = param1;
         this.modeChanged = true;
         invalidate();
         if(this._mode == ControlBar.MODE_TAKING_PIC)
         {
            this._takeinPicStage = -1;
            this.startTakePic();
         }
      }
      
      private function picasaClickListener(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         dispatchEvent(new Event("picasaPicture"));
      }
      
      override protected function update() : void
      {
         if(wasResized || this.modeChanged)
         {
            this.skin.draw(this);
            this.efBtn.move(width - 15 - this.efBtn.width,17);
            this.shutterBtn.move(301,12);
            this.countDownCam.move(411,11);
            this.sb1.move(276,21);
            this.sb2.move(276 + 24,21);
            this.sb3.move(276 + 2 * 24,21);
            this.sb4.move(276 + 3 * 24,21);
            this.lblDownload.validateNow();
            this.btnDownload.move(20,8);
            this.lblDownload.move(11,40);
            this.lblFacebook.validateNow();
            this.btnFacebook.move(80,8);
            this.lblFacebook.move(72,40);
            this.lblPicasa.validateNow();
            this.btnPicasa.move(width - 52,8);
            this.lblPicasa.move(width - 50,40);
            this.lblFlickr.validateNow();
            this.btnFlickr.move(width - 52 - 60,8);
            this.lblFlickr.move(width - 50 - 60,40);
         }
         if(this.scrollChanged)
         {
            trace("scroll changed");
            this.scrollChanged = false;
            if(this._scrollIndex == 0)
            {
               this.efBtn.leftEnabled = false;
            }
            else
            {
               this.efBtn.leftEnabled = true;
            }
            if(this._scrollIndex == 3)
            {
               this.efBtn.rightEnabled = false;
            }
            else
            {
               this.efBtn.rightEnabled = true;
            }
            this.sb1.selected = this.sb2.selected = this.sb3.selected = this.sb4.selected = false;
            switch(this._scrollIndex)
            {
               case 0:
                  this.sb1.selected = true;
                  break;
               case 1:
                  this.sb2.selected = true;
                  break;
               case 2:
                  this.sb3.selected = true;
                  break;
               case 3:
                  this.sb4.selected = true;
            }
         }
         if(this.modeChanged)
         {
            this.modeChanged = false;
            switch(this.mode)
            {
               case MODE_EFFECTS:
                  this.sb1.visible = this.sb2.visible = this.sb3.visible = this.sb4.visible = true;
                  this.picModeButtonBar.visible = true;
                  this.efBtn.visible = true;
                  this.shutterBtn.visible = false;
                  this.countDownCam.visible = false;
                  this.lbl1.visible = this.lbl2.visible = this.lbl3.visible = false;
                  this.efBtn.mode = EffectsButton.MODE_EFFECTS;
                  break;
               case MODE_PIC:
                  this.shutterBtn.inactive = false;
                  this.btnDownload.visible = this.lblDownload.visible = this.btnFacebook.visible = this.lblFacebook.visible = this.btnFlickr.visible = this.lblFlickr.visible = false;
                  this.picModeButtonBar.visible = true;
                  this.sb1.visible = this.sb2.visible = this.sb3.visible = this.sb4.visible = false;
                  this.efBtn.visible = true;
                  this.shutterBtn.visible = true;
                  this.shutterBtn.inactive = false;
                  this.countDownCam.visible = false;
                  this.lbl1.visible = this.lbl2.visible = this.lbl3.visible = false;
                  this.efBtn.mode = EffectsButton.MODE_NORMAL;
                  break;
               case MODE_TAKING_PIC:
                  this.sb1.visible = this.sb2.visible = this.sb3.visible = this.sb4.visible = false;
                  this.countDownCam.visible = true;
                  this.efBtn.visible = false;
                  this.shutterBtn.visible = false;
                  this.picModeButtonBar.visible = false;
                  this.lbl1.visible = this.lbl2.visible = this.lbl3.visible = true;
                  loop5:
                  switch(this._takeinPicStage)
                  {
                     case 0:
                        this.lbl1.filters = this.lbl2.filters = this.lbl3.filters = [];
                        this.lbl1.alpha = this.lbl2.alpha = this.lbl3.alpha = 0.2;
                        this.countDownCam.state = CountDownCam.STATE_DIM;
                        break;
                     case 1:
                        this.lbl2.filters = this.lbl1.filters = [];
                        this.lbl2.alpha = this.lbl1.alpha = 0.2;
                        this.lbl3.filters = [this.wordGlow];
                        this.lbl3.alpha = 1;
                        this.countDownCam.state = CountDownCam.STATE_DIM;
                        break;
                     case 2:
                        this.lbl1.filters = this.lbl3.filters = [];
                        this.lbl1.alpha = this.lbl3.alpha = 0.2;
                        this.lbl2.filters = [this.wordGlow];
                        this.lbl2.alpha = 1;
                        this.countDownCam.state = CountDownCam.STATE_DIM;
                        break;
                     case 3:
                        this.lbl2.filters = this.lbl3.filters = [];
                        this.lbl2.alpha = this.lbl3.alpha = 0.2;
                        this.lbl1.filters = [this.wordGlow];
                        this.lbl1.alpha = 1;
                        this.countDownCam.state = CountDownCam.STATE_DIM;
                        break;
                     case 4:
                        this.lbl1.filters = this.lbl2.filters = this.lbl3.filters = [];
                        this.lbl1.alpha = this.lbl2.alpha = this.lbl3.alpha = 0.2;
                        switch(this.takingPicType)
                        {
                           case TAKING_PIC_1PIC:
                              this.countDownCam.state = CountDownCam.STATE_BRIGHT;
                              break loop5;
                           case TAKING_PIC_4PIC:
                              this.countDownCam.state = CountDownCam.STATE_1QUAD;
                              break loop5;
                           default:
                              break loop5;
                        }
                        break;
                     case 5:
                        this.countDownCam.state = CountDownCam.STATE_2QUAD;
                        break;
                     case 6:
                        this.countDownCam.state = CountDownCam.STATE_3QUAD;
                        break;
                     case 7:
                        this.countDownCam.state = CountDownCam.STATE_BRIGHT;
                  }
                  break;
               case MODE_VIEWER:
                  this.shutterBtn.inactive = true;
                  this.interruptTakingPic();
                  this.sb1.visible = this.sb2.visible = this.sb3.visible = this.sb4.visible = false;
                  this.picModeButtonBar.visible = false;
                  this.efBtn.visible = false;
                  this.countDownCam.visible = false;
                  this.lbl1.visible = this.lbl2.visible = this.lbl3.visible = false;
                  this.shutterBtn.visible = true;
                  this.shutterBtn.inactive = true;
                  this.btnDownload.visible = this.lblDownload.visible = this.btnFacebook.visible = this.lblFacebook.visible = this.btnFlickr.visible = this.lblFlickr.visible = true;
            }
         }
      }
      
      private function interruptTakingPic() : void
      {
         if(TimerManager.getInstance().hasCallBack(this.startTakePic))
         {
            TimerManager.getInstance().removeCallBack(this.startTakePic);
         }
      }
      
      private function flickrClickListener(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         dispatchEvent(new Event("flickrPicture"));
      }
      
      private function scroll1Listener(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         this.scrollIndex = 0;
         dispatchEvent(new Event("changeScroll"));
      }
      
      private function scroll2Listener(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         this.scrollIndex = 1;
         dispatchEvent(new Event("changeScroll"));
      }
      
      private function scroll3Listener(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         this.scrollIndex = 2;
         dispatchEvent(new Event("changeScroll"));
      }
      
      private function scroll4Listener(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         this.scrollIndex = 3;
         dispatchEvent(new Event("changeScroll"));
      }
      
      private function facebookClickListener(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         dispatchEvent(new Event("facebookPicture"));
      }
      
      private function shutterClickListener(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         if(this.shutterBtn.inactive)
         {
            dispatchEvent(new Event("goPicMode"));
         }
         else
         {
            dispatchEvent(new Event("startTakePic"));
            this.mode = MODE_TAKING_PIC;
         }
      }
   }
}

