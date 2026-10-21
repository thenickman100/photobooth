package com.karthik.photobooth.screens.effects
{
   import com.karthik.photobooth.screens.PBJScreen;
   import flash.display.Shader;
   import flash.filters.ShaderFilter;
   import flash.utils.ByteArray;
   
   public class SepiaScreen extends PBJScreen
   {
      
      public static const TYPE:String = "sepia";
      
      private var PbjSource:Class = SepiaScreen_PbjSource;
      
      public function SepiaScreen()
      {
         super();
         screenName = "Sepia";
      }
      
      override protected function createChildren() : void
      {
         super.createChildren();
         shader = new Shader(new this.PbjSource() as ByteArray);
         shaderFilter = new ShaderFilter(shader);
         canvas.filters = [shaderFilter];
      }
   }
}

