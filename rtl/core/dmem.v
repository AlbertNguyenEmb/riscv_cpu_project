`timescale 1ns/1ps

module dmem (
    input  wire        clk,
    input  wire        mem_write,
    input  wire        mem_read,
    input  wire [2:0]  funct3,
    input  wire [31:0] addr,
    input  wire [31:0] write_data,

    output reg [31:0] read_data
);

    reg [7:0] mem [0:255];
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            mem[i] = 8'b0;
        end
    end

    always @(posedge clk) begin
        if (mem_write) begin
            case (funct3)
                3'b000: begin
                    // SB
                    mem[addr] <= write_data[7:0];
                end
                
                3'b001: begin
                    // SH
                    mem[addr]     <= write_data[7:0];
                    mem[addr + 1] <= write_data[15:8];
                end

                3'b010: begin
                    // SW
                    mem[addr]     <= write_data[7:0];
                    mem[addr + 1] <= write_data[15:8];
                    mem[addr + 2] <= write_data[23:16];
                    mem[addr + 3] <= write_data[31:24];
                end

                default: begin
                    mem[addr]     <= write_data[7:0];
                    mem[addr + 1] <= write_data[15:8];
                    mem[addr + 2] <= write_data[23:16];
                    mem[addr + 3] <= write_data[31:24];
                end
            endcase
        end
    end

    always @(*) begin
        if (mem_read) begin
            case (funct3)
                3'b000: begin
                    // LB
                    read_data = {{24{mem[addr][7]}}, mem[addr]};
                end

                3'b001: begin
                    // LH
                    read_data = {{16{mem[addr + 1][7]}}, 
                                mem[addr + 1], 
                                mem[addr]};
                end

                3'b010: begin
                    // LW
                    read_data = {mem[addr + 3],
                                 mem[addr + 2],
                                 mem[addr + 1],
                                 mem[addr]};
                end

                3'b100: begin
                    // LBU
                    read_data = {24'b0, mem[addr]};
                end

                3'b101: begin
                    // LHU
                    read_data = {16'b0,
                                 mem[addr + 1],
                                 mem[addr]};
                end

                default: begin
                    read_data = 32'b0;
                end
            endcase
        end else begin
            read_data = 32'b0;
        end
    end

endmodule