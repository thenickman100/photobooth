package com.karthik.photobooth.control_bar
{
   import com.karthik.core.KComponent;
   import com.karthik.core.KSkin;
   import com.karthik.managers.Singletons;
   import com.karthik.photobooth.skins.control_bar.shutter_button.CountdownCamSkin;
   import flash.display.Sprite;
   import flash.filters.GlowFilter;
   
   public class CountDownCam extends KComponent
   {
      
      public static const STATE_DIM:int = 1;
      
      public static const STATE_BRIGHT:int = 2;
      
      public static const STATE_1QUAD:int = 3;
      
      public static const STATE_2QUAD:int = 4;
      
      public static const STATE_3QUAD:int = 5;
      
      protected var glowMask:Sprite;
      
      protected var stateChanged:Boolean = false;
      
      protected var _state:int = 1;
      
      protected var skin:KSkin;
      
      public function CountDownCam()
      {
         super();
         this.skin = Singletons.getInstance(CountdownCamSkin);
      }
      
      public function set state(param1:int) : void
      {
         if(param1 == this.state)
         {
            return;
         }
         this._state = param1;
         this.stateChanged = true;
         invalidate();
      }
      
      override protected function update() : void
      {
         if(wasResized || this.stateChanged)
         {
            this.stateChanged = false;
            this.skin.draw(this,{"glowMask":this.glowMask});
         }
      }
      
      public function get state() : int
      {
         return this._state;
      }
      
      override protected function createChildren() : void
      {
         this.glowMask = new Sprite();
         this.glowMask.filters = [new GlowFilter(16777215,0.7,20,20,4,3)];
         addChild(this.glowMask);
      }
   }
}

