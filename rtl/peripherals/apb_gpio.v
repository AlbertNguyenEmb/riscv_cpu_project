`timescale 1ns/1ps

module apb_gpio(
    input wire        PCLK,
    input wire        PRESETn, //active low

    input wire        PSEL,
    input wire        PENABLE,
    input wire        PWRITE,
    input wire [31:0] PADDR,
    input wire [31:0] PWDATA,
    input wire [3:0]  PSTRB,

    output reg [31:0] PRDATA,
    output wire       PREADY,
    output reg        PSLVERR,

    input  wire [31:0] gpio_in,
    output wire [31:0] gpio_out,
    output wire [31:0] gpio_dir
);
    
    localparam ADDR_GPIO_OUT = 12'h000;
    localparam ADDR_GPIO_IN  = 12'h004;
    localparam ADDR_GPIO_DIR = 12'h008;//dir = 1 => output, dir = 0 => input

    reg [31:0] gpio_out_reg;
    reg [31:0] gpio_dir_reg;

    wire apb_access;
    wire [11:0] local_addr;

    assign apb_access = PSEL && PENABLE;
    assign local_addr = PADDR[11:0];

    assign gpio_out = gpio_out_reg;
    assign gpio_dir = gpio_dir_reg;

    assign PREADY = 1'b1;

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            gpio_out_reg <= 32'b0;
            gpio_dir_reg <= 32'b0;
            PSLVERR      <= 1'b0;
        end else begin
            PSLVERR <= 1'b0;

            if (apb_access && PWRITE) begin
                case (local_addr)
                    
                    ADDR_GPIO_OUT: begin
                        if (PSTRB[0]) gpio_out_reg[7:0]   <= PWDATA[7:0];
                        if (PSTRB[1]) gpio_out_reg[15:8]  <= PWDATA[15:8];
                        if (PSTRB[2]) gpio_out_reg[23:16] <= PWDATA[23:16];
                        if (PSTRB[3]) gpio_out_reg[31:24] <= PWDATA[31:24];
                    end

                    ADDR_GPIO_DIR: begin
                        if (PSTRB[0]) gpio_dir_reg[7:0]   <= PWDATA[7:0];
                        if (PSTRB[1]) gpio_dir_reg[15:8]  <= PWDATA[15:8];
                        if (PSTRB[2]) gpio_dir_reg[23:16] <= PWDATA[23:16];
                        if (PSTRB[3]) gpio_dir_reg[31:24] <= PWDATA[31:24];
                    end

                    ADDR_GPIO_IN: begin
                        PSLVERR <= 1'b1;
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
                
                ADDR_GPIO_OUT: begin
                    PRDATA = gpio_out_reg;
                end

                ADDR_GPIO_IN: begin
                    PRDATA = gpio_in;
                end

                ADDR_GPIO_DIR: begin
                    PRDATA = gpio_dir_reg;
                end

                default: begin
                    PRDATA = 32'b0;
                end
            endcase
        end
    end
endmodule