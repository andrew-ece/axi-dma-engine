# AXI DMA Engine

An ongoing SystemVerilog project to design and verify an AXI-based Direct Memory Access (DMA) engine.

## Current Status
### AXI4-Lite Control Interface — Implemented and Tested

Completed a 32-bit AXI4-Lite subordinate register interface (with 5 registers) for configuring and monitoring the planned DMA engine. The interface has passed self-checking directed simulations in ModelSim.

The DMA data-transfer engine is not yet implemented.

## Implemented Features
- AXI4-Lite read/write interface: Independent read and write channels using VALID/READY handshakes.

- Decoupled AW/W channels: Supports write addresses and write data arriving in either order.

- Memory-mapped registers: Five control/status registers with address decoding.

- Byte-enable writes: WSTRB support for partial register updates.

- Backpressure handling: Holds read and write responses until accepted by the manager.

- Error responses: Returns SLVERR for unmapped accesses and writes to read-only registers.

- Concurrent operations: Supports simultaneous read and write transactions.

### AXI-Lite4 Register Map
| Address Offset | Register | Access |
| -------- | -------- | -------- |
| 0x00 | DMA_CTRL | Read/Write |
| 0x04 | DMA_STATUS | Read-only |
| 0x08 | SRC_ADDR | Read/Write |
| 0x0C | DST_ADDR | Read/Write |
| 0x10 | LENGTH | Read/Write |

DMA_CTRL and DMA_STATUS currently provide register storage/readback behavior only; operational DMA control and status reporting will be added with the transfer engine.

## Verification Results

Tool: Siemens ModelSim
Language: SystemVerilog
Method: Self-checking directed testbench using automated checks
Result: All current directed tests passed

### Verified Scenarios

| Test | Verified Behaviour | Result |
| -------- | -------- | -------- |
| AW-before-W transaction | Independent write-address buffering and B-channel backpressure | PASS |
| W-before-AW transaction | Independent write-data buffering and byte-level WSTRB write | PASS |
| DMA_CTRL register write | Full 32-bit register update and OKAY write response | PASS |
| LENGTH register write | Partial register update using WSTRB (0011) | PASS |
| Read-only STATUS register write | Register remains unchanged, SLVERR returned | PASS |
| Invalid-address write | SLVERR returned for unmapped write address | PASS |
| Valid register read | Correct data and OKAY response were held under backpressure| PASS |
| Invalid-address read | Zero read data and SLVERR response | PASS |
| Concurrent read/write transactions | Register updated, old value was read with OKAY response | PASS |

The testbench checks transaction behavior, internal register updates, response validity, response codes, and data stability under backpressure.

### Running the Tests
The AXI4-Lite control interface is verified using a self-checking SystemVerilog testbench in Siemens ModelSim.
Requirements: ModelSim/QuestaSim with SystemVerilog support.

Run the following commands from the repository root.
1. Create the simulation library and compile the RTL and testbench

```
vlib work

vlog -sv rtl/axi_lite_regs.sv tb/*.sv
```

2. Run the directed tests

```
vsim -c work.tb_axi_lite_regs -do "run -all; quit -f"
```

## Tools and Technologies 
- SystemVerilog — RTL design and testbench development

- Siemens ModelSim — RTL simulation and waveform debugging

- AMD Vivado — FPGA synthesis and resource utilization analysis

- Git/GitHub — Version control

## Planned Components
- AXI DMA memory read engine

- AXI DMA memory write engine

- FIFO-based data buffering

- Transfer control, completion status, and error handling

- Protocol assertions and expanded verification

- Constrained-random and UVM verification

- End-to-end DMA transfer testing
