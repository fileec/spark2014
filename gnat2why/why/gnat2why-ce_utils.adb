------------------------------------------------------------------------------
--                                                                          --
--                            GNAT2WHY COMPONENTS                           --
--                                                                          --
--                      G N A T 2 W H Y - C E _ U T I L S                   --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--                        Copyright (C) 2018, AdaCore                       --
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

with Gnat2Why.Tables; use Gnat2Why.Tables;

package body Gnat2Why.CE_Utils is

   --------------------------------------
   -- Count_Why_Visible_Regular_Fields --
   --------------------------------------

   function Count_Why_Visible_Regular_Fields (E : Entity_Id) return Natural is
      Count : Natural := 0;
   begin
      --  Add one field for tagged types to represent the unknown extension
      --  components. The field for the tag itself is stored directly in the
      --  Why3 record.

      if Is_Tagged_Type (E) then
         Count := Count + 1;
      end if;

      --  ??? Inefficient: the length could be computed once.
      for Component of Get_Component_Set (E) loop
         if Component_Is_Present_In_Type (E, Component) then
            Count := Count + 1;
         end if;
      end loop;

      return Count;
   end Count_Why_Visible_Regular_Fields;

   ------------------------
   -- Is_Visible_In_Type --
   ------------------------

   --  Body intentionally hidden from spec file
   function Is_Visible_In_Type (Rec  : Entity_Id;
                                Comp : Entity_Id)
                                return Boolean
   is
     (Ekind (Comp) = E_Discriminant
      or else (not Is_Type (Comp)
               and then Component_Is_Present_In_Type
                 (Rec, Search_Component_In_Type (Rec, Comp))));

   -------------------
   -- Get_Entity_Id --
   -------------------

   function Get_Entity_Id (Is_Record : Boolean; S : String) return Entity_Id is
      I : constant Integer := (if Is_Record then 1 else 0);
   begin
      if S'First + I > S'Last then
         return Empty;
      else
         return Entity_Id'Value (S (S'First + I .. S'Last));
      end if;
   exception
      when Constraint_Error =>
         return Empty;
   end Get_Entity_Id;

end Gnat2Why.CE_Utils;
