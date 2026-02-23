`timescale 1ns/1ps
`include "/Users/josh/Desktop/374/datapath/defines.vh"


module tb_logic;

  reg clk = 0;
  always #5 clk = ~clk;
  //5ns clock

  reg reset;
    //Descriptions can be found in the datapath
  reg [4:0]  bus_sel;
  reg [15:0] Rin;
  reg Yin, Zin; 
  reg [3:0] op;
  reg [31:0] InPort_data;

  wire [31:0] BUS, R5_q, R6_q, R3_q, R2_q, Y_q;
  wire [63:0] Z_q;

  datapath_logic dut (
    .clk(clk), .reset(reset),
    .bus_sel(bus_sel),
    .Rin(Rin),
    .Yin(Yin),
    .Zin(Zin),
    .op(op),
    .InPort_data(InPort_data),
    .BUS(BUS),
    .R5_q(R5_q),
    .R6_q(R6_q),
    .R3_q(R3_q),
    .R2_q(R2_q),
    .Y_q(Y_q),
    .Z_q(Z_q)
  );
    //Clears control signals between ticks
  task clear_ctrl;
    begin
      bus_sel = 0;
      Rin     = 0;
      Yin     = 0;
      Zin     = 0;
      op   = 0;
    end
  endtask
    //Ticks the clock forward and waits a nanosecond
  task tick;
    begin
      @(negedge clk);
      @(posedge clk);
      #1;
    end
  endtask

    //Local vars 
    localparam SEL_R5   = 5'd5;
    localparam SEL_R6   = 5'd6;
    localparam SEL_ZLOW = 5'd23;
    localparam SEL_ZHI  = 5'd24;
    localparam SEL_IN   = 5'd20; //Use 20 for select (MDR)

    localparam a        = 32'hF0F0_0F0F;
    localparam b        = 32'h0000_0007;

  initial begin
    $dumpfile("logic.vcd");
    $dumpvars(0, tb_logic);

    // reset
    clear_ctrl();
    reset = 1;
    InPort_data = 0;
    tick;
    reset = 0;

    // Load R5 = 0xF0F00F0F
    clear_ctrl();
    InPort_data = a;
    bus_sel = SEL_IN;
    Rin[5] = 1;
    tick;

    // Load R6 = 0xAAAA5555
    clear_ctrl();
    InPort_data = b;
    bus_sel = SEL_IN;
    Rin[6] = 1;
    tick;

    // -------- AND: R2 = R5 & R6 --------
    // T1: R5 -> Y
    clear_ctrl();
    bus_sel = SEL_R5;
    Yin = 1;
    tick;

    // T2: R6 + AND -> Z
    clear_ctrl();
    bus_sel = SEL_R6;
    op = `ANDop;
    Zin = 1;
    tick;

    // T3: Zlow -> R2
    clear_ctrl();
    bus_sel = SEL_ZLOW;
    Rin[2] = 1;
    tick;

    if (R2_q !== (a & b)) begin
      $display("FAIL AND: R2=%h expected=%h", R2_q, (32'hF0F0_0F0F & 32'hAAAA_5555));
      $fatal;
    end
    $display("PASS AND: R2=%h", R2_q);

    // -------- OR: R2 = R5 | R6 --------
    // reuse same destination register
    // T1: R5 -> Y
    clear_ctrl();
    bus_sel = SEL_R5;
    Yin = 1;
    tick;

    // T2: R6 + OR -> Z
    clear_ctrl();
    bus_sel = SEL_R6;
    op = `ORop;
    Zin = 1;
    tick;

    // T3: Zlow -> R2
    clear_ctrl();
    bus_sel = SEL_ZLOW;
    Rin[2] = 1;
    tick;

    if (R2_q !== (a | b)) begin
      $display("FAIL OR: R2=%h expected=%h", R2_q, (32'hF0F0_0F0F | 32'hAAAA_5555));
      $fatal;
    end
    $display("PASS OR: R2=%h", R2_q);

    // -------- SHL: R2 = R5 << (R6[4:0]) --------
    // T1: R5 -> Y
    clear_ctrl();
    bus_sel = SEL_R5;
    Yin = 1;
    tick;

    // T2: SHL using BUS=R6 as shift amount -> Z
    clear_ctrl();
    bus_sel = SEL_R6;
    op = `SHLop;
    Zin = 1;
    tick;

    // T3: Zlow -> R2
    clear_ctrl();
    bus_sel = SEL_ZLOW;
    Rin[2] = 1;
    tick;

    if (R2_q !== (a << b)) begin
      $display("FAIL SHL: R2=%h expected=%h", R2_q, (a << b));
      $fatal;
    end
    $display("PASS SHL: R2=%h", R2_q);

    // -------- SHR: R2 = R5 >> (R6[4:0]) --------
    // T1: R5 -> Y
    clear_ctrl();
    bus_sel = SEL_R5;
    Yin = 1;
    tick;

    // T2: SHR using BUS=R6 as shift amount -> Z
    clear_ctrl();
    bus_sel = SEL_R6;
    op = `SHRop;
    Zin = 1;
    tick;

    // T3: Zlow -> R2
    clear_ctrl();
    bus_sel = SEL_ZLOW;
    Rin[2] = 1;
    tick;

    if (R2_q !== (a >> b)) begin
      $display("FAIL SHR: R2=%h expected=%h", R2_q, (a >> b));
      $fatal;
    end
    $display("PASS SHR: R2=%h", R2_q);

    // -------- SHRA: R2 = $signed(R5) >>> (R6[4:0]) --------
    // T1: R5 -> Y
    clear_ctrl();
    bus_sel = SEL_R5;
    Yin = 1;
    tick;

    // T2: SHRA using BUS=R6 as shift amount -> Z
    clear_ctrl();
    bus_sel = SEL_R6;
    op = `SHRAop;
    Zin = 1;
    tick;

    // T3: Zlow -> R2
    clear_ctrl();
    bus_sel = SEL_ZLOW;
    Rin[2] = 1;
    tick;

    if (R2_q !== ($signed(a) >>> b)) begin
      $display("FAIL SHRA: R2=%h expected=%h", R2_q, ($signed(a) >>> b));
      $fatal;
    end
    $display("PASS SHRA: R2=%h", R2_q);

    // -------- ROL: R2 = ROL(R5, R6[4:0]) --------
    // T1: R5 -> Y
    clear_ctrl();
    bus_sel = SEL_R5;
    Yin = 1;
    tick;

    // T2: ROL using BUS=R6 as rotate amount -> Z
    clear_ctrl();
    bus_sel = SEL_R6;
    op = `ROLop;
    Zin = 1;
    tick;

    // T3: Zlow -> R2
    clear_ctrl();
    bus_sel = SEL_ZLOW;
    Rin[2] = 1;
    tick;

    if (R2_q !== ((a << b[4:0]) | (a >> (5'd32 - b[4:0])))) begin
      $display("FAIL ROL: R2=%h expected=%h", R2_q,
              ((a << b[4:0]) | (a >> (5'd32 - b[4:0]))));
      $fatal;
    end
    $display("PASS ROL: R2=%h", R2_q);

    // -------- ROR: R2 = ROR(R5, R6[4:0]) --------
    // T1: R5 -> Y
    clear_ctrl();
    bus_sel = SEL_R5;
    Yin = 1;
    tick;

    // T2: ROR using BUS=R6 as rotate amount -> Z
    clear_ctrl();
    bus_sel = SEL_R6;
    op = `RORop;
    Zin = 1;
    tick;

    // T3: Zlow -> R2
    clear_ctrl();
    bus_sel = SEL_ZLOW;
    Rin[2] = 1;
    tick;

    if (R2_q !== ((a >> b[4:0]) | (a << (5'd32 - b[4:0])))) begin
      $display("FAIL ROR: R2=%h expected=%h", R2_q,
              ((a >> b[4:0]) | (a << (5'd32 - b[4:0]))));
      $fatal;
    end
    $display("PASS ROR: R2=%h", R2_q);




    // Load R5 = 0xF0F00F0F
    clear_ctrl();
    InPort_data = 32'h0001_0000;
    bus_sel = SEL_IN;
    Rin[5] = 1;
    tick;

    // Load R6 = 0xAAAA5555
    clear_ctrl();
    InPort_data = 32'h0001_0000;
    bus_sel = SEL_IN;
    Rin[6] = 1;
    tick;

    // -------- ADD: R2 = R5 + R6 --------
    // reuse same destination register
    // T1: R5 -> Y
    clear_ctrl();
    bus_sel = SEL_R5;
    Yin = 1;
    tick;

    // T2: R6 + R5 -> Z
    clear_ctrl();
    bus_sel = SEL_R6;
    op = `ADDop;
    Zin = 1;
    tick;

    // T3: Zlow -> R2
    clear_ctrl();
    bus_sel = SEL_ZLOW;
    Rin[2] = 1;
    tick;

    if (R2_q !== (32'h0001_0000 + 32'h0001_0000)) begin
      $display("FAIL OR: R2=%h expected=%h", R2_q, (32'h0001_0000 + 32'h0001_0000));
      $fatal;
    end
    $display("PASS ADD: R2=%h", R2_q);

    // -------- MUL: R2 = R5 + R6 --------
    // reuse same destination register
    // T1: R5 -> Y
    clear_ctrl();
    bus_sel = SEL_R5;
    Yin = 1;
    tick;

    // T2: R6 + R5 -> Z
    clear_ctrl();
    bus_sel = SEL_R6;
    op = `MULop;
    Zin = 1;
    tick;

    // T3: Zlow -> R2
    clear_ctrl();
    bus_sel = SEL_ZLOW;
    Rin[2] = 1;
    tick;

    // T3: Zlow -> R3
    clear_ctrl();
    bus_sel = SEL_ZHI;
    Rin[3] = 1;
    tick;

    if ({R3_q, R2_q} !== (64'h0001_0000 * 64'h0001_0000)) begin
      $display("FAIL MUL: R2=%h expected=%h", {R3_q, R2_q}, (64'h0001_0000 * 64'h0001_0000));
      $fatal;
    end
    $display("PASS MUL: R2R3=%h", {R3_q, R2_q});

    $finish;
  end

endmodule
