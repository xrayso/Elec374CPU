module booth_bit_pair #(
    parameter N = 32
)(
    input  wire signed [N-1:0] M,   // multiplicand
    input  wire signed [N-1:0] Q,   // multiplier
    output reg  signed [2*N-1:0] P  // product
);

    integer i;

    reg signed [2*N-1:0] M_ext;
    reg signed [2*N-1:0] pp;        // current partial product (unshifted)
    reg [2:0] booth_bits;

    always @(*) begin
        M_ext = {{N{M[N-1]}}, M};   // sign-extend M to 2N
        P     = {2*N{1'b0}};

        //Bit Pair: (q[2i+1], q[2i], q[2i-1]) with q[-1] = 0
        for (i = 0; i < N/2; i = i + 1) begin
            booth_bits[0] = (i == 0) ? 1'b0 : Q[2*i - 1];

            booth_bits[1] = Q[2*i];
        
            booth_bits[2] = ((2*i + 1) < N) ? Q[2*i + 1] : Q[N-1];

            // Decode to pp in {-2M, -M, 0, +M, +2M}
            if ((booth_bits == 3'b000) || (booth_bits == 3'b111)) begin
                pp = {2*N{1'b0}};
            end else if ((booth_bits == 3'b001) || (booth_bits == 3'b010)) begin
                pp = M_ext;
            end else if (booth_bits == 3'b011) begin
                pp = M_ext <<< 1;
            end else if (booth_bits == 3'b100) begin
                pp = -(M_ext <<< 1);
            end else if ((booth_bits == 3'b101) || (booth_bits == 3'b110)) begin
                pp = -M_ext;
            end else begin
                pp = {2*N{1'b0}};
            end

            // Shift by 2i (shifted for the )
            P = P + (pp <<< (2*i));            
        end
    end

endmodule
