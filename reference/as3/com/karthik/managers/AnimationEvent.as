package com.karthik.managers
{
   import flash.events.Event;
   
   public class AnimationEvent extends Event
   {
      
      public static const ANIMATION_COMPLETE:String = "animation_complete";
      
      public var interrupted:Boolean = false;
      
      public function AnimationEvent()
      {
         super(ANIMATION_COMPLETE);
      }
   }
}

