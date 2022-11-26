//арбитр шины

module judge1(
	input clk,
	inout [2:0] C1_to_CPU,
	inout [15:0] D1_to_CPU,
	inout [2:0] C1_to_cache,
	inout [15:0] D1_to_cache,
	);

	reg [2:0] com_to_CPU,
	reg [15:0] data_to_CPU,
	reg [2:0] com_to_cache,
	reg [15:0] data_to_cache,

	always @(posedge clk)
	begin
		
	end

endmodule