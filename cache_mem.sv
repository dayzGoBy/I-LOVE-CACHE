`define CACHE_LINE_SIZE 16
`define CACHE_LINE_COUNT 64
`define CACHE_WAY 2
`define CACHE_TAG_SIZE 10
`define CACHE_SET_SIZE 5
`define CACHE_OFFSET_SIZE 4
`define CACHE_ADDR_SIZE 10
`define C1_NOP 0
`define C1_READ8 1  
`define C1_READ16 2 
`define C1_READ32 3
`define C1_INVALIDATE_LINE 4
`define C1_WRITE8 5
`define C1_WRITE16 6
`define C1_WRITE32 7
`define C1_RESPONSE 7
`define C2_NOP 0
`define C2_READ_LINE 2
`define C2_WRITE_LINE 3
`define C2_RESPONSE 1

module Cache(
	input clk,
	input C_DUMP,
	input RESET,

	input [14:0] A1,

	inout [2:0] C1,
	inout [15:0] D1,
	inout [1:0] C2,
	inout [15:0] D2,

	output [14:0] A2
	);

	reg [2:0] command;

	reg [63:0] data [0:25];


	always @(posedge clk) 
	begin 
		$display("%d on cache", C1);
		case (C1) 

			`C1_NOP: begin
				$display("no operation recieved");  
			end

			`C1_READ8:  begin
				$display("READ8 recieved"); 

				#10;
			end

			`C1_READ16: begin
				$display("READ8 recieved"); 
				#10;
			end

			`C1_READ32: begin
				$display("READ32 recieved");
				#10;
			end

			`C1_INVALIDATE_LINE: begin
				$display("INVALIDATE_LINE recieved");
			end

			`C1_WRITE8: begin
				$display("WRITE8 recieved");
			end

			`C1_WRITE16: begin
				$display("WRITE16 recieved");
			end

			`C1_WRITE32: begin
				$display("WRITE32 recieved");
			end

		endcase

		case (C2)
			`C2_RESPONSE: begin 
				$display("%b", D2);
			end
		endcase

	end

endmodule

