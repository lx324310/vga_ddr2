`timescale 1ns / 100ps
`include "system-defines.v"
module system(
	`ifdef VGA0
		//ch7301 interface
		inout dvi_scl,
		inout dvi_sda,
		output dvi_rst,
		//character 16x2 LCD interface			
		output [3:0] sf_d,
		output lcd_e,
		output lcd_rs,
		output lcd_rw,
		//LED and push button
		output config_done_led,
		input ld_config_btn,  
		//
		output dvi_pclk_p, 
		output dvi_pclk_m, 
		output dvi_hsync, 
		output dvi_vsync, 
		output dvi_de, // dvi data enable
		output [11:0] dvi_d, // dvi 12bit output
	`endif
  // DDR2
	`ifdef	XILINX_DDR2
		output phy_init_done,
		output fill_done,
		output [12:0]      ddr2_a,
		output [1:0]       ddr2_ba,
		output 	       	 ddr2_ras_n,
		output 	        	 ddr2_cas_n,
		output 	       	 ddr2_we_n,
		output [1:0]       ddr2_cs_n,
		output [1:0]       ddr2_odt,
		output [1:0]       ddr2_cke,
		output [7:0]       ddr2_dm,
		inout [63:0]       ddr2_dq,	  
		inout [7:0]        ddr2_dqs,
		inout [7:0]        ddr2_dqs_n,
		output [1:0]       ddr2_ck,
		output [1:0]       ddr2_ck_n,
	`endif
	input clk200_p,
	input clk200_n,
	input rst_i
  );	

wire  wb_clk; //50MHz
wire  pixel_clk;//50MHZ 640X480
wire  reset;
wire  clk200;//200MHZ
wire  ddr2_if_clk;//266MHZ
wire  ddr2_if_rst;
clkgen clk_inst (
    .sys_clk_p_pad_i(clk200_p), 
    .sys_clk_n_pad_i(clk200_n), 
    .wb_clk_o(wb_clk), 
    .wb_rst_o(reset), 
    .async_rst_o(), 
    .dvi_clk_o(pixel_clk), 
    .ddr2_if_clk_o(ddr2_if_clk), 
    .ddr2_if_rst_o(ddr2_if_rst), 
    .clk200_o(clk200), 
    .rst_n_pad_i(~rst_i)
    );
			
subsys0 subsys0_inst (
  .clk( wb_clk ),
  .reset( reset ),
  //ch7301 interface
  .dvi_scl(dvi_scl),
  .dvi_sda(dvi_sda),
  .dvi_rst(dvi_rst),
  //character 16x2 LCD interface			
  .sf_d(sf_d),
  .lcd_e(lcd_e),
  .lcd_rs(lcd_rs),
  .lcd_rw(lcd_rw),
  //LED and push button
  .config_done_led(config_done_led),
  .ld_config_btn(ld_config_btn)        
	);

//
wire wbm_cyc_i;
wire wbm_stb_i;
wire wbm_we_i;
wire[3:0] wbm_sel_i;
wire[2:0] wbm_cti_i;
wire[1:0] wbm_bte_i;
wire[31:0] wbm_adr_i;
wire wbm_ack_o;
wire wbm_err_o;
wire[31:0] wbm_dat_o;

//
subsys1 subsys1_inst( 
  //system input
  .wb_clk( wb_clk ), //50MHz 
  .pixel_clk( pixel_clk ), //50M 640x480
  .reset( reset | ~config_done_led | ~fill_done ),
  //master interface: read data from frame buffer
  .wbm_adr_o(wbm_adr_i), 
  .wbm_bte_o(wbm_bte_i), 
  .wbm_cti_o(wbm_cti_i), 
  .wbm_cyc_o(wbm_cyc_i), 
  .wbm_dat_i(wbm_dat_o), 
  .wbm_sel_o(wbm_sel_i), 
  .wbm_stb_o(wbm_stb_i), 
  .wbm_we_o(wbm_we_i), 
  .wbm_ack_i(wbm_ack_o), 
  .wbm_err_i(wbm_err_o), 
  //dvi output
  .dvi_pclk_p( dvi_pclk_p ), //40MHz
  .dvi_pclk_m( dvi_pclk_m ), //40MHz
  .dvi_hsync( dvi_hsync ), 
  .dvi_vsync( dvi_vsync ), 
  .dvi_de( dvi_de ), // dvi data enable
  .dvi_d( dvi_d ) // dvi 12bit output
  );

//
//
// Instantiate the module
subsys2 subsys2_inst (
    .wb_clk(wb_clk), 
    .wb_rst(reset), 
    .wbm_adr_i(wbm_adr_i), 
    .wbm_bte_i(wbm_bte_i), 
    .wbm_cti_i(wbm_cti_i), 
    .wbm_cyc_i(wbm_cyc_i), 
    .wbm_dat_i(32'b0), 
    .wbm_sel_i(wbm_sel_i), 
    .wbm_stb_i(wbm_stb_i), 
    .wbm_we_i(wbm_we_i), 
    .wbm_ack_o(wbm_ack_o), 
    .wbm_err_o(wbm_err_o), 
    .wbm_rty_o(), 
    .wbm_dat_o(wbm_dat_o), 
    .fill_done(fill_done),
	 .phy_init_done(phy_init_done),
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
    .ddr2_if_clk(ddr2_if_clk), 
    .clk200(clk200), 
    .ddr2_if_rst(ddr2_if_rst)
    );
	
endmodule
