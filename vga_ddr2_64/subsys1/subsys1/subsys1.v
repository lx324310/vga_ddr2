`timescale 1ns / 100ps
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
module subsys1( 
  //system input
  input  wb_clk, //50MHz 
  input  vga_clk,  //vga_clk=2*wb_clk used as wbmaster data_fifo write clk lx
  input  pixel_clk, //50MHz, 640x480
  input  reset,
  // master signals
  output [31:0] wbm_adr_o,     // addressbus output
  input  [63:0] wbm_dat_i,     // Master databus input  //lx 31->63
  output [ 7:0] wbm_sel_o,     // byte select outputs   //lx 3->7
  output        wbm_we_o,      // write enable output
  output        wbm_stb_o,     // strobe output
  output        wbm_cyc_o,     // valid bus cycle output
  output [ 2:0] wbm_cti_o,     // cycle type identifier
  output [ 1:0] wbm_bte_o,     // burst type extensions
  input         wbm_ack_i,     // bus cycle acknowledge input
  input         wbm_err_i,     // bus cycle error input
  //dvi output
  output dvi_pclk_p, 
  output dvi_pclk_m, 
  output dvi_hsync, 
  output dvi_vsync, 
  output dvi_de, // dvi data enable
  output [11:0] dvi_d // dvi 12bit output
  );

reg [31:0] adr_to_dvi;
reg [31:0] dat_to_dvi;
reg we_to_dvi;
reg cs_to_dvi;
wire ack_from_dvi;	

//
///////vga core//////////
//
vga_enh_top  dvi_core_inst (
    .wb_clk_i ( wb_clk ), 
	 .vga_clk_i( vga_clk),
    .wb_rst_i ( reset ), 
    .rst_i    ( ~reset ), 
    .wb_inta_o(  ), //not used 
    //slave interface: to configure core
    .wbs_adr_i( adr_to_dvi[11:0] ), 
    .wbs_dat_i( dat_to_dvi ), 
    .wbs_dat_o( ), 
    .wbs_sel_i( 4'b1111 ), 
    .wbs_we_i ( we_to_dvi ), 
    .wbs_stb_i( cs_to_dvi ), 
    .wbs_cyc_i( cs_to_dvi ), 
    .wbs_ack_o( ack_from_dvi ), 
    .wbs_rty_o(  ), 
    .wbs_err_o(  ),
    //master interface: read data from frame buffer
    .wbm_adr_o( wbm_adr_o ), 
    .wbm_dat_i( wbm_dat_i ), 
    .wbm_cti_o( wbm_cti_o ), 
    .wbm_bte_o( wbm_bte_o ), 
    .wbm_sel_o( wbm_sel_o ), 
    .wbm_we_o ( wbm_we_o ), 
    .wbm_stb_o( wbm_stb_o ), 
    .wbm_cyc_o( wbm_cyc_o ), 
    .wbm_ack_i( wbm_ack_i ), 
    .wbm_err_i( wbm_err_i ),
    //dvi interface
    .clk_p_i      ( pixel_clk ), //pixel clock
    .dvi_pclk_p_o ( dvi_pclk_p ), //dvi output
    .dvi_pclk_m_o ( dvi_pclk_m ),  //dvi output 
    .dvi_hsync_o  ( dvi_hsync ),  //dvi output
    .dvi_vsync_o  ( dvi_vsync ),  //dvi output
    .dvi_de_o     ( dvi_de ),  //dvi output
    .dvi_d_o      ( dvi_d ), //dvi output
    .clk_p_o      (  ),     //unused for VGA
    .hsync_pad_o  (  ), //unused for VGA
    .vsync_pad_o  (  ), //unused for VGA
    .csync_pad_o  (  ), //unused for VGA
    .blank_pad_o  (  ), //unused for VGA
    .r_pad_o      (  ), //unused for VGA
    .g_pad_o      (  ), //unused for VGA
    .b_pad_o      (  )//unused for VGA
  );
//vga control register address map
`define   VGA_REG_CTRL   32'h0000_0000
`define   VGA_REG_STAT   32'h0000_0004
`define   VGA_REG_HTIM   32'h0000_0008
`define   VGA_REG_VTIM   32'h0000_000c
`define   VGA_REG_HVLEN  32'h0000_0010
`define   VGA_REG_VBARA  32'h0000_0014
`define   VGA_REG_VBARB  32'h0000_0018
//
//PARAMETERS
//
//frame buffer base address
parameter vbara  = 32'h3c000; //frame buffer A base address 0-4k
//
//vga timing parameter definitions 
/*
//640x480x60hz 50.25mhz
parameter thsync = 8'd95;
parameter thgdel = 8'd39;
parameter thgate = 16'd639; //640
parameter thlen  = 16'd799;

parameter tvsync = 8'd1;
parameter tvgdel = 8'd24;
parameter tvgate = 16'd479;//480
parameter tvlen  = 16'd524;
*/
/*
//800x600x60hz 80mhz
parameter thsync = 8'd127;
parameter thgdel = 8'd87;
parameter thgate = 16'd799; //800
parameter thlen  = 16'd1056;

parameter tvsync = 8'd3;
parameter tvgdel = 8'd22;
parameter tvgate = 16'd599;//600
parameter tvlen  = 16'd628;
*/

