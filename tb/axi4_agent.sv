// ============================================
// AXI4 Agent
// Container for: sequencer + driver + monitor
// Active agent: drives + monitors (is_active=UVM_ACTIVE)
// Author: Saravana Kumar T J A
// ============================================
`include "uvm_macros.svh"
import uvm_pkg::*;
class axi4_agent extends uvm_agent;

    `uvm_component_utils(axi4_agent)

    axi4_sequencer  sequencer;
    axi4_driver     driver;
    axi4_monitor    monitor;

    // Analysis port — passes monitor output upward to scoreboard
    uvm_analysis_port #(axi4_seq_item) ap;

    function new(string name = "axi4_agent",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);

        monitor   = axi4_monitor::type_id::create("monitor", this);

        // Only create driver and sequencer for active agent
        if (get_is_active() == UVM_ACTIVE) begin
            sequencer = axi4_sequencer::type_id::create("sequencer", this);
            driver    = axi4_driver::type_id::create("driver", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        // Connect driver seq_item_port to sequencer seq_item_export
        if (get_is_active() == UVM_ACTIVE)
            driver.seq_item_port.connect(sequencer.seq_item_export);

        // Connect monitor analysis port up to agent analysis port
        monitor.ap.connect(ap);
    endfunction

endclass
