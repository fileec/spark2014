------------------------------------------------------------------------------
--                                                                          --
--                            GNAT2WHY COMPONENTS                           --
--                                                                          --
--                                 F L O W                                  --
--                                                                          --
--                                 S p e c                                  --
--                                                                          --
--                  Copyright (C) 2013-2016, Altran UK Limited              --
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
------------------------------------------------------------------------------

with Ada.Containers;
with Ada.Containers.Hashed_Maps;
with Ada.Containers.Hashed_Sets;
with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;      use Ada.Strings.Unbounded;
with Atree;                      use Atree;
with Common_Containers;          use Common_Containers;
with Einfo;                      use Einfo;
with Flow_Dependency_Maps;       use Flow_Dependency_Maps;
with Flow_Refinement;            use Flow_Refinement;
with Flow_Types;                 use Flow_Types;
with Graphs;
with Types;                      use Types;

package Flow is

   ----------------------------------------------------------------------
   --  Common abbreviations and acronyms
   --
   --  Through the Flow.* package hierarchy, the following abbreviations
   --  and acronyms are used:
   --
   --  CDG  - Control Dependence Graph
   --  CFG  - Control Flow Graph
   --  DDG  - Data Dependence Graph
   --  IPFA - Interprocedural Flow Analysis
   --  PDG  - Program Dependence Graph
   --  TDG  - Transitive Dependence Graph
   ----------------------------------------------------------------------

   ----------------------------------------------------------------------
   --  Flow_Graphs
   ----------------------------------------------------------------------

   package Flow_Graphs is new Graphs
     (Vertex_Key   => Flow_Id,
      Key_Hash     => Hash,
      Edge_Colours => Edge_Colours,
      Null_Key     => Null_Flow_Id,
      Test_Key     => "=");

   package Attribute_Maps is new Ada.Containers.Hashed_Maps
     (Key_Type        => Flow_Graphs.Vertex_Id,
      Element_Type    => V_Attributes,
      Hash            => Flow_Graphs.Vertex_Hash,
      Equivalent_Keys => Flow_Graphs."=");

   procedure Print_Graph_Vertex (G : Flow_Graphs.Graph;
                                 M : Attribute_Maps.Map;
                                 V : Flow_Graphs.Vertex_Id);
   --  Print a human-readable representation for the given vertex.

   ----------------------------------------------------------------------
   --  Vertex Pair
   ----------------------------------------------------------------------

   type Vertex_Pair is record
      From : Flow_Graphs.Vertex_Id;
      To   : Flow_Graphs.Vertex_Id;
   end record;

   function Vertex_Pair_Hash
     (VD : Vertex_Pair)
      return Ada.Containers.Hash_Type;
   --  Hash a Vertex_Pair (useful for building sets of vertex pairs).

   ----------------------------------------------------------------------
   --  Utility packages
   ----------------------------------------------------------------------

   package Node_To_Vertex_Maps is new Ada.Containers.Hashed_Maps
     (Key_Type        => Node_Id,
      Element_Type    => Flow_Graphs.Vertex_Id,
      Hash            => Node_Hash,
      Equivalent_Keys => "=",
      "="             => Flow_Graphs."=");

   package Vertex_Sets is new Ada.Containers.Hashed_Sets
     (Element_Type        => Flow_Graphs.Vertex_Id,
      Hash                => Flow_Graphs.Vertex_Hash,
      Equivalent_Elements => Flow_Graphs."=",
      "="                 => Flow_Graphs."=");

   package Vertex_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Flow_Graphs.Vertex_Id,
      "="          => Flow_Graphs."=");

   package Vertex_To_Vertex_Set_Maps is new Ada.Containers.Hashed_Maps
     (Key_Type        => Flow_Graphs.Vertex_Id,
      Element_Type    => Vertex_Sets.Set,
      Hash            => Flow_Graphs.Vertex_Hash,
      Equivalent_Keys => Flow_Graphs."=",
      "="             => Vertex_Sets."=");

   package Vertex_To_Natural_Maps is new Ada.Containers.Hashed_Maps
     (Key_Type        => Flow_Graphs.Vertex_Id,
      Element_Type    => Natural,
      Hash            => Flow_Graphs.Vertex_Hash,
      Equivalent_Keys => Flow_Graphs."=",
      "="             => "=");

   package Vertex_Pair_Sets is new Ada.Containers.Hashed_Sets
     (Element_Type        => Vertex_Pair,
      Hash                => Vertex_Pair_Hash,
      Equivalent_Elements => "=",
      "="                 => "=");

   ----------------------------------------------------------------------
   --  Flow_Analysis_Graphs
   ----------------------------------------------------------------------

   --  ??? This should be a variant record, but O325-005 and AI12-0047 make
   --      this difficult.
   type Flow_Global_Generation_Info is record
      Aborted : Boolean;
      --  Set if graph creation, processing or analysis raised some error;
      --  or if the entity should not be analyzed in the first place.

      Globals : Node_Sets.Set;
      --  Non-local variables and parameters other than those of the analyzed
      --  entity.
   end record;

   type Tasking_Info_Kind is (Suspends_On,
                              Entry_Calls,
                              Unsynch_Accesses,
                              Read_Locks,
                              Write_Locks);
   pragma Ordered (Tasking_Info_Kind);
   --  Tasking-related information that needs to be collected for each analyzed
   --  entity.

   type Tasking_Info is array (Tasking_Info_Kind) of Node_Sets.Set;
   --  Named array type for sets of nodes related to tasking

   type Flow_Analysis_Graphs_Root
     (Kind               : Analyzed_Subject_Kind := Kind_Subprogram;
      Generating_Globals : Boolean               := False)
   is record
      Analyzed_Entity       : Entity_Id;
      B_Scope               : Flow_Scope;
      S_Scope               : Flow_Scope;
      --  The entity and scope (of the body and spec) of the analysed entity.
      --  The two scopes might be the same in some cases.

      Spec_Entity           : Entity_Id;
      --  Useful shorthand to the node where the N_Contract node is attached

      Start_Vertex          : Flow_Graphs.Vertex_Id;
      Helper_End_Vertex     : Flow_Graphs.Vertex_Id;
      End_Vertex            : Flow_Graphs.Vertex_Id;
      --  The start, helper end and end vertices in the graphs. Start and end
      --  are the obvious, and the helper end is used to indicate the end of
      --  the procedure (i.e. returns jump here), but before postconditions
      --  are checked.

      CFG                   : Flow_Graphs.Graph;
      DDG                   : Flow_Graphs.Graph;
      CDG                   : Flow_Graphs.Graph;
      TDG                   : Flow_Graphs.Graph;
      PDG                   : Flow_Graphs.Graph;
      --  The graphs

      Atr                   : Attribute_Maps.Map;
      --  The vertex attributes for the above graphs.

      Other_Fields          : Vertex_To_Vertex_Set_Maps.Map;
      --  For a vertex corresponding to a record field this map will hold a
      --  vertex set of the other record fields.

      Local_Constants       : Node_Sets.Set;
      --  All constants that have been locally declared. This is used as a
      --  workaround to the issue of constants being ignored in general.
      --  This field should be removed once constants, attributes, etc. are
      --  dealt with correctly.

      All_Vars              : Flow_Id_Sets.Set;
      --  Variables used in the body

      Pragma_Un_Vars        : Node_Sets.Set;
      --  Variables that are not expected to be modified, used or referenced
      --  because they were named in a pragma Unmodified or a pragma Unused
      --  or pragma Unreferenced.

      Loops                 : Node_Sets.Set;
      --  Loops (identified by labels)

      Base_Filename         : Unbounded_String;
      --  A string with the name of the entity that is being analysed. It
      --  follows the convention that we use for naming the .dot and .pdf
      --  files.

      Dependency_Map        : Dependency_Maps.Map;
      --  A map of all the dependencies

      No_Errors_Or_Warnings : Boolean;
      --  True if no errors or warnings were found while flow analysing this
      --  entity. This is initialized to True and set to False when an error
      --  or a warning is found.

      Direct_Calls          : Node_Sets.Set;
      --  Subprograms called

      GG                    : Flow_Global_Generation_Info;
      --  Information for globals computation

      Tasking               : Tasking_Info;
      --  Tasking-related information collected in phase 1

      Is_Generative         : Boolean;
      --  True if we do not have a global contract

      case Kind is
         when Kind_Subprogram | Kind_Task =>
            Is_Main : Boolean;
            --  True if this is a task or a main program, i.e. a library level
            --  subprogram without formal parameters (global parameters are
            --  allowed).

            Last_Statement_Is_Raise : Boolean;
            --  True if the last statement of the subprogram is an
            --  N_Raise_Statement.

            Global_N          : Node_Id;
            Refined_Global_N  : Node_Id;
            Depends_N         : Node_Id;
            Refined_Depends_N : Node_Id;
            --  A few contract nodes cached as they can be a tedious to find

            No_Effects : Boolean;
            --  True if this is a subprogram with no effects. Certain analysis
            --  are disabled in this case as we would spam the user with error
            --  messages for almost every statement.

            Function_Side_Effects_Present : Boolean;
            --  Set to True if we are dealing with a function that has side
            --  effects.

         when Kind_Package | Kind_Package_Body =>
            Initializes_N : Node_Id;
            --  Contract node cached, since it is tedious to find

            Visible_Vars : Flow_Id_Sets.Set;
            --  Variables visible in the package elaboration

            Spec_Vars : Flow_Id_Sets.Set;
            --  Variables visible in the package specification (including
            --  private ones).

      end case;
   end record;

   function Is_Valid (X : Flow_Analysis_Graphs_Root) return Boolean;

   subtype Flow_Analysis_Graphs is Flow_Analysis_Graphs_Root
   with Dynamic_Predicate => Is_Valid (Flow_Analysis_Graphs);

   package Analysis_Maps is new Ada.Containers.Hashed_Maps
     (Key_Type        => Entity_Id,
      Element_Type    => Flow_Analysis_Graphs,
      Hash            => Node_Hash,
      Equivalent_Keys => "=",
      "="             => "=");

   ----------------------------------------------------------------------
   --  Utilities
   ----------------------------------------------------------------------

   function Loop_Parameter_From_Loop (E : Entity_Id) return Entity_Id
   with Pre  => Ekind (E) = E_Loop,
        Post => No (Loop_Parameter_From_Loop'Result) or else
                Ekind (Loop_Parameter_From_Loop'Result) = E_Loop_Parameter;
   --  Given a loop label, returns the identifier of the loop
   --  parameter or Empty.

   ----------------------------------------------------------------------
   --  Debug
   ----------------------------------------------------------------------

   procedure Print_Graph
     (Filename          : String;
      Analyzed_Entity   : Entity_Id;
      G                 : Flow_Graphs.Graph;
      M                 : Attribute_Maps.Map;
      Start_Vertex      : Flow_Graphs.Vertex_Id := Flow_Graphs.Null_Vertex;
      Helper_End_Vertex : Flow_Graphs.Vertex_Id := Flow_Graphs.Null_Vertex;
      End_Vertex        : Flow_Graphs.Vertex_Id := Flow_Graphs.Null_Vertex);
   --  Write a dot and pdf file for the given graph.

   ----------------------------------------------------------------------
   --  Main entry to flo analysis
   ----------------------------------------------------------------------

   procedure Flow_Analyse_CUnit (GNAT_Root : Node_Id);
   --  Flow analyses the current compilation unit

   procedure Generate_Flow_Globals (GNAT_Root : Node_Id);
   --  Generate flow globals for the current compilation unit

private

   FA_Graphs : Analysis_Maps.Map := Analysis_Maps.Empty_Map;
   --  All analysis results are stashed here in case we need them later. In
   --  particular the Flow.Trivia package makes use of this.

end Flow;
