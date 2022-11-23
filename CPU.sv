`define C1_NOP 0
`define C1_READ8 1  
`define C1_READ16 2 
`define C1_READ32 3
`define C1_INVALIDATE_LINE 4
`define C1_WRITE8 5
`define C1_WRITE16 6
`define C1_WRITE32 7
`define C1_RESPONSE 7

module CPU(
	input clk,
	inout [15:0] D1,
	inout [2:0] C1,
	output [14:0] A1
	);

	reg [2:0] command;
	assign C1 = command;
	initial begin
		command = 3'b011;
	end

	always @(posedge clk) begin
		$display("%d on CPU", C1);
		case (C1) 
			`C1_NOP: $display("no operation");
			`C1_RESPONSE: $display("response recieved");
		endcase
		command++;
	end
endmodule