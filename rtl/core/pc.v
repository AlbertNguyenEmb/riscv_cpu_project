`timescale 1ns/1ps

module pc (
    input  wire        clk,
    input  wire        rst,
    output reg  [31:0] pc_out
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_out <= 32'b0;
        end else begin
            pc_out <= pc_out + 32'd4;
        end
    end

endmodule