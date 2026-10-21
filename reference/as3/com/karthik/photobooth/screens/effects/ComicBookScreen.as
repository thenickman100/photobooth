package com.karthik.photobooth.screens.effects
{
   import com.karthik.photobooth.screens.PBJScreen;
   import flash.display.Shader;
   import flash.filters.ShaderFilter;
   import flash.utils.ByteArray;
   
   public class ComicBookScreen extends PBJScreen
   {
      
      public static const TYPE:String = "comic_book";
      
      private var PbjSource:Class = ComicBookScreen_PbjSource;
      
      public function ComicBookScreen()
      {
         super();
         screenName = "Comic Book";
      }
      
      override protected function createChildren() : void
      {
         super.createChildren();
         shader = new Shader(new this.PbjSource() as ByteArray);
         shaderFilter = new ShaderFilter(shader);
         shader.data.dot_spacing.value = [5.5];
         shader.data.max_dot_size.value = [5];
         canvas.filters = [shaderFilter];
      }
   }
}

