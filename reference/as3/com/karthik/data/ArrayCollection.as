package com.karthik.data
{
   import com.karthik.data.arraycollection_events.CollectionEvent;
   import flash.events.EventDispatcher;
   
   public class ArrayCollection extends EventDispatcher
   {
      
      private var _source:Array;
      
      public function ArrayCollection(param1:Array)
      {
         super(null);
         this._source = param1;
      }
      
      public function addItem(param1:Object) : void
      {
         this.addItemAt(param1,this.length);
      }
      
      public function removeItemAt(param1:int) : Object
      {
         var _loc2_:Object = this._source.splice(param1,1);
         var _loc3_:CollectionEvent = new CollectionEvent();
         _loc3_.index = param1;
         _loc3_.item = _loc2_;
         _loc3_.kind = CollectionEvent.TYPE_REMOVE;
         dispatchEvent(_loc3_);
         return _loc2_;
      }
      
      public function get length() : int
      {
         return this._source.length;
      }
      
      public function addItemAt(param1:Object, param2:int) : void
      {
         this._source.splice(param2,0,param1);
         var _loc3_:CollectionEvent = new CollectionEvent();
         _loc3_.index = param2;
         _loc3_.item = param1;
         _loc3_.kind = CollectionEvent.TYPE_ADD;
         dispatchEvent(_loc3_);
      }
      
      public function getItemIndex(param1:Object) : int
      {
         var _loc2_:int = 0;
         while(_loc2_ < this._source.length)
         {
            if(param1 == this._source[_loc2_])
            {
               return _loc2_;
            }
            _loc2_++;
         }
         return -1;
      }
      
      public function get source() : Array
      {
         return this._source;
      }
      
      public function getItemAt(param1:int) : Object
      {
         return this._source[param1];
      }
      
      public function set source(param1:Array) : void
      {
         if(this._source == param1)
         {
            return;
         }
         this._source = param1;
         var _loc2_:CollectionEvent = new CollectionEvent();
         _loc2_.kind = CollectionEvent.TYPE_OTHER;
         dispatchEvent(_loc2_);
      }
      
      public function contains(param1:Object) : Boolean
      {
         return this.getItemIndex(param1) != -1;
      }
   }
}

