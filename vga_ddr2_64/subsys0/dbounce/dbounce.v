`timescale 1ns / 100ps

module dbounce(
    input clk, 
    input button_in,
    output button_db
    );

reg  [19:0] counter = 0;
always @(posedge clk) begin
  counter <= counter + 1;
end

wire en = counter[19];

reg btn_delay1, btn_delay2, btn_delay3;
always @(posedge clk) begin
  if(en) begin
    btn_delay1 <= button_in;
	 btn_delay2 <= btn_delay1;
	 btn_delay3 <= btn_delay2;
  end
end

assign button_db = btn_delay1 & btn_delay2 & btn_delay3;

endmodule
