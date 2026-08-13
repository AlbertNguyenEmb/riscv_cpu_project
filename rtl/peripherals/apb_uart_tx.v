`timescale 1ns/1ps

module apb_uart_tx(
    input wire PCLK,
    input wire PRESETn,

    input wire        PSEL,
    input wire        PENABLE,
    input wire        PWRITE,
    input wire [31:0] PADDR,
    input wire [31:0] PWDATA,
    input wire [3:0]  PSTRB,
    
    output reg [31:0] PRDATA,
    output wire       PREADY,
    output reg        PSLVERR,

    output reg        uart_tx
);
    
    localparam ADDR_TXDATA = 12'h000;
    localparam ADDR_STATUS = 12'h004;
    localparam ADDR_BAUD_DIV = 12'h008;

    localparam S_IDLE  = 2'd0;
    localparam S_START = 2'd1;
    localparam S_DATA  = 2'd2;
    localparam S_STOP  = 2'd3;

    reg [1:0]  state;
    reg [7:0]  tx_shift;
    reg [2:0]  bit_index;
    reg [15:0] baud_div;
    reg [15:0] baud_count;
    reg        tx_busy;
    reg        tx_done_flag;

    wire apb_access;
    wire [11:0] local_addr;

    assign apb_access = PSEL && PENABLE;
    assign local_addr = PADDR[11:0];

    assign PREADY = 1'b1;

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            state        <= S_IDLE;
            tx_shift     <= 8'b0;
            bit_index    <= 3'b0;
            baud_div     <= 16'd4;
            baud_count   <= 16'b0;
            tx_busy      <= 1'b0;
            tx_done_flag <= 1'b0;
            uart_tx      <= 1'b1;
            PSLVERR      <= 1'b0;
        end else begin
            PSLVERR <= 1'b0;

            // UART transmitter FSM
            case (state)
                
                S_IDLE: begin
                    uart_tx <= 1'b1;
                    tx_busy <= 1'b0;

                    if (apb_access && PWRITE && local_addr == ADDR_TXDATA) begin
                        if (!tx_busy) begin
                            tx_shift   <= PWDATA[7:0];
                            bit_index  <= 3'd0;
                            baud_count <= baud_div;
                            tx_busy      <= 1'b1;
                            tx_done_flag <= 1'b0;
                            uart_tx      <= 1'b0; // start bit
                            state        <= S_START;
                        end else begin
                            PSLVERR <= 1'b1;
                        end
                    end
                end

                S_START: begin
                    tx_busy <= 1'b1;
                    uart_tx <= 1'b0;

                    if (baud_count == 16'd0) begin
                        baud_count <= baud_div;
                        uart_tx    <= tx_shift[0];
                        state      <= S_DATA;
                    end else begin
                        baud_count <= baud_count - 16'd1;
                    end
                end

                S_DATA: begin
                    tx_busy <= 1'b1;
                    uart_tx <= tx_shift[bit_index];

                    if (baud_count == 16'd0) begin
                        baud_count <= baud_div;

                        if (bit_index == 3'd7) begin
                            state <= S_STOP;
                            uart_tx <= 1'b1;
                        end else begin
                            bit_index <= bit_index + 3'd1;
                            uart_tx   <= tx_shift[bit_index + 3'd1];
                        end
                    end else begin
                        baud_count <= baud_count - 16'd1;
                    end
                end

                S_STOP: begin
                    tx_busy <= 1'b1;
                    uart_tx <= 1'b1;

                    if (baud_count == 16'd0) begin
                        state        <= S_IDLE;
                        tx_busy      <= 1'b0;
                        tx_done_flag <= 1'b1;
                    end else begin
                        baud_count <= baud_count - 16'd1;
                    end
                end

                default: begin
                    state <= S_IDLE;
                end
            endcase
        end

        // APB register writes
        if (apb_access && PWRITE) begin
            case (local_addr)
                
                ADDR_STATUS: begin
                    if (PWDATA[1]) begin
                        tx_done_flag <= 1'b0;
                    end
                end

                ADDR_BAUD_DIV: begin
                    if (PSTRB[0]) baud_div[7:0]  <= PWDATA[7:0];
                    if (PSTRB[1]) baud_div[15:8] <= PWDATA[15:8];
                end

                ADDR_TXDATA: begin
                        // handled by FSM above
                    end

                default: begin
                    PSLVERR <= 1'b1;
                end
            endcase
        end
    end

    always @(*) begin
        PRDATA = 32'b0;

        if (PSEL && !PWRITE) begin
            case (local_addr)

                ADDR_TXDATA: begin
                    PRDATA = {24'b0, tx_shift};
                end

                ADDR_STATUS: begin
                    // bit0 = busy, bit1 = done
                    PRDATA = {30'b0, tx_done_flag, tx_busy};
                end

                ADDR_BAUD_DIV: begin
                    PRDATA = {16'b0, baud_div};
                end

                default: begin
                    PRDATA = 32'b0;
                end

            endcase
        end
    end
endmodule