// Christopher Hays
// 12-bit binary to BCD converter
// Uses the "shift and add 3" algorithm

module bcd (input [11:0] binary,
			output reg [11:0] out
		   );
		   
	reg [3:0] hundreds;		// holds the bcd values
	reg [3:0] tens;
	reg [3:0] ones;
	
	
	integer i;
	always @(binary) begin	// always on input change
		hundreds = 4'd0;
		tens = 4'd0;
		ones = 4'd0;
		
		for (i = 11; i>=0; i=i-1) begin  	// for all 12 bits
			if (hundreds >= 5)			 	// check if the column has a value >= 5
				hundreds = hundreds + 3;	// if so, add 3
			if (tens >= 5)					// check tens
				tens = tens + 3;
			if (ones >= 5)					// check ones
				ones = ones + 3;
			hundreds = hundreds << 1;		// shift all values left by one bit
			hundreds[0] = tens[3];
			tens = tens << 1;
			tens[0] = ones[3];
			ones = ones << 1;
			ones[0] = binary[i];			// lsb comes from the input, location i
		end
		
		out = {hundreds[3:0],tens[3:0],ones[3:0]};  // concatenate output
	end
endmodule
