`timescale 1ns/1ps
`include "defines.vh"

module tb_logic;
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

  localparam [4:0] SEL_R0   = 5'd0;
  localparam [4:0] SEL_R4   = 5'd4;
  localparam [4:0] SEL_R5   = 5'd5;
  localparam [4:0] SEL_R6   = 5'd6;
  localparam [4:0] SEL_R7   = 5'd7;
  localparam [4:0] SEL_PC   = 5'd16;
  localparam [4:0] SEL_MDR  = 5'd20;
  localparam [4:0] SEL_ZLOW = 5'd23;

  localparam [31:0] A_VAL = 32'hF0F0_0F0F;
  localparam [31:0] B_VAL = 32'hAAAA_5555;
  localparam [4:0]  SHAMT = 5'd7;

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
        $display("FAIL FETCH: IR=%h expected=%h", IR_q_dbg, opcode);
        $fatal;
      end
    end
  endtask

  task exec_bin_to_reg;
    input [4:0] src_a_sel;
    input [4:0] src_b_sel;
    input [3:0] alu_op;
    input integer dst;
    begin
      // T3: src_a -> Y
      clear_ctrl();
      bus_sel = src_a_sel;
      Yin = 1'b1;
      tick;

      // T4: src_b + ALU op -> Z
      clear_ctrl();
      bus_sel = src_b_sel;
      op = alu_op;
      Zin = 1'b1;
      tick;

      // T5: Zlow -> dst
      clear_ctrl();
      bus_sel = SEL_ZLOW;
      Rin[dst] = 1'b1;
      tick;
    end
  endtask

  initial begin
    $dumpfile("logic.vcd");
    $dumpvars(0, tb_logic);

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

    load_reg(5, A_VAL);         // R5
    load_reg(6, B_VAL);         // R6
    load_reg(0, A_VAL);         // R0
    load_reg(4, {27'd0, SHAMT}); // R4

    // OR R2, R5, R6
    fetch_instr(32'h192B0000);
    exec_bin_to_reg(SEL_R5, SEL_R6, `ORop, 2);
    if (R2_q !== (A_VAL | B_VAL)) begin
      $display("FAIL OR: R2=%h expected=%h", R2_q, (A_VAL | B_VAL));
      $fatal;
    end
    $display("PASS OR: R2=%h", R2_q);

    // SHR R7, R0, R4
    fetch_instr(32'h23820000);
    exec_bin_to_reg(SEL_R0, SEL_R4, `SHRop, 7);
    if (R7_q !== (A_VAL >> SHAMT)) begin
      $display("FAIL SHR: R7=%h expected=%h", R7_q, (A_VAL >> SHAMT));
      $fatal;
    end
    $display("PASS SHR: R7=%h", R7_q);

    // SHRA R7, R0, R4
    fetch_instr(32'h2B820000);
    exec_bin_to_reg(SEL_R0, SEL_R4, `SHRAop, 7);
    if (R7_q !== 32'hFFE1_E01E) begin
      $display("FAIL SHRA: R7=%h expected=%h", R7_q, 32'hFFE1_E01E);
      $fatal;
    end
    $display("PASS SHRA: R7=%h", R7_q);

    // SHL R7, R0, R4
    fetch_instr(32'h33820000);
    exec_bin_to_reg(SEL_R0, SEL_R4, `SHLop, 7);
    if (R7_q !== (A_VAL << SHAMT)) begin
      $display("FAIL SHL: R7=%h expected=%h", R7_q, (A_VAL << SHAMT));
      $fatal;
    end
    $display("PASS SHL: R7=%h", R7_q);

    // ROR R7, R0, R4
    fetch_instr(32'h3B820000);
    exec_bin_to_reg(SEL_R0, SEL_R4, `RORop, 7);
    if (R7_q !== ((A_VAL >> SHAMT) | (A_VAL << (6'd32 - SHAMT)))) begin
      $display("FAIL ROR: R7=%h expected=%h", R7_q, ((A_VAL >> SHAMT) | (A_VAL << (6'd32 - SHAMT))));
      $fatal;
    end
    $display("PASS ROR: R7=%h", R7_q);

    // ROL R7, R0, R4
    fetch_instr(32'h43820000);
    exec_bin_to_reg(SEL_R0, SEL_R4, `ROLop, 7);
    if (R7_q !== ((A_VAL << SHAMT) | (A_VAL >> (6'd32 - SHAMT)))) begin
      $display("FAIL ROL: R7=%h expected=%h", R7_q, ((A_VAL << SHAMT) | (A_VAL >> (6'd32 - SHAMT))));
      $fatal;
    end
    $display("PASS ROL: R7=%h", R7_q);

    if (PC_q_dbg !== 32'd6) begin
      $display("FAIL LOGIC: PC=%h expected=%h", PC_q_dbg, 32'd6);
      $fatal;
    end

    $display("PASS LOGIC SUITE: PC=%h", PC_q_dbg);
    $finish;
  end

endmodule
