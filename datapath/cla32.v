module cla32(
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire        cin,
    output wire [31:0] sum,
    output wire        cout
);
    wire [7:0] P, G;      // group propagate/generate from each 4-bit block
    wire [8:0] C;         // carry into each block (C[0]=cin), C[8]=final cout

    assign C[0] = cin;

    genvar k;
    generate
        for (k=0; k<8; k=k+1) begin : BLK
            cla4 inst_cla4 (
                .a   (a[4*k+3 : 4*k]),
                .b   (b[4*k+3 : 4*k]),
                .cin (C[k]),
                .sum (sum[4*k+3 : 4*k]),
                .cout(),        // not needed since we use group P/G + C[k] to form C[k+1] below
                .P   (P[k]), //2 Gate Delays
                .G   (G[k])  //3 Gate Delays
            );
        end
    endgenerate

    // Carry from block to block (hierarchical CLA)
    assign C[1] = G[0] | (P[0] & C[0]); //4 gate delays
    assign C[2] = G[1] | (P[1] & C[1]); //6 gate delays
    assign C[3] = G[2] | (P[2] & C[2]); //8 gate delays
    assign C[4] = G[3] | (P[3] & C[3]); //10 gate delays
    assign C[5] = G[4] | (P[4] & C[4]); //12 gate delays
    assign C[6] = G[5] | (P[5] & C[5]); //14 gate delays
    assign C[7] = G[6] | (P[6] & C[6]); //16 gate delays
    assign C[8] = G[7] | (P[7] & C[7]); //18 gate delays

    assign cout = C[8];
endmodule
