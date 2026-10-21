package com.karthik.photobooth.screens
{
   import com.karthik.photobooth.screens.bg_removed.BGRemovedScreen;
   import com.karthik.photobooth.screens.bg_removed.UploadBgScreen;
   import com.karthik.photobooth.screens.displacements.BulgeScreen;
   import com.karthik.photobooth.screens.displacements.DentScreen;
   import com.karthik.photobooth.screens.displacements.FisheyeScreen;
   import com.karthik.photobooth.screens.displacements.LightTunnelScreen;
   import com.karthik.photobooth.screens.displacements.MirrorScreen;
   import com.karthik.photobooth.screens.displacements.PinchScreen;
   import com.karthik.photobooth.screens.displacements.StretchScreen;
   import com.karthik.photobooth.screens.displacements.TwirlScreen;
   import com.karthik.photobooth.screens.effects.*;
   
   public class ScreenFactory
   {
      
      public function ScreenFactory()
      {
         super();
      }
      
      public function newScreenInstance(param1:*) : BaseScreen
      {
         switch(param1.toString())
         {
            case BlackWhiteScreen.TYPE:
               return new BlackWhiteScreen();
            case GlowScreen.TYPE:
               return new GlowScreen();
            case SepiaScreen.TYPE:
               return new SepiaScreen();
            case PopArtScreen.TYPE:
               return new PopArtScreen();
            case ThermalScreen.TYPE:
               return new ThermalScreen();
            case ComicBookScreen.TYPE:
               return new ComicBookScreen();
            case SketchScreen.TYPE:
               return new SketchScreen();
            case XrayScreen.TYPE:
               return new XrayScreen();
            case TwirlScreen.TYPE:
               return new TwirlScreen();
            case LightTunnelScreen.TYPE:
               return new LightTunnelScreen();
            case MirrorScreen.TYPE:
               return new MirrorScreen();
            case FisheyeScreen.TYPE:
               return new FisheyeScreen();
            case StretchScreen.TYPE:
               return new StretchScreen();
            case BulgeScreen.TYPE:
               return new BulgeScreen();
            case PinchScreen.TYPE:
               return new PinchScreen();
            case DentScreen.TYPE:
               return new DentScreen();
            case "clouds":
               return new BGRemovedScreen("images/clouds.jpg","Clouds");
            case "color_dots":
               return new BGRemovedScreen("images/colored_dots.jpg","Color Dots");
            case "earthrise":
               return new BGRemovedScreen("images/earth_rise.jpg","Earthrise");
            case "effel_tower":
               return new BGRemovedScreen("images/Effel_Tower.swf","Effel Tower");
            case "fish":
               return new BGRemovedScreen("images/Fish.swf","Fish");
            case "rollercoaster":
               return new BGRemovedScreen("images/RollerCoaster.swf","RollerCoaster");
            case "sunset":
               return new BGRemovedScreen("images/Sunset.swf","Sunset");
            case "yosemite":
               return new BGRemovedScreen("images/Yosmite.swf","Yosmite");
            case UploadBgScreen.TYPE:
               return new UploadBgScreen();
            default:
               return new BaseScreen();
         }
      }
   }
}

