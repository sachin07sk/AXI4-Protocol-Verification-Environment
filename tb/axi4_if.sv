// ============================================
// AXI4 Interface
// Contains all 5 channel signals
// Used by: driver, monitor, DUT
// Author: Saravana Kumar T J A
// ============================================

`include "uvm_macros.svh"
import uvm_pkg::*;
interface axi4_if (input logic clk, input logic reset);

    // ── Write Address Channel (AW) ──────────
    logic [31:0] awaddr;
    logic [7:0]  awlen;
    logic [2:0]  awsize;
    logic [1:0]  awburst;
    logic [3:0]  awid;
    logic        awvalid;
    logic        awready;

    // ── Write Data Channel (W) ───────────────
    logic [31:0] wdata;
    logic [3:0]  wstrb;
    logic        wlast;
    logic        wvalid;
    logic        wready;

    // ── Write Response Channel (B) ───────────
    logic [1:0]  bresp;
    logic [3:0]  bid;
    logic        bvalid;
    logic        bready;

    // ── Read Address Channel (AR) ────────────
    logic [31:0] araddr;
    logic [7:0]  arlen;
    logic [2:0]  arsize;
    logic [1:0]  arburst;
    logic [3:0]  arid;
    logic        arvalid;
    logic        arready;

    // ── Read Data Channel (R) ────────────────
    logic [31:0] rdata;
    logic [1:0]  rresp;
    logic        rlast;
    logic [3:0]  rid;
    logic        rvalid;
    logic        rready;

    // ── Driver Clocking Block ────────────────
    // Driver DRIVES signals — outputs sampled on posedge
    // #1 delay prevents race with DUT
    clocking driver_cb @(posedge clk);
        default input #1 output #1;
        // AW channel — driver drives these
        output awaddr, awlen, awsize, awburst, awid, awvalid;
        input  awready;
        // W channel
        output wdata, wstrb, wlast, wvalid;
        input  wready;
        // B channel
        input  bresp, bid, bvalid;
        output bready;
        // AR channel
        output araddr, arlen, arsize, arburst, arid, arvalid;
        input  arready;
        // R channel
        input  rdata, rresp, rlast, rid, rvalid;
        output rready;
    endclocking

    // ── Monitor Clocking Block ───────────────
    // Monitor OBSERVES signals — all inputs
    clocking monitor_cb @(posedge clk);
        default input #1;
        input awaddr, awlen, awsize, awburst, awid, awvalid, awready;
        input wdata, wstrb, wlast, wvalid, wready;
        input bresp, bid, bvalid, bready;
        input araddr, arlen, arsize, arburst, arid, arvalid, arready;
        input rdata, rresp, rlast, rid, rvalid, rready;
    endclocking

    // ── Modports ─────────────────────────────
    modport DRIVER  (clocking driver_cb,  input clk, reset);
    modport MONITOR (clocking monitor_cb, input clk, reset);
    modport DUT (
        input  clk, reset,
        input  awaddr, awlen, awsize, awburst, awid, awvalid,
        output awready,
        input  wdata, wstrb, wlast, wvalid,
        output wready,
        output bresp, bid, bvalid,
        input  bready,
        input  araddr, arlen, arsize, arburst, arid, arvalid,
        output arready,
        output rdata, rresp, rlast, rid, rvalid,
        input  rready
    );

endinterface
