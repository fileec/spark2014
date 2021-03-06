--------------------------------------------------------
--  This file was automatically generated by Ocarina  --
--  Do NOT hand-modify this file, as your             --
--  changes will be lost when you re-run Ocarina      --
--------------------------------------------------------
pragma Style_Checks
 ("NM32766");

with PolyORB_HI_Generated;
with PolyORB_HI.Marshallers_G;
pragma Elaborate_All (PolyORB_HI.Marshallers_G);

package body PolyORB_HI_Generated.Marshallers is

  --  Marshallers for interface type of thread p.impl

  --------------
  -- Marshall --
  --------------

  procedure Marshall
   (Data : PolyORB_HI_Generated.Activity.Software_P_Impl_Interface;
    Message : in out PolyORB_HI.Messages.Message_Type)
  is
    use PolyORB_HI_Generated.Activity;
  begin
    if (Data.Port
      = PolyORB_HI_Generated.Activity.Data_Source)
    then
      PolyORB_HI_Generated.Marshallers.Marshall
       (Data.Data_Source_DATA,
        Message);
    end if;
  end Marshall;

  ----------------
  -- Unmarshall --
  ----------------

  procedure Unmarshall
   (Port : PolyORB_HI_Generated.Activity.Software_P_Impl_Port_Type;
    Data : out PolyORB_HI_Generated.Activity.Software_P_Impl_Interface;
    Message : in out PolyORB_HI.Messages.Message_Type)
  is
    pragma Unreferenced
     (Port);
    pragma Unreferenced
     (Message);
    pragma Unreferenced
     (Data);
  begin
    null;
  end Unmarshall;

  --  Marshallers for DATA type alpha_type

  package Alpha_Type_Marshallers is
   new PolyORB_HI.Marshallers_G
     (PolyORB_HI_Generated.Types.Alpha_Type);

  procedure Marshall
   (Data : PolyORB_HI_Generated.Types.Alpha_Type;
    Message : in out PolyORB_HI.Messages.Message_Type)
   renames Alpha_Type_Marshallers.Marshall;

  procedure Unmarshall
   (Data : out PolyORB_HI_Generated.Types.Alpha_Type;
    Message : in out PolyORB_HI.Messages.Message_Type)
   renames Alpha_Type_Marshallers.Unmarshall;

  --  Marshallers for interface type of thread q.impl

  --------------
  -- Marshall --
  --------------

  procedure Marshall
   (Data : PolyORB_HI_Generated.Activity.Software_Q_Impl_Interface;
    Message : in out PolyORB_HI.Messages.Message_Type)
  is
    pragma Unreferenced
     (Message);
    pragma Unreferenced
     (Data);
  begin
    null;
  end Marshall;

  ----------------
  -- Unmarshall --
  ----------------

  procedure Unmarshall
   (Port : PolyORB_HI_Generated.Activity.Software_Q_Impl_Port_Type;
    Data : out PolyORB_HI_Generated.Activity.Software_Q_Impl_Interface;
    Message : in out PolyORB_HI.Messages.Message_Type)
  is
    Data_Sink_DATA : PolyORB_HI_Generated.Types.Alpha_Type;
    use PolyORB_HI_Generated.Activity;
  begin
    if (Port
      = PolyORB_HI_Generated.Activity.Data_Sink)
    then
      PolyORB_HI_Generated.Marshallers.Unmarshall
       (Data_Sink_DATA,
        Message);
      Data :=
       PolyORB_HI_Generated.Activity.Software_Q_Impl_Interface'
         (Port => PolyORB_HI_Generated.Activity.Data_Sink,
          Data_Sink_DATA => Data_Sink_DATA);
    end if;
  end Unmarshall;

end PolyORB_HI_Generated.Marshallers;
