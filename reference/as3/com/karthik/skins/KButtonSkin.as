package com.karthik.skins
{
   import com.karthik.components.Button;
   import com.karthik.core.KSkin;
   import com.karthik.core.KSprite;
   
   public class KButtonSkin extends KSkin
   {
      
      protected var opt:Object;
      
      protected var btn:Button;
      
      public function KButtonSkin()
      {
         super();
      }
      
      protected function drawDisabled() : void
      {
         this.drawNormal();
      }
      
      protected function opSet() : void
      {
      }
      
      override public function draw(param1:KSprite, param2:Object = null) : void
      {
         this.btn = param1 as Button;
         this.opt = {"target":param1};
         this.opSet();
         clear(param1.graphics);
         if(this.btn.disabled)
         {
            this.drawDisabled();
         }
         else if(this.btn.state == "over")
         {
            this.drawOver();
         }
         else if(this.btn.state == "down")
         {
            this.drawDown();
         }
         else
         {
            this.drawNormal();
         }
      }
      
      protected function drawNormal() : void
      {
         drawRect(this.opt,{"fillStyle":{"alpha":0.5}});
      }
      
      protected function drawDown() : void
      {
         drawRect(this.opt,{"fillStyle":{"alpha":1}});
      }
      
      protected function drawOver() : void
      {
         drawRect(this.opt,{"fillStyle":{"alpha":0.3}});
      }
   }
}

