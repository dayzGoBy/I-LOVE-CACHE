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
`define C2_DETHRONE 2'bzz
`define D_DETHRONE 16'bzzzzzzzzzzzzzzz
`define A_DETHRONE 15'bzzzzzzzzzzzzzzz

module MemCTR(
	input clk, 
	input [14:0] A2, // мы читаем линию - значит без оффсета
	input M_DUMP,
	input RESET,

	inout [15:0] D2,
	inout [1:0] C2
	);

	reg [7:0] mem [0:`MEM_SIZE - 1];
	reg [15:0] data2 = `D_DETHRONE;
	reg [1:0] command2 = `C2_DETHRONE;

	int address;

	assign D2 = data2;
	assign C2 = command2;

	initial begin		
		for (int i = 0; i < `MEM_SIZE; i++) begin
			mem [i] = i % 7;
		end
	end

	always @(posedge clk)
	begin
		case (C2) 
			`C2_NOP: begin
				$display("MEM: no operation");
			end
			`C2_READ_LINE: begin
				$display("MEM: READ_LINE recieved",);
				$display("getting line %b", A2);
				address = A2;
				#200;
				command2 = `C2_RESPONSE;
				for (int i = 0; i < 8; i++) begin
					for (int j = 0; j < 8; j++) begin
						data2 [j] = mem [address << `CACHE_OFFSET_SIZE + 2 * i] [7 - j];
					end
					for (int j = 0; j < 8; j++) begin
						data2 [8 + j] = mem [address << `CACHE_OFFSET_SIZE + 2 * i + 1] [7 - j];
					end
					#2;
				end
				#1;
				command2 = `C2_DETHRONE;
				data2 = `D_DETHRONE;
			end
			`C2_WRITE_LINE: begin
				$display("MEM: WRITE_LINE recieved",);
				$display("writing line %b", A2);
				#200;
				for (int i = 0; i < 8; i++) begin
					mem [A2 << 4 + 2 * i] = data2 [7:0];
					mem [A2 << 4 + 2 * i + 1] = data2[15:8];
					//TODO: little endian
					//#2;
				end
			end
		endcase
	end

endmodule