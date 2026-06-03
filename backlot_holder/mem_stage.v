// ============================================
// MEM Stage — Memory Access
// Handles LW (load) and SW (store)
// + MEM/WB Pipeline Register
// ============================================
module mem_stage (
    input         clk,
    input         reset,

    // From EX/MEM register
    input  [31:0] ex_mem_pc_branch,
    input         ex_mem_branch,
    input         ex_mem_zero,
    input  [31:0] ex_mem_alu_result,
    input  [31:0] ex_mem_write_data,
    input  [4:0]  ex_mem_rd,
    input         ex_mem_mem_read,
    input         ex_mem_mem_write,
    input         ex_mem_reg_write,
    input         ex_mem_mem_to_reg,

    // From data memory
    input  [31:0] mem_read_data,

    // To data memory
    output        mem_we,
    output [31:0] mem_addr,
    output [31:0] mem_write_data,

    // Branch control → goes back to PC
    output        branch_taken,
    output [31:0] branch_target,

    // MEM/WB pipeline register outputs
    output reg [31:0] mem_wb_read_data,
    output reg [31:0] mem_wb_alu_result,
    output reg [4:0]  mem_wb_rd,
    output reg        mem_wb_reg_write,
    output reg        mem_wb_mem_to_reg
);

    // ── Memory Control ──────────────────────────────
    assign mem_we         = ex_mem_mem_write;
    assign mem_addr       = ex_mem_alu_result;  // Address from ALU
    assign mem_write_data = ex_mem_write_data;  // rs2 value for SW

    // ── Branch Decision ─────────────────────────────
    // BEQ: branch taken when zero=1 (rs1 - rs2 == 0)
    assign branch_taken  = ex_mem_branch & ex_mem_zero;
    assign branch_target = ex_mem_pc_branch;

    // ── MEM/WB Pipeline Register ────────────────────
    always @(posedge clk) begin
        if (reset) begin
            mem_wb_read_data   <= 32'd0;
            mem_wb_alu_result  <= 32'd0;
            mem_wb_rd          <= 5'd0;
            mem_wb_reg_write   <= 0;
            mem_wb_mem_to_reg  <= 0;
        end
        else begin
            mem_wb_read_data   <= mem_read_data;
            mem_wb_alu_result  <= ex_mem_alu_result;
            mem_wb_rd          <= ex_mem_rd;
            mem_wb_reg_write   <= ex_mem_reg_write;
            mem_wb_mem_to_reg  <= ex_mem_mem_to_reg;
        end
    end

endmodul// ============================================
// MEM Stage — Memory Access
// Handles LW (load) and SW (store)
// + MEM/WB Pipeline Register
// ============================================
module mem_stage (
    input         clk,
    input         reset,

    // From EX/MEM register
    input  [31:0] ex_mem_pc_branch,
    input         ex_mem_branch,
    input         ex_mem_zero,
    input  [31:0] ex_mem_alu_result,
    input  [31:0] ex_mem_write_data,
    input  [4:0]  ex_mem_rd,
    input         ex_mem_mem_read,
    input         ex_mem_mem_write,
    input         ex_mem_reg_write,
    input         ex_mem_mem_to_reg,

    // From data memory
    input  [31:0] mem_read_data,

    // To data memory
    output        mem_we,
    output [31:0] mem_addr,
    output [31:0] mem_write_data,

    // Branch control → goes back to PC
    output        branch_taken,
    output [31:0] branch_target,

    // MEM/WB pipeline register outputs
    output reg [31:0] mem_wb_read_data,
    output reg [31:0] mem_wb_alu_result,
    output reg [4:0]  mem_wb_rd,
    output reg        mem_wb_reg_write,
    output reg        mem_wb_mem_to_reg
);

    // ── Memory Control ──────────────────────────────
    assign mem_we         = ex_mem_mem_write;
    assign mem_addr       = ex_mem_alu_result;  // Address from ALU
    assign mem_write_data = ex_mem_write_data;  // rs2 value for SW

    // ── Branch Decision ─────────────────────────────
    // BEQ: branch taken when zero=1 (rs1 - rs2 == 0)
    assign branch_taken  = ex_mem_branch & ex_mem_zero;
    assign branch_target = ex_mem_pc_branch;

    // ── MEM/WB Pipeline Register ────────────────────
    always @(posedge clk) begin
        if (reset) begin
            mem_wb_read_data   <= 32'd0;
            mem_wb_alu_result  <= 32'd0;
            mem_wb_rd          <= 5'd0;
            mem_wb_reg_write   <= 0;
            mem_wb_mem_to_reg  <= 0;
        end
        else begin
            mem_wb_read_data   <= mem_read_data;
            mem_wb_alu_result  <= ex_mem_alu_result;
            mem_wb_rd          <= ex_mem_rd;
            mem_wb_reg_write   <= ex_mem_reg_write;
            mem_wb_mem_to_reg  <= ex_mem_mem_to_reg;
        end
    end

endmodule
