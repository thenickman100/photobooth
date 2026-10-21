package com.karthik.photobooth.control_bar
{
   import com.karthik.core.KComponent;
   import com.karthik.core.KSkin;
   import com.karthik.core.KSprite;
   import com.karthik.managers.Singletons;
   import com.karthik.photobooth.skins.control_bar.picmode_buttonbar.PicModeBtnBarSkin;
   import com.karthik.photobooth.skins.control_bar.picmode_buttonbar.PicModePic1Skin;
   import com.karthik.photobooth.skins.control_bar.picmode_buttonbar.PicModePic4Skin;
   import com.karthik.photobooth.skins.control_bar.picmode_buttonbar.PicModeVidSkin;
   import flash.events.Event;
   import flash.events.MouseEvent;
   
   public class PicModeButtonBar extends KComponent
   {
      
      public static const MODE_1PIC:int = 1;
      
      public static const MODE_4PIC:int = 2;
      
      public static const MODE_VID:int = 3;
      
      protected var maskL:KSprite;
      
      protected var stateChanged:Boolean = true;
      
      protected var maskR:KSprite;
      
      protected var btn4Pic:SelectableButton;
      
      protected var btn1Pic:SelectableButton;
      
      protected var _state:int = 1;
      
      protected var btnVid:SelectableButton;
      
      public var skin:KSkin;
      
      public function PicModeButtonBar()
      {
         super({
            "width":92,
            "height":25
         });
         this.skin = Singletons.getInstance(PicModeBtnBarSkin);
      }
      
      public function set state(param1:int) : void
      {
         if(param1 == this.state)
         {
            return;
         }
         this._state = param1;
         dispatchEvent(new Event("picModeChange"));
         this.stateChanged = true;
         invalidate();
      }
      
      override protected function update() : void
      {
         if(wasResized || this.stateChanged)
         {
            this.btn1Pic.move(1,1);
            this.btn1Pic.setActualSize(29,22);
            this.btn4Pic.move(31,1);
            this.btn4Pic.setActualSize(30,22);
            this.btnVid.move(62,1);
            this.btnVid.setActualSize(29,22);
            this.stateChanged = false;
            this.skin.draw(this,{
               "maskL":this.maskL,
               "maskR":this.maskR,
               "btn1":this.btn1Pic,
               "btn2":this.btn4Pic,
               "btn3":this.btnVid
            });
            switch(this.state)
            {
               case MODE_1PIC:
                  this.btn1Pic.selected = true;
                  this.btn4Pic.selected = false;
                  this.btnVid.selected = false;
                  break;
               case MODE_4PIC:
                  this.btn1Pic.selected = false;
                  this.btn4Pic.selected = true;
                  this.btnVid.selected = false;
                  break;
               case MODE_VID:
                  this.btn1Pic.selected = false;
                  this.btn4Pic.selected = false;
                  this.btnVid.selected = true;
            }
         }
      }
      
      private function btn1PicClickListener(param1:MouseEvent) : void
      {
         this.state = MODE_1PIC;
      }
      
      private function btnVidClickListener(param1:MouseEvent) : void
      {
      }
      
      private function btn4PicClickListener(param1:MouseEvent) : void
      {
         this.state = MODE_4PIC;
      }
      
      public function get state() : int
      {
         return this._state;
      }
      
      override protected function createChildren() : void
      {
         super.createChildren();
         this.maskL = new KSprite();
         this.maskR = new KSprite();
         addChild(this.maskL);
         addChild(this.maskR);
         this.btn1Pic = new SelectableButton({"skin":Singletons.getInstance(PicModePic1Skin)});
         this.btn4Pic = new SelectableButton({"skin":Singletons.getInstance(PicModePic4Skin)});
         this.btnVid = new SelectableButton({"skin":Singletons.getInstance(PicModeVidSkin)});
         this.btn1Pic.mask = this.maskL;
         this.btnVid.mask = this.maskR;
         this.btn1Pic.addEventListener(MouseEvent.MOUSE_DOWN,this.btn1PicClickListener);
         this.btn4Pic.addEventListener(MouseEvent.MOUSE_DOWN,this.btn4PicClickListener);
         this.btnVid.addEventListener(MouseEvent.MOUSE_DOWN,this.btnVidClickListener);
         addChild(this.btn1Pic);
         addChild(this.btn4Pic);
         addChild(this.btnVid);
      }
   }
}

