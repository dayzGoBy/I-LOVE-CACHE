`include "nand2.sv"

module nand2_test;
  reg[1:0] in_value;
  wire out;
  
  nand2_switch not_instance(.out(out), .in1(in_value[1]), .in2(in_value[0]));
  
  typedef enum {C1_NOP=0, C1_RESPONSE=7} enum_set;
    
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(1, nand2_test);
    
    $monitor("in:%b, out:%b", in_value, out);
    
    #1 in_value = 2'b00; 
    #2 in_value = 2'b01; 
    #3 in_value = 2'b10; 
    #4 in_value = 2'b11; 
  end 
    
  initial begin    
    enum_set enum_var;  
    enum_var = C1_NOP; $display ("enum_var {C1_NOP} = %0d", enum_var);
    enum_var = C1_RESPONSE; $display ("enum_var {C1_RESPONSE} = %0d", enum_var);
  end 	  
  
endmodule
