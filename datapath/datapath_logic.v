module datapath_logic (
    input   wire        clk,
    input   wire        reset,

    // bus control
    input   wire [4:0]  bus_sel,      // selects bus source
    input   wire [15:0] Rin,          // load enables for R0..R15
    input   wire        Yin,          // load Y from BUS
    input   wire        Zin,          // load Z from ALU output


    
    input   wire [31:0] PC,
    input   wire [31:0] IR,
    input   wire [31:0] HI,
    input   wire [31:0] LO,


    input   wire [31:0] MAR,
    input   wire [31:0] MDR,          // Injecting data through MDR

    // ALU logic controls
    input   wire [3:0]  op,


    //input  wire [31:0]  PC, IR, Y, MAR, MDR, HI, LO,

    // debug/visibility
    output    wire  [31:0] BUS,
    output    wire  [31:0] R5_q,
    output    wire  [31:0] R6_q,
    output    wire  [31:0] R3_q,
    output    wire  [31:0] R2_q,
    output    wire  [31:0] Y_q,
    output    wire  [63:0] Z_q
);

    // -------- Registers R0..R15 --------
    wire [31:0] R [0:15];

    genvar i;
    generate
      for (i = 0; i < 16; i = i + 1) begin : GEN_REGS
        register32 Ri (
          .clk(clk), .reset(reset),
          .en(Rin[i]),
          .d(BUS),
          .q(R[i])
        );
      end
    endgenerate

    assign R5_q = R[5];
    assign R6_q = R[6];
    assign R2_q = R[2];
    assign R3_q = R[3];

    // -------- Y register (operand A latch) --------
    register32 Yreg (
      .clk(clk), .reset(reset),
      .en(Yin),
      .d(BUS),
      .q(Y_q)
    );

    // -------- ALU logic (A=Y, B=BUS) --------
    wire [63:0] ALU_C;

    alu_logic ULOGIC (
      .A(Y_q),
      .B(BUS),
      .op(op),
      .C(ALU_C)
    );

    // -------- Z register --------
    register64 Zreg (
      .clk(clk), .reset(reset),
      .en(Zin),
      .d(ALU_C),
      .q(Z_q)
    );

    wire [31:0] Zlow = Z_q[31:0];
    wire [31:0] Zhigh = Z_q[63:32];
    

bus_mux UBUS (
  .sel(bus_sel),

  .R0(R[0]), .R1(R[1]), .R2(R[2]), .R3(R[3]),
  .R4(R[4]), .R5(R[5]), .R6(R[6]), .R7(R[7]),
  .R8(R[8]), .R9(R[9]), .R10(R[10]), .R11(R[11]),
  .R12(R[12]), .R13(R[13]), .R14(R[14]), .R15(R[15]),

  .PC(PC),
  .IR(IR),
  .Y(Y_q),
  .MAR(MAR),
  .MDR(MDR),   // handy hack: lets you inject via sel=20
  .HI(HI),
  .LO(LO),

  .Zlow(Zlow),
  .Zhigh(Zhigh),

  .bus(BUS)
);



endmodule
