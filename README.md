# Reaction Timer (FPGA Implementation Based on VHDL)

This project is a reaction time tester implemented using the VHDL hardware description language and deployed on an FPGA platform. It measures user reaction time and provides feedback through LEDs, a 7-segment display, a buzzer, and buttons.

------

## 🚀 Overview

The main features of this project include:

1. Generating a random delay (2–6 seconds)
   💡 **Note**: The current delay is pseudo-randomly generated using a fixed counter. You may upgrade it to true randomness if needed.
2. Providing visual stimulus through an LED
3. Measuring reaction time after user button press
4. Displaying results on a 6-digit 7-segment display
5. Giving feedback through LED matrix and buzzer

------

## ⚙️ Hardware & Development Environment

- **Development Board**: HEDL-2 Experiment Box
- **Toolchain**: Quartus II
- **System Clock**: 24 MHz
- **Input Devices**: `start` and `stop` buttons, reset button
- **Output Devices**:
  - LED (as visual cue)
  - LED matrix (for status feedback like “Ready” or “Violation”)
  - 7-segment display (up to 9999 ms resolution)
  - Buzzer (distinct sounds for success and violations)

------

## ⚙️ Core Components

1. **Five-State Finite State Machine (FSM)**:
   - `READY`: Initial state (LED matrix displays "Ready")
   - `RANDOM_DELAY`: Waits for 2–6 seconds (LED off)
   - `TIMING`: Reaction time recording (LED on, counter runs)
   - `DONE`: Test complete (display shows "Done")
   - `VIOLATION`: Violation (display shows "Violation")
2. **Peripheral Control**:
   - Start/Stop buttons
   - LED for visual cue
   - 16×16 LED Matrix for status indicators
   - 6-digit 7-segment display for time
   - Buzzer for audio feedback
3. **Key Modules**:
   - Clock divider (24 MHz → 1 kHz)
   - Random delay generator (2–6 seconds)
   - Millisecond timer (0–9999 ms)
   - Display drivers (LED matrix + 7-segment)
   - Buzzer controller (1.2 kHz for success, 1 kHz pulse for violation)

------

## 🛠️ Instructions

1. **Reset**:
   System enters `READY` state, LED lights up, matrix shows "Ready".
2. **Start Test**:
   Press `start` → Enters `RANDOM_DELAY` state (LED turns off).
3. **Reaction Test**:
   When LED lights up (`TIMING` state), press `stop` immediately:
   - Valid: 7-segment shows reaction time (e.g., "211" ms), matrix shows "Done", buzzer sounds.
   - Timeout: If no press, timer stops at 9999 ms.
4. **Violation Handling**:
   If `stop` is pressed during `RANDOM_DELAY`:
   - Matrix shows "Violation"
   - LED blinks at 1 Hz
   - Buzzer emits 1 kHz pulse sound

------

## 🔌 Hardware Interface

| Signal    | Dir. | Description              |
| --------- | ---- | ------------------------ |
| `clk`     | In   | 24 MHz system clock      |
| `reset`   | In   | Global reset             |
| `start`   | In   | Start test button        |
| `stop`    | In   | Stop timing button       |
| `led`     | Out  | Visual stimulus LED      |
| `led_row` | Out  | LED matrix row selection |
| `led_col` | Out  | LED matrix column data   |
| `seg`     | Out  | 7-segment segment select |
| `dig`     | Out  | 7-segment digit select   |
| `buzzer`  | Out  | Buzzer control signal    |

------

## 🧩 Code Structure

```vhdl
ReactionTimeTester.vhd
├── Clock Divider (24 MHz → 1 ms clock)
├── Finite State Machine (5 states)
├── Random Delay Generator
├── Timer Module (0–9999 ms)
├── 7-Segment Display Driver
│   └── Digit-to-Segment Encoder
├── LED Matrix Controller
│   └── Character Font for Display ("Ready", "Start", "Done", "Violation")
└── Buzzer Controller
    ├── 1.2 kHz tone (success)
    └── 1 kHz pulse tone (violation)
```
