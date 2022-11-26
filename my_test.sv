`include "CPU.sv"
`include "cache_mem.sv"
`include "mem_ctr.sv"

module test;
	reg clk = 1'b0;

	wire [14:0] A1;
	wire [14:0] A2;
	wire [15:0] D1, D2;
	wire [2:0] C1;
	wire [1:0] C2;

	wire C_DUMP;
	wire M_DUMP;
	wire RESET;

	CPU cpu(.clk(clk), .D1(D1), .C1(C1), .A1(A1));

	Cache cache(.clk(clk), .C_DUMP(C_DUMP), .RESET(RESET), .A1(A1),
		.C1(C1), .D1(D1), .C2(C2), .D2(D2), .A2(A2));

	MemCTR mem_ctr(.clk(clk), .A2(A2), .M_DUMP(M_DUMP), .RESET(RESET),
		.D2(D2), .C2(C2));

	always begin
		#1 clk = ~clk;
		if (clk) begin
			$display("--------------------WIRE INSTANCES----------------------");
			$display("command1: %d | address1: %B | data1: %B", C1, A1, D1);
			$display("command2: %d | address2: %B | data2: %B ", C2, A2, D2);
			$display("--------------------------------------------------------");
		end
	end

	initial	begin
		#30 $finish;
	end

endmodule