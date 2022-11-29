`define CACHE_LINE_SIZE 16
`define CACHE_LINE_COUNT 64
`define CACHE_WAY 2
`define CACHE_TAG_SIZE 10
`define CACHE_SET_SIZE 5
`define CACHE_OFFSET_SIZE 4
`define CACHE_SET_COUNT 32
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
	
	// initializing buses
	reg [2:0] command1 = `C1_DETHRONE;
	reg [1:0] command2 = `C2_DETHRONE;
	reg [14:0] address2 = `A_DETHRONE;
	reg [15:0] data1 = `D_DETHRONE;
	reg [15:0] data2 = `D_DETHRONE;
	
	// useful variables
	int tag;
	int set;
	int offset;
	int where;
	int bytes_to_read;

	reg [7:0] data [0:63] [0:15]; // useful data storage
	reg [7:0] responded_line [0:15]; // a place to temporary save the mem's responce
	reg [7:0] to_write [0:3]; // bytes recieved from cpu, but not written yet
	reg [9:0] tags [0:63]; // line's tags
	reg [1:0] valid_dirty [0:63]; // dirty := modifided but not stored; valid := line is not empty
	reg last_used [0:31]; //for every cache-set we save the last used line
	
	// assigning registers where we write commands to buses
	assign C1 = command1;
	assign C2 = command2;
	assign A2 = address2;
	assign D1 = data1;
	assign D2 = data2;

	// reset makes all lines invalide
	function void reset();
		for (int i = 0; i < 64; i++) begin
			valid_dirty [i] = 0;
		end
	endfunction

	task reset_buses2();
		#1;
		command2 = `C2_DETHRONE;
		address2 = `A_DETHRONE;
	endtask

	task reset_buses1();
		#1;
		command1 = `C1_DETHRONE;
		data1 = `D_DETHRONE;
	endtask

	task read_address();
		$display("reading a byte on %b block", A1); 
		// recieving the address
		tag = A1 >> `CACHE_SET_SIZE;
		set = A1 % `CACHE_SET_COUNT;
		#2;
		$display("offset equals to", A1 % 32);
		offset = A1 % `CACHE_LINE_SIZE;
		#6;
	endtask

	task send8 ();
		command1 = `C1_RESPONSE;
		data1 [7:0] = data [where + set * 2] [offset];
	endtask

	task send16 ();
		command1 = `C1_RESPONSE;
		data1 [15:8] = data [where + set * 2] [offset];
		data1 [7:0] = data [where + set * 2] [offset + 1];
	endtask

	task send32 ();
		command1 = `C1_RESPONSE;
		data1 [15:8] = data [where + set * 2] [offset];
		data1 [7:0] = data [where + set * 2] [offset + 1];
		#2;
		data1 [15:8] = data [where + set * 2] [offset + 2];
		data1 [7:0] = data [where + set * 2] [offset + 3];
	endtask

	task write8 ();
		data [set * 2 + where] [offset] = D1[7:0];
		valid_dirty [set * 2 + where] [1] = 1;
	endtask

	task write16 ();
		data [set * 2 + where] [offset] = D1[15:8];
		data [set * 2 + where] [offset + 1] = D1[7:0];
		valid_dirty [set * 2 + where] [1] = 1;
	endtask

	task write32 ();
		data [set * 2 + where] [offset] = D1[15:8];
		data [set * 2 + where] [offset + 1] = D1[7:0];
		#2;
		data [set * 2 + where] [offset + 2] = D1[15:8];
		data [set * 2 + where] [offset + 3] = D1[7:0];
		valid_dirty [set * 2 + where] [1] = 1;
	endtask

	task set_address();
		command2 = `C2_READ_LINE;
		address2 [14:5] = tag;
		address2 [4:0] = set;
	endtask

	task write_line();
		for (int i = 0; i < 8; i++) begin
			responded_line [2 * i] = D2 [15:8];
			responded_line [2 * i + 1] = D2 [7:0];
			#2;
		end
		if (valid_dirty[set * 2][0] == 0 || valid_dirty[set * 2 + 1][0] == 0) begin
			where = valid_dirty[set * 2][0] != 0;		
		end else begin
			where = ~last_used [set];
			if (valid_dirty [set * 2 + where] == 1) begin
				command2 = `C2_WRITE_LINE;
				address2 = tag << `CACHE_SET_SIZE + set;
				for (int i = 0; i < 8; i++) begin
					data2 [15:8] = data [set * 2 + where] [i * 2]; 
					data2 [7:0] = data [set * 2 + where] [i * 2 + 1];
					#2;
				end
			end
		end

		tags[set * 2 + where] = tag;
		valid_dirty[set * 2 + where] [0] = 1;
		for (int i = 0; i < 16; i++) begin
			data [set * 2 + where] [i] = responded_line [i];
		end
		valid_dirty [set * 2 + where] = 2'b10;
	endtask

	initial begin
		reset();
	end

	// there we watch, what happens on command lines and doing sth then
	always @(posedge clk) begin 
		if (RESET) reset();
		if (C_DUMP) begin
			$dumpfile("cache_dump.vcd");
    		$dumpvars(1, Cache);
		end

		case (C1) 
			`C1_NOP: begin
				$display("CACHE: no operation");  
			end

			`C1_READ8:  begin
				bytes_to_read = 1;

				$display("CACHE: READ8 recieved"); 
				read_address();

				// we look for the byte in the set
				if (tags[set * 2] == tag || tags[set * 2 + 1] == tag)	begin 
					where = tags[set * 2] != tag;
					send8();
				end else begin
					// if we miss, go to mem for demanded data
					set_address();
					reset_buses2();
				end
				reset_buses1();
			end

			`C1_READ16: begin
				$display("CACHE: READ16 recieved"); 
				bytes_to_read = 2;
				$display("reading a byte on %b block", A1); 

				read_address();

				// we look for the byte in the set
				if (tags[set * 2] == tag || tags[set * 2 + 1] == tag)	begin 
					where = tags[set * 2] != tag;
					send16();
				end else begin
					set_address();
					reset_buses2();
				end
				reset_buses1();
			end

			`C1_READ32: begin
				$display("CACHE: READ32 recieved");
				bytes_to_read = 4;
				$display("reading a byte on %b block", A1); 

				read_address();

				// we look for the byte in the set
				if (tags[set * 2] == tag || tags[set * 2 + 1] == tag) begin 
					where = tags[set * 2] != tag;
					send32();
				end else begin
					set_address();
					reset_buses2();
				end
				reset_buses1();
			end

			`C1_INVALIDATE_LINE: begin
				$display("CACHE: INVALIDATE_LINE recieved");

				tag = A1 >> `CACHE_SET_SIZE;
				set = A1 % `CACHE_SET_COUNT;

				if (tags[set * 2] == tag || tags[set * 2 + 1] == tag)	begin 
					where = tags[set * 2] != tag;
					valid_dirty [set * 2 + where] = 0;
				end
			end

			`C1_WRITE8: begin
				$display("CACHE: WRITE8 recieved");
				$display("writing a byte on %b block", A1); 

				read_address();

				if (tags[set * 2] == tag || tags[set * 2 + 1] == tag)	begin 
					where = tags[set * 2] != tag;
				end else begin
					set_address();
					reset_buses2();
					wait(C2 == `C2_RESPONSE);
					write_line();
				end
				write8();
			end

			`C1_WRITE16: begin
				$display("CACHE: WRITE16 recieved");

				read_address();

				if (tags[set * 2] == tag || tags[set * 2 + 1] == tag)	begin 
					where = tags[set * 2] != tag;
				end else begin
					set_address();
					reset_buses2();
					wait(C2 == `C2_RESPONSE);
					write_line();
				end
				write16();
			end

			`C1_WRITE32: begin
				$display("CACHE: WRITE32 recieved");
				
				read_address();

				if (tags[set * 2] == tag || tags[set * 2 + 1] == tag)	begin 
					where = tags[set * 2] != tag;
				end else begin
					set_address();
					reset_buses2();
					wait(C2 == `C2_RESPONSE);
					write_line();
				end
				write32();
			end

		endcase

		case (C2)
			`C2_RESPONSE: begin 
				$display("CACHE: response recieved");
				write_line();
				
				command1 = `C1_RESPONSE;
				case (bytes_to_read) 
					1: send8();
					2: send16();
					4: send32();
				endcase				
				reset_buses1();
			end
		endcase

	end

endmodule
