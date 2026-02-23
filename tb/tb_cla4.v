`timescale 1ns/1ps

module tb_cla4;
  reg  [3:0] a, b;
  reg        cin;
  wire [3:0] sum;
  wire       cout;
  wire       P, G;

  cla4 dut (
    .a(a), .b(b), .cin(cin),
    .sum(sum), .cout(cout),
    .P(P), .G(G)
  );

  //reference (5-bit because 4-bit + carry)
  reg [4:0] refVal;

  integer i;

  task check;
    begin
      refVal = a + b + cin;
      #1; // let signals settle
      if ({cout, sum} !== refVal) begin
        $display("FAIL: a=%b b=%b cin=%b | got cout,sum=%b_%b expected=%b", a, b, cin, cout, sum, refVal);
        $stop;
      end
    end
  endtask

  initial begin
    $display("Starting 4 bit cla test...");

    // 1) all 4-bit combos for a and b + cin (2^4 * 2^4 * 2^1 = 512 tests)
    for (i = 0; i < 512; i = i + 1) begin
      {cin, a, b} = i[8:0]; //Loop value as 9 bits
      check();
    end
    $display("All a, b, cin, combinations have passed.");

    $finish;
  end
endmodule
