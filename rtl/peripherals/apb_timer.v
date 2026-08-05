`timescale 1ns/1ps

module apb_timer(
    // The signal of APB bridge
    input wire PCLK,
    input wire PRESETn,

    input wire PSEL,
    input wire PENABLE,
    input wire PWRITE,
    input wire [31:0] PADDR,
    input wire [31:0] PWDATA,
    input wire [3:0]  PSTRB,

    output reg [31:0] PRDATA,
    output wire       PREADY,
    output reg        PSLVERR,

    // The signal of timer peripheral
    output wire       timer_irq
);
    
    localparam ADDR_TIMER_CTRL    = 12'h000;
    localparam ADDR_TIMER_COUNT   = 12'h004;
    localparam ADDR_TIMER_COMPARE = 12'h008;
    localparam ADDR_TIMER_STATUS  = 12'h00C;

    reg        timer_enable;
    reg [31:0] timer_count;
    reg [31:0] timer_compare;
    reg        irq_flag;

    wire apb_access;
    wire [11:0] local_addr;

    assign apb_access = PSEL && PENABLE;
    assign local_addr = PADDR[11:0];
    
    assign PREADY = 1'b1;
    assign timer_irq = irq_flag;

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            timer_enable  <= 1'b0;
            timer_count   <= 32'b0;
            timer_compare <= 32'd10;
            irq_flag      <= 1'b0;
            PSLVERR       <= 1'b0; 
        end else begin
            PSLVERR <= 1'b0;

            if (timer_enable) begin
                timer_count <= timer_count + 1'b1;

                if (timer_count == timer_compare) begin
                    irq_flag <= 1'b1;
                end
            end

            if (apb_access && PWRITE) begin
                    case (local_addr)
                        
                        ADDR_TIMER_CTRL: begin
                            timer_enable <= PWDATA[0];

                            if (PWDATA[1]) begin
                                timer_count <= 32'b0;
                            end

                            if (PWDATA[2]) begin
                                irq_flag <= 1'b0;
                            end
                        end

                        ADDR_TIMER_COMPARE: begin
                            if (PSTRB[0]) timer_compare[7:0]   <= PWDATA[7:0];
                            if (PSTRB[1]) timer_compare[15:8]  <= PWDATA[15:8];
                            if (PSTRB[2]) timer_compare[23:16] <= PWDATA[23:16];
                            if (PSTRB[3]) timer_compare[31:24] <= PWDATA[31:24];
                        end

                        ADDR_TIMER_COUNT: begin
                            PSLVERR <= 1'b1;
                        end

                        ADDR_TIMER_STATUS: begin
                            if (PWDATA[0]) begin
                                irq_flag <= 1'b0;
                            end
                        end
                        
                        default: begin
                            PSLVERR <= 1'b1;
                        end
                    endcase
            end
        end
    end

    always @(*) begin
        PRDATA = 32'b0;

        if (PSEL && !PWRITE) begin
            case (local_addr)
                
                ADDR_TIMER_CTRL: begin
                    PRDATA = {31'b0, timer_enable};
                end

                ADDR_TIMER_COUNT: begin
                    PRDATA = timer_count;
                end

                ADDR_TIMER_COMPARE: begin
                    PRDATA = timer_compare;
                end

                ADDR_TIMER_STATUS: begin
                    PRDATA = {31'b0, irq_flag};
                end

                default: begin
                    PRDATA = 32'b0;
                end
            endcase
        end
    end
endmodule