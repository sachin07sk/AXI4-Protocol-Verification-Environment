// ============================================
// Data Memory — Read/Write RAM
// 256 words × 32-bit = 1KB data space
// ============================================
module data_mem (
    input         clk,
    input         we,          // Write enable (SW instruction)
    input  [31:0] addr,        // Memory address from ALU
    input  [31:0] write_data,  // Data to store (SW)
    output [31:0] read_data    // Data loaded (LW)
);

    reg [31:0] mem [0:255];

    initial begin
        integer i;
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 32'd0;
    end

    // Synchronous write
    always @(posedge clk) begin
        if (we)
            mem[addr[9:2]] <= write_data;
    end

    // Asynchronous read
    assign read_data = mem[addr[9:2]];

endmodule
