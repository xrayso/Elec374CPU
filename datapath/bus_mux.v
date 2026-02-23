module bus_mux (
    input  wire [4:0]  sel,
    input  wire [31:0]  R0, R1, R2, R3, R4, R5, R6, R7, R8, R9, R10, R11, R12, R13, R14, R15,
    input  wire [31:0]  PC, IR, Y, MAR, MDR, HI, LO,
    input  wire [31:0]  Zlow, Zhigh,
    output reg  [31:0]  bus
);
    //Register numbers may need changing
    always @(*) begin
        case (sel)
            5'd0:  bus = R0;
            5'd1:  bus = R1;
            5'd2:  bus = R2;
            5'd3:  bus = R3;
            5'd4:  bus = R4;
            5'd5:  bus = R5;
            5'd6:  bus = R6;
            5'd7:  bus = R7;
            5'd8:  bus = R8;
            5'd9:  bus = R9;
            5'd10: bus = R10;
            5'd11: bus = R11;
            5'd12: bus = R12;
            5'd13: bus = R13;
            5'd14: bus = R14;
            5'd15: bus = R15;

            5'd16: bus = PC;
            5'd17: bus = IR;
            5'd18: bus = Y;
            5'd19: bus = MAR;
            5'd20: bus = MDR;
            5'd21: bus = HI;
            5'd22: bus = LO;
            5'd23: bus = Zlow;
            5'd24: bus = Zhigh;

            default: bus = 32'b0;
        endcase
    end
endmodule
