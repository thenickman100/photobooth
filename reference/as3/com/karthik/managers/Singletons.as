package com.karthik.managers
{
   import flash.utils.Dictionary;
   
   public class Singletons
   {
      
      private static var skins:Dictionary = new Dictionary();
      
      public function Singletons()
      {
         super();
      }
      
      public static function getInstance(param1:Class) : *
      {
         if(!skins[param1])
         {
            skins[param1] = new param1();
         }
         return skins[param1];
      }
   }
}

