package Tasks is

   type Empty_Record is
      record
         null;
      end record;

   task type Bad_Timer (Countdown : Natural)
   is
      pragma Priority (10);
   end Bad_Timer;

   task type Timer (Countdown : Natural)
   is
      pragma Priority (10);
   end Timer;

   task type Timer_Stub;

   protected type Store
   is
      pragma Priority (10);
      function Get return Integer;
      procedure Put (X : in Integer);
      --  entry Wait;
   private
      The_Stored_Data : Integer := 0;
      The_Guard : Boolean := False;
   end Store;

   subtype Sub_Store is Store;
   subtype Sub_Timer is Timer (5);

   protected type Store_Stub
   is
      procedure Put (X : in Integer);
      --  entry Wait;
   private
      The_Stored_Data : Integer := 0;
   end Store_Stub;

end Tasks;
