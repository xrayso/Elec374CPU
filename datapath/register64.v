// register64.v
module register64 (
    input  wire        clk,
    input  wire        reset,
    input  wire        en,
    input  wire [63:0] d,
    output reg  [63:0] q
);

    always @(posedge clk) begin
        if (reset) begin
            q <= 64'b0;
        end else if (en) begin
            q <= d;
        end
    end

endmodule
