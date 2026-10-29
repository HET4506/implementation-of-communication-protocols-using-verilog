# Implementation of Communication Protocols using Verilog

A modular, hardware-synthesizable implementation of digital communication protocols in Verilog HDL.

---

## Protocols Implemented

### 1. [UART (Universal Asynchronous Receiver-Transmitter)](UART/README.md)
* **Location:** [`UART/`](UART/)
* **Features:**
  * **Transmitter (TX):** Parameterized data width, synchronized double-buffered pipeline (`input_register` + `parallel_to_serial`), hardware flow control (`tx_ready`, `tx_busy`, `tx_done`), back-to-back transmission.
  * **Receiver (RX):** Asynchronous midpoint oversampling, 2-stage flip-flop synchronizer against metastability, false start-bit glitch rejection, stop-bit framing error detection (`rx_error`), double-buffered output (`output_register`).
  * **Detailed Documentation & Waveforms:** See [UART/README.md](UART/README.md).

---

## Repository Structure

```
.
├── README.md                      # Repository top-level overview
└── UART/                          # UART Core Subsystem
    ├── README.md                  # Comprehensive UART protocol & architecture documentation
    ├── counter.v                  # Modulo counter for baud timing
    ├── register.v                 # Parameterized n-bit holding register
    ├── D_ff.v                     # Synchronous reset D flip-flop primitive
    ├── mux_2_1.v                  # 2-to-1 multiplexer primitive
    ├── testbench.v                # Transmitter testbench
    ├── testbench_receiver.v       # End-to-end loopback & receiver testbench
    ├── transmitter/
    │   ├── transmitter.v          # Transmitter top-level
    │   ├── transmitter_fsm.v      # Transmitter FSM controller
    │   └── parallel_to_serial.v   # PISO shift register
    └── receiver/
        ├── receiver.v             # Receiver top-level
        ├── receiver_fsm.v         # Receiver FSM controller (oversampling logic)
        └── serial_to_parallel.v   # SIPO shift register
```

---

## Quick Simulation Guide

### Test UART Full-Duplex Loopback (TX + RX)
```bash
cd UART
iverilog -o sim_rx testbench_receiver.v receiver/receiver.v receiver/receiver_fsm.v receiver/serial_to_parallel.v transmitter/transmitter.v transmitter/transmitter_fsm.v transmitter/parallel_to_serial.v register.v counter.v D_ff.v mux_2_1.v
vvp sim_rx
```

### Test UART Transmitter Standalone
```bash
cd UART
iverilog -o sim_tx testbench.v transmitter/transmitter.v transmitter/transmitter_fsm.v transmitter/parallel_to_serial.v register.v counter.v D_ff.v mux_2_1.v
vvp sim_tx
```

---

## Project Roadmap

* [x] **UART Transmitter (TX):** Double-buffered pipeline with FSM flow control and back-to-back streaming.
* [x] **UART Receiver (RX):** Midpoint oversampling receiver with 2-stage synchronizer, glitch rejection, and framing error detection.
* [ ] **Parity Support:** Configurable even/odd/none parity generation and checking.
* [ ] **FIFO Buffers:** Multi-byte TX/RX FIFO integration.
* [ ] **Additional Protocols:** SPI (Master/Slave) and I2C controllers.
