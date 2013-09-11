------------------------------------------------------------------------------
--                                                                          --
--                            GNAT2WHY COMPONENTS                           --
--                                                                          --
--                          G N A T 2 W H Y - A R G S                       --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--                       Copyright (C) 2010-2013, AdaCore                   --
--                                                                          --
-- gnat2why is  free  software;  you can redistribute  it and/or  modify it --
-- under terms of the  GNU General Public License as published  by the Free --
-- Software  Foundation;  either version 3,  or (at your option)  any later --
-- version.  gnat2why is distributed  in the hope that  it will be  useful, --
-- but WITHOUT ANY WARRANTY; without even the implied warranty of  MERCHAN- --
-- TABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public --
-- License for  more details.  You should have  received  a copy of the GNU --
-- General  Public License  distributed with  gnat2why;  see file COPYING3. --
-- If not,  go to  http://www.gnu.org/licenses  for a complete  copy of the --
-- license.                                                                 --
--                                                                          --
-- gnat2why is maintained by AdaCore (http://www.adacore.com)               --
--                                                                          --
------------------------------------------------------------------------------

with GNAT.Directory_Operations; use GNAT.Directory_Operations;
with GNAT.OS_Lib;               use GNAT.OS_Lib;

with Call;                      use Call;
with Output;                    use Output;
with Types;                     use Types;

package body Gnat2Why_Args is

   --  The extra options are passed to gnat2why using a file, specified
   --  via -gnates. This file contains on each line a single argument.
   --  Each argument is of the form
   --    name=value
   --  where neither "name" nor "value" can contain spaces. Each "name"
   --  corresponds to a global variable in this package (lower case).

   --  For boolean variables, the presence of the name means "true", absence
   --  means "false". For other variables, the value is given after the "="
   --  sign. No "=value" part is allowed for boolean variables.

   Warning_Mode_Name        : constant String := "warning_mode";
   Global_Gen_Mode_Name     : constant String := "global_gen_mode";
   Check_Mode_Name          : constant String := "check_mode";
   Flow_Analysis_Mode_Name  : constant String := "flow_analysis_mode";
   Flow_Debug_Mode_Name     : constant String := "flow_debug";
   Flow_Advanced_Debug_Name : constant String := "flow_advanced_debug";
   Analyze_File_Name        : constant String := "analyze_file";
   Limit_Subp_Name          : constant String := "limit_subp";
   Pedantic_Name            : constant String := "pedantic";
   Ide_Mode_Name            : constant String := "ide_mode";

   procedure Interpret_Token (Token : String);
   --  This procedure should be called on an individual token in the
   --  environment variable. It will set the corresponding boolean variable to
   --  True. The program is stopped if an unrecognized option is encountered.

   ----------
   -- Init --
   ----------

   procedure Init is

      procedure Read_File is new For_Line_In_File (Interpret_Token);

   begin
      if Opt.SPARK_Switches_File_Name /= null then
         Read_File (Opt.SPARK_Switches_File_Name.all);
      end if;
   end Init;

   ---------------------
   -- Interpret_Token --
   ---------------------

   procedure Interpret_Token (Token : String) is
   begin
      if Token = Global_Gen_Mode_Name then
         Global_Gen_Mode := True;

      elsif Token = Check_Mode_Name then
         Check_Mode := True;

      elsif Token = Flow_Analysis_Mode_Name then
         Flow_Analysis_Mode := True;

      elsif Token = Flow_Debug_Mode_Name then
         Flow_Debug_Mode := True;

      elsif Token = Flow_Advanced_Debug_Name then
         Flow_Advanced_Debug := True;

      elsif Token = Pedantic_Name then
         Pedantic := True;

      elsif Token = Ide_Mode_Name then
         Ide_Mode := True;

      elsif Starts_With (Token, Warning_Mode_Name) and then
        Token (Token'First + Warning_Mode_Name'Length) = '='
      then
         declare
            Start : constant Integer :=
              Token'First + Warning_Mode_Name'Length + 1;
         begin
            Warning_Mode :=
              Opt.Warning_Mode_Type'Value (Token (Start .. Token'Last));
         end;

      elsif Starts_With (Token, Analyze_File_Name) and then
        Token (Token'First + Analyze_File_Name'Length) = '='
      then
         declare
            Start : constant Integer :=
              Token'First + Analyze_File_Name'Length + 1;
         begin
            Analyze_File.Append (Token (Start .. Token'Last));
         end;

      elsif Starts_With (Token, Limit_Subp_Name) and then
        Token (Token'First + Limit_Subp_Name'Length) = '='
      then
         declare
            Start : constant Integer :=
              Token'First + Limit_Subp_Name'Length + 1;
         begin
            Limit_Subp := To_Unbounded_String (Token (Start .. Token'Last));
         end;
      else

         --  We play it safe and quit if there is an unrecognized option

         Write_Str ("error: unrecognized option" & Token & " given");
         Write_Eol;
         raise Terminate_Program;
      end if;
   end Interpret_Token;

   ---------
   -- Set --
   ---------

   function Set (Obj_Dir : String) return String is
      Cur_Dir : constant String := Get_Current_Dir;
      FD      : File_Descriptor;
      Name    : GNAT.OS_Lib.String_Access;

      procedure Write_Line (S : String);
      --  Write S to FD, and add a newline

      ----------------
      -- Write_Line --
      ----------------

      procedure Write_Line (S : String) is
         N : Integer;
         pragma Unreferenced (N);
      begin
         N := Write (FD, S'Address, S'Length);
         N := Write (FD, ASCII.LF'Address, 1);
      end Write_Line;

      --  beginning of processing for Set

   begin
      --  We need to switch to the given Obj_Dir so that the temp file is
      --  created there

      Change_Dir (Obj_Dir);
      Create_Temp_Output_File (FD, Name);

      --  Warning_Mode is only relevant when Global_Mode = False, so ignore its
      --  value if Global_Mode = True.

      if not Global_Gen_Mode then
         Write_Line (Warning_Mode_Name & "=" &
                       Opt.Warning_Mode_Type'Image (Warning_Mode));
      end if;

      if Global_Gen_Mode then
         Write_Line (Global_Gen_Mode_Name);
      end if;

      if Check_Mode then
         Write_Line (Check_Mode_Name);
      end if;

      if Flow_Analysis_Mode then
         Write_Line (Flow_Analysis_Mode_Name);
      end if;

      if Flow_Debug_Mode then
         Write_Line (Flow_Debug_Mode_Name);
      end if;

      if Flow_Advanced_Debug then
         Write_Line (Flow_Advanced_Debug_Name);
      end if;

      if Pedantic then
         Write_Line (Pedantic_Name);
      end if;

      if Ide_Mode then
         Write_Line (Ide_Mode_Name);
      end if;

      for File of Analyze_File loop
         Write_Line (Analyze_File_Name & "=" & File);
      end loop;

      if Limit_Subp /= Null_Unbounded_String then
         Write_Line (Limit_Subp_Name & "=" & To_String (Limit_Subp));
      end if;

      Close (FD);
      Change_Dir (Cur_Dir);

      declare
         S : constant String := Name.all;
      begin
         Free (Name);
         return Obj_Dir & Dir_Separator & S;
      end;
   end Set;

end Gnat2Why_Args;
