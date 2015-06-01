
module lfsr (input  clk,
			 input  rst_n,
			 output reg [4:0] data
			 );

wire feedback = data[4] ^ data[1] ;  // xor


always @(posedge clk or negedge rst_n) begin
  if (~rst_n)
    data <= 4'hf;	// 4 bit hex F
  else
    data <= {data[3:0], feedback};
end
	
endmodule