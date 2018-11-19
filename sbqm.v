

`timescale 1ns/100ps
module Testbench2(wt,pc,f,e);
  output f,e;
  output wt,pc;
  wire f,e;  //under observation
  wire [top.n-1:0] pc;
  wire [top.n+1:0] wt;
  reg  a,b,rst;    //inputs to DUT
  wire [1:0] tc;
  reg i;
  reg [top.n-1:0] initial_state;
   assign tc=2;  //two tellers
   top DUT1(.A(a),.B(b),.reset(rst),.wtime(wt),.pcount(pc),.tcount(tc),.full(f),.empty(e));
initial
  begin
    
    //case1 : initial///////////////////////////////////////////////////////
    initial_state = {top.n*(1'b0)};  //case1 : initial
    b = 1'b1;
    a = 1'b1;
    rst=0;
    $display("initially  pcount = %b",pc);
    $display("initially  wtime = %b",wt);
    $display("Full flag = %d", f);
    $display("Empty flag = %d", e);
    #10
    b = 1'b0;  #5  b=1'b1 ;  //someone enters 
    #5 a=1'b0;               //arrrives at the tellers
    $display("Pcount = %d", pc);
    $display("Full flag = %d", f);
    $display("wtime = %b",wt);
    $display("Empty flag = %d", e);
    #10
    b = 1'b0; #5 b=1'b1 ;        //another one enters
    #5
    $display("Pcount = %d", pc);
    $display("Full flag = %d", f);
    $display("wtime = %b",wt);
    $display("Empty flag = %d", e);
    #10            
    //case2 : trying to under flow//////////////////////////////////////////////////////////
    rst=1'b1; a=1'b0; #10 rst=1'b0 ; //resetting the DUT
    
    $display("Pcount = %d", pc);
    $display("Full flag = %d", f);
    $display("wtime = %b",wt);
    $display("Empty flag = %d", e);
    
    #10
    a = 1'b1; #5 a=1'b0 ; // as if someone tries to exit the qeue (underflow)
    $display("Pcount = %d", pc);
    $display("Full flag = %d", f);
    $display("wtime = %b",wt);
    $display("Empty flag = %d", e);
    #10 rst=1'b1; a=1'b1; #10 rst=1'b0 ; //resetting the DUT
    
    //case3: trying to overflow////////////////////////////////////////////////////////////////
    //the DUT is reset now at a state of pcount=00000
    //we will try to fill it then attempt to over flow it
    #5 
    a=1'b0;
    for(i=1;i<=(2**top.n);i=i+1)
      begin #5 b=1'b0; #5 b=1'b1 ; end
    //the qeue should be full by now
    $display("Pcount = %d", pc);
    $display("Full flag = %d", f);
    $display("wtime = %b",wt);
    $display("Empty flag = %d", e);
    //attempting to overflow
    #5 b=1'b0; #5 b=1'b1;
    $display("Pcount = %d", pc);
    $display("Full flag = %d", f);
    $display("wtime = %b",wt);
    $display("Empty flag = %d", e); 
  end  
endmodule 

//TestBench2 commented out as it doesn't work 


module top (A,B,reset,pcount,wtime,tcount,full,empty); //works fine with all other modules
        parameter n=3;   //default value,the width of pcount bus 
        input A,B,reset;
        input [1:0] tcount;  //will be set during simulation
        output [n+1:0] wtime;
        output full,empty;
        reg full,empty;
        output [n-1:0] pcount; 

        initial 
          begin full=0 ; empty=1; end
          
        upDownCounter counter1 (reset,A,B,pcount);
        always @(pcount)
          begin
            if (pcount==(2**n -1)) full =1;
            else full =0;
            if (pcount==0) empty =1;
            else empty=0;
          end
        
        LUT lut1 (.addr({pcount,tcount}),.data(wtime));  //LUT address formed by concatenation
    
endmodule

module upDownCounter (reset,inA,inB,count);  //asynchronous up/down counter with reset
        input inA,inB,reset;
        output [top.n-1:0] count;
        reg [top.n-1:0] count;
        
        initial count=(Testbench2.initial_state); //should be replaced by TestBench2.initial_state when TestBench2 works properly 
        
        always @( posedge reset, posedge inA, negedge inB)
        begin
         
          if(reset) count <= 0;
          else if ( inA && (count != 0)) count <= count -1; //decrements with posedge A ,protected from underflow
          else if (~inB &&(count != (2**top.n -1)))  count <= count + 1; //increments with negedge B ,protected from overflow   
               
        end       
endmodule        



module LUT (addr,data); //look up table
         parameter n=3; //replace with top.n when done simulating
         input [n+1:0] addr; //width of both address and data buses is n+2
         output [n+1:0] data;
         
         reg [n+1:0] rom[0:(2**(n+2))-1]; //the first 2**n addresses locate empty cells in the rom
         
         integer i; // i designates number of clients ,while j number of tellers
         integer j;
         
         initial 
         begin    //filling the table initially
             for(j=1;j<=3;j=j+1) 
              for(i=0; i<= 2**n -1 ;i=i+1)
                    rom[i*4+j]=3*(i+j-1)/j ;
         end
         
         assign data = rom[addr];
endmodule




