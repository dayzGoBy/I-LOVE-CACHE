module Cache(
	input clk,
	input C_DUMP,
	input RESET,

	input [`ADDR1_BUS_SIZE - 1:0] A1,

	inout [`CTR1_BUS_SIZE - 1:0] C1,
	inout [`DATA_BUS_SIZE - 1:0] D1,
	inout [`CTR2_BUS_SIZE - 1:0] C2,
	inout [`DATA_BUS_SIZE - 1:0] D2,

	output [`ADDR1_BUS_SIZE - 1:0] A2
	);
	
	// initializing busses
	reg [`CTR1_BUS_SIZE - 1:0] command1 = `C1_DETHRONE;
	reg [`CTR2_BUS_SIZE - 1:0] command2 = `C2_DETHRONE;
	reg [`ADDR1_BUS_SIZE - 1:0] address2 = `A_DETHRONE;
	reg [`DATA_BUS_SIZE - 1:0] data1 = `D_DETHRONE;
	reg [`DATA_BUS_SIZE - 1:0] data2 = `D_DETHRONE;

	// assigning registers where we write commands to busses
	assign C1 = command1;
	assign C2 = command2;
	assign A2 = address2;
	assign D1 = data1;
	assign D2 = data2;

	reg [7:0] data [0:`CACHE_LINE_COUNT - 1] [0:`CACHE_LINE_SIZE - 1]; // useful data storage
	reg [7:0] responded_line [0:`CACHE_LINE_SIZE - 1]; // a place to temporary save the mem's responce
	reg [7:0] to_write [0:3]; // bytes recieved from cpu, but not written yet
	reg [`CACHE_TAG_SIZE - 1:0] tags [0:`CACHE_LINE_COUNT - 1]; // line's tags
	reg [1:0] valid_dirty [0:`CACHE_LINE_COUNT - 1]; // dirty := modifided but not stored; valid := line is not empty
	reg last_used [0:`CACHE_SET_COUNT - 1]; //for every cache-set we save the last used line

	// useful variables
	int tag;
	int set;
	int offset;
	int where = 0;
	int bytes_to_read;

	// reset makes all lines invalide
	task reset;
		for (int i = 0; i < 64; i++) begin
			valid_dirty [i] = 0;
		end
	endtask

	// give ownership to the partner
	task reset_busses2;
		#1;
		command2 = `C2_DETHRONE;
		address2 = `A_DETHRONE;
		data2 = `D_DETHRONE;
	endtask

	task reset_busses1;
		#1;
		command1 = `C1_DETHRONE;
		data1 = `D_DETHRONE;
	endtask

	task read_address;
		//$display("byte on %b block", A1); 
		// recieving the address
		tag = A1 >> `CACHE_SET_SIZE;
		set = A1 % `CACHE_SET_COUNT;
		#2;
		//$display("offset equals to", A1 % 16);
		offset = A1 % `CACHE_LINE_SIZE;
	endtask

	//tasks that send to CPU
	task send8;
		#1;
		command1 = `C1_RESPONSE;
		data1 [7:0] = data [where + set * 2] [offset];
		last_used [set] = where;
		#1;
	endtask

	task send16;
		#1;
		command1 = `C1_RESPONSE;
		data1 [15:8] = data [where + set * 2] [offset];
		data1 [7:0] = data [where + set * 2] [offset + 1];
		last_used [set] = where;
		#1;
	endtask

	task send32;
		#1;
		command1 = `C1_RESPONSE;
		data1 [15:8] = data [where + set * 2] [offset];
		data1 [7:0] = data [where + set * 2] [offset + 1];
		#2;
		data1 [15:8] = data [where + set * 2] [offset + 2];
		data1 [7:0] = data [where + set * 2] [offset + 3];
		last_used [set] = where;
		#1;
	endtask

	// task that rewrite data
	task write8;
		data [set * 2 + where] [offset] = to_write[0];
		valid_dirty [set * 2 + where] = 3;
		last_used [set] = where;
	endtask

	task get8;
		to_write [0] = D1[7:0];
	endtask

	task write16;
		data [set * 2 + where] [offset] = to_write[0];
		data [set * 2 + where] [offset + 1] = to_write[1];
		valid_dirty [set * 2 + where] = 3;
		last_used [set] = where;
	endtask

	task get16;
		to_write [0] = D1[15:8];
		to_write [1] = D1[7:0];
	endtask

	task write32;
		data [set * 2 + where] [offset] = to_write[0];
		data [set * 2 + where] [offset + 1] = to_write[1];
		#2;
		data [set * 2 + where] [offset + 2] = to_write[2];
		data [set * 2 + where] [offset + 3] = to_write[3];
		valid_dirty [set * 2 + where] = 3;
		last_used [set] = where;
	endtask

	task get32;
		to_write [0] = D1[15:8];
		to_write [1] = D1[7:0];
		#2;
		to_write [2] = D1[15:8];
		to_write [3] = D1[7:0];
	endtask

	task ask_for_data;
		#8;
		if (tags[set * 2] == tag || tags[set * 2 + 1] == tag)	begin 
			hit_cnt++;
			where = tags[set * 2] != tag;
		end else begin
			miss_cnt++;
			#4;
			set_address();
			reset_busses2();
			wait(C2 == `C2_RESPONSE);
			write_line();
		end
		last_used [set] = where;
		#2;
	endtask

	task get_asked_data;
		read_address();
		#8;
		// we look for the byte in the set
		if (tags[set * 2] == tag || tags[set * 2 + 1] == tag) begin 
			hit_cnt++;
			where = tags[set * 2] != tag;
		end else begin
			miss_cnt++;
			#4;
			set_address();
			reset_busses2();
			wait(C2 == `C2_RESPONSE);
			for (int i = 0; i < 8; i++) begin
				responded_line [2 * i] = D2 [15:8];
				responded_line [2 * i + 1] = D2 [7:0];
				#2;
			end
			write_line();
		end
		last_used [set] = where;
		#2;
	endtask

	task set_address;
		#1;
		command2 = `C2_READ_LINE;
		address2 [14:5] = tag;
		address2 [4:0] = set;
		#1;
	endtask

	task write_line;
		// check for validness
		if (valid_dirty[set * 2] >> 1 == 0 || valid_dirty[set * 2 + 1] >> 1 == 0) begin
			where = valid_dirty[set * 2] != 0;		
		end else begin
			// LRU
			where = last_used [set] != 1;
			if (valid_dirty [set * 2 + where] == 3) begin
				#1;
				command2 = `C2_WRITE_LINE;
				address2 = tag << `CACHE_SET_SIZE + set;
				for (int i = 0; i < 8; i++) begin
					data2 [15:8] = data [set * 2 + where] [i * 2]; 
					data2 [7:0] = data [set * 2 + where] [i * 2 + 1];
					#2;
				end
				#1;
				reset_busses2();
				wait(C2 == `C2_NOP);
			end
		end

		tags[set * 2 + where] = tag;
		for (int i = 0; i < 16; i++) begin
			data [set * 2 + where] [i] = responded_line [i];
		end
		last_used [set] = where;
		valid_dirty [set * 2 + where] = 2;
	endtask

	task send_nop;
		#1;
		command1 = `C1_NOP;
		#2;
		command1= `D_DETHRONE;
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
				//$display("CACHE: no operation");  
			end

			`C1_READ8:  begin
				//$display("CACHE: READ8 recieved"); 
				get_asked_data();
				send8();
				reset_busses1();
			end

			`C1_READ16: begin
				//$display("CACHE: READ16 recieved"); 
				get_asked_data();
				send16();
				reset_busses1();
			end

			`C1_READ32: begin
				//$display("CACHE: READ32 recieved");
				get_asked_data();
				send32();
				reset_busses1();
			end

			`C1_INVALIDATE_LINE: begin
				//$display("CACHE: INVALIDATE_LINE recieved");
				tag = A1 >> `CACHE_SET_SIZE;
				set = A1 % `CACHE_SET_COUNT;
				if (tags[set * 2] == tag || tags[set * 2 + 1] == tag)	begin 
					where = tags[set * 2] != tag;
					valid_dirty [set * 2 + where] = 0;
				end
			end

			`C1_WRITE8: begin
				//$display("CACHE: WRITE8 recieved");
				read_address();
				get8();
				ask_for_data();
				write8();
				send_nop();
			end

			`C1_WRITE16: begin
				//$display("CACHE: WRITE16 recieved");
				read_address();
				get16();
				ask_for_data();
				write16();
				send_nop();
			end

			`C1_WRITE32: begin
				//$display("CACHE: WRITE32 recieved");
				read_address();
				get32();
				ask_for_data();
				write32();
				send_nop();
			end
		endcase
	end
endmodule
