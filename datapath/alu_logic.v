`include "/Users/josh/Desktop/374/datapath/defines.vh"

module alu_logic (
    input   wire [31:0]     A,
    input   wire [31:0]     B,
    input   wire [3:0]      op,  

    output reg          overflow,
    output reg  [63:0]  C
    //Implemented - And(1), Or(2), Addition (CLA)(8), Multiplication(10), Shift Left(3)
                      //Rotate Left(6), Rotate Right(7), Shift Right(4), Shift Right (Signed)(5)
    //Not Implemented - Subtraction(9), Division(11), negate, not
);

    // Add/Sub wiring
    wire [31:0] B_eff   = (op == `SUBop) ? ~B : B; //Invert B if subtracting
    wire        cin_eff = (op == `SUBop) ? 1'b1 : 1'b0; //Add a carry in that will finish the 2's compliment

    wire [31:0] add_sum;
    wire        add_cout;
    wire [63:0] md_sum;
    
    wire [4:0] sh = B[4:0]; //For Rotating



    cla32 inst_cla32 (
                .a  (A),
                .b  (B),
                .cin    (cin_eff),
                .sum    (add_sum),
                .cout   (add_cout)
            );
    
    booth_bit_pair inst_bbp (
                .M(A),
                .Q(B),
                .P(md_sum)
            );

    always @(*) begin
        C = 64'b0;



        case (op)

            `ANDop:  C = {32'b0, (A & B)};
            `ORop:   C = {32'b0, (A | B)};
            `SHLop:  C = {32'b0, A << B}; //32-bit return
            `SHRop:  C = {32'b0, A >> B}; //32-bit return
            `SHRAop: C = (A[31] == 1) ? {32'b0, A >>> B} : {32'b0, A >>> B}; //32-bit return
            `ROLop:  C = {32'b0, (sh == 0) ? A : ((A << sh) | (A >> (5'd32 - sh)))};
            `RORop:  C = {32'b0, (sh == 0) ? A : ((A >> sh) | (A << (5'd32 - sh)))};
            `ADDop:  C = {32'b0, add_sum};
            `MULop:  C = {md_sum};
            `NEGop:  C = {32'b0, ~B+1'b1};
            `NOTop:  C = {32'b0, ~B};
            `SUBop:  C = {32'b0, add_sum};

        endcase



    end
endmodule
