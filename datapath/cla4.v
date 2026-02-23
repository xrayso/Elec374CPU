module cla4(
    input  wire [3:0] a,
    input  wire [3:0] b,
    input  wire       cin,
    output wire [3:0] sum,
    output wire       cout,
    output wire       P,   // group propagate
    output wire       G    // group generate
);
    wire [3:0] p, g;
    wire c1, c2, c3, c4;

    //First Gate Delay
    assign p = a ^ b; //XOR
    assign g = a & b;

    //Second(&) and Third(|) Gate Delay
    assign c1 = g[0] | (p[0] & cin);
    assign c2 = g[1] | (p[1] & g[0]) | (p[1] & p[0] & cin);
    assign c3 = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & cin);
    assign c4 = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1])
                      | (p[3] & p[2] & p[1] & g[0])
                      | (p[3] & p[2] & p[1] & p[0] & cin);

    //Fourth Gate Delay
    assign sum[0] = p[0] ^ cin;
    assign sum[1] = p[1] ^ c1;
    assign sum[2] = p[2] ^ c2;
    assign sum[3] = p[3] ^ c3;

    assign cout = c4;

    // Group P/G for building 32-bit hierarchy
    assign P = p[3] & p[2] & p[1] & p[0]; //2 Delays
    assign G = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]); //3 Delays
endmodule
