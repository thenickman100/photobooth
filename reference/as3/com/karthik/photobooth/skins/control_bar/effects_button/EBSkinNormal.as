package com.karthik.photobooth.skins.control_bar.effects_button
{
   import com.karthik.components.Button;
   import com.karthik.components.Label;
   import com.karthik.core.KSprite;
   import com.karthik.lang.HashUtil;
   import com.karthik.managers.Singletons;
   import com.karthik.photobooth.control_bar.EffectsButton;
   import com.karthik.skins.KButtonSkin;
   import flash.display.Sprite;
   
   public class EBSkinNormal extends KButtonSkin
   {
      
      private var efb:EffectsButton;
      
      private var isEffects:Boolean = false;
      
      public function EBSkinNormal()
      {
         super();
      }
      
      override public function draw(param1:KSprite, param2:Object = null) : void
      {
         var _loc3_:Button = param2.left;
         var _loc4_:Button = param2.right;
         var _loc5_:Label = param2.label;
         var _loc6_:Sprite = param2.mask1;
         var _loc7_:Sprite = param2.mask2;
         var _loc8_:EffectsButton = param1 as EffectsButton;
         this.efb = param1 as EffectsButton;
         if(this.efb.mode == EffectsButton.MODE_EFFECTS)
         {
            this.isEffects = true;
            _loc5_.fontColor = 16777215;
         }
         else
         {
            this.isEffects = false;
            _loc5_.fontColor = 4802889;
         }
         _loc3_.skin = Singletons.getInstance(LBSkin);
         _loc4_.skin = Singletons.getInstance(RBSkin);
         super.draw(param1,param2);
         clear(_loc6_);
         drawKRoundRect({
            "lineStyle":null,
            "target":_loc6_,
            "x":2,
            "y":1,
            "width":param1.width - 3,
            "height":param1.height - 2,
            "fillStyle":{
               "color":0,
               "alpha":1
            },
            "radius":3
         });
         clear(_loc7_);
         drawKRoundRect({
            "lineStyle":null,
            "target":_loc7_,
            "x":2,
            "y":1,
            "width":param1.width - 3,
            "height":param1.height - 2,
            "fillStyle":{
               "color":0,
               "alpha":1
            },
            "radius":3
         });
      }
      
      override protected function drawDown() : void
      {
         drawKRoundRect(opt,{
            "fillStyle":null,
            "y":1,
            "lineStyle":{"color":13553358}
         });
         if(this.isEffects)
         {
            opt = HashUtil.mergeHash(opt,{"fillStyle":{"colors":[3355443,6776679]}});
         }
         else
         {
            opt = HashUtil.mergeHash(opt,{"fillStyle":{"colors":[12040119,8289918]}});
         }
         drawKRoundRect(opt);
      }
      
      override protected function drawOver() : void
      {
         this.drawNormal();
      }
      
      override protected function opSet() : void
      {
         opt = HashUtil.mergeHash(opt,{
            "lineStyle":{
               "type":"color",
               "thickness":1,
               "alpha":1,
               "color":4934475,
               "hint":true
            },
            "fillStyle":{
               "type":"gradient",
               "colors":[16645629,11382189],
               "box":{
                  "x":0,
                  "y":1,
                  "width":btn.width,
                  "height":btn.height - 1
               }
            },
            "height":btn.height - 2,
            "width":btn.width - 2,
            "radius":3,
            "y":0,
            "x":1
         });
      }
      
      override protected function drawNormal() : void
      {
         drawKRoundRect(opt,{
            "fillStyle":null,
            "y":1,
            "lineStyle":{"color":13553358}
         });
         if(this.isEffects)
         {
            opt = HashUtil.mergeHash(opt,{"fillStyle":{"colors":[3355443,6776679]}});
         }
         drawKRoundRect(opt);
      }
   }
}

