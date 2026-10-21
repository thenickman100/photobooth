package com.karthik.photobooth
{
   import com.karthik.data.ArrayCollection;
   import flash.events.Event;
   import flash.events.EventDispatcher;
   
   public class Model extends EventDispatcher
   {
      
      public static const MODE_PIC:int = 1;
      
      public static const MODE_EFFECTS:int = 2;
      
      public static const MODE_TAKING_PIC:int = 5;
      
      public static const MODE_VIEWER:int = 3;
      
      public static const MODE_TAKING_VIDEO:int = 4;
      
      public static const MAX_SCREEN_HSCROLL:int = 3;
      
      public static const PIC_MODE_1PIC:int = 1;
      
      public static const PIC_MODE_4_PIC:int = 2;
      
      protected var _mainState:int = 1;
      
      public var screens:Array = ["sepia","comic_book","thermal","black_white","normal","xray","glow","sketch","popart","bulge","pinch","light_tunnel","dent","normal","fish_eye","twirl","mirror","stretch","clouds","effel_tower","rollercoaster","color_dots","normal","sunset","earthrise","fish","yosemite","upload","upload","upload","upload","normal","upload","upload","upload","upload"];
      
      public var photos:ArrayCollection = new ArrayCollection([]);
      
      public var pic4Buffer:Array = [];
      
      protected var _picMode:int = 1;
      
      protected var _effectScreenHScroll:int = 0;
      
      protected var _selectedPhotoIndex:int;
      
      public function Model()
      {
         super();
      }
      
      public function set picMode(param1:int) : void
      {
         if(param1 == this.picMode)
         {
            return;
         }
         this._picMode = param1;
         dispatchEvent(new Event("picModeChange"));
      }
      
      public function get picMode() : int
      {
         return this._picMode;
      }
      
      public function set effectScreenHScroll(param1:int) : void
      {
         param1 = param1 < 0 ? 0 : (param1 > MAX_SCREEN_HSCROLL ? MAX_SCREEN_HSCROLL : param1);
         if(param1 == this.effectScreenHScroll)
         {
            return;
         }
         this._effectScreenHScroll = param1;
         dispatchEvent(new Event("screenHScrollChange"));
      }
      
      public function set selectedPhotoIndex(param1:int) : void
      {
         if(param1 == this.selectedPhotoIndex)
         {
            return;
         }
         this._selectedPhotoIndex = param1;
         dispatchEvent(new Event("selectedPhotoChange"));
      }
      
      public function set mainState(param1:int) : void
      {
         if(param1 == this.mainState)
         {
            return;
         }
         this._mainState = param1;
         dispatchEvent(new Event("modeChange"));
      }
      
      public function get effectScreenHScroll() : int
      {
         return this._effectScreenHScroll;
      }
      
      public function get selectedPhotoIndex() : int
      {
         return this._selectedPhotoIndex;
      }
      
      public function get mainState() : int
      {
         return this._mainState;
      }
   }
}

