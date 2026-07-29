`timescale 1ns/1ps 

module simple_to_apb_bridge(
    input wire clk,
    input wire rst,

    // Simple bus side
    input wire        req,
    input wire        we, // 1 = write, 0 = read
    input wire [31:0] addr,
    input wire [31:0] wdata,
    input wire [3:0]  be

    output reg [31:0] rdata,
    output reg        ready,
    output reg        err,

    // APB master side
    output reg [31:0] PADDR,
    output reg        PSEL,
    output reg        PENABLE,
    output reg        PWRITE,
    output reg [31:0] PWDATA,
    output reg [3:0]  PSTRB,

    input  wire [31:0] PRDATA,
    input  wire        PREADY,
    input  wire        PSLVERR
);
    
    localparam IDLE   = 2'd0;
    localparam SETUP  = 2'd1;
    localparam ACCESS = 2'd2;

    reg [1:0] state;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state   <= IDLE;

            PADDR   <= 32'b0;
            PSEL    <= 1'b0;
            PENABLE <= 1'b0;
            PWRITE  <= 1'b0;
            PWDATA  <= 32'b0;
            PSTRB   <= 4'b0;

            rdata   <= 32'b0;
            ready   <= 1'b0;
            err     <= 1'b0;
        end else begin
            ready <= 1'b0;
            err   <= 1'b0;

            case (state)
                
                IDLE: begin
                    PSEL    <= 1'b0;
                    PENABLE <= 1'b0;

                    if (req) begin
                        PADDR   <= addr;
                        PWRITE  <= we;
                        PWDATA  <= wdata;
                        PSTRB   <= be;

                        PSEL    <= 1'b1;
                        PENABLE <= 1'b0;
                        state   <= SETUP;
                    end
                end

                SETUP: begin
                    PSEL    <= 1'b1;
                    PENABLE <= 1'b1;
                    state   <= ACCESS;
                end

                ACCESS: begin
                    PSEL    <= 1'b1;
                    PENABLE <= 1'b1;

                    if (PREADY) begin
                        rdata <= PRDATA;
                        ready <= 1'b1;
                        err   <= PSLVERR;

                        PSEL    <= 1'b0;
                        PENABLE <= 1'b0;
                        state   <= IDLE;
                    end
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule