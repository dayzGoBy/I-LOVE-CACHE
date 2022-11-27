`define C1_NOP 0
`define C1_READ8 1  
`define C1_READ16 2 
`define C1_READ32 3
`define C1_INVALIDATE_LINE 4
`define C1_WRITE8 5
`define C1_WRITE16 6
`define C1_WRITE32 7
`define C1_RESPONSE 7
`define C1_DETHRONE 3'bzzz
`define D_DETHRONE 16'bzzzzzzzzzzzzzzz
`define A_DETHRONE 15'bzzzzzzzzzzzzzzz

module CPU(
	input clk,
	inout [15:0] D1,
	inout [2:0] C1,
	output [14:0] A1
	);

	reg [2:0] command1 = `C1_NOP;
	reg [14:0] address1 = `A_DETHRONE;

	assign C1 = command1;
	assign A1 = address1;

	reg [2:0] commands [0:4];
	reg [14:0] addresses [0:4];
	int cnt = 0;

	always @(posedge clk) begin
		case (C1) 
			`C1_NOP: begin
				$display("CPU: no operation");
			end
			`C1_RESPONSE: begin
				$display("CPU: response recieved");
			end
		endcase

		if (cnt == 0) begin
			command1 = `C1_READ8;
			address1 = 2'b11;
			#4;
			address1 = 2'b10;
			#1;
			command1 = `C1_DETHRONE;
			address1 = `A_DETHRONE;
		end
		cnt++;
	end
endmodule