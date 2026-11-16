# Dual Joystick USB Mouse (Arduino Uno R3 + Processing)

Control your PC mouse cursor, left/right click-and-drag, middle click, and scrolling using an **Arduino Uno R3** and **two analog joystick modules**.

Because the Arduino Uno R3 cannot act as a USB mouse by itself, it reads the joystick values and sends them over USB to **Processing**, which moves the real mouse using Java's `Robot` class.

---

## Software Required
Install both free programs before running the code:
* **[Download Arduino IDE](https://www.arduino.cc/en/software/)** — Used to upload the `.ino` code to your Arduino Uno R3.
* **[Download Processing](https://processing.org/download)** — Used to run the `.pde` code on your PC so the joysticks can move your mouse.

---

## Wiring (No Breadboard Needed)
* **Left Stick (Cursor):** `GND` → `GND` | `+5V` → `5V` | `VRx` → `A0` | `VRy` → `A1` | `SW` → `D2`
* **Right Stick (Scroll & Clicks):** `GND` → `GND` | `+5V` → `IOREF` (or `D4`) | `VRx` → `A2` | `VRy` → `A3` | `SW` → `D3`

---

## Controls
* **Left Stick:** Move cursor (Hold button for 1 sec to Pause/Resume)
* **Right Stick Up/Down:** Scroll up and down
* **Right Stick Left/Right:** Left click / Right click (hold to drag)
* **Right Stick Button:** Middle click

---

## Credits
* Built & wired by **Malhar Kiran Desale**
* Code written with **Claude**
