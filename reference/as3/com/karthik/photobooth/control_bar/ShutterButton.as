package com.karthik.photobooth.control_bar
{
   import com.karthik.components.Button;
   import com.karthik.managers.Singletons;
   import com.karthik.photobooth.skins.control_bar.shutter_button.ShutterButtonSkinNormal;
   
   public class ShutterButton extends Button
   {
      
      protected var _movieMode:Boolean = true;
      
      protected var _inactive:Boolean = false;
      
      public function ShutterButton()
      {
         super({
            "skin":Singletons.getInstance(ShutterButtonSkinNormal),
            "width":39,
            "height":38
         });
      }
      
      public function get movieMode() : Boolean
      {
         return this._movieMode;
      }
      
      public function set inactive(param1:Boolean) : void
      {
         if(param1 == this.inactive)
         {
            return;
         }
         this._inactive = param1;
         stateChanged = true;
         trace("set inactive: " + param1);
         invalidate();
      }
      
      public function get inactive() : Boolean
      {
         return this._inactive;
      }
      
      public function set movieMode(param1:Boolean) : void
      {
         if(param1 == this.movieMode)
         {
            return;
         }
         this._movieMode = param1;
         stateChanged = true;
         invalidate();
      }
   }
}

