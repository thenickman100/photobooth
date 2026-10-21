package com.karthik.photobooth.photo_list_item
{
   import com.karthik.components.Button;
   import com.karthik.managers.Singletons;
   import com.karthik.photobooth.skins.photo_list.ScrollBtnLeftSkin;
   import flash.filters.DropShadowFilter;
   
   public class LeftScrollBtn extends Button
   {
      
      public function LeftScrollBtn()
      {
         super({
            "width":26,
            "height":98,
            "skin":Singletons.getInstance(ScrollBtnLeftSkin)
         });
         filters = [new DropShadowFilter(3,0,0,0.4,3,0)];
      }
   }
}

