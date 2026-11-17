# Joymouse (Arduino UNO/Wired)

Turn an **Arduino Uno R3** and **two analog thumbstick modules** into a working USB computer mouse. 

Because the Uno R3 can’t act as a USB mouse by itself, the Arduino reads both joysticks and streams the values over USB Serial (`115200` baud). **Processing** then reads that stream and moves the real cursor, clicks, and scrolls using Java’s `Robot` class.

> **Safety Note:** `dual_joystick_mouse_processing.pde` starts **paused** by default so you can verify that the stick directions match your movements before letting it control your real mouse cursor.

---

## Software Required

Install both free programs before running the code:
* **[Download Arduino IDE](https://www.arduino.cc/en/software/)** — To upload `dual_joystick_mouse_arduino.ino` to your Arduino Uno R3.
* **[Download Processing](https://processing.org/download)** — To run `dual_joystick_mouse_processing.pde` on your computer.

---

## Wiring

**check the 'Wiring' folder for the wirings and diagram !!**
---

## How to Run It

1. **Upload the Arduino Sketch**
   * Open `dual_joystick_mouse_arduino.ino` in the **Arduino IDE**.
   * Set **Board** to `Arduino Uno`, pick your COM port, and click **Upload**.
   * *(Optional)* Open the Serial Monitor at **`115200` baud** to check that you see lines like `512,510,515,509,0,0`, then **close the Serial Monitor**.
2. **Run the Processing Sketch**
   * Open `dual_joystick_mouse_processing.pde` in **Processing** and press **Run**.
   * If you have more than one serial port, press the number key (`0`, `1`, etc.) for your Arduino’s port in the Processing window.
3. **Calibrate & Go Live**
   * Keep your hands off the sticks for a second while it calibrates.
   * Wiggle both sticks and verify the on-screen dots follow them.
   * Press **`SPACE`**, or **hold the left stick’s button for 1 second**, to go live. Leave the Processing window open while you use it.

*(Note: If either IDE asks to move a file into a folder with the same name, click **Yes**).*

---

## Controls

* **Left stick:** Moves the cursor.
* **Right stick up/down:** Scrolls up and down (faster the harder you push).
* **Right stick left/right:** Left-click and right-click. Keep it pushed to click-and-drag.
* **Right stick button (press):** Middle-click.
* **Left stick button (hold 1 second) or `SPACE`:** Pauses or resumes cursor control so the cursor can’t run away.

---

## Troubleshooting

* **A direction is reversed:** Flip the matching `INVERT_` flag (`true` / `false`) at the top of the Processing sketch.
* **Left/right and up/down are swapped:** Swap the two analog pins (`A0`/`A1` or `A2`/`A3`) in the Arduino sketch.
* **The cursor drifts:** Press **`C`** with your hands off the sticks to recalibrate, or raise the `DEADZONE` value in Processing.
* **“Could not open” the port:** Close the Arduino Serial Monitor. Also stop the Processing sketch before re-uploading code to the Arduino.
* **No COM port appears:** Many blue Uno clones use a **CH340** USB chip, which requires installing the CH340 driver on Windows.
* **On a Mac:** Allow Processing under **System Settings → Privacy & Security → Accessibility**.
* **Skip the startup pause:** Once everything behaves properly, set `START_LIVE = true` at the top of the Processing sketch.

---

## Credits

* Hardware build, wiring, and testing by **Malhar Kiran Desale**
* Sketches generated with **Claude** (Anthropic)
