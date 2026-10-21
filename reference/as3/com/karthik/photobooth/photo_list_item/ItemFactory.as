package com.karthik.photobooth.photo_list_item
{
   import com.karthik.data.ClassFactory;
   
   public class ItemFactory extends ClassFactory
   {
      
      public function ItemFactory()
      {
         super();
      }
      
      override public function newInstance() : *
      {
         return new PhotoItem();
      }
   }
}

