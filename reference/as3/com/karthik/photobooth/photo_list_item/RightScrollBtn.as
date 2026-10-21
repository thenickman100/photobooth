package com.karthik.photobooth.photo_list_item
{
   import com.karthik.components.Button;
   import com.karthik.managers.Singletons;
   import com.karthik.photobooth.skins.photo_list.ScrollBtnRightSkin;
   import flash.filters.DropShadowFilter;
   
   public class RightScrollBtn extends Button
   {
      
      public function RightScrollBtn()
      {
         super({
            "width":26,
            "height":98,
            "skin":Singletons.getInstance(ScrollBtnRightSkin)
         });
         filters = [new DropShadowFilter(3,180,0,0.3,3)];
      }
   }
}

