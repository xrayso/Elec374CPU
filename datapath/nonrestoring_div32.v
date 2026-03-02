module nonrestoring_div32(
    input  wire [31:0] numerator,
    input  wire [31:0] denominator,
    output reg  [31:0] remainder,
    output reg  [31:0] quotient
);

    reg  signed [32:0] a;
    reg         [31:0] q;      
    reg  signed [32:0] m;

    reg num_neg, den_neg;

    integer i;

    reg [31:0] num_mag, den_mag;

    always @(*) begin
        num_neg = ($signed(numerator)   < 0);
        den_neg = ($signed(denominator) < 0);

        if (denominator == 32'b0) begin
            quotient  = 32'hFFFF_FFFF;
            remainder = numerator;
        end else begin
            num_mag = num_neg ? (~numerator + 1'b1) : numerator;
            den_mag = den_neg ? (~denominator + 1'b1) : denominator;

            a = 33'sd0;
            q = num_mag;
            m = {1'b0, den_mag};  

            for (i = 0; i < 32; i = i + 1) begin
                a = {a[31:0], q[31]};
                q = q << 1;

                if (a >= 0)
                    a = a - m;
                else
                    a = a + m;

                q[0] = (a >= 0);
            end

            if (a < 0)
                a = a + m;

            if (num_neg ^ den_neg)
                quotient = ~q + 1'b1;
            else
                quotient = q;

            if (num_neg)
                remainder = ~a[31:0] + 1'b1;
            else
                remainder = a[31:0];
        end
    end

endmodule