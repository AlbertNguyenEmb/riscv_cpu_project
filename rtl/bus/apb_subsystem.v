`timescale 1ns/1ps

module apb_subsystem(
    input wire clk,
    input wire rst,

    // Simple bus side from CPU
    input  wire        req,
    input  wire        we,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    input  wire [3:0]  be,

    output wire [31:0] rdata,
    output wire        ready,
    output wire        err,

    input  wire [31:0] gpio_in,
    output wire [31:0] gpio_out,
    output wire [31:0] gpio_dir,

    output wire        timer_irq,
    output wire        uart_tx
);
    
    wire [31:0] PADDR;
    wire        PSEL;
    wire        PENABLE;
    wire        PWRITE;
    wire [31:0] PWDATA;
    wire [3:0]  PSTRB;

    wire [31:0] PRDATA;
    wire        PREADY;
    wire        PSLVERR;

    simple_to_apb_bridge u_simple_to_apb_bridge (
        .clk(clk),
        .rst(rst),

        .req(req),
        .we(we),
        .addr(addr),
        .wdata(wdata),
        .be(be),

        .rdata(rdata),
        .ready(ready),
        .err(err),

        .PADDR(PADDR),
        .PSEL(PSEL),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PWDATA(PWDATA),
        .PSTRB(PSTRB),

        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .PSLVERR(PSLVERR)
    );

    apb_decoder u_apb_decoder (
        .PCLK(clk),
        .PRESETn(~rst),

        .PADDR(PADDR),
        .PSEL(PSEL),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PWDATA(PWDATA),
        .PSTRB(PSTRB),

        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .PSLVERR(PSLVERR),

        .gpio_in(gpio_in),
        .gpio_out(gpio_out),
        .gpio_dir(gpio_dir),

        .timer_irq(timer_irq),
        .uart_tx(uart_tx)
    );
endmodule