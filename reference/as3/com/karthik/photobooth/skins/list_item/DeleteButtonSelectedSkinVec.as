package com.karthik.photobooth.skins.list_item
{
   public class DeleteButtonSelectedSkinVec extends DeleteButtonSkinVec
   {
      
      public function DeleteButtonSelectedSkinVec()
      {
         super();
      }
      
      override protected function drawOver() : void
      {
         drawDeleteBtn(16777215,2651099,2651099);
      }
      
      override protected function drawNormal() : void
      {
         drawDeleteBtn(13229302,2651099,2651099);
      }
      
      override protected function drawDown() : void
      {
         drawDeleteBtn(9611738,2651099,2651099);
      }
   }
}

