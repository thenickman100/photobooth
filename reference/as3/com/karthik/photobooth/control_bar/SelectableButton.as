package com.karthik.photobooth.control_bar
{
   import com.karthik.components.Button;
   import flash.events.MouseEvent;
   
   public class SelectableButton extends Button
   {
      
      protected var _selected:Boolean = false;
      
      public function SelectableButton(param1:Object = null)
      {
         super(param1);
      }
      
      override protected function mouseUp(param1:MouseEvent) : void
      {
         if(this.selected)
         {
            return;
         }
         super.mouseUp(param1);
      }
      
      public function set selected(param1:Boolean) : void
      {
         if(param1 == this._selected)
         {
            return;
         }
         this._selected = param1;
         if(param1)
         {
            _state = "down";
         }
         else
         {
            _state = "normal";
         }
         stateChanged = true;
         invalidate();
      }
      
      override protected function mouseOver(param1:MouseEvent) : void
      {
         if(this.selected)
         {
            return;
         }
         super.mouseOver(param1);
      }
      
      override protected function mouseOut(param1:MouseEvent) : void
      {
         if(this.selected)
         {
            return;
         }
         super.mouseOut(param1);
      }
      
      public function get selected() : Boolean
      {
         return this._selected;
      }
   }
}

