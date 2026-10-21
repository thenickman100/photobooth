package com.karthik.managers
{
   import com.karthik.core.KComponent;
   
   public class KState
   {
      
      public var width:int;
      
      public var height:int;
      
      public var x:int;
      
      public var y:int;
      
      public var alpha:Number;
      
      public function KState(param1:int, param2:int, param3:int, param4:int, param5:Number)
      {
         super();
         this.x = param1;
         this.y = param2;
         this.width = param3;
         this.height = param4;
         this.alpha = param5;
      }
      
      public static function stateFromKComponent(param1:KComponent, param2:KState) : KState
      {
         param2.update(param1.x,param1.y,param1.width,param1.height,param1.alpha);
         return param2;
      }
      
      public function update(param1:int, param2:int, param3:int, param4:int, param5:Number) : void
      {
         this.x = param1;
         this.y = param2;
         this.width = param3;
         this.height = param4;
         this.alpha = param5;
      }
      
      public function toString() : String
      {
         return "x: " + this.x + " y: " + this.y + " width: " + this.width + " height: " + this.height;
      }
      
      public function intersect(param1:KState) : Boolean
      {
         return !(param1.y >= this.y + this.height || param1.x + param1.width <= this.x || param1.x >= this.x + this.width || param1.y + param1.height <= this.y);
      }
   }
}

