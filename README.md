# FSM Vending Machine on Gowin FPGA

Exploring FSM architectures on FPGA: a comparative study of **Moore vs Mealy** FSM models and **Binary vs One-hot** state encodings, applied to a vending machine design.

Team research project at FPT University Da Nang (course FAP201, SU26).

## Overview

- Target device: Gowin GW5A-25 FPGA
- Language: Verilog
- Inputs: 3 coins (10k, 20k, 50k), 3 product buttons (A, B, C), reset
- Outputs: 2-digit 7-segment display (via 74HC595), buzzer, 3 product LEDs
- Goal: find optimal design approaches for real-world embedded control systems

## Results (from the project poster)

### Moore vs Mealy

| Feature | Moore FSM | Mealy FSM |
|---|---|---|
| Number of states | 6 | 5 |
| LUTs | 295 | 290 |
| Flip-flops | 282 | 280 |
| Fmax | 223.2 MHz | 222.8 MHz |
| Glitch | None | Possible |
| Output delay | 1 cycle | No delay |

### Binary vs One-hot

| Feature | Binary | One-hot |
|---|---|---|
| Encoding bits | 3 | 6 |
| LUTs | 295 | 308 |
| Flip-flops | 282 | 285 |
| Fmax | 223.2 MHz | 222.8 MHz |

Both designs exceed the 100 MHz requirement and use about 1.3% of the device LUTs.

## Team and contributions

| Part | Work | Members |
|---|---|---|
| Main system | Vending machine design (`src/`): Moore FSM, Binary encoding, datapath, display | Nguyen Van Nhat |
| Part B | Moore vs Mealy comparison | Nguyen Phuc Thinh, Nguyen Dinh Quoc Huy |
| Part B | Binary vs One-hot comparison (`encoding_comparison/`) | Dinh Phuoc Hoang, Le Huu Nguyen Khang |
| Team | Poster and report | Whole team |

Team members: Nguyen Van Nhat, Nguyen Phuc Thinh, Nguyen Dinh Quoc Huy, Dinh Phuoc Hoang, Le Huu Nguyen Khang, Tran Trung Tin.

### My contribution (Dinh Phuoc Hoang)

- Wrote and simulated Binary and One-hot versions of a simplified vending FSM in Verilog, with testbenches.
- [Add any other real tasks: synthesis on Gowin EDA, collecting LUT/FF/Fmax, poster, report ...]

## Repository structure

```
src/                   Main vending machine design (Moore + Binary)
tb/                    Testbenches for the main design
encoding_comparison/   Simplified FSM drafts for Binary vs One-hot (to be added)
docs/                  Poster and diagrams (to be added)
results/               Waveforms, resource and timing reports (to be added)
```

## Current contents

- Included: Moore FSM with Binary encoding (main design)
- Not yet added: Moore One-hot, Mealy Binary, Mealy One-hot

### Design files (`src/`)

| File | Description |
|---|---|
| `top_vending_machine.v` | Top module: FSM, datapath, buzzer control |
| `clock_div.v` | Clock dividers (`Chiaxung_N`, `Chiaxung_1hz`) |
| `binary_to_bcd_2digit.v` | Binary to 2-digit BCD |
| `bcd_to_7seg.v` | BCD to 7-segment decoder |
| `display_595_driver_2digit.v` | 74HC595 serial display driver |

### Testbenches (`tb/`)

| File | Description |
|---|---|
| `tb_vending_machine.v` | Waveform testbench (12 test sections) |
| `tb_vending_machine_selfcheck.v` | Self-checking testbench, prints PASS/FAIL |

### Encoding comparison (`encoding_comparison/`)

Early, simplified Moore FSM used only to compare Binary and One-hot encodings. It takes `balance` and `price` as inputs and has no coin, buzzer or display logic. It is **not** the final system on the poster.

| File | Description |
|---|---|
| `fsm_vending_binary.v` | 6 states, 3-bit binary encoding |
| `fsm_vending_onehot.v` | 6 states, 6-bit one-hot encoding |
| `fsm_vending_binary_tb.v` | Testbench for the binary version |
| `fsm_vending_onehot_tb.v` | Testbench for the one-hot version |

## How to simulate

Requires [Icarus Verilog](https://steveicarus.github.io/iverilog/) and GTKWave.

Self-checking testbench (main design):

```
iverilog -g2012 -o sim src/*.v tb/tb_vending_machine_selfcheck.v
vvp sim
```

Waveform testbench (main design):

```
iverilog -o sim src/*.v tb/tb_vending_machine.v
vvp sim
gtkwave tb_vending_machine.vcd
```

Use one testbench per build; do not compile `tb/*.v` together.

## Simulation notes

This version of the code is configured for simulation:

- `TIMEOUT_SEC = 0` disables the timeout
- Clock dividers use very small values (`DIV = 5`) to keep waveforms short
- Input debounce is removed, so a button held for many clock cycles adds money on every cycle

The poster describes a 7-cycle debounce filter. A version for the real board needs debounce enabled and realistic clock dividers.

## Prices and money units

| Item | Value |
|---|---|
| Coin 10k | +1 |
| Coin 20k | +2 |
| Coin 50k | +5 |
| Product A | 1 (10k) |
| Product B | 2 (20k) |
| Product C | 3 (30k) |

## Future work

- Add the remaining three FSM variants
- Enable debounce and test on the physical board
- Add a self-checking testbench for each variant
- Fix the simplified FSM in `encoding_comparison/`: state S2 stays stuck when balance is lower than price, and `timeout` has no effect there
