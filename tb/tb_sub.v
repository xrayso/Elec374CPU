`timescale 1ns/1ps
`include "defines.vh"

module tb_sub;
  reg clk = 1'b0;
  always #5 clk = ~clk;

  reg         reset;
  reg  [4:0]  bus_sel;
  reg  [15:0] Rin;
  reg         Yin, Zin;
  reg         PCin, IRin, MARin, MDRin, HIin, LOin, IncPC, Read;
  reg  [3:0]  op;
  reg  [31:0] Mdatain;
  reg  [31:0] PC, IR, HI, LO, MAR, MDR;

  wire [31:0] BUS;
  wire [31:0] R5_q, R6_q, R3_q, R2_q, R0_q, R1_q, R4_q, R7_q;
  wire [31:0] HI_q_dbg, LO_q_dbg, IR_q_dbg, PC_q_dbg, Y_q;
  wire [63:0] Z_q;

  localparam [4:0] SEL_R5   = 5'd5;
  localparam [4:0] SEL_R6   = 5'd6;
  localparam [4:0] SEL_PC   = 5'd16;
  localparam [4:0] SEL_MDR  = 5'd20;
  localparam [4:0] SEL_ZLOW = 5'd23;
  reg [31:0] sub_a;
  reg [31:0] sub_b;
  reg [31:0] expected_sub;
  reg        expected_overflow;
  reg        sub_overflow_seen;

  datapath_logic dut (
    .clk(clk), .reset(reset),
    .bus_sel(bus_sel), .Rin(Rin), .Yin(Yin), .Zin(Zin),
    .PCin(PCin), .IRin(IRin), .MARin(MARin), .MDRin(MDRin),
    .HIin(HIin), .LOin(LOin), .IncPC(IncPC), .Read(Read), .Mdatain(Mdatain),
    .PC(PC), .IR(IR), .HI(HI), .LO(LO), .MAR(MAR), .MDR(MDR),
    .op(op),
    .BUS(BUS),
    .R5_q(R5_q), .R6_q(R6_q), .R3_q(R3_q), .R2_q(R2_q),
    .R0_q(R0_q), .R1_q(R1_q), .R4_q(R4_q), .R7_q(R7_q),
    .HI_q_dbg(HI_q_dbg), .LO_q_dbg(LO_q_dbg), .IR_q_dbg(IR_q_dbg), .PC_q_dbg(PC_q_dbg),
    .Y_q(Y_q), .Z_q(Z_q)
  );

  task clear_ctrl;
    begin
      bus_sel  = 5'd0;
      Rin      = 16'b0;
      Yin      = 1'b0;
      Zin      = 1'b0;
      PCin     = 1'b0;
      IRin     = 1'b0;
      MARin    = 1'b0;
      MDRin    = 1'b0;
      HIin     = 1'b0;
      LOin     = 1'b0;
      IncPC    = 1'b0;
      Read     = 1'b0;
      op       = 4'd0;
      Mdatain  = 32'd0;
    end
  endtask

  task tick;
    begin
      @(negedge clk);
      @(posedge clk);
      #1;
    end
  endtask

  task load_reg;
    input integer dst;
    input [31:0] value;
    begin
      clear_ctrl();
      Mdatain = value;
      Read = 1'b1;
      MDRin = 1'b1;
      tick;

      clear_ctrl();
      bus_sel = SEL_MDR;
      Rin[dst] = 1'b1;
      tick;
    end
  endtask

  task fetch_instr;
    input [31:0] opcode;
    begin
      clear_ctrl();
      bus_sel = SEL_PC;
      MARin = 1'b1;
      IncPC = 1'b1;
      Zin = 1'b1;
      tick;

      clear_ctrl();
      bus_sel = SEL_ZLOW;
      PCin = 1'b1;
      Read = 1'b1;
      MDRin = 1'b1;
      Mdatain = opcode;
      tick;

      clear_ctrl();
      bus_sel = SEL_MDR;
      IRin = 1'b1;
      tick;
    end
  endtask

  initial begin
    $dumpfile("sub.vcd");
    $dumpvars(0, tb_sub);

    PC = 32'd0;
    IR = 32'd0;
    HI = 32'd0;
    LO = 32'd0;
    MAR = 32'd0;
    MDR = 32'd0;

    clear_ctrl();
    reset = 1'b1;
    tick;
    reset = 1'b0;

    sub_a = 32'h0000_0034;
    sub_b = 32'h0000_0045;
    expected_sub = sub_a - sub_b;
    expected_overflow = 1'b0;
    load_reg(5, sub_a);
    load_reg(6, sub_b);
    load_reg(2, 32'h0000_0067);

    fetch_instr(32'h092B0000); // sub R2, R5, R6
    if (IR_q_dbg !== 32'h092B0000) begin
      $display("FAIL SUB FETCH: IR=%h expected=%h", IR_q_dbg, 32'h092B0000);
      $fatal;
    end

    // T3: R5out, Yin
    clear_ctrl();
    bus_sel = SEL_R5;
    Yin = 1'b1;
    tick;

    // T4: R6out, SUB, Zin
    clear_ctrl();
    bus_sel = SEL_R6;
    op = `SUBop;
    Zin = 1'b1;
    tick;
    sub_overflow_seen = dut.ULOGIC.overflow;

    if (sub_overflow_seen !== expected_overflow) begin
      $display("FAIL SUB OVERFLOW: overflow=%b expected=%b (A=%h B=%h)", sub_overflow_seen, expected_overflow, sub_a, sub_b);
      $fatal;
    end

    // T5: Zlowout, R2in
    clear_ctrl();
    bus_sel = SEL_ZLOW;
    Rin[2] = 1'b1;
    tick;

    if (R2_q !== expected_sub) begin
      $display("FAIL SUB: R2=%h expected=%h (A=%h B=%h)", R2_q, expected_sub, sub_a, sub_b);
      $fatal;
    end

    $display("PASS SUB: R2=%h expected=%h overflow=%b", R2_q, expected_sub, sub_overflow_seen);
    $finish;
  end

endmodule
