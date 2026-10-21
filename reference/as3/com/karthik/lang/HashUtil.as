package com.karthik.lang
{
   import flash.utils.getQualifiedClassName;
   
   public class HashUtil
   {
      
      public function HashUtil()
      {
         super();
      }
      
      public static function mergeHashArr(param1:Array) : Object
      {
         var _loc4_:Object = null;
         var _loc5_:String = null;
         var _loc6_:Object = null;
         var _loc2_:Object = {};
         if(param1.length == 0)
         {
            return _loc2_;
         }
         var _loc3_:int = 0;
         while(_loc3_ < param1.length)
         {
            _loc4_ = param1[_loc3_];
            for(_loc5_ in _loc4_)
            {
               _loc6_ = _loc4_[_loc5_];
               if(getQualifiedClassName(_loc6_) == "Object" && Boolean(_loc2_.hasOwnProperty(_loc5_)))
               {
                  _loc2_[_loc5_] = mergeHash(_loc2_[_loc5_],_loc4_[_loc5_]);
               }
               else
               {
                  _loc2_[_loc5_] = _loc4_[_loc5_];
               }
            }
            _loc3_++;
         }
         return _loc2_;
      }
      
      public static function transferProperties(param1:Object, param2:Object) : void
      {
         var _loc3_:String = null;
         for(_loc3_ in param1)
         {
            if(param2.hasOwnProperty(_loc3_))
            {
               param2[_loc3_] = param1[_loc3_];
            }
         }
      }
      
      public static function mergeHash(... rest) : Object
      {
         return mergeHashArr(rest);
      }
   }
}

