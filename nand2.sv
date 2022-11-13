module nand2_switch(out, in1, in2);
  input in1, in2;
  output out;
  wire w;
  
  supply1 power;
  supply0 ground;
  
	nmos n1(w, ground, in2);
	nmos n2(out, w, in1);
  
	pmos p1(out, power, in1);  
	pmos p2(out, power, in2);
  
endmodule