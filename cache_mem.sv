`define CACHE_LINE_SIZE 16
`define CACHE_LINE_COUNT 64
`define CACHE_WAY 2
`define CACHE_TAG_SIZE 10
`define CACHE_SET_SIZE 5
`define CACHE_OFFset_SIZE 4
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

	reg [2:0] command1 = 3'bzzz;
	reg [1:0] command2 = 2'bzz;
	reg [14:0] address2 = 15'bzzzzzzzzzzzzzzz;
	reg [15:0] data1 = 16'bzzzzzzzzzzzzzzz;
	reg [15:0] data2 = 16'bzzzzzzzzzzzzzzz;
	
	int tag;
	int set;
	int offset;

	reg [7:0] data [0:63] [0:16];
	reg [9:0] tags [0:63];
	reg [1:0] valid [0:63];

	assign C1 = command1;
	assign C2 = command2;
	assign A2 = address2;
	assign D1 = data1;
	assign D2 = data2;

	always @(posedge clk) begin 
		case (C1) 
			`C1_NOP: begin
				$display("CACHE: no operation");  
			end

			`C1_READ8:  begin
				$display("CACHE: READ8 recieved"); 
				$display("reading a byte on %b block", A1); 
				tag = A1 >> 5;
				set = A1 % 64;
				#2;
				$display("offset equals to", A1 % 32);
				offset = A1 % 32;
				if (tags[set * 2] == tag)	begin //once we met this tag, we cannot meet him again
					#6;
					command1 = `C1_RESPONSE;
					data1 [7:0] = data [set * 2] [offset];
					//TODO: little endian
				end	else if (tags[set * 2 + 1] == tag) begin
					#6;
					command1 = `C1_RESPONSE;
					data1 [7:0] = data [set * 2 + 1] [offset];
					//TODO: little endian
				end else begin
					command2 = `C2_READ_LINE;
					address2 [14:5] = tag;
					address2 [4:0] = set;
					//куда писать?
				end
				#1;
				command2 = 3'bzzz;
				command1 = 3'bzzz;
				data1 = 16'bzzzzzzzzzzzzzzzz;
			end

			`C1_READ16: begin
				$display("CACHE: READ16 recieved"); 
				//#10;
			end

			`C1_READ32: begin
				$display("CACHE: READ32 recieved");
				//#10;
			end

			`C1_INVALIDATE_LINE: begin
				$display("CACHE: INVALIDATE_LINE recieved");
			end

			`C1_WRITE8: begin
				$display("CACHE: WRITE8 recieved");
			end

			`C1_WRITE16: begin
				$display("CACHE: WRITE16 recieved");
			end

			`C1_WRITE32: begin
				$display("CACHE: WRITE32 recieved");
			end

		endcase

		case (C2)
			`C2_RESPONSE: begin 
				$display("CACHE: response recieved");
				tags[set * 2] = tag;
				//read by two bytes
			end
		endcase

	end

endmodule
