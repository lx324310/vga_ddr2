/* 
 * Wrapper for Xilinx MIG'd DDR2 controller, allowing 3 masters
 * to contol the single interface.
 */

module xilinx_ddr2
  (
   // Inputs
    input [31:0] 	wbm0_adr_i, 
    input [1:0]  	wbm0_bte_i, 
    input [2:0]  	wbm0_cti_i, 
    input 	 	  	wbm0_cyc_i, 
    input [63:0] 	wbm0_dat_i, //lx 31->63 
    input [7:0]  	wbm0_sel_i, //lx 3->7
    input 	 	  	wbm0_stb_i, 
    input 	     	wbm0_we_i, 
   // Outputs
    output 	     	wbm0_ack_o, 
    output 	 	  	wbm0_err_o, 
    output 	     	wbm0_rty_o, 
    output[63:0] 	wbm0_dat_o, //lx 31->63
  
  
   // Inputs
    input [31:0]  wbm1_adr_i,  
    input [1:0]   wbm1_bte_i, 
    input [2:0]   wbm1_cti_i, 
    input 	  		wbm1_cyc_i, 
    input [63:0]  wbm1_dat_i, //lx 31->63
    input [7:0]   wbm1_sel_i, //lx 3->7
    input 	  		wbm1_stb_i, 
    input 	  		wbm1_we_i, 
   // Outputs
    output 	  		wbm1_ack_o, 
    output 	  		wbm1_err_o, 
    output 	  		wbm1_rty_o, 
    output[63:0] 	wbm1_dat_o, //lx 31->63

   // Inputs
    input [31:0]  wbm2_adr_i, 
    input [1:0]   wbm2_bte_i, 
    input [2:0]   wbm2_cti_i, 
    input 	  		wbm2_cyc_i, 
    input [63:0]  wbm2_dat_i, //lx 31->63
    input [7:0]   wbm2_sel_i, //lx 3->7
    input 	  		wbm2_stb_i, 
    input 	  		wbm2_we_i, 
   // Outputs
    output 	  		wbm2_ack_o, 
    output 	  		wbm2_err_o, 
    output 	  		wbm2_rty_o, 
    output [63:0] wbm2_dat_o, //lx 31->63
	
	// Inputs
    input [31:0] 	wbm3_adr_i, 
    input [1:0]  	wbm3_bte_i, 
    input [2:0]  	wbm3_cti_i, 
    input 	 	 	wbm3_cyc_i, 
    input [63:0] 	wbm3_dat_i, //lx 31->63
    input [7:0]  	wbm3_sel_i, //lx 3->7
    input 	 	 	wbm3_stb_i, 
    input 	    	wbm3_we_i, 
   // Outputs
    output 	 		wbm3_ack_o, 
    output 	 		wbm3_err_o, 
    output 	 		wbm3_rty_o, 
    output [63:0] wbm3_dat_o, //lx 31->63
   
   // Inputs
    input [31:0]  wbm4_adr_i, 
    input [1:0]   wbm4_bte_i, 
    input [2:0]   wbm4_cti_i, 
    input 	  		wbm4_cyc_i, 
    input [63:0]  wbm4_dat_i, //lx 31->63
    input [7:0]   wbm4_sel_i, //lx 3->7
    input 	  		wbm4_stb_i, 
    input 	  		wbm4_we_i, 
   // Outputs
    output 	  		wbm4_ack_o, 
    output 	  		wbm4_err_o, 
    output 	  		wbm4_rty_o, 
    output [63:0] wbm4_dat_o,	//lx 31->63

    input 	  wb_clk,
    input 	  wb_rst,

    output [12:0] ddr2_a,
    output [1:0]  ddr2_ba,
    output 	  ddr2_ras_n,
    output 	  ddr2_cas_n,
    output 	  ddr2_we_n,
    output [1:0]  ddr2_cs_n,
    output [1:0]  ddr2_odt,
    output [1:0]  ddr2_cke,
    output [7:0]  ddr2_dm,
   
    inout [63:0]  ddr2_dq,		  
    inout [7:0]   ddr2_dqs,
    inout [7:0]   ddr2_dqs_n,
    output [1:0]  ddr2_ck,
    output [1:0]  ddr2_ck_n,
    output	  phy_init_done,//lx
    input 	  ddr2_if_clk,
    input 	  clk200,
    input 	  ddr2_if_rst
   
   );

   // Internal wires to actual RAM
   wire [31:0]   wbs_ram_adr_i;
   wire [1:0] 	  wbs_ram_bte_i;
   wire [2:0] 	  wbs_ram_cti_i;
   wire 	  	     wbs_ram_cyc_i;
   wire [63:0]   wbs_ram_dat_i; //lx 31->63
   wire [7:0] 	  wbs_ram_sel_i; //lx 3->7
   wire 	  	     wbs_ram_stb_i;
   wire 	   	  wbs_ram_we_i;
   
   wire 	  	     wbs_ram_ack_o;
   wire [63:0]   wbs_ram_dat_o; //lx 31->63

   reg [4:0] 	  input_select, last_selected;
   wire 	  	     arb_for_wbm0, arb_for_wbm1, arb_for_wbm2, arb_for_wbm3, arb_for_wbm4;
   // Wires allowing selection of new input
   assign arb_for_wbm0 = (last_selected[1] | last_selected[2] | last_selected[3] | last_selected[4] |
						  !wbm1_cyc_i | !wbm2_cyc_i | !wbm3_cyc_i | !wbm4_cyc_i) & !(|input_select);
			  
   assign arb_for_wbm1 = (last_selected[0] | last_selected[2] | last_selected[3] | last_selected[4] |
						  !wbm0_cyc_i | !wbm2_cyc_i | !wbm3_cyc_i | !wbm4_cyc_i) & !(|input_select);
			  
   assign arb_for_wbm2 = (last_selected[0] | last_selected[1] | last_selected[3] | last_selected[4] | 
						  !wbm0_cyc_i | !wbm1_cyc_i | !wbm3_cyc_i | !wbm4_cyc_i) & !(|input_select);
						  
   assign arb_for_wbm3 = (last_selected[0] | last_selected[1] | last_selected[2] | last_selected[4] |
						  !wbm0_cyc_i | !wbm1_cyc_i | !wbm2_cyc_i | !wbm4_cyc_i) & !(|input_select);

   assign arb_for_wbm4 = (last_selected[0] | last_selected[1] | last_selected[2] | last_selected[3] |
						  !wbm0_cyc_i | !wbm1_cyc_i | !wbm2_cyc_i | !wbm3_cyc_i) & !(|input_select);						  
   // Master select logic
   always @(posedge wb_clk)
     if (wb_rst)
       input_select <= 0;
     else if ((input_select[0] & !wbm0_cyc_i) | (input_select[1] & !wbm1_cyc_i) |
	          (input_select[2] & !wbm2_cyc_i) | (input_select[3] & !wbm3_cyc_i) | (input_select[4] & !wbm4_cyc_i))
       input_select <= 0;
     else if (!(&input_select) & wbm0_cyc_i & arb_for_wbm0)
       input_select <= 5'b00001;
     else if (!(&input_select) & wbm1_cyc_i & arb_for_wbm1)
       input_select <= 5'b00010;
     else if (!(&input_select) & wbm2_cyc_i & arb_for_wbm2)
       input_select <= 5'b00100;
	 else if (!(&input_select) & wbm3_cyc_i & arb_for_wbm3)
       input_select <= 5'b01000;
     else if (!(&input_select) & wbm4_cyc_i & arb_for_wbm4)
       input_select <= 5'b10000;  
	 
   
   always @(posedge wb_clk)
     if (wb_rst)
       last_selected <= 0;
     else if (!(&input_select) & wbm0_cyc_i & arb_for_wbm0)
       last_selected <= 5'b00001;
     else if (!(&input_select) & wbm1_cyc_i & arb_for_wbm1)
       last_selected <= 5'b00010;
     else if (!(&input_select) & wbm2_cyc_i & arb_for_wbm2)
       last_selected <= 5'b00100;
	 else if (!(&input_select) & wbm3_cyc_i & arb_for_wbm3)
       last_selected <= 5'b01000;
     else if (!(&input_select) & wbm4_cyc_i & arb_for_wbm4)
       last_selected <= 5'b10000;

   // Mux input signals to RAM (default to wbm0)
   assign wbs_ram_adr_i = (input_select[4]) ? wbm4_adr_i : 
						  (input_select[3]) ? wbm3_adr_i :
						  (input_select[2]) ? wbm2_adr_i : 
						  (input_select[1]) ? wbm1_adr_i : 
						  (input_select[0]) ? wbm0_adr_i : 0;
						  
   assign wbs_ram_bte_i = (input_select[4]) ? wbm4_bte_i : 
						  (input_select[3]) ? wbm3_bte_i :
						  (input_select[2]) ? wbm2_bte_i : 
						  (input_select[1]) ? wbm1_bte_i : 
						  (input_select[0]) ? wbm0_bte_i : 0;
						  
   assign wbs_ram_cti_i = (input_select[4]) ? wbm4_cti_i : 
						  (input_select[3]) ? wbm3_cti_i : 
						  (input_select[2]) ? wbm2_cti_i : 
						  (input_select[1]) ? wbm1_cti_i : 
						  (input_select[0]) ? wbm0_cti_i : 0;
						  
   assign wbs_ram_cyc_i = (input_select[4]) ? wbm4_cyc_i : 
						  (input_select[3]) ? wbm3_cyc_i : 
						  (input_select[2]) ? wbm2_cyc_i : 
						  (input_select[1]) ? wbm1_cyc_i : 
						  (input_select[0]) ? wbm0_cyc_i : 0;
						  
   assign wbs_ram_dat_i = (input_select[4]) ? wbm4_dat_i : 
						  (input_select[3]) ? wbm3_dat_i :
						  (input_select[2]) ? wbm2_dat_i : 
						  (input_select[1]) ? wbm1_dat_i : 
						  (input_select[0]) ? wbm0_dat_i : 0;
						  
   assign wbs_ram_sel_i = (input_select[4]) ? wbm4_sel_i : 
						  (input_select[3]) ? wbm3_sel_i : 
						  (input_select[2]) ? wbm2_sel_i : 
						  (input_select[1]) ? wbm1_sel_i : 
						  (input_select[0]) ? wbm0_sel_i : 0;
						  
   assign wbs_ram_stb_i = (input_select[4]) ? wbm4_stb_i : 
						  (input_select[3]) ? wbm3_stb_i :
						  (input_select[2]) ? wbm2_stb_i : 
						  (input_select[1]) ? wbm1_stb_i : 
						  (input_select[0]) ? wbm0_stb_i : 0;
						  
   assign wbs_ram_we_i  = (input_select[4]) ? wbm4_we_i  :
						  (input_select[3]) ? wbm3_we_i  :
						  (input_select[2]) ? wbm2_we_i  :
						  (input_select[1]) ? wbm1_we_i  : 
						  (input_select[0]) ? wbm0_we_i  : 0;
						  

   // Output from RAM, gate the ACK, ERR, RTY signals appropriately
   assign wbm0_dat_o = wbs_ram_dat_o;
   assign wbm0_ack_o = wbs_ram_ack_o & input_select[0];
   assign wbm0_err_o = 0;   
   assign wbm0_rty_o = 0;

   assign wbm1_dat_o = wbs_ram_dat_o;
   assign wbm1_ack_o = wbs_ram_ack_o & input_select[1];
   assign wbm1_err_o = 0;
   assign wbm1_rty_o = 0;

   assign wbm2_dat_o = wbs_ram_dat_o;
   assign wbm2_ack_o = wbs_ram_ack_o & input_select[2];
   assign wbm2_err_o = 0;
   assign wbm2_rty_o = 0;
	
	assign wbm3_dat_o = wbs_ram_dat_o;
   assign wbm3_ack_o = wbs_ram_ack_o & input_select[3];
   assign wbm3_err_o = 0;
   assign wbm3_rty_o = 0;

   assign wbm4_dat_o = wbs_ram_dat_o;
   assign wbm4_ack_o = wbs_ram_ack_o & input_select[4];
   assign wbm4_err_o = 0;
   assign wbm4_rty_o = 0;

    xilinx_ddr2_if xilinx_ddr2_if0
     (

      .wb_dat_o				(wbs_ram_dat_o),
      .wb_ack_o				(wbs_ram_ack_o),
      .wb_adr_i				(wbs_ram_adr_i),
      .wb_stb_i				(wbs_ram_stb_i),
      .wb_cti_i				(wbs_ram_cti_i),
      .wb_bte_i				(wbs_ram_bte_i),
      .wb_cyc_i				(wbs_ram_cyc_i),
      .wb_we_i					(wbs_ram_we_i),
      .wb_sel_i				(wbs_ram_sel_i),
      .wb_dat_i				(wbs_ram_dat_i),

      .ddr2_a				(ddr2_a[12:0]),
      .ddr2_ba				(ddr2_ba[1:0]),
      .ddr2_ras_n			(ddr2_ras_n),
      .ddr2_cas_n			(ddr2_cas_n),
      .ddr2_we_n			(ddr2_we_n),
      .ddr2_cs_n			(ddr2_cs_n),
      .ddr2_odt				(ddr2_odt),
      .ddr2_cke				(ddr2_cke),
      .ddr2_dm				(ddr2_dm[7:0]),
      .ddr2_ck				(ddr2_ck[1:0]),
      .ddr2_ck_n			(ddr2_ck_n[1:0]),
      .ddr2_dq				(ddr2_dq[63:0]),
      .ddr2_dqs				(ddr2_dqs[7:0]),
      .ddr2_dqs_n			(ddr2_dqs_n[7:0]),	 
		.phy_init_done    (phy_init_done),//lx
      .ddr2_if_clk      		(ddr2_if_clk),
      .idly_clk_200			(clk200),
      .ddr2_if_rst                      (ddr2_if_rst),
      .wb_clk				(wb_clk),
      .wb_rst				(wb_rst));
  


   
endmodule

