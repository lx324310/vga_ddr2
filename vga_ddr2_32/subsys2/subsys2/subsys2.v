`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:10:30 03/09/2015 
// Design Name: 
// Module Name:    subsys2 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module subsys2(
	 input 	  wb_clk,
    input 	  wb_rst,
	//wishbone master port
	 input [31:0] 	wbm_adr_i, 
    input [1:0]  	wbm_bte_i, 
    input [2:0]  	wbm_cti_i, 
    input 	 	  	wbm_cyc_i, 
    input [31:0] 	wbm_dat_i, 
    input [3:0]  	wbm_sel_i,
    input 	 	  	wbm_stb_i, 
    input 	     	wbm_we_i, 
   // Outputs
    output 	     	wbm_ack_o, 
    output 	 	  	wbm_err_o, 
    output 	     	wbm_rty_o, 
    output[31:0] 	wbm_dat_o,
	//fill ddr2 finish signal
    output			fill_done,
	//ddr2 initial done
	 output			phy_init_done,
	//ddr2 port
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

    input 	  ddr2_if_clk,
    input 	  clk200,
    input 	  ddr2_if_rst
    );
	 //wishbone master1 signal define
	 reg wbm1_cyc_o;
	 reg wbm1_stb_o;
	 reg[3:0] wbm1_sel_o;
	 reg[2:0] wbm1_cti_o;
	 reg[1:0] wbm1_bte_o;
	 reg[31:0] wbm1_adr_o;
	 reg[31:0] wbm1_dat_o;
	 reg wbm1_we_o;
//
// xilinx ddir wraper define
xilinx_ddr2 xilinx_ddr2_inst (
    .wbm0_adr_i(wbm_adr_i), 
    .wbm0_bte_i(wbm_bte_i), 
    .wbm0_cti_i(wbm_cti_i), 
    .wbm0_cyc_i(wbm_cyc_i), 
    .wbm0_dat_i(wbm_dat_i), 
    .wbm0_sel_i(wbm_sel_i), 
    .wbm0_stb_i(wbm_stb_i), 
    .wbm0_we_i(wbm_we_i), 
    .wbm0_ack_o(wbm_ack_o), 
    .wbm0_err_o(wbm_err_o), 
    .wbm0_rty_o(wbm_rty_o), 
    .wbm0_dat_o(wbm_dat_o), 
    .wbm1_adr_i(wbm1_adr_o), 
    .wbm1_bte_i(wbm1_bte_o), 
    .wbm1_cti_i(wbm1_cti_o), 
    .wbm1_cyc_i(wbm1_cyc_o), 
    .wbm1_dat_i(wbm1_dat_o), 
    .wbm1_sel_i(wbm1_sel_o), 
    .wbm1_stb_i(wbm1_stb_o), 
    .wbm1_we_i(wbm1_we_o), 
    .wbm1_ack_o(wbm1_ack_i), 
    .wbm1_err_o(wbm1_err_i), 
    .wbm1_rty_o(), 
    .wbm1_dat_o(), 
    .wbm2_adr_i(0), 
    .wbm2_bte_i(0), 
    .wbm2_cti_i(0), 
    .wbm2_cyc_i(0), 
    .wbm2_dat_i(0), 
    .wbm2_sel_i(0), 
    .wbm2_stb_i(0), 
    .wbm2_we_i(0), 
    .wbm2_ack_o(), 
    .wbm2_err_o(), 
    .wbm2_rty_o(), 
    .wbm2_dat_o(), 
    .wbm3_adr_i(0), 
    .wbm3_bte_i(0), 
    .wbm3_cti_i(0), 
    .wbm3_cyc_i(0), 
    .wbm3_dat_i(0), 
    .wbm3_sel_i(0), 
    .wbm3_stb_i(0), 
    .wbm3_we_i(0), 
    .wbm3_ack_o(), 
    .wbm3_err_o(), 
    .wbm3_rty_o(), 
    .wbm3_dat_o(), 
    .wbm4_adr_i(0), 
    .wbm4_bte_i(0), 
    .wbm4_cti_i(0), 
    .wbm4_cyc_i(0), 
    .wbm4_dat_i(0), 
    .wbm4_sel_i(0), 
    .wbm4_stb_i(0), 
    .wbm4_we_i(0), 
    .wbm4_ack_o(), 
    .wbm4_err_o(), 
    .wbm4_rty_o(), 
    .wbm4_dat_o(), 
    .wb_clk(wb_clk), 
    .wb_rst(wb_rst), 
    .ddr2_a(ddr2_a), 
    .ddr2_ba(ddr2_ba), 
    .ddr2_ras_n(ddr2_ras_n), 
    .ddr2_cas_n(ddr2_cas_n), 
    .ddr2_we_n(ddr2_we_n), 
    .ddr2_cs_n(ddr2_cs_n), 
    .ddr2_odt(ddr2_odt), 
    .ddr2_cke(ddr2_cke), 
    .ddr2_dm(ddr2_dm), 
    .ddr2_dq(ddr2_dq), 
    .ddr2_dqs(ddr2_dqs), 
    .ddr2_dqs_n(ddr2_dqs_n), 
    .ddr2_ck(ddr2_ck), 
    .ddr2_ck_n(ddr2_ck_n), 
	 .phy_init_done(phy_init_done),//lx
    .ddr2_if_clk(ddr2_if_clk), 
    .clk200(clk200), 
    .ddr2_if_rst(ddr2_if_rst)
    );

// color defines 
`define   RED      32'h00ff0000 //R:00000000_11111111_00000000_00000000
`define   GREEN    32'h0000ff00
`define   BLUE     32'h000000ff //B:00000000_00000000_00000000_11111111
`define   WHITE    32'h00ffffff
`define   BLACK    32'h00000000
`define   YELLOW   32'h00ffff00
`define   PINK     32'h00ff00ff
`define   OTHER    32'h0000ffff
parameter base_addr  =32'h3c000;
parameter image_size =32'h4b000;//640*480;
parameter idel		   =2'b00;
parameter normal_tran=2'b01;
parameter burst_tran =2'b10;
reg[1:0] cur_state,next_state;
reg wait_ack;
reg[31:0] rgb_cnt;
wire tran_stall= wait_ack & ~wbm1_ack_i;
always @(posedge wb_clk ) 
	if( wb_rst )
		begin
			cur_state=idel;
			rgb_cnt=0;
		end
	else if(!tran_stall)
		begin
			cur_state=next_state;
			if(wbm1_ack_i)
				rgb_cnt=rgb_cnt+1;
		end
wire[31:0] rgb_cnt0=rgb_cnt;		
assign fill_done=rgb_cnt0>=image_size;

wire[31:0] rgb_addr,color;
reg[31:0] color0;
assign rgb_addr=base_addr+rgb_cnt0*4;
assign color=color0;
always@( rgb_cnt0 )
	if(rgb_cnt0<32'h9600)
		color0<=`RED;
	else if(rgb_cnt0<32'h12c00)
		color0<=`GREEN;
	else if(rgb_cnt0<32'h1c200)
		color0<=`BLUE;
	else if(rgb_cnt0<32'h25800)
		color0<=`WHITE;
	else if(rgb_cnt0<32'h2ee00)
		color0<=`BLACK;
	else if(rgb_cnt0<32'h38400)
		color0<=`YELLOW;
	else if(rgb_cnt0<32'h41a00)
		color0<=`PINK;
	else
		color0<=`OTHER;

always@( cur_state or fill_done or phy_init_done )
	begin
		next_state=cur_state;
		case(cur_state)
			idel:begin 
			      wait_ack=0;
					if( !phy_init_done | fill_done)
						next_state=idel;
					else
						next_state=normal_tran;
				  end
			normal_tran:
				  begin
						wait_ack=1;
						next_state=idel;
					end
			default:next_state=idel;
		endcase
	end

always@(posedge wb_clk)
	case(cur_state)
		idel:
		begin
			wbm1_cyc_o<=1'b0;
			wbm1_stb_o<=1'b0;
			wbm1_sel_o<=4'b0;
			wbm1_cti_o<=3'b0;
			wbm1_bte_o<=2'b0;
			wbm1_we_o <=1'b1;
		end		
		normal_tran:
		begin
			wbm1_cyc_o<=1'b1  ;
			wbm1_stb_o<=1'b1  ;
			wbm1_sel_o<=4'hf;
			wbm1_cti_o<=3'b0;
			wbm1_bte_o<=2'b0;
			wbm1_adr_o<=rgb_addr;
			wbm1_dat_o<=color;
			wbm1_we_o <=1'b1;
		end
	endcase
	
endmodule
