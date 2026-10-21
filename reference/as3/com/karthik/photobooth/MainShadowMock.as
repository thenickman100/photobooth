package com.karthik.photobooth
{
   import com.karthik.core.KComponent;
   import com.karthik.core.KSkin;
   import com.karthik.managers.Singletons;
   import com.karthik.photobooth.skins.MainShadowMockSkin;
   import flash.filters.DropShadowFilter;
   
   public class MainShadowMock extends KComponent
   {
      
      protected var skin:KSkin;
      
      public function MainShadowMock()
      {
         super({
            "width":642,
            "height":684
         });
         var _loc1_:DropShadowFilter = new DropShadowFilter(1,0,0,1,70,70,2,3);
         this.filters = [_loc1_];
         this.skin = Singletons.getInstance(MainShadowMockSkin);
      }
      
      override protected function update() : void
      {
         if(wasResized)
         {
            this.skin.draw(this);
         }
      }
   }
}

