`timescale 1ns/1ps

module tb_cla32;
  reg   [31:0]  a, b;
  reg           cin;
  wire  [31:0]  sum;
  wire          cout;

  cla32 dut (
    .a(a), .b(b), .cin(cin),
    .sum(sum), .cout(cout)
  );

  //reference (33-bit because 32-bit + carry)
  reg [32:0] refValue;

  integer i;
  integer tests;
  time startTime, currentTime, goalTime;
  integer minutes;

  task check;
    begin
      tests = tests + 1;
      refValue = {1'b0,a} + {1'b0,b} + cin;
      #1; // let signals settle
      if ({cout, sum} !== refValue) begin
        $display("FAIL: a=%b b=%b cin=%b | got cout,sum=%b_%b expected=%b", a, b, cin, cout, sum, refValue);
        $stop;
      end
    end
  endtask

  initial begin
    tests = -7; //Start at -7 to offset corner cases
    goalTime = 64'd300000000000000; // 300s = 3e14 ps
    $display("Starting 32 bit cla test...");

    //Can no longer check every combination as it would take far too long ~ 1100 years

    //Start With Corner cases
    a=32'h00000000; b=32'h00000000; cin=0; check(); //0 + 0
    a=32'h00000000; b=32'h00000000; cin=1; check(); //0 + 0 + carry in
    a=32'hFFFFFFFF; b=32'h00000001; cin=0; check(); //Just Carry Out (Cascading Down)
    a=32'hFFFFFFFF; b=32'hFFFFFFFF; cin=0; check(); //Max Addition (No Carry In)
    a=32'hFFFFFFFF; b=32'hFFFFFFFF; cin=1; check(); //Max Addition (With Carry In)
    a=32'h80000000; b=32'h80000000; cin=0; check(); //Just Carry Out (Single Bit Flip)
    a=32'h7FFFFFFF; b=32'h00000001; cin=0; check(); //Flip all bits
    
    $display("Corner Cases have been passed");

    $display("Starting on random testing...");
    startTime = $time;
    currentTime = $time;
    forever begin
      a   = $random;
      b   = $random;
      cin = $random;
      check();

      currentTime = $time;
      if (tests % 1000000 == 0) begin
        minutes = (currentTime - startTime) / 60_000_000_000_000.0; // ps to minutes
        $display("Tests Completed:\n Random tests: %0d, Sim minutes elapsed: %0.3f\n", tests, minutes); //Timing is wierd confused on sim vs real time
      end
    end
  end
endmodule
