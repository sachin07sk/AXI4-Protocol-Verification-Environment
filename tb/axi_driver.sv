// ============================================
// AXI4 Driver
// Gets seq_items from sequencer
// Drives AXI4 signals on interface
// Implements VALID/READY handshake
// Author: Saravana Kumar T J A
// ============================================

`include "uvm_macros.svh"
import uvm_pkg::*;
class axi4_driver extends uvm_driver #(axi4_seq_item);

    `uvm_component_utils(axi4_driver)

    // Virtual interface handle
    virtual axi4_if.DRIVER vif;

    function new(string name = "axi4_driver",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // ── Build Phase ───────────────────────────
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // Get interface from config database
        if (!uvm_config_db #(virtual axi4_if)::get(
                this, "", "axi4_vif", vif))
            `uvm_fatal("CFG", "Cannot get axi4_vif from config_db")
    endfunction

    // ── Run Phase — main loop ─────────────────
    task run_phase(uvm_phase phase);
        // Initialize all outputs to safe values
        reset_signals();
        // Wait for reset to deassert
        @(negedge vif.reset);
        @(posedge vif.clk);

        forever begin
            axi4_seq_item item;
            // Get next item from sequencer
            seq_item_port.get_next_item(item);
            `uvm_info("DRV",
                $sformatf("Driving %s transaction", item.op_type.name()),
                UVM_MEDIUM)

            // Drive based on operation type
            if (item.op_type == axi4_seq_item::WRITE)
                drive_write(item);
            else
                drive_read(item);

            // Tell sequencer item is done
            seq_item_port.item_done();
        end
    endtask

    // ── Drive Write Transaction ───────────────
    task drive_write(axi4_seq_item item);
        // ── AW Channel: send write address ────
        vif.driver_cb.awvalid <= 1;
        vif.driver_cb.awaddr  <= item.addr;
        vif.driver_cb.awlen   <= item.burst_len;
        vif.driver_cb.awsize  <= item.burst_size;
        vif.driver_cb.awburst <= item.burst_type;
        vif.driver_cb.awid    <= item.id;

        // Wait for AWREADY handshake
        @(posedge vif.clk);
        while (!vif.driver_cb.awready)
            @(posedge vif.clk);
        vif.driver_cb.awvalid <= 0;

        // ── W Channel: send write data beats ──
        foreach(item.data[i]) begin
            vif.driver_cb.wvalid <= 1;
            vif.driver_cb.wdata  <= item.data[i];
            vif.driver_cb.wstrb  <= item.wstrb;
            vif.driver_cb.wlast  <= (i == item.data.size()-1);

            // Wait for WREADY handshake
            @(posedge vif.clk);
            while (!vif.driver_cb.wready)
                @(posedge vif.clk);
        end
        vif.driver_cb.wvalid <= 0;
        vif.driver_cb.wlast  <= 0;

        // ── B Channel: accept write response ──
        vif.driver_cb.bready <= 1;
        @(posedge vif.clk);
        while (!vif.driver_cb.bvalid)
            @(posedge vif.clk);
        vif.driver_cb.bready <= 0;

        `uvm_info("DRV", $sformatf(
            "Write complete: addr=0x%08h resp=%0b",
            item.addr, vif.driver_cb.bresp), UVM_LOW)
    endtask

    // ── Drive Read Transaction ────────────────
    task drive_read(axi4_seq_item item);
        // ── AR Channel: send read address ─────
        vif.driver_cb.arvalid <= 1;
        vif.driver_cb.araddr  <= item.addr;
        vif.driver_cb.arlen   <= item.burst_len;
        vif.driver_cb.arsize  <= item.burst_size;
        vif.driver_cb.arburst <= item.burst_type;
        vif.driver_cb.arid    <= item.id;

        // Wait for ARREADY handshake
        @(posedge vif.clk);
        while (!vif.driver_cb.arready)
            @(posedge vif.clk);
        vif.driver_cb.arvalid <= 0;

        // ── R Channel: receive read data beats─
        vif.driver_cb.rready <= 1;
        item.data = new[item.burst_len + 1]; // size array

        for (int i = 0; i <= item.burst_len; i++) begin
            @(posedge vif.clk);
            while (!vif.driver_cb.rvalid)
                @(posedge vif.clk);
            item.data[i] = vif.driver_cb.rdata;
            item.resp     = vif.driver_cb.rresp;

            if (vif.driver_cb.rlast) begin
                vif.driver_cb.rready <= 0;
                break;
            end
        end

        `uvm_info("DRV", $sformatf(
            "Read complete: addr=0x%08h data[0]=0x%08h",
            item.addr, item.data[0]), UVM_LOW)
    endtask

    // ── Reset All Signals to Safe State ───────
    task reset_signals();
        vif.driver_cb.awvalid <= 0;
        vif.driver_cb.awaddr  <= 0;
        vif.driver_cb.awlen   <= 0;
        vif.driver_cb.awsize  <= 3'b010;
        vif.driver_cb.awburst <= 2'b01;
        vif.driver_cb.awid    <= 0;
        vif.driver_cb.wvalid  <= 0;
        vif.driver_cb.wdata   <= 0;
        vif.driver_cb.wstrb   <= 4'hF;
        vif.driver_cb.wlast   <= 0;
        vif.driver_cb.bready  <= 0;
        vif.driver_cb.arvalid <= 0;
        vif.driver_cb.araddr  <= 0;
        vif.driver_cb.arlen   <= 0;
        vif.driver_cb.arsize  <= 3'b010;
        vif.driver_cb.arburst <= 2'b01;
        vif.driver_cb.arid    <= 0;
        vif.driver_cb.rready  <= 0;
    endtask

endclass
