`timescale 1ns/1ps

module multi_cycle_cpu (
    input wire clk,
    input wire rst
);

    // State encoding
    localparam FETCH = 4'd0;
    localparam DECODE = 4'd1;
    localparam EXEC_R = 4'd2;
    localparam EXEC_I = 4'd3;
    localparam MEM_ADDR = 4'd4;
    localparam MEM_READ = 4'd5;
    localparam MEM_WRITE = 4'd6;
    localparam WB_R = 4'd7;
    localparam WB_I = 4'd8;
    localparam WB_MEM = 4'd9;
    
    // Opcodes
    localparam OPCODE_RTYPE = 7'b0110011;
    localparam OPCODE_ITYPE = 7'b0010011;
    localparam OPCODE_LOAD = 7'b0000011;
    localparam OPCODE_STORE = 7'b0100011;

    // Imm select
    localparam IMM_I = 2'b00;
    localparam IMM_S = 2'b01;

    // Internal registers
    reg [3:0] state;
    reg [31:0] pc;
    reg [31:0] ir;
    reg [31:0] A;
    reg [31:0] B;
    reg [31:0] alu_out;
    reg [31:0] mdr;

    // Instruction fields
    wire [6:0] opcode;
    wire [4:0] rd;
    wire [2:0] funct3;
    wire [4:0] rs1;
    wire [4:0] rs2;
    wire [6:0] funct7;

    assign opcode = ir[6:0];
    assign rd     = ir[11:7];
    assign funct3 = ir[14:12];
    assign rs1    = ir[19:15];
    assign rs2    = ir[24:20];
    assign funct7 = ir[31:25];

    // IMEM
    wire [31:0] instr_from_imem;

    imem u_imem(
        .addr(pc),
        .instr(instr_from_imem)
    );

    // Register File
    wire reg_write;
    wire [31:0] write_back_data;
    wire [31:0] read_data1;
    wire [31:9] read_data2;

    assign reg_write = (state == WB_R) || (state == WB_I) || (state == WB_MEM);

    assign write_back_data = (state == WB_MEM) ? mdr : alu_out;

    regfile u_regfile(
        .clk(clk),
        .reg_write(reg_write),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .write_data(write_back_data),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );

    // Immediate Generator
    reg [1:0] imm_sel;
    wire [31:0] imm_out;

    always @(*) begin
        case (opcode)
            OPCODE_STORE: imm_sel = IMM_S;
            default:      imm_sel = IMM_I;
        endcase
    end

    imm_gen u_imm_gen(
        .instr(ir),
        .imm_sel(imm_sel),
        .imm_out(imm_out)
    );

    // ALU Control
    reg [1:0] alu_op;
    wire [3:0] alu_ctrl;

    always @(*) begin
        case (state)
            EXEC_R: alu_op = 2'b10;
            EXEC_I: alu_op = 2'b11;
            MEM_ADDR: alu_op = 2'b00;
            default: alu_op = 2'b00;
        endcase
    end

    alu_control u_alu_control (
        .alu_op(alu_op),
        .funct3(funct3),
        .funct7(funct7),
        .alu_ctrl(alu_ctrl)
    );

    // ALU
    wire [31:0] alu_a;
    wire [31:0] alu_b;
    wire [31:0] alu_result;
    wire zero;

    assign alu_a = A;
    assign alu_b = ((state == EXEC_I) || (state == MEM_ADDR)) ? imm_out : B;

    alu u_alu(
        .a(alu_a),
        .b(alu_b),
        .alu_ctrl(alu_ctrl),
        .result(alu_result),
        .zero(zero)
    );

    // Data Memmory
    wire mem_read;
    wire mem_write;
    wire [31:0] dmem_read_data;

    assign mem_read = (state == MEM_READ);
    assign mem_write = (state == MEM_WRITE);

    dmem u_dmem (
        .clk(clk),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .addr(alu_out),
        .write_data(B),
        .read_data(dmem_read_data)
    );

    //FSM sequential logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= FETCH;
            pc <= 32'b0;
            ir <= 32'b0;
            A <= 32'b0;
            B <= 32'b0;
            alu_out <= 32'b0;
            mdr <= 32'b0;
        end else begin
            case (state)
                FETCH: begin
                    ir <= instr_from_imem;
                    pc <= pc + 32'd4;
                    state <= DECODE;
                end

                DECODE: begin
                    A <= read_data1;
                    B <= read_data2;

                    case (opcode)
                        OPCODE_RTYPE: state <= EXEC_R;
                        OPCODE_ITYPE: state <= EXEC_I;
                        OPCODE_LOAD:  state <= MEM_ADDR;
                        OPCODE_STORE: state <= MEM_ADDR;
                        default:      state <= FETCH;
                    endcase
                end

                EXEC_R: begin
                    alu_out <= alu_result;
                    state <= WB_R;
                end

                EXEC_I: begin
                    alu_out <= alu_result;
                    state <= WB_I;
                end

                MEM_ADDR: begin
                    alu_out <= alu_result;

                    if (opcode == OPCODE_LOAD) begin
                        state <= MEM_READ;
                    end else if (opcode == OPCODE_STORE) begin
                        state <= MEM_WRITE;
                    end else begin
                        state <= FETCH;
                    end
                end

                MEM_READ: begin
                    mdr <= dmem_read_data;
                    state <= WB_MEM;
                end

                MEM_WRITE: begin
                    state <= FETCH;
                end

                WB_R: begin
                    state <= FETCH;
                end

                WB_I: begin
                    state <= FETCH;
                end

                WB_MEM: begin
                    state <= FETCH;
                end

                default: begin
                    state <= FETCH;
                end
            endcase
        end
    end


endmodule