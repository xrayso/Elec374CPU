`timescale 1ns/1ps
`include "defines.vh"

module datapath_add_tb;

  // clock/reset
  reg clk;
  reg reset;

  // ===== Controls into your datapath =====
  reg  [4:0]  bus_sel;
  reg  [15:0] Rin;
  reg         Yin;
  reg         Zin;
  reg  [3:0]  op;

  // ===== External inputs that your bus_mux can select =====
  reg [31:0] PC;
  reg [31:0] IR;
  reg [31:0] HI;
  reg [31:0] LO;
  reg [31:0] MAR;
  reg [31:0] MDR;

  // ===== Observability =====
  wire [31:0] BUS;
  wire [31:0] R5_q, R6_q, R3_q, R2_q, Y_q;
  wire [63:0] Z_q;

  // ===== DUT =====
  datapath_logic dut (
    .clk(clk),
    .reset(reset),

    .bus_sel(bus_sel),
    .Rin(Rin),
    .Yin(Yin),
    .Zin(Zin),

    .PC(PC),
    .IR(IR),
    .HI(HI),
    .LO(LO),
    .MAR(MAR),
    .MDR(MDR),

    .op(op),

    .BUS(BUS),
    .R5_q(R5_q),
    .R6_q(R6_q),
    .R3_q(R3_q),
    .R2_q(R2_q),
    .Y_q(Y_q),
    .Z_q(Z_q)
  );

  // ===== bus_sel constants from your bus_mux =====
  localparam SEL_R5   = 5'd5;
  localparam SEL_R6   = 5'd6;
  localparam SEL_MDR  = 5'd20;
  localparam SEL_ZLOW = 5'd23;

  // ===== FSM states (same pattern as the provided solution) =====
  parameter Default    = 4'b0000,
            Reg_load1a = 4'b0001, Reg_load1b = 4'b0010,
            Reg_load2a = 4'b0011, Reg_load2b = 4'b0100,
            Reg_load3a = 4'b0101, Reg_load3b = 4'b0110,
            T0         = 4'b0111,
            T1         = 4'b1000,
            T2         = 4'b1001,
            T3         = 4'b1010,
            T4         = 4'b1011,
            T5         = 4'b1100;

  reg [3:0] Present_state;

  // ===== Clock generation =====
  initial clk = 1'b0;
  always #5 clk = ~clk; // 100MHz equivalent

  // ===== State progression (posedge) =====
  always @(posedge clk) begin
    if (reset) begin
      Present_state <= Default;
    end else begin
      case (Present_state)
        Default    : Present_state <= Reg_load1a;
        Reg_load1a : Present_state <= Reg_load1b;
        Reg_load1b : Present_state <= Reg_load2a;
        Reg_load2a : Present_state <= Reg_load2b;
        Reg_load2b : Present_state <= Reg_load3a;
        Reg_load3a : Present_state <= Reg_load3b;
        Reg_load3b : Present_state <= T0;

        // We keep T0/T1/T2 in the sequence to match the template,
        // but we don't need to do a fetch in Phase 1.
        T0 : Present_state <= T1;
        T1 : Present_state <= T2;
        T2 : Present_state <= T3;

        T3 : Present_state <= T4;
        T4 : Present_state <= T5;
        T5 : Present_state <= T5; // stop advancing (or go Default)
        default: Present_state <= Default;
      endcase
    end
  end

  // ===== Combinational control for each state =====
  // Directly drives *your* datapath signals (bus_sel, Rin, Yin, Zin, op)
  always @(*) begin
    // defaults
    bus_sel = 5'd0;
    Rin     = 16'b0;
    Yin     = 1'b0;
    Zin     = 1'b0;
    op      = `ADDop;   // default ALU op

    // For Phase 1, IR/PC/MAR/HI/LO can be held constant unless you want otherwise.
    // We will drive IR separately in an initial block.

    case (Present_state)

      // ---------- Preload registers (via MDR -> BUS -> Rn) ----------
      // Load R5 with 7
      Reg_load1a: begin
        // put immediate value into MDR reg (TB-controlled)
        // actual assignment to MDR happens in a sequential block below
      end
      Reg_load1b: begin
        bus_sel = SEL_MDR;  // BUS <- MDR
        Rin[5]  = 1'b1;     // R5 <- BUS
      end

      // Load R6 with 11
      Reg_load2a: begin
        // put immediate value into MDR reg (TB-controlled)
      end
      Reg_load2b: begin
        bus_sel = SEL_MDR;  // BUS <- MDR
        Rin[6]  = 1'b1;     // R6 <- BUS
      end

      // optional third preload state (not used here)
      Reg_load3a: begin end
      Reg_load3b: begin end

      // ---------- T0/T1/T2: fetch in the prof design ----------
      // Not required in Phase 1; we keep them as "do nothing"
      T0: begin end
      T1: begin end
      T2: begin end

      // ---------- Execute ADD: R2 <- R5 + R6 ----------
      // T3: R5out, Yin
      T3: begin
        bus_sel = SEL_R5;   // BUS <- R5
        Yin     = 1'b1;     // Y <- BUS
      end

      // T4: R6out, ADD, Zin
      T4: begin
        bus_sel = SEL_R6;   // BUS <- R6
        op      = `ADDop;   // ALU does add
        Zin     = 1'b1;     // Z <- ALU
      end

      // T5: Zlowout, R2in
      T5: begin
        bus_sel = SEL_ZLOW; // BUS <- Zlow
        Rin[2]  = 1'b1;     // R2 <- BUS
      end

      default: begin end
    endcase
  end

  // ===== Sequential “TB-controlled” registers =====
  // We change MDR contents during the preload states.
  always @(posedge clk) begin
    if (reset) begin
      MDR <= 32'd0;
    end else begin
      case (Present_state)
        Reg_load1a: MDR <= 32'd7;
        Reg_load2a: MDR <= 32'd11;
        default: MDR <= MDR;
      endcase
    end
  end

  // ===== Test flow =====
  initial begin
    // init external inputs
    PC  = 32'd0;
    IR  = 32'd0;     // you can force IR to an "ADD R2,R5,R6" encoding if you want
    HI  = 32'd0;
    LO  = 32'd0;
    MAR = 32'd0;
    MDR = 32'd0;

    // reset
    reset = 1'b1;
    Present_state = Default;
    repeat (2) @(posedge clk);
    reset = 1'b0;

    // run until after T5 executes
    // Sequence length: Default + Reg_load1a/b + Reg_load2a/b + Reg_load3a/b + T0/T1/T2 + T3/T4/T5
    // That’s 1 + 2 + 2 + 2 + 3 + 3 = 13 cycles after reset deassert; give a bit extra.
    repeat (20) @(posedge clk);

    // check result
    $display("R5=%0d R6=%0d R2=%0d", R5_q, R6_q, R2_q);

    if (R2_q !== 32'd18) begin
      $display("FAIL: Expected R2=18, got R2=%0d", R2_q);
      $stop;
    end else begin
      $display("PASS: R2 = R5 + R6 verified.");
    end

    $finish;
  end

endmodule