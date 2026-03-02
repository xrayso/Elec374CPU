`timescale 1ns/1ps
`include "defines.vh"

module tb_mul;
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

  localparam [4:0] SEL_R1    = 5'd1;
  localparam [4:0] SEL_R3    = 5'd3;
  localparam [4:0] SEL_PC    = 5'd16;
  localparam [4:0] SEL_MDR   = 5'd20;
  localparam [4:0] SEL_ZLOW  = 5'd23;
  localparam [4:0] SEL_ZHIGH = 5'd24;

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
    $dumpfile("mul.vcd");
    $dumpvars(0, tb_mul);

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

    load_reg(3, 32'h0001_0000);
    load_reg(1, 32'h0001_0000);

    fetch_instr(32'h6988_0000); // mul R3, R1
    if (IR_q_dbg !== 32'h6988_0000) begin
      $display("FAIL MUL FETCH: IR=%h expected=%h", IR_q_dbg, 32'h6988_0000);
      $fatal;
    end

    // T3: R3out, Yin
    clear_ctrl();
    bus_sel = SEL_R3;
    Yin = 1'b1;
    tick;

    // T4: R1out, MUL, Zin
    clear_ctrl();
    bus_sel = SEL_R1;
    op = `MULop;
    Zin = 1'b1;
    tick;

    // T5: Zlowout, LOin
    clear_ctrl();
    bus_sel = SEL_ZLOW;
    LOin = 1'b1;
    tick;

    // T6: Zhighout, HIin
    clear_ctrl();
    bus_sel = SEL_ZHIGH;
    HIin = 1'b1;
    tick;

    if (LO_q_dbg !== 32'h0000_0000 || HI_q_dbg !== 32'h0000_0001) begin
      $display("FAIL MUL: HI=%h LO=%h expected HI=00000001 LO=00000000", HI_q_dbg, LO_q_dbg);
      $fatal;
    end

    $display("PASS MUL: HI=%h LO=%h", HI_q_dbg, LO_q_dbg);
    $finish;
  end

endmodule
