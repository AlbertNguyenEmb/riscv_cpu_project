`timescale 1ns/1ps

module apb_decoder(
    input wire PCLK,
    input wire PRESETn,

    //The signal of Master side APB
    input wire [31:0] PADDR,
    input wire        PSEL,
    input wire        PENABLE,
    input wire        PWRITE,
    input wire [31:0] PWDATA,
    input wire [3:0]  PSTRB,

    output reg [31:0] PRDATA,
    output wire       PREADY,
    output reg       PSLVERR,

    input  wire [31:0] gpio_in,
    output wire [31:0] gpio_out,
    output wire [31:0] gpio_dir,
    output wire        timer_irq,
    output wire        uart_tx
);

    wire sel_gpio;
    wire sel_timer;
    wire sel_uart;

    assign sel_gpio  = PSEL && (PADDR[31:12] == 20'h10000);
    assign sel_timer = PSEL && (PADDR[31:12] == 20'h10001);
    assign sel_uart  = PSEL && (PADDR[31:12] == 20'h10002);
    
    wire [31:0] gpio_prdata;
    wire        gpio_pready;
    wire        gpio_pslverr;

    wire [31:0] timer_prdata;
    wire        timer_pready;
    wire        timer_pslverr;

    wire [31:0] uart_prdata;
    wire        uart_pready;
    wire        uart_pslverr;

    apb_gpio u_apb_gpio (
        .PCLK(PCLK),
        .PRESETn(PRESETn),

        .PSEL(sel_gpio),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .PSTRB(PSTRB),

        .PRDATA(gpio_prdata),
        .PREADY(gpio_pready),
        .PSLVERR(gpio_pslverr),

        .gpio_in(gpio_in),
        .gpio_out(gpio_out),
        .gpio_dir(gpio_dir)
    );

    apb_timer u_apb_timer (
        .PCLK(PCLK),
        .PRESETn(PRESETn),

        .PSEL(sel_timer),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .PSTRB(PSTRB),

        .PRDATA(timer_prdata),
        .PREADY(timer_pready),
        .PSLVERR(timer_pslverr),

        .timer_irq(timer_irq)
    );

    apb_uart_tx u_apb_uart_tx (
        .PCLK(PCLK),
        .PRESETn(PRESETn),

        .PSEL(sel_uart),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .PSTRB(PSTRB),

        .PRDATA(uart_prdata),
        .PREADY(uart_pready),
        .PSLVERR(uart_pslverr),

        .uart_tx(uart_tx)
    );

    assign PREADY =
        sel_gpio  ? gpio_pready  :
        sel_timer ? timer_pready :
        sel_uart  ? uart_pready  :
                    1'b1;

    always @(*) begin
        PRDATA  = 32'b0;
        PSLVERR = 1'b0;

        if (sel_gpio) begin
            PRDATA  = gpio_prdata;
            PSLVERR = gpio_pslverr;
        end else if (sel_timer) begin
            PRDATA  = timer_prdata;
            PSLVERR = timer_pslverr;
        end else if (sel_uart) begin
            PRDATA  = uart_prdata;
            PSLVERR = uart_pslverr;
        end else if (PSEL) begin
            PRDATA  = 32'b0;
            PSLVERR = 1'b1;
        end
    end
endmodule