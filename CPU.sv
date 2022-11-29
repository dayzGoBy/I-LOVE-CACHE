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
int clk_cnt;

module CPU(
	input clk,
	inout [`DATA_BUS_SIZE - 1:0] D1,
	inout [`CTR1_BUS_SIZE - 1:0] C1,
	output [`ADDR1_BUS_SIZE - 1:0] A1
	);

	reg [`CTR1_BUS_SIZE - 1:0] command1 = `C1_NOP;
	reg [`ADDR1_BUS_SIZE - 1:0] address1 = `A_DETHRONE;

	assign C1 = command1;
	assign A1 = address1;

	reg [`CTR1_BUS_SIZE - 1:0] commands [0:4];
	reg [`ADDR1_BUS_SIZE - 1:0] addresses [0:4];
	int cnt = 0;


	task reset_com();
		#1;
		command1 = `C1_DETHRONE;
		address1 = `A_DETHRONE;
	endtask

/* TODO: перехуярить это в машинные команды

#define M 64
#define N 60
#define K 32
int8 a[M][K];
int16 b[K][N];
int32 c[M][N];
 
void mmul()
{
  int8 *pa = a;
  int32 *pc = c;
  for (int y = 0; y < M; y++)
  {
    for (int x = 0; x < N; x++)
    {
      int16 *pb = b;
      int32 s = 0;
      for (int k = 0; k < K; k++)
      {
        s += pa[k] * pb[x];
        pb += N;
      }
      pc[x] = s;
    }
    pa += K;
    pc += N;
  }
}


*/
	reg [7:0] a[0:`M - 1][0:`K - 1];
	reg [15:0] b[0:`K - 1][0:`N - 1];
	reg [32:0] c[0:`M - 1][0:`N - 1];

	initial begin
		command1 = `C1_READ32;
		address1 = 1337;
		#2;
		address1 = 8;
		reset_com();
		#1;
		wait (C1 == `C1_RESPONSE);
		command1 = `C1_READ32;
		address1 = 1337;
		#2;
		address1 = 8;
		reset_com();
		#1;
		wait (C1 == `C1_RESPONSE);


		for (int y = 0; y < `M; y++) begin
			for (int x = 0; x < `N; x++) begin			
				for (int k = 0; k < `K; k++) begin
					
				end
			end
		end
	end


	always @(posedge clk) begin
		case (C1) 
			`C1_NOP: begin
				$display("CPU: no operation");
			end
			`C1_RESPONSE: begin
				$display("CPU: response recieved");
			end
		endcase
	end
endmodule