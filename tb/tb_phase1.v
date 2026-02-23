`timescale 1ns/1ps
`include "/Users/josh/Desktop/374/datapath/defines.vh"



module tb_phase1;


reg clk = 0;
  always #5 clk = ~clk;
  //5ns clock

  reg reset;
    //Descriptions can be found in the datapath
  reg [4:0]  bus_sel;
  reg [15:0] Rin;
  reg Yin, Zin; 
  reg [3:0] op;
  reg [31:0] MDR;
  reg [31:0] MAR;

  wire [31:0] BUS, R5_q, R6_q, R3_q, R2_q, Y_q;
  wire [63:0] Z_q;

    

    datapath_logic dut (
    .clk(clk), .reset(reset),
    .bus_sel(bus_sel),
    .Rin(Rin),
    .Yin(Yin),
    .Zin(Zin),
    .op(op),
    .MDR(MDR),
    .MAR(MAR)
    .BUS(BUS),
    .R5_q(R5_q),
    .R6_q(R6_q),
    .R3_q(R3_q),
    .R2_q(R2_q),
    .Y_q(Y_q),
    .Z_q(Z_q)
  );


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


    parameter Default = 4'b0000, Reg_load1a = 4'b0001, Reg_load1b = 4'b0010, Reg_load2a = 4'b0011,
    Reg_load2b = 4'b0100, Reg_load3a = 4'b0101, Reg_load3b = 4'b0110, T0 = 4'b0111,
    T1 = 4'b1000, T2 = 4'b1001, T3 = 4'b1010, T4 = 4'b1011, T5 = 4'b1100;
    reg [3:0] Present_state = Default


  initial begin
    $dumpfile("logic.vcd");
    $dumpvars(0, tb_phase1);


  end

  always @(posedge clk) // finite state machine; if clock rising-edge
    begin
        case (Present_state)
            Default : Present_state = Reg_load1a;
            Reg_load1a : Present_state = Reg_load1b;
            Reg_load1b : Present_state = Reg_load2a;
            Reg_load2a : Present_state = Reg_load2b;
            Reg_load2b : Present_state = Reg_load3a;
            Reg_load3a : Present_state = Reg_load3b;
            Reg_load3b : Present_state = T0;
            T0 : Present_state = T1;
            T1 : Present_state = T2;
            T2 : Present_state = T3;
            T3 : Present_state = T4;
            T4 : Present_state = T5;
        endcase
    end


always @(Present_state) // do the required job in each state
 begin
    case (Present_state) // assert the required signals in each clock cycle
        Default: begin
            PCout <= 0; Zlowout <= 0; MDRout <= 0; // initialize the signals
            R3out <= 0; R7out <= 0; MARin <= 0; Zin <= 0;
            PCin <=0; MDRin <= 0; IRin <= 0; Yin <= 0;
            IncPC <= 0; Read <= 0; AND <= 0;
            R2in <= 0; R5in <= 0; R6in <= 0; Mdatain <= 32'h00000000;
        end
        Reg_load1a: begin
            Mdatain <= 32'h00000034;
            Read = 0; MDRin = 0; // the first zero is there for completeness
            Read <= 1; MDRin <= 1; // Took out #15 for '1', as it may not be needed
            #15 Read <= 0; MDRin <= 0; // for your current implementation
        end
            Reg_load1b: begin
            MDRout <= 1; R5in <= 1;
            #15 MDRout <= 0; R5in <= 0; // initialize R5 with the value 0x34
        end
        Reg_load2a: begin
            Mdatain <= 32’h00000045;
            Read <= 1; MDRin <= 1;
            #15 Read <= 0; MDRin <= 0;
        end
        Reg_load2b: begin
            MDRout <= 1; R6in <= 1;
            #15 MDRout <= 0; R6in <= 0; // initialize R6 with the value 0x45
        end
        Reg_load3a: begin
            Mdatain <= 32'h00000067;
            Read <= 1; MDRin <= 1;
            #15 Read <= 0; MDRin <= 0;
        end
        Reg_load3b: begin
            MDRout <= 1; R2in <= 1;
            #15 MDRout <= 0; R2in <= 0; // initialize R2 with the value 0x67
        end
        T0: begin // see if you need to de-assert these signals
            PCout <= 1; MARin <= 1; IncPC <= 1; Zin <= 1;
        end
        T1: begin
            Zlowout <= 1; PCin <= 1; Read <= 1; MDRin <= 1;
            Mdatain <= 32'h112B0000; // opcode for “and R2, R5, R6”
        end
        T2: begin
            MDRout <= 1; IRin <= 1; 
        end
        T3: begin
            R5out <= 1; Yin <= 1;
        end
        T4: begin
            R6out <= 1; AND <= 1; Zin <= 1;
        end
        T5: begin
            Zlowout <= 1; R2in <= 1;
        end
    endcase
end

endmodule