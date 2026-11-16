// ============================================================
//  DUAL-JOYSTICK MOUSE  -  Processing side
// ------------------------------------------------------------
//  The Arduino sends one line per update:  lx,ly,rx,ry,lBtn,rBtn
//  This sketch turns those numbers into a real mouse.
//
//    LEFT  stick ............. move the cursor
//    RIGHT stick up / down ... scroll up / down (harder = faster)
//    RIGHT stick left ........ left click  (keep it pushed to drag)
//    RIGHT stick right ....... right click
//    RIGHT stick button ...... middle click
//
//    SPACE, or hold the LEFT stick button for 1 s = pause / resume
//    C = recalibrate the centre (hands off the sticks!)
//
//  Close the Arduino Serial Monitor first: only one program can
//  use the USB port at a time.
// ============================================================

import processing.serial.*;
import java.awt.Robot;
import java.awt.AWTException;
import java.awt.MouseInfo;
import java.awt.Point;
import java.awt.event.InputEvent;

// ------------------ SETTINGS (safe to tweak) ------------------
int     PORT_INDEX   = -1;      // -1 = automatic / choose in the window, or a number from the console list
int     BAUD         = 115200;  // must match Serial.begin() in the Arduino sketch
boolean START_LIVE   = false;   // false = start paused, so you can check the directions first
float   CURSOR_SPEED = 18;      // pixels per frame at full push
float   DEADZONE     = 0.12;    // 0..1  stick travel ignored around the centre
float   CURVE        = 2.0;     // 1 = linear, 2 = precise near the centre, fast at the edge
float   CLICK_ON     = 0.65;    // push the right stick this far left/right to press a button
float   CLICK_OFF    = 0.40;    // ...and bring it back inside this to release it
int     SCROLL_SLOW  = 300;     // ms between scroll steps at a light push
int     SCROLL_FAST  = 50;      // ms between scroll steps at a full push
boolean INVERT_LX = false, INVERT_LY = false;   // flip if the cursor moves the wrong way
boolean INVERT_RX = false, INVERT_RY = false;   // flip if scroll / click directions are reversed
// --------------------------------------------------------------

Serial   port;
String[] ports;
String   portName = "";
String   error = "";
Robot    robot;

volatile int[]   raw = new int[6];   // newest sample: lx, ly, rx, ry, leftBtn, rightBtn
volatile boolean gotData = false;
volatile int     lastSample = 0;     // millis() when it arrived

float[] centre = {512, 512, 512, 512};   // calibrated rest position of each axis
float[] calSum = new float[4];
int     calCount = 0;
boolean calibrating = true;

boolean live;                        // is the mouse switched on?
boolean leftDown, rightDown, midDown;
float   accX, accY;                  // sub-pixel remainder carried to the next frame
int     lastScroll = 0;
int     holdStart = -1;
boolean holdDone = false;
float   lx, ly, rx, ry;              // stick positions, -1..+1


void setup() {
  size(500, 350);
  frameRate(60);
  live = START_LIVE;

  try {
    robot = new Robot();
  } catch (AWTException e) {
    println("Could not create the Robot: " + e);
  }

  ports = Serial.list();
  printArray(ports);                 // the same list is shown in the window
  if (PORT_INDEX >= 0 && PORT_INDEX < ports.length) connect(PORT_INDEX);
  else if (ports.length == 1) connect(0);
}


void connect(int i) {
  try {
    port = new Serial(this, ports[i], BAUD);
    port.bufferUntil('\n');
    portName = ports[i];
    error = "";
  } catch (Exception e) {
    port = null;
    error = "Could not open " + ports[i] + " - is the Serial Monitor still open?";
  }
}


// Called automatically for every complete line the Arduino sends.
void serialEvent(Serial p) {
  String line = p.readStringUntil('\n');
  if (line == null) return;
  String[] t = splitTokens(trim(line), ",");
  if (t.length != 6) return;                       // ignore half-received lines
  int[] v = new int[6];
  for (int i = 0; i < 6; i++) v[i] = parseInt(t[i]);
  raw = v;
  gotData = true;
  lastSample = millis();
}


