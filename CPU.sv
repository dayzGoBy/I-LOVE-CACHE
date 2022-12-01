`define CACHE_LINE_SIZE 16
`define CACHE_LINE_COUNT 64
`define CACHE_WAY 2
`define CACHE_TAG_SIZE 10
`define CACHE_SET_SIZE 5
`define CACHE_OFFSET_SIZE 4
`define CACHE_SET_COUNT 32
`define CACHE_ADDR_SIZE 19
`define ADDR1_BUS_SIZE 15
`define ADDR2_BUS_SIZE 15
`define CTR1_BUS_SIZE 3
`define CTR2_BUS_SIZE 2
`define DATA_BUS_SIZE 16
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
`define MEM_SIZE 524288
`define SEED 225526
`define M 64
`define N 60
`define K 32


int miss_cnt;
int all_cnt;
int hit_cnt;
int clk_cnt;

module CPU(
	input clk,
	inout [`DATA_BUS_SIZE - 1:0] D1,
	inout [`CTR1_BUS_SIZE - 1:0] C1,
	output [`ADDR1_BUS_SIZE - 1:0] A1
	);

	reg [`CTR1_BUS_SIZE - 1:0] command1 = `C1_NOP;
	reg [`ADDR1_BUS_SIZE - 1:0] address1 = `A_DETHRONE;
	reg [`DATA_BUS_SIZE - 1:0] data1 = `D_DETHRONE;

	assign D1 = data1;
	assign C1 = command1;
	assign A1 = address1;

	int cnt = 0;

	int a_begin_mem = 0;
	int b_begin_mem = `M * `K;
	int c_begin_mem = 2 * `K * `N + b_begin_mem;

	int pa = a_begin_mem;
	int pb = b_begin_mem;
	int pc = c_begin_mem;

	task reset_busses;
		#1;
		command1 = `C1_DETHRONE;
		address1 = `A_DETHRONE;
		data1 = `D_DETHRONE;
		#1;
	endtask

	task pa_k (int pa_p, int k);
		#1;
		command1 = `C1_READ8;
		address1 = (pa_p + k) >> 4;
		#2;
		address1 = (pa_p + k) % 16;
		#1;
		reset_busses();
		wait(C1 == `C1_RESPONSE);
		#1;
	endtask

	task pb_x (int pb_p, int x);
		#1;
		command1 = `C1_READ16;
		address1 = (pb_p + 2 * x) >> 4;
		#2;
		address1 = (pb_p + 2 * x) % 16;
		#1;
		reset_busses();
		wait(C1 == `C1_RESPONSE);
		#1;
	endtask

	task pc_x (int pc_p, int x);
		#1;
		command1 = `C1_WRITE32;
		address1 = (pc_p + 4 * x) >> 4;
		#2;
		address1 = (pc_p + 4 * x) % 16;
		#1;
		reset_busses();
		wait(C1 == `C1_NOP);
		#3;
	endtask

	initial begin
		
		for (int y = 0; y < `M; y++) begin
			for (int x = 0; x < `N; x++) begin			
				pb = b_begin_mem;
				for (int k = 0; k < `K; k++) begin
					pa_k(pa, k);
					pb_x(pb, x);
					pb += 2 * `N;
				end
				pc_x(pc, x);
			end
			pa += `K;
			pc += 4 * `N;
		end

		$display("misses: %d", miss_cnt);
		$display("hits: %d", hit_cnt);
		$display("clocks %d", clk_cnt);
		$finish;
	end


	always @(posedge clk) begin
		case (C1) 
			`C1_NOP: begin
				//$display("CPU: no operation");
			end
			`C1_RESPONSE: begin
				//$display("CPU: response recieved");
			end
		endcase
	end
endmodule