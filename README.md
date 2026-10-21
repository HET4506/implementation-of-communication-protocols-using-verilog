# Implementation of Communication Protocols using Verilog

A modular, hardware-synthesizable implementation of digital communication protocols in Verilog HDL.

---

## Current Implementation: Serial Transmitter (UART Architecture)

The repository currently features a fully parameterizable **Serial Transmitter** designed to packetize and serialize parallel data into standard serial frames (LSB-to-MSB), complete with Start and Stop framing bits and Idle line holding.

---

## Architecture Overview

The transmitter employs a modular, structural design with clean separation between data buffering, frame packing, and serialization.

```
                         +-----------------------------------+
                         |            transmitter            |
                         |                                   |
data_frame [n-1:0] ----->|   +---------------------------+   |
                         |   |     input_register        |   |
clk, rst --------------->|   |      (register.v)         |   |
                         |   +-------------+-------------+   |
                         |                 |                 |
                         |             out[n-1:0]            |
                         |                 |                 |
start_bit -------------->|---\             v             /---|
                         |    +-------------------------+    |
stop_bit --------------->|    |   stream concatenation  |    |
                         |    +------------+------------+    |
                         |                 |                 |
                         |           stream[n+1:0]           |
                         |                 |                 |
                         |   +-------------v-------------+   |
                         |   |      output_register      |   |
select ----------------->|   |   (parallel_to_serial.v)  |   |
                         |   +-------------+-------------+   |
                         |                 |                 |
                         +-----------------|-----------------+
                                           v
                                   transmitted_signal
```

---

## Frame & Protocol Specification

* **Default Data Width ($n$):** 8 bits (parameterized via `#(.n(8))`)
* **Total Frame Width ($n+2$):** 10 bits (`[9:0]`)
* **Transmission Order:** **LSB to MSB**
* **Start Bit:** Active-Low (`1'b0`)
* **Stop Bit:** Active-High (`1'b1`)
* **Idle State:** Line held High (`1'b1`)

### Stream Composition
In `transmitter.v`, the frame is packed as:
$$\text{stream}[n+1:0] = \{\text{stop\_bit},\, \text{out}[n-1:0],\, \text{start\_bit}\}$$

| Frame Index | Signal Bit | Role | Transmission Timing |
| :---: | :---: | :---: | :---: |
| `stream[0]` | `start_bit` | Start Bit (`0`) | Cycle 0 (at Load) |
| `stream[1]` | `out[0]` | Data Bit 0 (LSB) | Cycle 1 (1st Shift) |
| `stream[2]` | `out[1]` | Data Bit 1 | Cycle 2 (2nd Shift) |
| ... | ... | ... | ... |
| `stream[n]` | `out[n-1]` | Data Bit $n-1$ (MSB) | Cycle $n$ ($n$-th Shift) |
| `stream[n+1]` | `stop_bit` | Stop Bit (`1`) | Cycle $n+1$ |
| Tail Shifts | `1'b1` | Idle Line (`1`) | Cycle $n+2$ onwards |

---

## Module Hierarchy & Description

### 1. `transmitter.v` (Top-Level Module)
Coordinates the transmission pipeline:
* Instantiates `register` to stage input data.
* Assembles the composite frame `stream = {stop_bit, out, start_bit}`.
* Feeds `stream` to `parallel_to_serial` for sequential serialization.

### 2. `register.v` (Input Buffer)
* **Parameter:** `n` (default = 8).
* Instantiates an array of `n` flip-flops (`D_ff`) to register `data_frame` synchronously on `posedge clk`.
* Stabilizes parallel inputs and isolates the transmitter core from external data bus glitches.

### 3. `parallel_to_serial.v` (Serializer)
* **Parameter:** `n` (default = 8, handles frame width of $n+2$).
* Implements an $(n+2)$-stage shift register using `mux_2_1` and `D_ff`:
  * **Parallel Load Mode (`select = 0`):** Simultaneously loads all $n+2$ bits from `data` into internal flip-flops (`muxin`).
  * **Serial Shift Mode (`select = 1`):** Shifts bits downward (`muxin[i] <= muxin[i+1]`), outputting through `muxin[0]`.
  * **Idle Padding:** The MSB stage (`m_tail`) shifts in logic `1'b1` during shift mode, guaranteeing the serial line naturally returns to and remains at UART idle high.

### 4. `mux_2_1.v` (Multiplexer)
* 2-to-1 multiplexer primitive (`assign out = select ? b : a;`).
* Used in each stage of `parallel_to_serial` to switch between parallel loading (`a = data[i]`) and serial shifting (`b = muxin[i+1]`).

### 5. `D_ff.v` (Flip-Flop)
* D flip-flop primitive with synchronous active-high reset (`rst`).
* Provides single-cycle sequential storage for both parallel staging and shift register stages.

---

## Operational Workflow

1. **Reset Phase:** Assert `rst = 1` synchronously on `clk` to clear all internal storage elements.
2. **Load Phase:**
   * Provide `data_frame`, `start_bit = 0`, and `stop_bit = 1`.
   * Set `select = 0` (Load Mode).
   * Clock cycles allow `input_register` to sample the input data and `parallel_to_serial` to load the composite `stream`.
   * The start bit (`stream[0] = 0`) immediately appears on `transmitted_signal`.
3. **Shift Phase:**
   * Assert `select = 1` (Shift Mode).
   * On each successive clock cycle, data bits shift out from **LSB (`out[0]`)** to **MSB (`out[n-1]`)**.
   * On the final shift cycle, the stop bit (`1`) is transmitted.
   * Subsequent cycles maintain idle high (`1`) on `transmitted_signal`.

---

## Planned Enhancements

* [ ] **Baud Rate Generator:** Configurable clock divider for standard baud rates (9600, 115200, etc.).
* [ ] **UART Receiver (RX):** Asynchronous oversampling receiver (16x clock) with start bit detection and majority voting.
* [ ] **Parity Support:** Configurable even/odd/none parity generation and checking.
* [ ] **FIFO Buffers:** TX/RX FIFO integration for continuous streaming.
* [ ] **Additional Protocols:** SPI (Master/Slave) and I2C controllers.
