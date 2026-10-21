package com.karthik.photobooth.screens.displacements
{
   import com.karthik.photobooth.screens.PBJScreen;
   import flash.display.Shader;
   import flash.filters.ShaderFilter;
   import flash.utils.ByteArray;
   
   public class PinchScreen extends PBJScreen
   {
      
      public static const TYPE:String = "pinch";
      
      private var PbjSource:Class = PinchScreen_PbjSource;
      
      public function PinchScreen()
      {
         super();
         usePosition = true;
         useSlider = true;
         screenName = "Pinch";
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

