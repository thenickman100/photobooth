package com.karthik.photobooth.model
{
   public interface IPhotoItem
   {
      
      function get dateTaken() : Date;
      
      function get type() : String;
      
      function get itemData() : Array;
   }
}

