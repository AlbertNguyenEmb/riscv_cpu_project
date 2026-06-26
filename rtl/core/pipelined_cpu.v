`timescale 1ns/1ps

module pipelined_cpu (
    input wire clk,
    input wire rst
);

    localparam NOP = 32'h00000013;
    // PC and IF stage
    reg [31:0] pc;
    wire [31:0] instr_from_imem;

    imm_pipeline u_imem(
        .addr(pc),
        .instr(instr_from_imem)
    );

    // IF/ID pipeline register
    reg [31:0] IF_ID_pc;
    reg [31:0] IF_ID_instr;

    // ID stage wires
    wire [6:0] ID_opcode;
    wire [4:0] ID_rd;
    wire [2:0] ID_funct3;
    wire [4:0] ID_rs1;
    wire [4:0] ID_rs2;
    wire [6:0] ID_funct7;

    assign ID_opcode = IF_ID_instr[6:0];
    assign ID_rd     = IF_ID_instr[11:7];
    assign ID_funct3 = IF_ID_instr[14:12];
    assign ID_rs1    = IF_ID_instr[19:15];
    assign ID_rs2    = IF_ID_instr[24:20];
    assign ID_funct7 = IF_ID_instr[31:25];

    wire        ID_reg_write;
    wire        ID_mem_read;
    wire        ID_mem_write;
    wire        ID_mem_to_reg;
    wire        ID_alu_src;
    wire [1:0]  ID_imm_sel;
    wire [1:0]  ID_alu_op;

    control_unit u_control_unit (
        .opcode(ID_opcode),
        .reg_write(ID_reg_write),
        .mem_read(ID_mem_read),
        .mem_write(ID_mem_write),
        .mem_to_reg(ID_mem_to_reg),
        .alu_src(ID_alu_src),
        .imm_sel(ID_imm_sel),
        .alu_op(ID_alu_op)
    );

    wire [31:0] ID_read_data1;
    wire [31:0] ID_read_data2;
    wire [31:0] ID_imm_out;

    // WB stage wires are connected back to register file
    wire WB_reg_write;
    wire [4:0] WB_rd;
    wire [31:0] WB_write_data;

    regfile u_regfile (
        .clk(clk),
        .reg_write(WB_reg_write),
        .rs1(ID_rs1),
        .rs2(ID_rs2),
        .rd(WB_rd),
        .write_data(WB_write_data),
        .read_data1(ID_read_data1),
        .read_data2(ID_read_data2)
    );

    imm_gen u_imm_gen (
        .instr(IF_ID_instr),
        .imm_sel(ID_imm_sel),
        .imm_out(ID_imm_out)
    );

    // ID/EX pipeline register
    reg [31:0] ID_EX_pc;
    reg [31:0] ID_EX_read_data1;
    reg [31:0] ID_EX_read_data2;
    reg [31:0] ID_EX_imm;

    reg [4:0] ID_EX_rd;
    reg [2:0] ID_EX_funct3;
    reg [6:0] ID_EX_funct7;

    reg ID_EX_reg_write;
    reg ID_EX_mem_read;
    reg ID_EX_mem_write;
    reg ID_EX_mem_to_reg;
    reg ID_EX_alu_src;
    reg [1:0] ID_EX_alu_op;

    //EX stage
    wire [31:0] EX_alu_b;
    wire [3:0] EX_alu_ctrl;
    wire [31:0] EX_alu_result;
    wire EX_zero;

    assign EX_alu_b = (ID_EX_alu_src) ? ID_EX_imm : ID_EX_read_data2;

    alu_control u_alu_control (
        .alu_op(ID_EX_alu_op),
        .funct3(ID_EX_funct3),
        .funct7(ID_EX_funct7),
        .alu_ctrl(EX_alu_ctrl)
    );

    alu u_alu (
        .a(ID_EX_read_data1),
        .b(EX_alu_b),
        .alu_ctrl(EX_alu_ctrl),
        .result(EX_alu_result),
        .zero(EX_zero)
    );

    // EX/MEM pipeline register
    reg [31:0] EX_MEM_alu_result;
    reg [31:0] EX_MEM_write_data;
    reg [4:0] EX_MEM_rd;

    reg EX_MEM_reg_write;
    reg EX_MEM_mem_read;
    reg EX_MEM_mem_write;
    reg EX_MEM_mem_to_reg;

    // MEM stage
    wire [31:0] MEM_read_data;

    dmem u_dmem (
        .clk(clk),
        .mem_write(EX_MEM_mem_write),
        .mem_read(EX_MEM_mem_read),
        .addr(EX_MEM_alu_result),
        .write_data(EX_MEM_write_data),
        .read_data(MEM_read_data)
    );

    // MEM/WB pipeline register
    reg [31:0] MEM_WB_read_data;
    reg [31:0] MEM_WB_alu_result;
    reg [4:0] MEM_WB_rd;

    reg MEM_WB_reg_write;
    reg MEM_WB_mem_to_reg;

    // WB stage
    assign WB_reg_write = MEM_WB_reg_write;
    assign WB_rd = MEM_WB_rd;

    assign WB_write_data = (MEM_WB_mem_to_reg) ? MEM_WB_read_data 
                                               : MEM_WB_alu_result;
    
    // Pipeline sequential logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc <= 32'd0;

            IF_ID_pc    <= 32'b0;
            IF_ID_instr <= NOP;

            ID_EX_pc          <= 32'b0;
            ID_EX_read_data1  <= 32'b0;
            ID_EX_read_data2  <= 32'b0;
            ID_EX_imm         <= 32'b0;
            ID_EX_rd          <= 5'b0;
            ID_EX_funct3      <= 3'b0;
            ID_EX_funct7      <= 7'b0;
            ID_EX_reg_write   <= 1'b0;
            ID_EX_mem_read    <= 1'b0;
            ID_EX_mem_write   <= 1'b0;
            ID_EX_mem_to_reg  <= 1'b0;
            ID_EX_alu_src     <= 1'b0;
            ID_EX_alu_op      <= 2'b0;

            EX_MEM_alu_result <= 32'b0;
            EX_MEM_write_data <= 32'b0;
            EX_MEM_rd         <= 5'b0;
            EX_MEM_reg_write  <= 1'b0;
            EX_MEM_mem_read   <= 1'b0;
            EX_MEM_mem_write  <= 1'b0;
            EX_MEM_mem_to_reg <= 1'b0;

            MEM_WB_read_data  <= 32'b0;
            MEM_WB_alu_result <= 32'b0;
            MEM_WB_rd         <= 5'b0;
            MEM_WB_reg_write  <= 1'b0;
            MEM_WB_mem_to_reg <= 1'b0;

        end else begin
            // IF stage
            IF_ID_pc <= pc;
            IF_ID_instr <= instr_from_imem;
            pc <= pc + 32'd4;

            // ID stage to ID/EX
            ID_EX_pc <= IF_ID_pc;
            ID_EX_read_data1 <= ID_read_data1;
            ID_EX_read_data2 <= ID_read_data2;
            ID_EX_imm <= ID_imm_out;

            ID_EX_rd <= ID_rd;
            ID_EX_funct3 <= ID_funct3;
            ID_EX_funct7 <= ID_funct7;

            ID_EX_reg_write <= ID_reg_write;
            ID_EX_mem_read   <= ID_mem_read;
            ID_EX_mem_write  <= ID_mem_write;
            ID_EX_mem_to_reg <= ID_mem_to_reg;
            ID_EX_alu_src    <= ID_alu_src;
            ID_EX_alu_op     <= ID_alu_op;

            // EX stage to EX/MEM
            EX_MEM_alu_result <= EX_alu_result;
            EX_MEM_write_data <= ID_EX_read_data2;
            EX_MEM_rd         <= ID_EX_rd;

            EX_MEM_reg_write  <= ID_EX_reg_write;
            EX_MEM_mem_read   <= ID_EX_mem_read;
            EX_MEM_mem_write  <= ID_EX_mem_write;
            EX_MEM_mem_to_reg <= ID_EX_mem_to_reg;

            // MEM stage to MEM/WB
            MEM_WB_read_data  <= MEM_read_data;
            MEM_WB_alu_result <= EX_MEM_alu_result;
            MEM_WB_rd         <= EX_MEM_rd;

            MEM_WB_reg_write  <= EX_MEM_reg_write;
            MEM_WB_mem_to_reg <= EX_MEM_mem_to_reg;
        end
    end
endmodule