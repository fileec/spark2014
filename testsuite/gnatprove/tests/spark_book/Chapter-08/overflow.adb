package body Overflow with SPARK_Mode => On is

   procedure Avg  (A : in  Natural;
                   B : in  Natural;
                   C : out Natural) is
   begin
      C := (A + B) / 2;
   end Avg;

end Overflow;
