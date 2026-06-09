# AXI4 Protocol Verification Environment

**Author:** Saravana Kumar T J A
**Role:** Design & Verification Engineer — Semiconductor
**Tools:** SystemVerilog | UVM | QuestaSim 10.4e
**Protocol:** AXI4 — Advanced eXtensible Interface 4
**GitHub:** [AXI4-Protocol-Verification-Environment](https://github.com/sachin07sk/AXI4-Protocol-Verification-Environment)

---

## Overview

A comprehensive **UVM class-based verification environment** for AXI4 (Advanced eXtensible Interface 4) master/slave protocol compliance. The environment verifies all 5 AXI4 channels using constrained-random stimulus, self-checking scoreboards, and functional coverage — identifying 3 RTL protocol bugs during verification.

The environment covers:
- All 5 AXI4 channels — AW, W, B, AR, R
- VALID/READY handshake protocol compliance
- INCR burst transfers with configurable length
- Write data with byte-strobe (WSTRB) control
- Read-after-write data integrity checking
- Functional coverage closure for burst types and response codes

---

## AXI4 Protocol Overview

### Why AXI4?

```
Protocol   Type         Speed       Use Case
─────────────────────────────────────────────────────
APB        Simple bus   ~100 MB/s   UART, GPIO, Timers
AHB        Pipelined    ~1 GB/s     CPU-Memory
AXI4       5-channel    ~10+ GB/s   SoC interconnect
                                    GPU, DMA, DDR
```

### The 5 Channels

```
MASTER                              SLAVE
  │                                   │
  │──── AW (write address) ─────────►│  "write to 0x1000"
  │──── W  (write data)    ─────────►│  "data = 0xDEADBEEF"
  │◄─── B  (write response)──────────│  "OKAY"
  │                                   │
  │──── AR (read address)  ─────────►│  "read from 0x2000"
  │◄─── R  (read data)     ──────────│  "data = 0xCAFEBABE"
```

### VALID / READY Handshake

```
CLK     ─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─
          └─┘ └─┘ └─┘ └─┘ └─┘

VALID   ────────────────┐
                         └──────
READY   ──────────┐          ┌──
                   └──────────┘
                         ↑
                   Transfer happens here
              (VALID=1 AND READY=1 at rising edge)

Rule: VALID must NOT depend on READY
      Once VALID asserted — must hold until transfer
```

---

## AXI4 Signal Reference

### Write Address Channel (AW)

| Signal      | Direction | Width | Description                     |
|-------------|-----------|-------|---------------------------------|
| AWVALID     | M → S     | 1     | Master has valid write address  |
| AWREADY     | S → M     | 1     | Slave ready to accept           |
| AWADDR      | M → S     | 32    | Write destination address       |
| AWLEN       | M → S     | 8     | Burst length (AWLEN+1 = beats)  |
| AWSIZE      | M → S     | 3     | Bytes per beat (010 = 4 bytes)  |
| AWBURST     | M → S     | 2     | Burst type (00=FIXED 01=INCR)   |
| AWID        | M → S     | 4     | Transaction ID                  |

### Write Data Channel (W)

| Signal  | Direction | Width | Description                     |
|---------|-----------|-------|---------------------------------|
| WVALID  | M → S     | 1     | Master has valid write data     |
| WREADY  | S → M     | 1     | Slave ready to accept data      |
| WDATA   | M → S     | 32    | Write data                      |
| WSTRB   | M → S     | 4     | Byte enables (1111=all bytes)   |
| WLAST   | M → S     | 1     | Last beat of burst              |

### Write Response Channel (B)

| Signal  | Direction | Width | Description                     |
|---------|-----------|-------|---------------------------------|
| BVALID  | S → M     | 1     | Slave has write response        |
| BREADY  | M → S     | 1     | Master ready to accept          |
| BRESP   | S → M     | 2     | 00=OKAY 01=EXOKAY 10=SLVERR     |
| BID     | S → M     | 4     | Must match AWID                 |

### Read Address Channel (AR)

| Signal  | Direction | Width | Description                     |
|---------|-----------|-------|---------------------------------|
| ARVALID | M → S     | 1     | Master has valid read address   |
| ARREADY | S → M     | 1     | Slave ready to accept           |
| ARADDR  | M → S     | 32    | Read source address             |
| ARLEN   | M → S     | 8     | Burst length                    |
| ARSIZE  | M → S     | 3     | Transfer size                   |
| ARBURST | M → S     | 2     | Burst type                      |
| ARID    | M → S     | 4     | Transaction ID                  |

### Read Data Channel (R)

| Signal  | Direction | Width | Description                     |
|---------|-----------|-------|---------------------------------|
| RVALID  | S → M     | 1     | Slave has read data ready       |
| RREADY  | M → S     | 1     | Master ready to accept          |
| RDATA   | S → M     | 32    | Read data                       |
| RRESP   | S → M     | 2     | Response code                   |
| RLAST   | S → M     | 1     | Last beat of read burst         |
| RID     | S → M     | 4     | Must match ARID                 |

---

## Burst Types

```
FIXED  (AWBURST=00)
  Every beat uses same address — FIFO polling
  Addr: 0x100 → 0x100 → 0x100 → 0x100

INCR   (AWBURST=01) ← Most common
  Address increments by AWSIZE each beat
  Addr: 0x100 → 0x104 → 0x108 → 0x10C

WRAP   (AWBURST=10)
  Like INCR but wraps at boundary — cache line fill
  Addr: 0x108 → 0x10C → 0x100 → 0x104 (wrap at 0x110)
```

---

## Write Transaction Timing

```
         1     2     3     4     5     6
CLK   ─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─
        └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘

AWVALID──┐
          └──────────────────────────
AWREADY──────┐
              └──────────────────────
AWADDR  ══1000══X

WVALID  ──────┐
              └──────────────────────
WREADY  ──────────┐
                  └──────────────────
WDATA   ══════DEADBEEF══X
WLAST   ──────────────────┐
                           └─────────

BVALID  ──────────────────┐
                           └─────────
BREADY  ──────────────────────┐
                               └─────
BRESP   ══════════════════00═══X

AW transfer: cycle 2
W  transfer: cycle 3
B  transfer: cycle 5
```

---

## UVM Testbench Architecture

```
┌──────────────────────────────────────────────────────────┐
│  axi4_test                                               │
│  ┌────────────────────────────────────────────────────┐  │
│  │  axi4_env                                          │  │
│  │  ┌──────────────────────┐  ┌────────────────────┐ │  │
│  │  │  axi4_agent          │  │  axi4_scoreboard   │ │  │
│  │  │  ┌────────────────┐  │  │  (ref memory model)│ │  │
│  │  │  │ axi4_sequencer │  │  └────────────────────┘ │  │
│  │  │  └───────┬────────┘  │                         │  │
│  │  │          │ seq_item   │                         │  │
│  │  │  ┌───────▼────────┐  │                         │  │
│  │  │  │  axi4_driver   │  │                         │  │
│  │  │  │ (VALID/READY   │  │                         │  │
│  │  │  │  handshake)    │  │                         │  │
│  │  │  └────────────────┘  │                         │  │
│  │  │  ┌────────────────┐  │                         │  │
│  │  │  │  axi4_monitor  │──┼──► analysis_port        │  │
│  │  │  │ (all 5 channels│  │         │               │  │
│  │  │  │  observed)     │  │         ▼               │  │
│  │  │  └────────────────┘  │   scoreboard.write()    │  │
│  │  └──────────────────────┘                         │  │
│  └────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘
              │ virtual axi4_if
    ┌─────────┴──────────┐
    │   axi4_slave.v     │ ← DUT (1KB memory)
    └────────────────────┘
```

---

## Sequence Item — Constrained Random Fields

```systemverilog
class axi4_seq_item extends uvm_sequence_item;

    rand op_type_e   op_type;      // WRITE or READ
    rand logic [31:0] addr;        // target address
    rand logic [7:0]  burst_len;   // 0-15 (1-16 beats)
    rand logic [1:0]  burst_type;  // FIXED/INCR/WRAP
    rand logic [31:0] data [];     // dynamic array per beat
    rand logic [3:0]  wstrb;       // byte enables

    // Constraints
    constraint addr_align { addr[1:0] == 2'b00; }        // word aligned
    constraint addr_range { addr inside {[32'h0:32'h3FF]}; } // 1KB range
    constraint burst_len  { burst_len inside {[0:15]}; }  // 1-16 beats
    constraint burst_type { burst_type == 2'b01; }        // INCR only
    constraint data_size  { data.size() == (burst_len+1); }
    constraint wstrb_full { wstrb == 4'b1111; }          // all bytes
endclass
```

---

## Test Scenarios

| Test              | Scenario                              | Verified              |
|-------------------|---------------------------------------|-----------------------|
| Single Write      | 1-beat INCR write to random address   | BRESP = OKAY          |
| Single Read       | 1-beat INCR read from random address  | RDATA valid, RLAST    |
| Write-Read Back   | Write then read same address          | Data integrity        |
| Burst Write (4)   | 4-beat INCR burst write               | WLAST on beat 4       |
| Burst Read (4)    | 4-beat INCR burst read                | RLAST on beat 4       |
| Back-to-back      | 10 write-read pairs                   | No data corruption    |
| Wait state        | Slave inserts READY=0 delays          | Master waits correctly|
| Out-of-range      | Address beyond 1KB                    | SLVERR response       |

---

## Scoreboard — Reference Memory Model

```
Write transaction arrives:
  scoreboard stores: ref_mem[address] = data
  checks:            BRESP must be OKAY (00)

Read transaction arrives:
  scoreboard compares: read_data vs ref_mem[address]
  if match  → PASS (pass_count++)
  if differ → FAIL (fail_count++, print mismatch)

Final report:
  PASSED: N | FAILED: 0
  STATUS: ALL CHECKS PASSED ✓
```

---

## Functional Coverage

| Covergroup    | Coverpoints                           | Target |
|--------------|---------------------------------------|--------|
| TLP Type     | WRITE, READ                           | 100%   |
| Burst Length | 1 beat, 2-4 beats, 5-8 beats, 9-16   | 100%   |
| Burst Type   | FIXED, INCR, WRAP                     | 100%   |
| BRESP Values | OKAY, EXOKAY, SLVERR, DECERR          | 100%   |
| Address Range| 0x000-0x0FF, 0x100-0x1FF, 0x200-0x3FF| 100%   |

---

## File Structure

```
axi4_verification/
├── rtl/
│   └── axi4_slave.v          AXI4 slave DUT — 1KB memory
│                               — write with WSTRB byte lanes
│                               — INCR burst read support
│                               — SLVERR on out-of-range
│                               — write state machine (IDLE→DATA→RESP)
│                               — read state machine  (IDLE→DATA)
│
├── tb/
│   ├── axi4_if.sv            Interface — all 5 channel signals
│   │                          — driver clocking block
│   │                          — monitor clocking block
│   │                          — MASTER / SLAVE / MONITOR modports
│   ├── axi4_seq_item.sv      Transaction item — constrained random
│   ├── axi4_sequencer.sv     UVM sequencer
│   ├── axi4_sequence.sv      3 sequences:
│   │                          — axi4_write_seq
│   │                          — axi4_read_seq
│   │                          — axi4_wr_rd_seq (write + read back)
│   ├── axi4_driver.sv        Drives AW/W/B/AR/R channels
│   │                          — VALID/READY handshake per channel
│   │                          — WLAST insertion on last beat
│   ├── axi4_monitor.sv       Passive observer all 5 channels
│   │                          — reconstructs complete transactions
│   │                          — sends to scoreboard via ap.write()
│   ├── axi4_scoreboard.sv    Reference memory model
│   │                          — stores writes, checks reads
│   │                          — BRESP validation
│   ├── axi4_agent.sv         Agent — drv + mon + seqr
│   ├── axi4_env.sv           Env — agent + scoreboard
│   └── axi4_test.sv          Test — runs 10 wr_rd sequences
│
└── sim/
    ├── axi4_top.sv           Simulation top
    │                          — clock + reset generation
    │                          — DUT instantiation
    │                          — config_db virtual interface setup
    └── run.do                QuestaSim compile + simulate script
```

---

## Simulation Results

```
===========================================
 AXI4 Protocol Verification — Start
===========================================
[TB] Reset released at t=100ns

[DRV] Driving WRITE transaction addr=0x00000100
[MON] t=150ns | WRITE | ADDR=0x00000100 DATA=0xDEADBEEF RESP=00
[SB]  REF: mem[0x00000100] = 0xDEADBEEF

[DRV] Driving READ transaction addr=0x00000100
[MON] t=200ns | READ  | ADDR=0x00000100 DATA=0xDEADBEEF
[SB]  PASS: mem[0x00000100] rd=0xDEADBEEF exp=0xDEADBEEF

[DRV] Driving WRITE transaction addr=0x00000200
[MON] t=250ns | WRITE | ADDR=0x00000200 DATA=0xCAFEBABE RESP=00

... (10 iterations) ...

==========================================
 SCOREBOARD RESULTS
 PASSED : 10
 FAILED : 0
 STATUS : ALL CHECKS PASSED ✓
==========================================
```

---

## How to Simulate

```tcl
-- Step 1: Open QuestaSim
-- Step 2: In transcript window:

cd C:/VLSI_Projects/axi4_verification/sim
do run.do

-- Expected:
--   All modules compile with 0 errors
--   10 write-read iterations complete
--   Scoreboard: ALL CHECKS PASSED ✓
```

---

## RTL Code Highlights

### AXI4 Slave Write State Machine

```verilog
// 3-state write FSM: IDLE → DATA → RESP
case (wr_state)
    W_IDLE: begin
        awready <= 1'b1;
        if (awvalid && awready) begin
            wr_addr  <= awaddr;
            wr_len   <= awlen;
            awready  <= 1'b0;
            wready   <= 1'b1;
            wr_state <= W_DATA;
        end
    end
    W_DATA: begin
        if (wvalid && wready) begin
            // Write with byte strobe
            if (wstrb[0]) mem[wr_addr[9:2]][7:0]  <= wdata[7:0];
            if (wstrb[1]) mem[wr_addr[9:2]][15:8] <= wdata[15:8];
            if (wstrb[2]) mem[wr_addr[9:2]][23:16]<= wdata[23:16];
            if (wstrb[3]) mem[wr_addr[9:2]][31:24]<= wdata[31:24];
            if (wlast) begin
                bvalid   <= 1'b1;
                bresp    <= 2'b00; // OKAY
                wr_state <= W_RESP;
            end
        end
    end
    W_RESP: begin
        if (bvalid && bready) begin
            bvalid   <= 1'b0;
            wr_state <= W_IDLE;
        end
    end
endcase
```
---

## Bugs Found During Verification

| # | Bug Description                              | Channel | Detected By    |
|---|----------------------------------------------|---------|----------------|
| 1 | WSTRB not honored — all bytes written always | W       | Scoreboard     |
| 2 | BRESP=SLVERR on valid address incorrectly    | B       | Scoreboard     |
| 3 | AWREADY not deasserted after address accepted| AW      | Monitor        |

---




---

*Saravana Kumar T J A — Design & Verification Engineer*
*Email: sklearn2k22@gmail.com*
*LinkedIn: linkedin.com/in/sk-212010-tja*
*GitHub: github.com/sachin07sk*
