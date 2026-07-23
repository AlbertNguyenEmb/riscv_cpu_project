`timescale 1ns/1ps

module pipelined_cpu (
    input  wire clk,
    input  wire rst,
    input  wire [31:0] gpio_in,
    output wire [31:0] gpio_out
);
    
    localparam NOP = 32'h00000013;
    localparam OPCODE_RTYPE = 7'b0110011;
    // ============================================================
    // Valid bit for instr_count
    // ============================================================
    reg IF_ID_valid;
    reg ID_EX_valid;
    reg EX_MEM_valid;
    reg MEM_WB_valid;

    // ============================================================
    // Performance registers
    // ============================================================
    reg [31:0] cycle_count;
    reg [31:0] instr_count;
    reg [31:0] stall_count;
    reg [31:0] flush_count;
    reg [31:0] m_stall_count;

    // ============================================================
    // GPIO registers
    // ============================================================
    reg [31:0] gpio_out_reg;

    assign gpio_out = gpio_out_reg;

    // ============================================================
    // PC and IF stage
    // ============================================================
    reg [31:0] pc;
    wire [31:0] instr_from_imem;

    imem_pipeline u_imem (
        .addr(pc),
        .instr(instr_from_imem)
    );

    // ============================================================
    // IF/ID pipeline register
    // ============================================================
    reg [31:0] IF_ID_pc;
    reg [31:0] IF_ID_instr;

    // ============================================================
    // ID stage
    // ============================================================
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
    wire [2:0]  ID_imm_sel;
    wire [1:0]  ID_alu_op;
    wire        ID_branch;
    wire        ID_jump;
    wire        ID_jalr;
    wire [1:0]  ID_alu_a_sel;

    control_unit u_control_unit (
        .opcode(ID_opcode),
        .reg_write(ID_reg_write),
        .mem_read(ID_mem_read),
        .mem_write(ID_mem_write),
        .mem_to_reg(ID_mem_to_reg),
        .alu_src(ID_alu_src),
        .imm_sel(ID_imm_sel),
        .alu_op(ID_alu_op),
        .branch(ID_branch),
        .jump(ID_jump),
        .jalr(ID_jalr),
        .alu_a_sel(ID_alu_a_sel)
    );

    wire [31:0] ID_read_data1;
    wire [31:0] ID_read_data2;
    wire [31:0] ID_imm_out;

    // ============================================================
    // WB wires
    // ============================================================
    wire        WB_reg_write;
    wire [4:0]  WB_rd;
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

    // ============================================================
    // ID/EX pipeline register
    // ============================================================
    reg [31:0] ID_EX_pc;
    reg [31:0] ID_EX_pc_plus4;
    reg [31:0] ID_EX_read_data1;
    reg [31:0] ID_EX_read_data2;
    reg [31:0] ID_EX_imm;
    reg [6:0]  ID_EX_opcode;

    reg [4:0]  ID_EX_rs1;
    reg [4:0]  ID_EX_rs2;
    reg [4:0]  ID_EX_rd;
    reg [2:0]  ID_EX_funct3;
    reg [6:0]  ID_EX_funct7;

    reg        ID_EX_reg_write;
    reg        ID_EX_mem_read;
    reg        ID_EX_mem_write;
    reg        ID_EX_mem_to_reg;
    reg        ID_EX_alu_src;
    reg [1:0]  ID_EX_alu_op;
    reg        ID_EX_branch;
    reg        ID_EX_jump;
    reg        ID_EX_jalr;
    reg [1:0]  ID_EX_alu_a_sel;

    // ============================================================
    // Hazard Detection Unit
    // ============================================================
    wire M_stall;
    wire load_use_stall;
    wire stall;
    wire EX_is_m_instr;
    // set up M-unit
    wire [31:0] M_result;
    wire        M_busy;
    wire        M_done;
    wire        M_start;
    
    assign EX_is_m_instr = (ID_EX_opcode == OPCODE_RTYPE) &&
                           (ID_EX_funct7 ==  7'b0000001);

    assign M_stall = EX_is_m_instr && !M_done;
    assign stall   = load_use_stall || M_stall;

    assign M_start = EX_is_m_instr && !M_busy && !M_done;
    // Detect load used data
    hazard_detection_unit u_hazard_detection_unit (
        .ID_EX_mem_read(ID_EX_mem_read),
        .ID_EX_rd(ID_EX_rd),
        .IF_ID_rs1(ID_rs1),
        .IF_ID_rs2(ID_rs2),
        .IF_ID_opcode(ID_opcode),
        .stall(load_use_stall)
    );

    // ============================================================
    // EX/MEM pipeline register declaration
    // ============================================================
    reg [31:0] EX_MEM_alu_result;
    reg [31:0] EX_MEM_write_data;
    reg [31:0] EX_MEM_pc_plus4;
    reg [4:0]  EX_MEM_rd;

    reg        EX_MEM_reg_write;
    reg        EX_MEM_mem_read;
    reg        EX_MEM_mem_write;
    reg        EX_MEM_mem_to_reg;
    reg        EX_MEM_jump;

    // ============================================================
    // MEM/WB pipeline register declaration
    // ============================================================
    reg [31:0] MEM_WB_read_data;
    reg [31:0] MEM_WB_alu_result;
    reg [31:0] MEM_WB_pc_plus4;
    reg [4:0]  MEM_WB_rd;

    reg        MEM_WB_reg_write;
    reg        MEM_WB_mem_to_reg;
    reg        MEM_WB_jump;

    // ============================================================
    // WB stage
    // ============================================================
    assign WB_reg_write = MEM_WB_reg_write;
    assign WB_rd        = MEM_WB_rd;

    assign WB_write_data =
        (MEM_WB_jump)       ? MEM_WB_pc_plus4 :
        (MEM_WB_mem_to_reg) ? MEM_WB_read_data :
                              MEM_WB_alu_result;

    // ============================================================
    // Forwarding Unit
    // ============================================================
    wire [1:0] forwardA;
    wire [1:0] forwardB;

    forwarding_unit u_forwarding_unit (
        .ID_EX_rs1(ID_EX_rs1),
        .ID_EX_rs2(ID_EX_rs2),

        .EX_MEM_rd(EX_MEM_rd),
        .EX_MEM_reg_write(EX_MEM_reg_write),
        .EX_MEM_mem_to_reg(EX_MEM_mem_to_reg),

        .MEM_WB_rd(MEM_WB_rd),
        .MEM_WB_reg_write(MEM_WB_reg_write),

        .forwardA(forwardA),
        .forwardB(forwardB)
    );

    wire [31:0] EX_MEM_forward_data;

    assign EX_MEM_forward_data =
        (EX_MEM_jump) ? EX_MEM_pc_plus4 : EX_MEM_alu_result;

    wire [31:0] EX_forwarded_a;
    wire [31:0] EX_forwarded_b;

    assign EX_forwarded_a =
        (forwardA == 2'b10) ? EX_MEM_forward_data :
        (forwardA == 2'b01) ? WB_write_data :
                               ID_EX_read_data1;

    assign EX_forwarded_b =
        (forwardB == 2'b10) ? EX_MEM_forward_data :
        (forwardB == 2'b01) ? WB_write_data :
                               ID_EX_read_data2;

    // ============================================================
    // EX stage
    // ============================================================
    // Using ALU
    localparam ALU_A_RS1  = 2'b00;
    localparam ALU_A_PC   = 2'b01;
    localparam ALU_A_ZERO = 2'b10;

    wire [31:0] EX_alu_a;

    assign EX_alu_a = (ID_EX_alu_a_sel == ALU_A_PC)   ? ID_EX_pc :
                      (ID_EX_alu_a_sel    == ALU_A_ZERO) ? 32'b0 :
                                                        EX_forwarded_a;
    wire [31:0] EX_alu_b;
    wire [3:0]  EX_alu_ctrl;
    wire [31:0] EX_alu_result;
    wire        EX_zero;

    assign EX_alu_b = (ID_EX_alu_src) ? ID_EX_imm : EX_forwarded_b;

    alu_control u_alu_control (
        .alu_op(ID_EX_alu_op),
        .funct3(ID_EX_funct3),
        .funct7(ID_EX_funct7),
        .alu_ctrl(EX_alu_ctrl)
    );

    alu u_alu (
        .a(EX_alu_a),
        .b(EX_alu_b),
        .alu_ctrl(EX_alu_ctrl),
        .result(EX_alu_result),
        .zero(EX_zero)
    );

    m_unit u_m_unit (
        .clk(clk),
        .rst(rst),
        .start(M_start),
        .funct3(ID_EX_funct3),
        .rs1_value(EX_forwarded_a),
        .rs2_value(EX_forwarded_b),
        .result(M_result),
        .busy(M_busy),
        .done(M_done)
    );

    wire [31:0] EX_execute_result;

    assign EX_execute_result = (EX_is_m_instr) ? M_result : EX_alu_result;
    // ============================================================
    // Branch decision
    // ============================================================
    reg EX_branch_condition;

    always @(*) begin
        case (ID_EX_funct3)
            3'b000: EX_branch_condition = (EX_forwarded_a == EX_forwarded_b); // beq
            3'b001: EX_branch_condition = (EX_forwarded_a != EX_forwarded_b); // bne
            3'b100: EX_branch_condition = ($signed(EX_forwarded_a) <  $signed(EX_forwarded_b)); // blt
            3'b101: EX_branch_condition = ($signed(EX_forwarded_a) >= $signed(EX_forwarded_b)); // bge
            3'b110: EX_branch_condition = (EX_forwarded_a <  EX_forwarded_b); // bltu
            3'b111: EX_branch_condition = (EX_forwarded_a >= EX_forwarded_b); // bgeu
            default: EX_branch_condition = 1'b0;
        endcase
    end

    wire EX_branch_taken;
    wire [31:0] EX_branch_target;
    wire [31:0] EX_jal_target;
    wire [31:0] EX_jalr_target;
    wire [31:0] EX_pc_target;
    wire        pc_redirect;

    assign EX_branch_taken  = ID_EX_branch && EX_branch_condition;
    assign EX_branch_target = ID_EX_pc + ID_EX_imm;
    assign EX_jal_target    = ID_EX_pc + ID_EX_imm;
    assign EX_jalr_target   = (EX_forwarded_a + ID_EX_imm) & 32'hffff_fffe;

    assign EX_pc_target =
        (ID_EX_jalr) ? EX_jalr_target :
        (ID_EX_jump) ? EX_jal_target  :
                       EX_branch_target;

    assign pc_redirect = EX_branch_taken || ID_EX_jump;

    // ============================================================
    // MEM stage
    // ============================================================

    // Decode MMIO address
    wire MEM_is_gpio; // MEM is GPIO
    wire MEM_is_perf; // MEM is Performance Counter
    wire MEM_is_dsp;
    wire MEM_is_mmio;
    wire MEM_is_ai;
    wire MEM_is_crypto;

    assign MEM_is_gpio   = (EX_MEM_alu_result[31:16] == 16'h1000);
    assign MEM_is_perf   = (EX_MEM_alu_result[31:16] == 16'h2000);
    assign MEM_is_dsp    = (EX_MEM_alu_result[31:16] == 16'h3000);
    assign MEM_is_ai     = (EX_MEM_alu_result[31:16] == 16'h4000);
    assign MEM_is_crypto = (EX_MEM_alu_result[31:16] == 16'h5000);

    assign MEM_is_mmio = MEM_is_gpio || MEM_is_perf || MEM_is_dsp || MEM_is_ai || MEM_is_crypto;

    wire [31:0] MEM_read_data;
    reg  [31:0] MEM_mmio_read_data;
    reg  [2:0]  EX_MEM_funct3;

    wire dmem_mem_read;
    wire dmem_mem_write;
    wire [31:0] MEM_dmem_read_data;

    assign dmem_mem_read  = EX_MEM_mem_read && !MEM_is_mmio;
    assign dmem_mem_write = EX_MEM_mem_write && !MEM_is_mmio;

    dmem u_dmem (
        .clk(clk),
        .mem_write(dmem_mem_write),
        .mem_read(dmem_mem_read),
        .funct3(EX_MEM_funct3),
        .addr(EX_MEM_alu_result),
        .write_data(EX_MEM_write_data),
        .read_data(MEM_dmem_read_data)
    );

    // ============================================================
    // Instantiate DSP Accelerator
    // ============================================================
    wire [31:0] DSP_read_data;
    wire        DSP_write_en;

    assign DSP_write_en = EX_MEM_mem_write && MEM_is_dsp;

    dsp_accel u_dsp_accel (
        .clk(clk),
        .rst(rst),
        .write_en(DSP_write_en),
        .addr(EX_MEM_alu_result[7:0]),
        .write_data(EX_MEM_write_data),
        .read_data(DSP_read_data)
    );
    // ============================================================
    // Instantiate AI accelerator
    // ============================================================
    wire [31:0] AI_read_data;
    wire        AI_write_en;

    assign AI_write_en = EX_MEM_mem_write && MEM_is_ai;

    ai_accel u_ai_accel (
        .clk(clk),
        .rst(rst),
        .write_en(AI_write_en),
        .addr(EX_MEM_alu_result[7:0]),
        .write_data(EX_MEM_write_data),
        .read_data(AI_read_data)
    );
    // ============================================================
    // Instantiate AES accelerator
    // ============================================================
    wire [31:0] CRYPTO_read_data;
    wire        CRYPTO_write_en;

    assign CRYPTO_write_en = EX_MEM_mem_write && MEM_is_crypto;

    crypto_accel u_crypto_accel (
        .clk(clk),
        .rst(rst),
        .write_en(CRYPTO_write_en),
        .addr(EX_MEM_alu_result[7:0]),
        .write_data(EX_MEM_write_data),
        .read_data(CRYPTO_read_data)
    );
    // ============================================================
    // MMIO Read Data Mux
    // ============================================================

    always @(*) begin
        if (MEM_is_dsp) begin
            MEM_mmio_read_data = DSP_read_data;
        end else if (MEM_is_ai) begin
            MEM_mmio_read_data = AI_read_data;
        end else if (MEM_is_crypto) begin
            MEM_mmio_read_data = CRYPTO_read_data;
        end else begin
            case (EX_MEM_alu_result)
                // GPIO
                32'h1000_0000:
                    MEM_mmio_read_data = gpio_out_reg;

                32'h1000_0004:
                    MEM_mmio_read_data = gpio_in;

                // Performance Counters
                32'h2000_0000:
                    MEM_mmio_read_data = cycle_count;

                32'h2000_0004:
                    MEM_mmio_read_data = instr_count;

                32'h2000_0008:
                    MEM_mmio_read_data = stall_count;

                32'h2000_000C:
                    MEM_mmio_read_data = flush_count;

                32'h2000_0010:
                    MEM_mmio_read_data = m_stall_count;

                default:
                    MEM_mmio_read_data = 32'b0;
            endcase
        end
    end

    assign MEM_read_data =
        MEM_is_mmio ? MEM_mmio_read_data :
                    MEM_dmem_read_data;

    // ============================================================
    // Pipeline sequential logic
    // ============================================================
    always @(posedge clk or posedge rst) begin
        if (rst) begin

            cycle_count   <= 32'b0;
            instr_count   <= 32'b0;
            stall_count   <= 32'b0;
            flush_count   <= 32'b0;
            m_stall_count <= 32'b0;

            gpio_out_reg <= 32'b0;

            pc <= 32'b0;

            IF_ID_pc    <= 32'b0;
            IF_ID_instr <= NOP;
            IF_ID_valid <= 1'b0;

            ID_EX_pc         <= 32'b0;
            ID_EX_pc_plus4   <= 32'b0;
            ID_EX_read_data1 <= 32'b0;
            ID_EX_read_data2 <= 32'b0;
            ID_EX_imm        <= 32'b0;
            ID_EX_rs1        <= 5'b0;
            ID_EX_rs2        <= 5'b0;
            ID_EX_rd         <= 5'b0;
            ID_EX_funct3     <= 3'b0;
            ID_EX_funct7     <= 7'b0;
            ID_EX_opcode     <= 7'b0;
            ID_EX_valid      <= 1'b0;

            ID_EX_reg_write  <= 1'b0;
            ID_EX_mem_read   <= 1'b0;
            ID_EX_mem_write  <= 1'b0;
            ID_EX_mem_to_reg <= 1'b0;
            ID_EX_alu_src    <= 1'b0;
            ID_EX_alu_op     <= 2'b0;
            ID_EX_branch     <= 1'b0;
            ID_EX_jump       <= 1'b0;
            ID_EX_jalr       <= 1'b0;
            ID_EX_alu_a_sel  <= 2'b00;

            EX_MEM_alu_result <= 32'b0;
            EX_MEM_write_data <= 32'b0;
            EX_MEM_pc_plus4   <= 32'b0;
            EX_MEM_rd         <= 5'b0;
            EX_MEM_funct3     <= 3'b0; 
            EX_MEM_valid      <= 1'b0;
            MEM_WB_valid      <= 1'b0;

            EX_MEM_reg_write  <= 1'b0;
            EX_MEM_mem_read   <= 1'b0;
            EX_MEM_mem_write  <= 1'b0;
            EX_MEM_mem_to_reg <= 1'b0;
            EX_MEM_jump       <= 1'b0;

            MEM_WB_read_data  <= 32'b0;
            MEM_WB_alu_result <= 32'b0;
            MEM_WB_pc_plus4   <= 32'b0;
            MEM_WB_rd         <= 5'b0;

            MEM_WB_reg_write  <= 1'b0;
            MEM_WB_mem_to_reg <= 1'b0;
            MEM_WB_jump       <= 1'b0;

        end else begin
            // ====================================================
            // Performance counters
            // ====================================================
            cycle_count <= cycle_count + 32'd1;
            
            if (MEM_WB_valid) begin
                instr_count <= instr_count + 32'd1;
            end

            if (load_use_stall || M_stall) begin
                stall_count <= stall_count + 32'd1;
            end

            if (M_stall) begin
                m_stall_count <= m_stall_count + 32'd1;
            end

            if (pc_redirect) begin
                flush_count <= flush_count + 32'd1;
            end
            // ============================================================
            // GPIO Write
            // ============================================================
            if (EX_MEM_mem_write && MEM_is_gpio) begin
                case (EX_MEM_alu_result)

                    32'h1000_0000:
                        gpio_out_reg <= EX_MEM_write_data;

                    default:
                        gpio_out_reg <= gpio_out_reg;

                endcase
            end
            // ====================================================
            // IF stage
            // Priority:
            // 1. pc_redirect / flush
            // 2. stall
            // 3. normal fetch
            // ====================================================
            if (pc_redirect) begin
                pc          <= EX_pc_target;
                IF_ID_pc    <= 32'b0;
                IF_ID_instr <= NOP;
                IF_ID_valid <= 1'b0;
            end else if (load_use_stall || M_stall) begin
                pc          <= pc;
                IF_ID_pc    <= IF_ID_pc;
                IF_ID_instr <= IF_ID_instr;
                IF_ID_valid <= IF_ID_valid;
            end else begin
                IF_ID_pc    <= pc;
                IF_ID_instr <= instr_from_imem;
                pc          <= pc + 32'd4;
                IF_ID_valid <= (instr_from_imem != NOP);
            end

            // ====================================================
            // ID stage → ID/EX
            // If redirect: flush wrong instruction.
            // If stall: insert bubble.
            // ====================================================
            if (pc_redirect || load_use_stall) begin
                ID_EX_pc         <= 32'b0;
                ID_EX_pc_plus4   <= 32'b0;
                ID_EX_read_data1 <= 32'b0;
                ID_EX_read_data2 <= 32'b0;
                ID_EX_imm        <= 32'b0;
                ID_EX_rs1        <= 5'b0;
                ID_EX_rs2        <= 5'b0;
                ID_EX_rd         <= 5'b0;
                ID_EX_funct3     <= 3'b0;
                ID_EX_funct7     <= 7'b0;
                ID_EX_opcode     <= 7'b0;
                ID_EX_valid      <= 1'b0;

                ID_EX_reg_write  <= 1'b0;
                ID_EX_mem_read   <= 1'b0;
                ID_EX_mem_write  <= 1'b0;
                ID_EX_mem_to_reg <= 1'b0;
                ID_EX_alu_src    <= 1'b0;
                ID_EX_alu_op     <= 2'b0;
                ID_EX_branch     <= 1'b0;
                ID_EX_jump       <= 1'b0;
                ID_EX_jalr       <= 1'b0;
                ID_EX_alu_a_sel  <= 2'b00;
            end else if (M_stall) begin
                // giữ nguyên instruction M trong EX stage
                ID_EX_pc         <= ID_EX_pc;
                ID_EX_pc_plus4   <= ID_EX_pc_plus4;
                ID_EX_read_data1 <= ID_EX_read_data1;
                ID_EX_read_data2 <= ID_EX_read_data2;
                ID_EX_imm        <= ID_EX_imm;
                ID_EX_rs1        <= ID_EX_rs1;
                ID_EX_rs2        <= ID_EX_rs2;
                ID_EX_rd         <= ID_EX_rd;
                ID_EX_funct3     <= ID_EX_funct3;
                ID_EX_funct7     <= ID_EX_funct7;
                ID_EX_opcode     <= ID_EX_opcode;
                ID_EX_valid      <= ID_EX_valid;

                ID_EX_reg_write  <= ID_EX_reg_write;
                ID_EX_mem_read   <= ID_EX_mem_read;
                ID_EX_mem_write  <= ID_EX_mem_write;
                ID_EX_mem_to_reg <= ID_EX_mem_to_reg;
                ID_EX_alu_src    <= ID_EX_alu_src;
                ID_EX_alu_op     <= ID_EX_alu_op;
                ID_EX_branch     <= ID_EX_branch;
                ID_EX_jump       <= ID_EX_jump;
                ID_EX_jalr       <= ID_EX_jalr;
                ID_EX_alu_a_sel  <= ID_EX_alu_a_sel;
            end
            else begin
                ID_EX_pc         <= IF_ID_pc;
                ID_EX_pc_plus4   <= IF_ID_pc + 32'd4;
                ID_EX_read_data1 <= ID_read_data1;
                ID_EX_read_data2 <= ID_read_data2;
                ID_EX_imm        <= ID_imm_out;
                ID_EX_opcode     <= ID_opcode;
                ID_EX_valid      <= IF_ID_valid;

                ID_EX_rs1    <= ID_rs1;
                ID_EX_rs2    <= ID_rs2;
                ID_EX_rd     <= ID_rd;
                ID_EX_funct3 <= ID_funct3;
                ID_EX_funct7 <= ID_funct7;

                ID_EX_reg_write  <= ID_reg_write;
                ID_EX_mem_read   <= ID_mem_read;
                ID_EX_mem_write  <= ID_mem_write;
                ID_EX_mem_to_reg <= ID_mem_to_reg;
                ID_EX_alu_src    <= ID_alu_src;
                ID_EX_alu_op     <= ID_alu_op;
                ID_EX_branch     <= ID_branch;
                ID_EX_jump       <= ID_jump;
                ID_EX_jalr       <= ID_jalr;
                ID_EX_alu_a_sel  <= ID_alu_a_sel;
            end

            // ====================================================
            // EX stage → EX/MEM
            // ====================================================
            if (M_stall) begin
                EX_MEM_alu_result <= EX_MEM_alu_result;
                EX_MEM_write_data <= EX_MEM_write_data;
                EX_MEM_pc_plus4   <= EX_MEM_pc_plus4;
                EX_MEM_rd         <= EX_MEM_rd;
                EX_MEM_funct3     <= EX_MEM_funct3;
                EX_MEM_valid      <= 1'b0;

                EX_MEM_reg_write  <= EX_MEM_reg_write;
                EX_MEM_mem_read   <= EX_MEM_mem_read;
                EX_MEM_mem_write  <= EX_MEM_mem_write;
                EX_MEM_mem_to_reg <= EX_MEM_mem_to_reg;
                EX_MEM_jump       <= EX_MEM_jump;
            end else begin
                EX_MEM_alu_result <= EX_execute_result;
                EX_MEM_write_data <= EX_forwarded_b;
                EX_MEM_pc_plus4   <= ID_EX_pc_plus4;
                EX_MEM_rd         <= ID_EX_rd;
                EX_MEM_funct3     <= ID_EX_funct3;
                EX_MEM_valid      <= ID_EX_valid;

                EX_MEM_reg_write  <= ID_EX_reg_write;
                EX_MEM_mem_read   <= ID_EX_mem_read;
                EX_MEM_mem_write  <= ID_EX_mem_write;
                EX_MEM_mem_to_reg <= ID_EX_mem_to_reg;
                EX_MEM_jump       <= ID_EX_jump;
            end

            // ====================================================
            // MEM stage → MEM/WB
            // ====================================================
                MEM_WB_read_data  <= MEM_read_data;
                MEM_WB_alu_result <= EX_MEM_alu_result;
                MEM_WB_pc_plus4   <= EX_MEM_pc_plus4;
                MEM_WB_rd         <= EX_MEM_rd;
                MEM_WB_valid      <= EX_MEM_valid;

                MEM_WB_reg_write  <= EX_MEM_reg_write;
                MEM_WB_mem_to_reg <= EX_MEM_mem_to_reg;
                MEM_WB_jump       <= EX_MEM_jump;
            end
    end

endmodule