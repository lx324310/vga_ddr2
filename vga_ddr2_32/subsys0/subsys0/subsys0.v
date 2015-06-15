`include "lcd_defines.v"
//
module subsys0(
	//system interface
	input clk,
	input reset,
	
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
	output reg config_done_led,
	input ld_config_btn        
	);

assign dvi_rst = ~reset;

/////////push button dbounce///////////
wire ld_config_btn_db;
reg  ld_config_btn_db_dly;
wire ld_config_wire;
reg  ld_config;
dbounce db_inst (
    .clk        ( clk ), //50MHz
    .button_in  ( ld_config_btn ),
    .button_db  ( ld_config_btn_db )
    );

always @ (posedge clk)
  ld_config_btn_db_dly <= ld_config_btn_db;
assign ld_config_wire = ld_config_btn_db_dly & ~ld_config_btn_db;

always @ (posedge clk)
  if(reset) ld_config <= 1'b0;
  else if (ld_config_wire) ld_config <= 1'b1;
  else ld_config <= 1'b0;

//
//////////I2C master to ch7301//////////
reg  [2 :0] i2c_addr;
reg  [7 :0] i2c_data_txm; //i2c data transmitted
wire [7 :0] i2c_data_rcv; //i2c data received

reg  i2c_we;
reg  i2c_cs;
wire i2c_ack;
wire scl_o, scl_oen, sda_o, sda_oen;

i2c_master_top i2c_inst (
		.wb_clk_i	( clk ),
		.wb_rst_i	( reset ), 
		.arst_i		( 1'b1 ), 
		.wb_adr_i	( i2c_addr ),   //[2:0]
		.wb_dat_i	( i2c_data_txm ), //[7:0]
		.wb_dat_o	( i2c_data_rcv ), //[7:0]
		.wb_we_i	( i2c_we ), 
		.wb_stb_i	( i2c_cs ), 
		.wb_cyc_i	( i2c_cs ), 
		.wb_ack_o	( i2c_ack ), 
		.wb_inta_o	(),
		.scl_pad_i	( dvi_scl ), 
		.scl_pad_o	( scl_o ), 
		.scl_padoen_o	( scl_oen ), 
		.sda_pad_i	( dvi_sda ), 
		.sda_pad_o	( sda_o ), 
		.sda_padoen_o	( sda_oen )
			 );
//create i2c wires
assign dvi_scl = scl_oen? 1'bz : scl_o;
assign dvi_sda = sda_oen? 1'bz : sda_o;

//////////LCD //////////
reg  [7 :0] lcd_data_txm; //lcd data transmit
wire [31:0] wb_lcd_data_i = {24'b0, lcd_data_txm};

wire [31:0] wb_lcd_data_o;
wire lcd_busy = wb_lcd_data_o[0];

reg  [7 :0] lcd_addr; //00-1F: character ram; 80h: repainting
wire [31:0] wb_lcd_addr = {24'b0, lcd_addr};

reg  lcd_we;
reg  lcd_cs;
wire lcd_ack;

wb_lcd lcd_inst	(
		.wb_clk_i	( clk ),
		.wb_rst_i	( reset ),
		.wb_dat_i	( wb_lcd_data_i ), //[7:0]
		.wb_dat_o	( wb_lcd_data_o ), //busy= data_o[0]
		.wb_adr_i	( wb_lcd_addr ),
		.wb_sel_i	( 4'b1111 ), //not used
		.wb_we_i	( lcd_we ),
		.wb_cyc_i	( lcd_cs ),
		.wb_stb_i	( lcd_cs ),
		.wb_ack_o	( lcd_ack ),
		.wb_err_o	(  ),
		.SF_D		( sf_d ),
		.LCD_E		( lcd_e ),
		.LCD_RS		( lcd_rs ),
		.LCD_RW		( lcd_rw )
		);

//=========main body==========//
//
parameter CH7301_DEV_ADDR  = 7'h76;
//
//configuration rom
//
wire [7:0] CH7301_REG_ADDR [0:7];
assign CH7301_REG_ADDR[0] =  8'h49; //Power Management Register
assign CH7301_REG_ADDR[1] =  8'h1F; //Input Data Format Register
assign CH7301_REG_ADDR[2] =  8'h21; //DAC Control Register
assign CH7301_REG_ADDR[3] =  8'h33; //DVI PLL Charge Pump Control Register
assign CH7301_REG_ADDR[4] =  8'h34; //DVI PLL Divider Register
assign CH7301_REG_ADDR[5] =  8'h36; //DVI PLL Filter Register
assign CH7301_REG_ADDR[6] =  8'h1C; //Clock Mode Register
assign CH7301_REG_ADDR[7] =  8'h48; //Test Pattern Register

wire [7:0] CH7301_REG_DATA [0:7];
//The following configurations is based on Xilinx TFT doc.
assign CH7301_REG_DATA[0] =  8'hC0; 
assign CH7301_REG_DATA[1] =  8'h98; //Data format:0
assign CH7301_REG_DATA[2] =  8'h09; //Hsyn/Vsyn Enabled
assign CH7301_REG_DATA[3] =  8'h08; //08: <=65MHz; 06: >60Mhz
assign CH7301_REG_DATA[4] =  8'h16; //16: <=65MHz; 26: >65MHz
assign CH7301_REG_DATA[5] =  8'h60; //60: <=65MHz; A0: >65MHz
assign CH7301_REG_DATA[6] =  8'h00; //00: dual edge; 01: single edge
//assign CH7301_REG_DATA[7] =  8'h19; //19: test output color bar
assign CH7301_REG_DATA[7] =  8'h18; 
//
//iic core Register Address
//
parameter PRER_LO = 3'b000; //frequency scale
parameter PRER_HI = 3'b001;
parameter CTR     = 3'b010; //control
parameter RXR     = 3'b011; //rx
parameter TXR     = 3'b011; //tx
parameter CR      = 3'b100; //command
parameter SR      = 3'b100; //status
parameter RD      = 1'b1;
parameter WR      = 1'b0;
//
//state machine
//
parameter wST0 = 6'h00;
parameter wST1 = 6'h01;
parameter wST2 = 6'h02;
parameter wST3 = 6'h03;
parameter wST4 = 6'h04;
parameter wST5 = 6'h05;
parameter wST6 = 6'h06;
parameter wST7 = 6'h07;
parameter wST8 = 6'h08;
parameter wST9 = 6'h09;
parameter wSTa = 6'h0a;
parameter wSTb = 6'h0b;
parameter wait0= 6'h0c;
parameter rST0 = 6'h0d;
parameter rST1 = 6'h0e;
parameter rST2 = 6'h0f;
parameter rST3 = 6'h10;
parameter rST4 = 6'h11;
parameter rST5 = 6'h12;
parameter rST6 = 6'h13;
parameter rST7 = 6'h14;
parameter rST8 = 6'h15;
parameter rST9 = 6'h16;
parameter rSTa = 6'h17;
parameter rSTb = 6'h18;
parameter wait1= 6'h19;
parameter dummy0 = 6'h1a;
parameter dummy1 = 6'h1b;
parameter dummy2 = 6'h1c;
parameter dummy3 = 6'h1d;
parameter dummy4 = 6'h1e;
parameter dummy5 = 6'h1f;
parameter dummy6 = 6'h20;

reg  [5:0] cur_state;
reg  [5:0] next_state;

reg  wait_i2c_ack;
wire i2c_stall = wait_i2c_ack & ~i2c_ack;
always @ (posedge clk)
begin
  if(reset) cur_state <= wST0;
  else if(~i2c_stall)
   begin
     if( (cur_state == wST5) || (cur_state == wST8) || (cur_state == wSTb) || (cur_state == rST2) || (cur_state == rST5) || (cur_state == rST8) || (cur_state == rSTa) )
       begin
	   if( !i2c_data_rcv[1] ) cur_state <= next_state;
	   end
     else  cur_state <= next_state;
   end
end
//
reg [3:0] idx;
//
always @ (posedge clk)
begin
  if(reset) idx <= 4'b0;
  else if( ~i2c_stall && ((cur_state == wSTa) || (cur_state == rST9)) ) idx <= idx + 1;
  else if(cur_state == wait0) idx <= 4'b0;  
end
//
//
reg  wait_lcd_ack;
wire lcd_stall = wait_lcd_ack & ~lcd_ack;
reg  [7:0] sr;
reg repaint;
//
always @ (posedge clk)
begin
  if(reset) sr <= 8'hff; 
  else if( (cur_state == rSTb) && ~i2c_stall )
     sr <= i2c_data_rcv;
  else if(repaint)begin
    if(~lcd_stall) 
      sr <= {sr[6:0], 1'b1};
  end //if repaint
end
//
reg  show;
always @ (posedge clk)
begin
  if(reset) show <= 1'b0;
  else if(repaint)
    show <= 1'b0;
  else if( (cur_state == rSTb) && ~i2c_stall )  
    show <= 1'b1;  
end
//
integer i = 0;
always @(posedge clk) 
begin
	if(reset) begin
		i <= 0;
		lcd_cs <= 0;
        wait_lcd_ack <= 0;	
        repaint = 1'b1;		
	end 
	else if(~lcd_stall) begin
		if (i < 8) begin
			i <= i + 1;
			lcd_cs <= 1'b1;
			lcd_we <= 1'b1;
			lcd_addr <= i;
			lcd_data_txm <= sr[7]+8'h30;
			wait_lcd_ack <= 1;
		end 
		else if (i < 32) begin
			i <= i + 1;
			lcd_cs <= 1'b1;
			lcd_we <= 1'b1;
			lcd_addr <= i;
			lcd_data_txm <= 8'h20;//space
			wait_lcd_ack <= 1;
		end
		else if (i == 32) begin
			if(!lcd_busy & show) begin
				i <= 0;
				repaint = 1'b1;
				lcd_cs <= 1;
				lcd_addr <= 8'b10000000; // Command register
				lcd_data_txm <=  8'b00000001; // Repaint command
				lcd_we <= 1'b1;
				wait_lcd_ack <= 1;
			end 
			else begin
				lcd_cs <= 0;
				wait_lcd_ack <= 0;
				repaint = 1'b0;
			end
		end //i == 32 		
	end //~stall
end //always


always @ (posedge clk)
  if(reset) config_done_led <= 1'b0;
  else if(cur_state == wait0) config_done_led <= 1'b1;

////////-----TASK: wb_read/wb_write-----///////////
task wb_access;
  input [2:0] addr_i;
  input [7:0] data_i;
  input rw;
  output cs;
  output we;
  output [2:0] addr_o;
  output [7:0] data_o;
  output wait_ack;
  begin
   cs = 1'b1;
   we = ~rw;
   addr_o = addr_i;
   data_o = data_i;
   wait_ack = 1'b1;
  end
endtask
//

//next state logic
always @ (cur_state or idx or ld_config)
begin
  next_state = cur_state;
  case(cur_state)
  //  
  //===configure iic core
  // 
  wST0:   begin //wb_write(PRER_LO, 8'hf4): load prescaler lo-byte
          //wb_access(PRER_LO, 8'hf4, WR, i2c_cs, i2c_we, i2c_addr, i2c_data_txm, wait_i2c_ack);
		  wb_access(PRER_LO, 8'hff, WR, i2c_cs, i2c_we, i2c_addr, i2c_data_txm, wait_i2c_ack);
		  next_state = wST1; 
		  end
  wST1:   begin //wb_write(PRER_HI, 8'h01): load prescaler hi-byte
          //wb_access(PRER_HI, 8'h01, WR, i2c_cs, i2c_we, i2c_addr, i2c_data_txm, wait_i2c_ack);
		  wb_access(PRER_HI, 8'h00, WR, i2c_cs, i2c_we, i2c_addr, i2c_data_txm, wait_i2c_ack);
          next_state = wST2; 
		  end
  wST2:   begin //wb_write(CTR, 8'h80): enable core
          wb_access(CTR, 8'h80, WR, i2c_cs, i2c_we, i2c_addr, i2c_data_txm, wait_i2c_ack);
          next_state = wST3; 
		  end
  //
  //===configure ch7301 via iic
  //  
  wST3:   begin //wb_write(TXR, {CH7301_DEV_ADDR, WR} ): present slave address, set write-bit
          wb_access(TXR, {CH7301_DEV_ADDR, WR}, WR, i2c_cs, i2c_we, i2c_addr, i2c_data_txm, wait_i2c_ack);
          next_state = wST4; 
		  end
  wST4:   begin //wb_write(CR, 8'h90 ): set command (start, write)
          wb_access(CR, 8'h90, WR, i2c_cs, i2c_we, i2c_addr, i2c_data_txm, wait_i2c_ack);
          next_state = dummy0; 
		  end
  dummy0: begin
          wb_access(SR, 8'h00, RD, i2c_cs, i2c_we, i2c_addr, i2c_data_txm, wait_i2c_ack);
          next_state = wST5;
          end
  wST5:   begin //wb_read(SR), check tip = SR[1]
          wb_access(SR, 8'h00, RD, i2c_cs, i2c_we, i2c_addr, i2c_data_txm, wait_i2c_ack);
          next_state = wST6;
		  end
  wST6:   begin //wb_write(TXR, CH7301_REG_ADDR[idx]);
          wb_access(TXR, CH7301_REG_ADDR[idx], WR, i2c_cs, i2c_we, i2c_addr, i2c_data_txm, wait_i2c_ack);
          next_state = wST7; 
		  end
  wST7:   begin //wb_write(CR, 8'h10): set command (write)
          wb_access(CR, 8'h10, WR, i2c_cs, i2c_we, i2c_addr, i2c_data_txm, wait_i2c_ack);
          next_state = dummy1; 
		  end
  dummy1: begin
          wb_access(SR, 8'h00, RD, i2c_cs, i2c_we, i2c_addr, i2c_data_txm, wait_i2c_ack);
          next_state = wST8;
          end  
  wST8:   begin //wb_read(SR), check tip = SR[1]
          wb_access(SR, 8'h00, RD, i2c_cs, i2c_we, i2c_addr, i2c_data_txm, wait_i2c_ack);
          next_state = wST9; 
		  end
  wST9:   begin //wb_write(TXR, CH7301_REG_DATA[idx]);
          wb_access(TXR, CH7301_REG_DATA[idx], WR, i2c_cs, i2c_we, i2c_addr, i2c_data_txm, wait_i2c_ack);
          next_state = wSTa; 
		  end
  wSTa:   begin //wb_write(CR, 8'h50): set command (write, stop)
          wb_access(CR, 8'h50, WR, i2c_cs, i2c_we, i2c_addr, i2c_data_txm, wait_i2c_ack);
          next_state = dummy2; 
		  end
  dummy2: begin
          wb_access(SR, 8'h00, RD, i2c_cs, i2c_we, i2c_addr, i2c_data_txm, wait_i2c_ack);
          next_state = wSTb;
          end  
  wSTb:   begin //wb_read(SR), tip = SR[1]
          wb_access(SR, 8'h00, RD, i2c_cs, i2c_we, i2c_addr, i2c_data_txm, wait_i2c_ack);
          if(idx < 8)
           next_state = wST3;
          else		   
	       next_state = wait0;			
		  end
  //
  //===awaiting user push button
  // 
  wait0: begin
          i2c_cs = 1'b0;
		  wait_i2c_ack = 1'b0;
          if(ld_config)
           next_state = rST0;
		 end
  //
  //===read ch7301 reg data back 
  // 
  rST0:   begin //wb_write(TXR, {CH7301_DEV_ADDR, WR} ): present slave address, set write-bit
          wb_access(TXR, {CH7301_DEV_ADDR, WR}, WR, i2c_cs, i2c_we, i2c_addr, i2c_data_txm, wait_i2c_ack);          
          next_state = rST1;
		  end
  rST1:   begin //wb_write(CR, 8'h90 ): set command (start, write)
          wb_access(CR, 8'h90, WR, i2c_cs, i2c_we, i2c_addr, i2c_data_txm, wait_i2c_ack);
          next_state = dummy3;
		  end
  dummy3: begin
          wb_access(SR, 8'h00, RD, i2c_cs, i2c_we, i2c_addr, i2c_data_txm, wait_i2c_ack);
          next_state = rST2;
          end  		  
  rST2:   begin //wb_read(SR), check tip = SR[1]
          wb_access(SR, 8'h00, RD, i2c_cs, i2c_we, i2c_addr, i2c_data_txm, wait_i2c_ack); 
          next_state = rST3;
		  end
  rST3:   begin //wb_write(TXR, CH7301_REG_ADDR[i]);
          wb_access(TXR, CH7301_REG_ADDR[idx[2:0]], WR, i2c_cs, i2c_we, i2c_addr, i2c_data_txm, wait_i2c_ack);
          next_state = rST4;
		  end
  rST4:   begin //wb_write(CR, 8'h10): set command (write)
          wb_access(CR, 8'h10, WR, i2c_cs, i2c_we, i2c_addr, i2c_data_txm, wait_i2c_ack);
          next_state = dummy4;
		  end
  dummy4: begin
          wb_access(SR, 8'h00, RD, i2c_cs, i2c_we, i2c_addr, i2c_data_txm, wait_i2c_ack);
          next_state = rST5;
          end  
  rST5:   begin //wb_read(SR), check tip = SR[1]
          wb_access(SR, 8'h00, RD, i2c_cs, i2c_we, i2c_addr, i2c_data_txm, wait_i2c_ack); 
          next_state = rST6;
		  end
  rST6:   begin //wb_write(TXR, {CH7301_DEV_ADDR, RD} ): present slave address, set read-bit
          wb_access(TXR, {CH7301_DEV_ADDR, RD}, WR, i2c_cs, i2c_we, i2c_addr, i2c_data_txm, wait_i2c_ack);          
          next_state = rST7;
		  end
  rST7:   begin //wb_write(CR, 8'h90 ): set command (start, write)
          wb_access(CR, 8'h90, WR, i2c_cs, i2c_we, i2c_addr, i2c_data_txm, wait_i2c_ack);
          next_state = dummy5;
		  end
  dummy5: begin
          wb_access(SR, 8'h00, RD, i2c_cs, i2c_we, i2c_addr, i2c_data_txm, wait_i2c_ack);
          next_state = rST8;
          end  
  rST8:   begin //wb_read(SR), check tip = SR[1]
          wb_access(SR, 8'h00, RD, i2c_cs, i2c_we, i2c_addr, i2c_data_txm, wait_i2c_ack); 
          next_state = rST9;  
		  end
  rST9:   begin //wb_write(CR, 8'h28): set command (read, nack_read), read complete!
          wb_access(CR, 8'h28, WR, i2c_cs, i2c_we, i2c_addr, i2c_data_txm, wait_i2c_ack); 
          next_state = dummy6;
		  end
  dummy6: begin
          wb_access(SR, 8'h00, RD, i2c_cs, i2c_we, i2c_addr, i2c_data_txm, wait_i2c_ack);
          next_state = rSTa;
          end  
  rSTa:   begin //wb_read(SR), check tip = SR[1]
          wb_access(SR, 8'h00, RD, i2c_cs, i2c_we, i2c_addr, i2c_data_txm, wait_i2c_ack); 
          next_state = rSTb;
		  end
  rSTb:   begin //wb_read(RXR)
          wb_access(RXR, 8'h00, RD, i2c_cs, i2c_we, i2c_addr, i2c_data_txm, wait_i2c_ack); 
	      next_state = wait1;		  
		  end
  wait1:  begin
          i2c_cs = 1'b0;
		  wait_i2c_ack = 1'b0;		  
	      if(ld_config)
           next_state = rST0;		   
		  end
  endcase
end //always

endmodule
