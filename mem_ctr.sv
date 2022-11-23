`define MEM_SIZE 524288
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

module MemCTR(
	input clk, 
	input [14:0] A2, // мы читаем линию - значит без оффсета
	input M_DUMP,
	input RESET,

	inout [15:0] D2,
	inout [1:0] C2
	);

	reg [7:0] mem [0:`MEM_SIZE - 1];

	always @(posedge clk)
	begin
		case (C2) 
			`C2_NOP: begin
				$display("no operation");
			end
			`C2_READ_LINE: begin
				$display("READ_LINE on mem");
				#100;

			end
			`C2_WRITE_LINE: begin
				$display("WRITE_LINE on mem");
			end
		endcase
	end

endmodule