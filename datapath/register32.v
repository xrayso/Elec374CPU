// register32.v
module register32 (
    input  wire        clk,
    input  wire        reset,   // set to 0 on reset
    input  wire        en,      // load enable
    input  wire [31:0] d,
    output reg  [31:0] q
);

    // Synchronous reset
    always @(posedge clk) begin
        if (reset) begin
            q <= 32'b0;
        end else if (en) begin
            q <= d;
        end
    end

endmodule