//1024x768x60hz 130mhz
parameter thsync = 8'd135;
parameter thgdel = 8'd159;
parameter thgate = 16'd1023; //1024
parameter thlen  = 16'd1343;

parameter tvsync = 8'd5;
parameter tvgdel = 8'd28;
parameter tvgate = 16'd767;//768
parameter tvlen  = 16'd805;

//
//Polarization parameters:
//0: Positive
//1: Negative
parameter hpol = 1'b1; //Horizontal Synchronization Pulse Polarization
parameter vpol = 1'b1; //Vertical Synchronization Pulse Polarization
parameter cpol = 1'b0; //Composite Synchronization Pulse Polarization
parameter bpol = 1'b0; //Blanking Polarization
//MISC
parameter dvi_odf = 2'b00;//dvi output format
parameter cd      = 2'h3; //32bpp colour depth
parameter pc      = 2'h0; //pseudo colour mode
parameter vbl     = 2'b10; //burst mode: classic wishbone cycle
parameter cbswe   = 1'b0; //CBSWE: CLUT bank switch enable
parameter vbswe   = 1'b0; //VBSWE: video buffer switch enable
parameter cbsie   = 1'b0; //CBSIE: CLUT bank switch interrupt enable
parameter vbsie   = 1'b0; //VBSIE: video buffer switch interrupt enable
parameter hie     = 1'b0; //HIE: HSync Interrupt Enable
parameter vie     = 1'b0; //VIE: VSync Interrupt Enable
parameter ven     = 1'b1; //VEN: Video Enable
////////////
//internal state machine
parameter init    = 3'h0;
parameter Cstop   = 3'h1;
parameter Cvbara  = 3'h2;
parameter Chtim   = 3'h3;
parameter Cvtim   = 3'h4;
parameter Chvlen  = 3'h5;
parameter Cstart  = 3'h6;

reg [2:0] cur_state;
reg [2:0] next_state;


//state machine control
reg wait_dvi_ack;
wire dvi_stall = wait_dvi_ack & (~ack_from_dvi);
//
reg init_done;
always @ (posedge wb_clk)
begin
 if(reset) 
	begin
		cur_state <= init;
		init_done<=1'b0;
	end
 else if(~dvi_stall) 
	begin
		cur_state <= next_state;
		if(cur_state==Cstart)
			init_done<=1'b1;
	end
end
// 
//
//next state logic
always@(cur_state)
begin
  next_state = cur_state;
  case(cur_state)
  //
  init: begin
      cs_to_dvi = 1'b0;
		dat_to_dvi = 32'h0;
		we_to_dvi   = 1'b0;
		wait_dvi_ack = 1'b0;
		if(init_done)
			next_state = init;
		else		
			next_state = Cstop;
		end
  //
  Cstop:begin
		cs_to_dvi = 1'b1;
		dat_to_dvi = 32'h0;
		adr_to_dvi = `VGA_REG_CTRL;
		we_to_dvi   = 1'b1;
		wait_dvi_ack = 1'b1;
		next_state = Cvbara;
		end

  //
  Cvbara: begin
		cs_to_dvi = 1'b1;
		dat_to_dvi = vbara;
		adr_to_dvi = `VGA_REG_VBARA;
		we_to_dvi   = 1'b1;
		wait_dvi_ack = 1'b1;
		next_state = Chtim;
		end
  
  Chtim: begin
		cs_to_dvi = 1'b1;
		dat_to_dvi = {thsync, thgdel, thgate};
		adr_to_dvi = `VGA_REG_HTIM;
		we_to_dvi   = 1'b1;
		wait_dvi_ack = 1'b1;
		next_state = Cvtim;
		end
  //
  Cvtim: begin
		cs_to_dvi = 1'b1;
		dat_to_dvi = {tvsync, tvgdel, tvgate};
		adr_to_dvi = `VGA_REG_VTIM;
		we_to_dvi   = 1'b1;
		wait_dvi_ack = 1'b1;
		next_state = Chvlen;
		end
  //
  Chvlen: begin
		cs_to_dvi = 1'b1;
		dat_to_dvi = {thlen, tvlen};
		adr_to_dvi = `VGA_REG_HVLEN;
		we_to_dvi   = 1'b1;
		wait_dvi_ack = 1'b1;
		next_state = Cstart;
		end
  //
  Cstart: begin
		cs_to_dvi = 1'b1;
		dat_to_dvi = {2'h0, dvi_odf, 12'h0, bpol, cpol, vpol, hpol, pc, cd, vbl, cbswe, vbswe, cbsie, vbsie, hie, vie, ven};
		adr_to_dvi = `VGA_REG_CTRL;
		we_to_dvi   = 1'b1;
		wait_dvi_ack = 1'b1;
		next_state = init;
		end
  endcase
end
//
endmodule