void draw() {
  background(24);

  boolean fresh = gotData && millis() - lastSample < 500;   // false if the cable is pulled
  if (fresh) {
    int[] r = raw;
    if (calibrating) calibrate(r);

    lx = axis(r[0], centre[0], INVERT_LX);
    ly = axis(r[1], centre[1], INVERT_LY);
    rx = axis(r[2], centre[2], INVERT_RX);
    ry = axis(r[3], centre[3], INVERT_RY);

    holdToToggle(r[4] == 1);
    if (live && !calibrating && robot != null) runMouse(r[5] == 1);
    else releaseAll();
  } else {
    releaseAll();                                           // never leave a button stuck down
  }
  drawUI(fresh);
}


// ---------------------------------------------------------------
//  Turn the stick positions into mouse actions
// ---------------------------------------------------------------
void runMouse(boolean middleBtn) {
  // ----- LEFT stick: move the cursor -----
  accX += response(lx) * CURSOR_SPEED;
  accY += response(ly) * CURSOR_SPEED;
  int dx = (int) accX;
  int dy = (int) accY;
  accX -= dx;
  accY -= dy;
  if (dx != 0 || dy != 0) {
    Point p = MouseInfo.getPointerInfo().getLocation();
    robot.mouseMove(p.x + dx, p.y + dy);
  }

  // ----- RIGHT stick: left / right = click, held while pushed so you can drag -----
  leftDown  = setButton(InputEvent.BUTTON1_DOWN_MASK, leftDown,  leftDown  ? rx < -CLICK_OFF : rx < -CLICK_ON);
  rightDown = setButton(InputEvent.BUTTON3_DOWN_MASK, rightDown, rightDown ? rx >  CLICK_OFF : rx >  CLICK_ON);
  midDown   = setButton(InputEvent.BUTTON2_DOWN_MASK, midDown,   middleBtn);

  // ----- RIGHT stick: up / down = scroll (faster the harder you push) -----
  float s = response(ry);
  boolean scrolling = s != 0 && abs(ry) > abs(rx) && !leftDown && !rightDown;
  if (scrolling) {
    int wait = (int) lerp(SCROLL_SLOW, SCROLL_FAST, abs(s));
    if (millis() - lastScroll >= wait) {
      robot.mouseWheel(s < 0 ? -1 : 1);                     // -1 = scroll up, +1 = scroll down
      lastScroll = millis();
    }
  }
}


// raw 0..1023  ->  -1..+1 around the calibrated centre
float axis(int value, float mid, boolean invert) {
  float v = constrain((value - mid) / 512.0, -1, 1);
  return invert ? -v : v;
}

// dead zone + response curve: smooth, controllable speed (returns -1..+1)
float response(float v) {
  float m = abs(v);
  if (m < DEADZONE) return 0;
  m = (m - DEADZONE) / (1 - DEADZONE);
  return (v < 0 ? -1 : 1) * pow(m, CURVE);
}

boolean setButton(int mask, boolean isDown, boolean want) {
  if (want && !isDown) robot.mousePress(mask);
  if (!want && isDown) robot.mouseRelease(mask);
  return want;
}

void releaseAll() {
  if (robot == null) return;
  leftDown  = setButton(InputEvent.BUTTON1_DOWN_MASK, leftDown,  false);
  rightDown = setButton(InputEvent.BUTTON3_DOWN_MASK, rightDown, false);
  midDown   = setButton(InputEvent.BUTTON2_DOWN_MASK, midDown,   false);
}


// Average ~0.75 s of samples to find where the sticks rest.
void calibrate(int[] r) {
  for (int i = 0; i < 4; i++) calSum[i] += r[i];
  calCount++;
  if (calCount >= 45) {
    for (int i = 0; i < 4; i++) centre[i] = calSum[i] / calCount;
    calibrating = false;
  }
}

