// Christopher Hays
// Linear Feedback Shift Register
// Creates a pseudo-random 5 bit output
// Uses a feedback loop to accomplish this


module lfsr (input  clk,
			 input  rst,
			 output reg [4:0] data
			 );

wire feedback = data[4] ^ data[1] ;  // xor bit 4 and bit 1


always @(posedge clk or negedge rst) begin
  if (~rst)
    data <= 4'hf;	// 4 bit hex F
  else
    data <= {data[3:0], feedback};  // LSB is replaced with the xor output
end
	
endmodule