`include "defines.vh"

module alu_logic (
    input   wire [31:0]     A,
    input   wire [31:0]     B,
    input   wire [3:0]      op,  

    output reg          overflow,
    output reg  [63:0]  C
    //Implemented - And(1), Or(2), Addition (CLA)(8), Multiplication(10), Shift Left(3)
                      //Rotate Left(6), Rotate Right(7), Shift Right(4), Shift Right (Signed)(5), negate, not, Subtraction(9), Division(11), 
);

    // Add/Sub wiring
    wire [31:0] B_eff   = (op == `SUBop) ? ~B : B;
    wire        cin_eff = (op == `SUBop) ? 1'b1 : 1'b0;

    wire [31:0] add_sum;
    wire        add_cout;
    wire [63:0] md_sum;

    // Division wiring
    wire [31:0] div_q;
    wire [31:0] div_r;
    
    wire [4:0] sh = B[4:0];
    wire       add_overflow = (~(A[31] ^ B[31])) & (add_sum[31] ^ A[31]);
    wire       sub_overflow = (A[31] ^ B[31]) & (add_sum[31] ^ A[31]);



    cla32 inst_cla32 (
                .a  (A),
                .b  (B_eff),
                .cin    (cin_eff),
                .sum    (add_sum),
                .cout   (add_cout)
            );
    
    booth_bit_pair inst_bbp (
                .M(A),
                .Q(B),
                .P(md_sum)
            );


    nonrestoring_div32 u_div (
        .numerator   (A),
        .denominator (B),
        .remainder   (div_r),
        .quotient    (div_q)
    );


    always @(*) begin
        C = 64'b0;
        overflow = 1'b0;

        case (op)

            `ANDop:  C = {32'b0, (A & B)};
            `ORop:   C = {32'b0, (A | B)};
            `SHLop:  C = {32'b0, A << sh};
            `SHRop:  C = {32'b0, A >> sh};
            `SHRAop: C = {32'b0, $signed(A) >>> sh};
            `ROLop:  C = {32'b0, (sh == 0) ? A : ((A << sh) | (A >> (6'd32 - sh)))};
            `RORop:  C = {32'b0, (sh == 0) ? A : ((A >> sh) | (A << (6'd32 - sh)))};
            `ADDop: begin
                C = {32'b0, add_sum};
                overflow = add_overflow;
            end
            `MULop:  C = {md_sum};
            `NEGop:  C = {32'b0, ~B+1'b1};
            `NOTop:  C = {32'b0, ~B};
            `SUBop: begin
                C = {32'b0, add_sum};
                overflow = sub_overflow;
            end
            `DIVop: C = {div_r, div_q};
            default: begin
                C = 64'b0;
                overflow = 1'b0;
            end

        endcase

    end
endmodule