void startCalibration() {
  calibrating = true;
  calCount = 0;
  calSum = new float[4];
}


// Hold the left stick button for 1 s to pause / resume.
void holdToToggle(boolean pressed) {
  if (!pressed) {
    holdStart = -1;
    holdDone = false;
    return;
  }
  if (holdStart < 0) holdStart = millis();
  if (!holdDone && millis() - holdStart >= 1000) {
    live = !live;
    holdDone = true;
  }
}


void keyPressed() {
  if (port == null) {                              // choosing a port
    int i = key - '0';
    if (i >= 0 && i < min(ports.length, 10)) connect(i);
    return;
  }
  if (key == ' ') live = !live;
  if (key == 'c' || key == 'C') startCalibration();
}


void exit() {
  releaseAll();
  super.exit();
}


// ---------------------------------------------------------------
//  Window: connection status + live view of both sticks
// ---------------------------------------------------------------
void drawUI(boolean fresh) {
  textAlign(LEFT, TOP);
  fill(255);
  textSize(18);
  text("Dual-Joystick Mouse", 20, 14);
  textSize(13);

  if (port == null) {                              // not connected yet: choose the Arduino's port
    fill(255, 180, 60);
    text(error.length() > 0 ? error : "Press the number of your Arduino's port:", 20, 48);
    fill(220);
    if (ports.length == 0) text("No serial ports found. Plug in the Arduino, then restart.", 20, 80);
    for (int i = 0; i < min(ports.length, 10); i++) text(i + ":  " + ports[i], 20, 80 + 20 * i);
    return;
  }

  fill(150);
  textAlign(RIGHT, TOP);
  text(portName, width - 20, 20);
  textAlign(LEFT, TOP);

  String state;
  int c = color(255, 180, 60);
  if (robot == null) {
    state = "Can't control the mouse on this system (see the console)";
    c = color(255, 90, 90);
  } else if (!gotData) {
    state = "Waiting for the Arduino (sketch uploaded? 115200 baud?)";
  } else if (!fresh) {
    state = "Lost the Arduino - check the USB cable";
  } else if (calibrating) {
    state = "Calibrating - keep your hands off the sticks...";
  } else if (live) {
    state = "LIVE - the mouse is ON";
    c = color(80, 220, 120);
  } else {
    state = "PAUSED - check the dots, then press SPACE";
  }
  fill(c);
  text(state, 20, 46);

  drawStick("LEFT stick: cursor", 40, 95, lx, ly);
  drawStick("RIGHT stick: scroll / click", 290, 95, rx, ry);

  String act = "";                                 // what the right stick is doing right now
  if (rx < -CLICK_ON)      act = "LEFT CLICK";
  else if (rx > CLICK_ON)  act = "RIGHT CLICK";
  else if (abs(ry) > abs(rx) && response(ry) != 0) act = (ry < 0) ? "SCROLL UP" : "SCROLL DOWN";
  fill(80, 200, 255);
  textAlign(CENTER, TOP);
  text(act, 370, 284);

  fill(150);
  textAlign(LEFT, TOP);
  text("SPACE or hold left stick button 1 s: pause / resume", 20, 312);
  text("C: recalibrate the centre (hands off the sticks)", 20, 330);
}

void drawStick(String label, float x, float y, float nx, float ny) {
  float s = 160;
  stroke(80);
  noFill();
  rect(x, y, s, s);
  line(x + s / 2, y, x + s / 2, y + s);
  line(x, y + s / 2, x + s, y + s / 2);
  noStroke();
  fill(80, 200, 255);
  ellipse(x + s / 2 + nx * s / 2, y + s / 2 + ny * s / 2, 16, 16);
  fill(200);
  textAlign(CENTER, TOP);
  text(label, x + s / 2, y + s + 8);
  textAlign(LEFT, TOP);
}
