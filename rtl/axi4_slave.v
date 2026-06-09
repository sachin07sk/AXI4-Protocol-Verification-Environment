// ============================================
// AXI4 Slave — Device Under Test
// Simple 1KB memory slave
// Supports: INCR burst reads and writes
// Author: Saravana Kumar T J A
// ============================================
module axi4_slave (
    input  logic        clk,
    input  logic        reset,
    // AW channel
    input  logic [31:0] awaddr,
    input  logic [7:0]  awlen,
    input  logic [2:0]  awsize,
    input  logic [1:0]  awburst,
    input  logic [3:0]  awid,
    input  logic        awvalid,
    output logic        awready,
    // W channel
    input  logic [31:0] wdata,
    input  logic [3:0]  wstrb,
    input  logic        wlast,
    input  logic        wvalid,
    output logic        wready,
    // B channel
    output logic [1:0]  bresp,
    output logic [3:0]  bid,
    output logic        bvalid,
    input  logic        bready,
    // AR channel
    input  logic [31:0] araddr,
    input  logic [7:0]  arlen,
    input  logic [2:0]  arsize,
    input  logic [1:0]  arburst,
    input  logic [3:0]  arid,
    input  logic        arvalid,
    output logic        arready,
    // R channel
    output logic [31:0] rdata,
    output logic [1:0]  rresp,
    output logic        rlast,
    output logic [3:0]  rid,
    output logic        rvalid,
    input  logic        rready
);

    // 1KB memory (256 words x 32-bit)
    logic [31:0] mem [0:255];

    // Internal state
    logic [31:0] wr_addr;
    logic [7:0]  wr_count;
    logic [7:0]  wr_len;
    logic [3:0]  wr_id;

    logic [31:0] rd_addr;
    logic [7:0]  rd_count;
    logic [7:0]  rd_len;
    logic [3:0]  rd_id;

    // State machines
    typedef enum logic [1:0] {W_IDLE, W_DATA, W_RESP} wr_state_t;
    typedef enum logic [1:0] {R_IDLE, R_DATA}          rd_state_t;

    wr_state_t wr_state;
    rd_state_t rd_state;

    // ── Write State Machine ───────────────────
    always_ff @(posedge clk) begin
        if (reset) begin
            wr_state <= W_IDLE;
            awready  <= 0;
            wready   <= 0;
            bvalid   <= 0;
            bresp    <= 2'b00;
            bid      <= 0;
        end else begin
            case (wr_state)
                W_IDLE: begin
                    awready <= 1;
                    wready  <= 0;
                    bvalid  <= 0;
                    if (awvalid && awready) begin
                        wr_addr  <= awaddr;
                        wr_len   <= awlen;
                        wr_id    <= awid;
                        wr_count <= 0;
                        awready  <= 0;
                        wready   <= 1;
                        wr_state <= W_DATA;
                    end
                end

                W_DATA: begin
                    if (wvalid && wready) begin
                        // Write to memory with byte strobe
                        if (wstrb[0]) mem[wr_addr[9:2]][7:0]   <= wdata[7:0];
                        if (wstrb[1]) mem[wr_addr[9:2]][15:8]  <= wdata[15:8];
                        if (wstrb[2]) mem[wr_addr[9:2]][23:16] <= wdata[23:16];
                        if (wstrb[3]) mem[wr_addr[9:2]][31:24] <= wdata[31:24];

                        wr_addr  <= wr_addr + 4;
                        wr_count <= wr_count + 1;

                        if (wlast) begin
                            wready   <= 0;
                            bvalid   <= 1;
                            bresp    <= 2'b00; // OKAY
                            bid      <= wr_id;
                            wr_state <= W_RESP;
                        end
                    end
                end

                W_RESP: begin
                    if (bvalid && bready) begin
                        bvalid   <= 0;
                        wr_state <= W_IDLE;
                    end
                end
            endcase
        end
    end

    // ── Read State Machine ────────────────────
    always_ff @(posedge clk) begin
        if (reset) begin
            rd_state <= R_IDLE;
            arready  <= 0;
            rvalid   <= 0;
            rlast    <= 0;
            rresp    <= 2'b00;
            rid      <= 0;
            rdata    <= 0;
        end else begin
            case (rd_state)
                R_IDLE: begin
                    arready <= 1;
                    rvalid  <= 0;
                    if (arvalid && arready) begin
                        rd_addr  <= araddr;
                        rd_len   <= arlen;
                        rd_id    <= arid;
                        rd_count <= 0;
                        arready  <= 0;
                        rd_state <= R_DATA;
                    end
                end

                R_DATA: begin
                    rvalid <= 1;
                    rdata  <= mem[rd_addr[9:2]];
                    rresp  <= 2'b00; // OKAY
                    rid    <= rd_id;
                    rlast  <= (rd_count == rd_len);

                    if (rvalid && rready) begin
                        rd_addr  <= rd_addr + 4;
                        rd_count <= rd_count + 1;
                        if (rlast) begin
                            rvalid   <= 0;
                            rlast    <= 0;
                            rd_state <= R_IDLE;
                        end
                    end
                end
            endcase
        end
    end

endmodule
