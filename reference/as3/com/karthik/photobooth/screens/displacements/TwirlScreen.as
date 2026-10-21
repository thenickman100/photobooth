package com.karthik.photobooth.screens.displacements
{
   import com.karthik.photobooth.screens.PBJScreen;
   import flash.display.Shader;
   import flash.filters.ShaderFilter;
   import flash.utils.ByteArray;
   
   public class TwirlScreen extends PBJScreen
   {
      
      public static const TYPE:String = "twirl";
      
      private var PbjSource:Class = TwirlScreen_PbjSource;
      
      public function TwirlScreen()
      {
         super();
         usePosition = true;
         useSlider = true;
         screenName = "Twirl";
         shader = new Shader(new this.PbjSource() as ByteArray);
         shaderFilter = new ShaderFilter(shader);
         effectDirty = true;
      }
      
      override protected function update() : void
      {
         var _loc1_:Number = NaN;
         var _loc2_:Number = NaN;
         super.update();
         if(effectDirty || wasResized)
         {
            effectDirty = false;
            _loc1_ = width * _centerX;
            _loc2_ = height * _centerY;
            shader.data.x.value = [_loc1_];
            shader.data.y.value = [_loc2_];
            shader.data.magnitude.value = [magnitude];
            shader.data.image_height.value = [height];
            shader.data.image_width.value = [width];
            this.canvas.filters = [shaderFilter];
         }
      }
   }
}

