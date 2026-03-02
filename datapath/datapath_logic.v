module datapath_logic (
    input   wire        clk,
    input   wire        reset,

    // bus control
    input   wire [4:0]  bus_sel,
    input   wire [15:0] Rin,
    input   wire        Yin,
    input   wire        Zin,

    // control of internal special registers
    input   wire        PCin,
    input   wire        IRin,
    input   wire        MARin,
    input   wire        MDRin,
    input   wire        HIin,
    input   wire        LOin,
    input   wire        IncPC,
    input   wire        Read,
    input   wire [31:0] Mdatain,

    // reset-time seed values for internal special registers
    input   wire [31:0] PC,
    input   wire [31:0] IR,
    input   wire [31:0] HI,
    input   wire [31:0] LO,
    input   wire [31:0] MAR,
    input   wire [31:0] MDR,

    // ALU logic controls
    input   wire [3:0]  op,

    // debug/visibility
    output  wire [31:0] BUS,
    output  wire [31:0] R5_q,
    output  wire [31:0] R6_q,
    output  wire [31:0] R3_q,
    output  wire [31:0] R2_q,
    output  wire [31:0] R0_q,
    output  wire [31:0] R1_q,
    output  wire [31:0] R4_q,
    output  wire [31:0] R7_q,
    output  wire [31:0] HI_q_dbg,
    output  wire [31:0] LO_q_dbg,
    output  wire [31:0] IR_q_dbg,
    output  wire [31:0] PC_q_dbg,
    output  wire [31:0] Y_q,
    output  wire [63:0] Z_q
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
    assign R0_q = R[0];
    assign R1_q = R[1];
    assign R4_q = R[4];
    assign R7_q = R[7];

    // -------- Internal special registers --------
    reg [31:0] PC_q;
    reg [31:0] IR_q;
    reg [31:0] MAR_q;
    reg [31:0] MDR_q;
    reg [31:0] HI_q;
    reg [31:0] LO_q;

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
      .overflow(),
      .C(ALU_C)
    );

    // IncPC path for T0: Z <- PC + 1 when IncPC is asserted.
    wire [63:0] Z_d = IncPC ? {32'b0, (BUS + 32'd1)} : ALU_C;

    // -------- Z register --------
    register64 Zreg (
      .clk(clk), .reset(reset),
      .en(Zin),
      .d(Z_d),
      .q(Z_q)
    );

    wire [31:0] Zlow  = Z_q[31:0];
    wire [31:0] Zhigh = Z_q[63:32];

    assign HI_q_dbg = HI_q;
    assign LO_q_dbg = LO_q;
    assign IR_q_dbg = IR_q;
    assign PC_q_dbg = PC_q;

    // Special registers load from control signals.
    always @(posedge clk) begin
      if (reset) begin
        PC_q  <= PC;
        IR_q  <= IR;
        MAR_q <= MAR;
        MDR_q <= MDR;
        HI_q  <= HI;
        LO_q  <= LO;
      end else begin
        if (MARin) begin
          MAR_q <= BUS;
        end

        if (MDRin) begin
          MDR_q <= Read ? Mdatain : BUS;
        end

        if (IRin) begin
          IR_q <= BUS;
        end

        if (PCin) begin
          PC_q <= BUS;
        end

        if (HIin) begin
          HI_q <= BUS;
        end

        if (LOin) begin
          LO_q <= BUS;
        end
      end
    end

    bus_mux UBUS (
      .sel(bus_sel),

      .R0(R[0]), .R1(R[1]), .R2(R[2]), .R3(R[3]),
      .R4(R[4]), .R5(R[5]), .R6(R[6]), .R7(R[7]),
      .R8(R[8]), .R9(R[9]), .R10(R[10]), .R11(R[11]),
      .R12(R[12]), .R13(R[13]), .R14(R[14]), .R15(R[15]),

      .PC(PC_q),
      .IR(IR_q),
      .Y(Y_q),
      .MAR(MAR_q),
      .MDR(MDR_q),
      .HI(HI_q),
      .LO(LO_q),

      .Zlow(Zlow),
      .Zhigh(Zhigh),

      .bus(BUS)
    );

endmodule
