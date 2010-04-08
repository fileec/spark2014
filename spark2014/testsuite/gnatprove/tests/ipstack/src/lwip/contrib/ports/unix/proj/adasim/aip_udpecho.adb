------------------------------------------------------------------------------
--                            IPSTACK COMPONENTS                            --
--             Copyright (C) 2010, Free Software Foundation, Inc.           --
------------------------------------------------------------------------------

with AIP_Ctypes, AIP_IPaddrs, AIP_Netbufs, AIP_Netconns;

package body AIP_Udpecho is

   procedure Run is
      NC : AIP_Netconns.Netconn_Id;
      NB : AIP_Netbufs.Netbuf_Id;
      IP : AIP_IPaddrs.IPaddr_Id;
      PT : AIP_Ctypes.U16_T;
      ER : AIP_Ctypes.Err_T;
   begin
      NC := AIP_Netconns.Netconn_New (AIP_Netconns.NETCONN_UDP);
      ER := AIP_Netconns.Netconn_Bind (NC, AIP_IPaddrs.IP_ADDR_ANY, 7);
      while True loop
         NB := AIP_Netconns.Netconn_Recv (NC);
         IP := AIP_Netbufs.Netbuf_Fromaddr (NB);
         PT := AIP_Netbufs.Netbuf_Fromport (NB);
         ER := AIP_Netconns.Netconn_Connect (NC, IP, PT);
         ER := AIP_Netconns.Netconn_Send (NC, NB);
         AIP_Netbufs.Netbuf_Delete (NB);
      end loop;
   end Run;

end AIP_Udpecho;
