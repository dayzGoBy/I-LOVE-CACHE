module MemCTR(
	input clk, 
	input [`ADDR2_BUS_SIZE - 1:0] A2,
	input M_DUMP,
	input RESET,

	inout [`DATA_BUS_SIZE - 1:0] D2,
	inout [`CTR2_BUS_SIZE - 1:0] C2
	);

	reg [7:0] mem [0:`MEM_SIZE - 1];
	reg [`DATA_BUS_SIZE - 1:0] data2 = `D_DETHRONE;
	reg [`CTR2_BUS_SIZE - 1:0] command2 = `C2_DETHRONE;

	int address;

	assign D2 = data2;
	assign C2 = command2;
	int SEED;

	task reset;
		SEED = `SEED;
		for (integer i = 0; i < `MEM_SIZE; i++) begin
			mem [i] = $random(SEED) >> 16;
		end
	endtask

	initial begin
		reset();
	end

	always @(posedge clk)
	begin
		if (RESET) reset();
		if (M_DUMP) begin
			$dumpfile("mem_dump.vcd");
    		$dumpvars(1, MemCTR);
		end

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
					data2 [15:8] = mem [(address << (`CACHE_OFFSET_SIZE) + 2 * i) % `MEM_SIZE];
					data2 [7:0] = mem [(address << (`CACHE_OFFSET_SIZE) + 2 * i + 1) % `MEM_SIZE];
					#2;
				end
				#1;
				command2 = `C2_DETHRONE;
				data2 = `D_DETHRONE;
			end
			`C2_WRITE_LINE: begin
				$display("MEM: WRITE_LINE recieved",);
				$display("writing line %b", A2);
				address = A2;

				for (int i = 0; i < 8; i++) begin
					mem [A2 << `CACHE_OFFSET_SIZE + 2 * i] = D2 [15:8]; 
					mem [A2 << `CACHE_OFFSET_SIZE + 2 * i + 1] = D2 [7:0]; 
					#2;
				end
				#184; // don't ask me why
			end
		endcase
	end
endmodule