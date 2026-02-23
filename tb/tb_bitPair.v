`timescale 1ns/1ps

module tb_bitPair;
  reg   signed [31:0]  M, Q;
  wire  signed [63:0]  sum;

  booth_bit_pair dut (
    .M(M), .Q(Q), .P(sum)
  );

  //reference (64-bit because 32-bit * 2)
  reg signed [63:0] refValue;

  integer i;
  integer tests;
  integer startTime, currentTime, goalTime, minutes;

  task check;
    begin
      tests = tests + 1;
      refValue = $signed(M) * $signed(Q);
      #1; // let signals settle
      if (sum !== refValue) begin
        $display("FAIL: M=%b Q=%b | got sum=%b expected=%b", M, Q, sum, refValue);
        $stop;
      end
    end
  endtask

  initial begin
    tests = -18; //Start at -18 to offset corner cases
    goalTime = 300 * 1_000_000_000_000; // 300s = 3e14 ps
    $display("Starting Booth's Bit Pair Test...");

    //Can no longer check every combination as it would take far too long

    //Start With Corner cases / Specific Cases

    //Edge Cases with 0 and tests with 1 and -1
    M=32'h00000000; Q=32'h00000000; check(); //0 * 0
    M=32'h00000000; Q=32'hFFFFFFFF; check(); //0 * (-1) = 0
    M=32'hFFFFFFFF; Q=32'h00000000; check(); //(-1) * 0 = 0
    M=32'h00000001; Q=32'hFFFFFFFF; check(); //(1) * (-1) = -1
    M=32'hFFFFFFFF; Q=32'hFFFFFFFF; check(); //(-1) * (-1) = +1

    //Sign + sign-extension specific tests
    M=32'h00000007; Q=32'hFFFFFFFD; check(); //7 * (-3) = -21
    M=32'hFFFFFFF9; Q=32'h00000003; check(); //(-7) * 3 = -21
    M=32'hFFFFFFF9; Q=32'hFFFFFFFD; check(); //(-7) * (-3) = +21

    //Most-negative (two's complement asymmetry) testing
    M=32'h80000000; Q=32'h00000001; check(); //min_int * 1
    M=32'h80000000; Q=32'hFFFFFFFF; check(); //min_int * (-1) (watch width / sign handling)
    M=32'h80000000; Q=32'h00000002; check(); //min_int * 2 (forces shifts / high bits)

    //Doubling / (+/-)2M testing
    M=32'h40000000; Q=32'h00000002; check(); //0x40000000 * 2 (tests +2M path)
    M=32'h40000000; Q=32'hFFFFFFFE; check(); //0x40000000 * (-2) (tests -2M path)

    //Checking Large Sums / overflows
    M=32'h00000001; Q=32'h7FFFFFFF; check(); //1 * max_pos (long run of 1s)
    M=32'h00010000; Q=32'h00010000; check(); //65536 * 65536 (product has 0x1 high word)
    M=32'h7FFFFFFF; Q=32'h7FFFFFFF; check(); //max_pos * max_pos (big positive, high word nonzero)
    M=32'h80000000; Q=32'hFFFFFFFE; check(); //min_int * (-2)

    
    $display("Corner Cases have been passed");

    $display("Starting on random testing...");
    startTime = $time;
    currentTime = $time;
    forever begin
      M   = $random;
      Q   = $random;
      check();

      currentTime = $time;
      if (tests % 100000 == 0) begin
        minutes = (currentTime - startTime) / 60_000_000_000_000.0; // ps to minutes
        $display("Tests Completed:\n Random tests: %0d, Sim minutes elapsed: %0.3f\n", tests, minutes); //Timing is wierd confused on sim vs real time
      end
    end
  end
endmodule
