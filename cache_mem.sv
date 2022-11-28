`define CACHE_LINE_SIZE 16
`define CACHE_LINE_COUNT 64
`define CACHE_WAY 2
`define CACHE_TAG_SIZE 10
`define CACHE_SET_SIZE 5
`define CACHE_OFFSET_SIZE 4
`define CACHE_ADDR_SIZE 19
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
`define C1_DETHRONE 3'bzzz
`define C2_DETHRONE 2'bzz
`define D_DETHRONE 16'bzzzzzzzzzzzzzzz
`define A_DETHRONE 15'bzzzzzzzzzzzzzzz


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

	reg [2:0] command1 = `C1_DETHRONE;
	reg [1:0] command2 = `C2_DETHRONE;
	reg [14:0] address2 = `A_DETHRONE;
	reg [15:0] data1 = `D_DETHRONE;
	reg [15:0] data2 = `D_DETHRONE;
	
	int tag;
	int set;
	int offset;
	int where;
	int bytes_to_read;

	reg [7:0] data [0:63] [0:16];
	reg [9:0] tags [0:63];
	reg [1:0] valid_dirty [0:63]; // dirty := modifided but not stored; valid := line is not empty

	assign C1 = command1;
	assign C2 = command2;
	assign A2 = address2;
	assign D1 = data1;
	assign D2 = data2;

	initial begin
		for (int i = 0; i < 64; i++) begin
			valid_dirty [i] = 0;
		end
	end

	always @(posedge clk) begin 
		case (C1) 
			`C1_NOP: begin
				$display("CACHE: no operation");  
			end

			`C1_READ8:  begin
				bytes_to_read = 1;
				$display("CACHE: READ8 recieved"); 
				$display("reading a byte on %b block", A1); 
				tag = A1 >> 5;
				set = A1 % 64;
				#2;
				$display("offset equals to", A1 % 32);
				offset = A1 % 32;
				#6;
				if (tags[set * 2] == tag || tags[set * 2 + 1] == tag)	begin //once we met this tag, we cannot meet him again
					where = tags[set * 2] != tag;
					command1 = `C1_RESPONSE;
					data1 [7:0] = data [where + set * 2] [offset];
				end else begin
					command2 = `C2_READ_LINE;
					address2 [14:5] = tag;
					address2 [4:0] = set;
					#1;
					command2 = `C2_DETHRONE;
					address2 = `A_DETHRONE;
				end
				#1;
				command1 = `C1_DETHRONE;
				data1 = `D_DETHRONE;
			end

			`C1_READ16: begin
				$display("CACHE: READ16 recieved"); 
				bytes_to_read = 2;
				//TODO: 2 bytes
				$display("reading a byte on %b block", A1); 
				tag = A1 >> 5;
				set = A1 % 64;
				#2;
				$display("offset equals to", A1 % 32);
				offset = A1 % 32;
				#6;
				if (tags[set * 2] == tag || tags[set * 2 + 1] == tag)	begin //once we met this tag, we cannot meet him again
					where = tags[set * 2] != tag;
					command1 = `C1_RESPONSE;
					data1 [7:0] = data [where + set * 2] [offset];
				end else begin
					command2 = `C2_READ_LINE;
					address2 [14:5] = tag;
					address2 [4:0] = set;
					#1;
					command2 = `C2_DETHRONE;
					address2 = `A_DETHRONE;
				end
				#1;
				command1 = `C1_DETHRONE;
				data1 = `D_DETHRONE;
			end

			`C1_READ32: begin
				$display("CACHE: READ32 recieved");
				//#10;
			end

			`C1_INVALIDATE_LINE: begin
				$display("CACHE: INVALIDATE_LINE recieved");
				if (tags[set * 2] == tag || tags[set * 2 + 1] == tag)	begin 
					where = tags[set * 2] != tag;
				end
				valid_dirty [set * 2] = 0;
			end

			`C1_WRITE8: begin
				$display("CACHE: WRITE8 recieved");
				$display("writing a byte on %b block", A1); 
				tag = A1 >> 5;
				set = A1 % 64;
				#2;
				$display("offset equals to", A1 % 32);
				offset = A1 % 32;
				if (tags[set * 2] == tag || tags[set * 2 + 1] == tag)	begin 
					where = tags[set * 2] != tag;
					data [set * 2 + where] [offset] = D1[7:0];
					valid_dirty [set * 2 + where] [1] = 1;
				end else begin
					//че делать если бита нет в блоке
				end
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
				//TODO: LRU
				if (valid_dirty[set * 2][0] == 0 || valid_dirty[set * 2 + 1][0] == 0) begin
					where = valid_dirty[set * 2][0] != 0;		
				end else if (valid_dirty[set * 2][1] == 0 || valid_dirty[set * 2 + 1][1] == 0) begin
					where = valid_dirty[set * 2][1] != 0;
				end else begin
					command2 = `C2_WRITE_LINE;
					address2 = tag << `CACHE_SET_SIZE + set;
					// по умолчанию из двух грязных линий пишем первую
					for (int i = 0; i < 8; i++) begin
						data2 [15:8] = data [set * 2] [i * 2]; 
						data2 [7:0] = data [set * 2] [i * 2 + 1];
						#2;
					end
					where = 0;
				end

				tags[set * 2 + where] = tag;
				valid_dirty[set * 2 + where] [0] = 1;
				for (int i = 0; i < 8; i++) begin
					data[set * 2 + where] [2 * i] = D2 [15:8];
					data[set * 2 + where] [2 * i + 1] = D2 [7:0];
					#2;
				end
				//TODO: separate cases of reading 8, 16, 32 bits
				//bytes_to_read
				command1 = `C1_RESPONSE;
				$display("%b", data [where + set * 2] [offset]);
				data1 [7:0] = data [where + set * 2] [offset];
				#1;
				command1 = `C1_DETHRONE;
			end
		endcase

	end

endmodule
