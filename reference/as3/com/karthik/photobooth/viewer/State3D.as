package com.karthik.photobooth.viewer
{
   import flash.display.Sprite;
   
   public class State3D
   {
      
      public var rx:Number;
      
      public var ry:Number;
      
      public var rz:Number;
      
      public var x:Number;
      
      public var y:Number;
      
      public var z:Number;
      
      public function State3D(param1:Number, param2:Number, param3:Number, param4:Number, param5:Number, param6:Number)
      {
         super();
         this.x = param1;
         this.y = param2;
         this.z = param3;
         this.rx = param4;
         this.ry = param5;
         this.rz = param6;
      }
      
      public function updateWithState(param1:Sprite) : void
      {
         param1.x = this.x;
         param1.y = this.y;
         param1.z = this.z;
         param1.rotationX = this.rx;
         param1.rotationY = this.ry;
         param1.rotationZ = this.rz;
      }
      
      public function toString() : String
      {
         return "x: " + this.x + " y: " + this.y + " z: " + this.z + " rx: " + this.rx + " ry: " + this.ry + " rz: " + this.rz;
      }
      
      public function interpolateTo(param1:State3D, param2:Number) : State3D
      {
         return new State3D(this.x + (param1.x - this.x) * param2,this.y + (param1.y - this.y) * param2,this.z + (param1.z - this.z) * param2,this.rx + (param1.rx - this.rx) * param2,this.ry + (param1.ry - this.ry) * param2,this.rz + (param1.rz - this.rz) * param2);
      }
      
      public function clone() : State3D
      {
         return new State3D(this.x,this.y,this.z,this.rx,this.ry,this.rz);
      }
      
      public function equals(param1:State3D) : Boolean
      {
         return this.x == param1.x && this.y == param1.y && this.z == param1.z && this.rx == param1.rx && this.ry == param1.ry && this.rz == param1.rz;
      }
   }
}

