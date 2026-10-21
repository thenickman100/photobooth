package com.karthik.photobooth.popups
{
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   
   public class TextFieldMultiLine extends TextField
   {
      
      public function TextFieldMultiLine()
      {
         super();
         selectable = false;
         multiline = true;
         autoSize = TextFieldAutoSize.LEFT;
         wordWrap = true;
      }
   }
}

