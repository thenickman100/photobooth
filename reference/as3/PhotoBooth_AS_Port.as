package
{
   import com.karthik.components.Label;
   import com.karthik.core.KComponentGlobals;
   import com.karthik.core.KSkin;
   import com.karthik.core.KSprite;
   import com.karthik.managers.Singletons;
   import com.karthik.managers.TimerManager;
   import com.karthik.photobooth.Main;
   import com.karthik.photobooth.MainShadowMock;
   import com.karthik.photobooth.managers.AssetManager;
   import com.karthik.photobooth.managers.GrowlManager;
   import com.karthik.photobooth.popups.Flasher;
   import flash.events.Event;
   import flash.media.Camera;
   
   public class PhotoBooth_AS_Port extends KSprite
   {
      
      public var skin:KSkin;
      
      private var copyright:Label;
      
      private var shadowMock:MainShadowMock;
      
      private var font:Object;
      
      private var main:Main;
      
      private var flasher:KSprite;
      
      public function PhotoBooth_AS_Port()
      {
         var _loc1_:Flasher = null;
         this.skin = Singletons.getInstance(AppSkin);
         this.font = AssetManager.lucidaGrande;
         super();
         KComponentGlobals.initialize(this);
         GrowlManager.init(this);
         stage.addEventListener(Event.RESIZE,this.resizeListener);
         this.skin.draw(this);
         if(Camera.getCamera() != null)
         {
            this.shadowMock = new MainShadowMock();
            addChild(this.shadowMock);
            this.copyright = new Label();
            this.copyright.text = "Created by Karthik Tharavaad, see http://tharavaad.wordpress.com/";
            this.copyright.fontSize = 10;
            this.copyright.fontColor = 14540253;
            addChild(this.copyright);
            this.main = new Main();
            addChild(this.main);
            this.positionMain();
            _loc1_ = new Flasher(this);
            addChild(_loc1_);
            this.main.flasher = _loc1_;
            TimerManager.getInstance().addCallBack(this.welcomeMSG,1,true,this);
         }
         else
         {
            TimerManager.getInstance().addCallBack(this.needCameraMsg,1,true,this);
         }
      }
      
      private function positionMain() : void
      {
         this.main.move((stage.stageWidth - this.main.width) / 2,(stage.stageHeight - this.main.height) / 2);
         this.shadowMock.move(this.main.x,this.main.y);
         this.copyright.validateNow();
         this.copyright.move(stage.stageWidth - this.copyright.getMeasuredWidth() - 10,stage.stageHeight - this.copyright.getMeasuredHeight() - 10);
      }
      
      private function needCameraMsg() : void
      {
         GrowlManager.getInstance().showMessage("No Camera","No webcam was detected on your computer =( unfortunately, you can\'t use this application without one. You can get a cheap webcam off Ebay for around $15. Email me at karthik_tharavaad@yahoo.com if you any questions.",null,int.MAX_VALUE);
      }
      
      private function resizeListener(param1:Event) : void
      {
         this.skin.draw(this);
         this.positionMain();
      }
      
      private function welcomeMSG() : void
      {
         GrowlManager.getInstance().showMessage("Welcome!","welcome to PictureBooth. Feel free to email me at karthik_tharavaad@yahoo.com if you any questions or find any bugs, otherwise, enjoy!");
      }
   }
}

import com.karthik.core.KSkin;
import com.karthik.core.KSprite;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.geom.Matrix;

class AppSkin extends KSkin
{
   
   private var bmpDat:BitmapData = (new this.Bmp() as Bitmap).bitmapData;
   
   private var Bmp:Class = AppSkin_Bmp;
   
   public function AppSkin()
   {
      super();
   }
   
   override public function draw(param1:KSprite, param2:Object = null) : void
   {
      clear(param1);
      this.drawRect({
         "target":param1,
         "lineStyle":null,
         "width":param1.stage.stageWidth,
         "height":param1.stage.stageHeight,
         "fillStyle":{
            "type":"bmp",
            "bmp":this.bmpDat,
            "matr":new Matrix(param1.stage.stageWidth / this.bmpDat.width,0,0,param1.stage.stageHeight / this.bmpDat.height)
         }
      });
   }
}
