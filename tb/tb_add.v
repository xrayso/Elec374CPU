`timescale 1ns/1ps
`include "defines.vh"

module datapath_add_tb;
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
  reg [31:0] add_a;
  reg [31:0] add_b;
  reg [31:0] expected_add;

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
      // T0: PCout, MARin, IncPC, Zin
      clear_ctrl();
      bus_sel = SEL_PC;
      MARin = 1'b1;
      IncPC = 1'b1;
      Zin = 1'b1;
      tick;

      // T1: Zlowout, PCin, Read, Mdatain, MDRin
      clear_ctrl();
      bus_sel = SEL_ZLOW;
      PCin = 1'b1;
      Read = 1'b1;
      MDRin = 1'b1;
      Mdatain = opcode;
      tick;

      // T2: MDRout, IRin
      clear_ctrl();
      bus_sel = SEL_MDR;
      IRin = 1'b1;
      tick;

      if (IR_q_dbg !== opcode) begin
        $display("FAIL ADD FETCH: IR=%h expected=%h", IR_q_dbg, opcode);
        $fatal;
      end
    end
  endtask

  initial begin
    $dumpfile("add.vcd");
    $dumpvars(0, datapath_add_tb);

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

    // Keep expectations aligned with the register preload values used in the demo.
    add_a = 32'h0000_0034;
    add_b = 32'h0000_0045;
    expected_add = add_a + add_b;

    load_reg(5, add_a);
    load_reg(6, add_b);
    load_reg(2, 32'h0000_0067);

    fetch_instr(32'h012B0000); // add R2, R5, R6

    // T3: R5out, Yin
    clear_ctrl();
    bus_sel = SEL_R5;
    Yin = 1'b1;
    tick;

    // T4: R6out, ADD, Zin
    clear_ctrl();
    bus_sel = SEL_R6;
    op = `ADDop;
    Zin = 1'b1;
    tick;

    // T5: Zlowout, R2in
    clear_ctrl();
    bus_sel = SEL_ZLOW;
    Rin[2] = 1'b1;
    tick;

    if (R2_q !== expected_add) begin
      $display("FAIL ADD: R2=%h expected=%h (A=%h B=%h)", R2_q, expected_add, add_a, add_b);
      $fatal;
    end

    if (PC_q_dbg !== 32'h0000_0001) begin
      $display("FAIL ADD: PC=%h expected=%h", PC_q_dbg, 32'h0000_0001);
      $fatal;
    end

    $display("PASS ADD: R2=%h expected=%h PC=%h IR=%h", R2_q, expected_add, PC_q_dbg, IR_q_dbg);
    $finish;
  end

endmodule
