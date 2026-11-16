/*
  DUAL-JOYSTICK MOUSE  -  Arduino side
  ------------------------------------
  Reads two analog joysticks and streams the values to the PC over USB.
  The Processing sketch turns that stream into real mouse movement.

  WIRING   (both joysticks:  +5V -> 5V,  GND -> GND)

      LEFT stick  (cursor)           RIGHT stick  (scroll / clicks)
        VRx -> A0                      VRx -> A2
        VRy -> A1                      VRy -> A3
        SW  -> D2                      SW  -> D3

  OUTPUT  (115200 baud, about 100 lines per second):

      leftX,leftY,rightX,rightY,leftButton,rightButton
      axes: 0..1023        buttons: 1 = pressed, 0 = released

  Tip: Serial Monitor at 115200 baud should show lines like
      512,510,515,509,0,0
  Close the Serial Monitor before starting the Processing sketch,
  because only one program can use the USB port at a time.
*/

const int LEFT_X   = A0;
const int LEFT_Y   = A1;
const int LEFT_SW  = 2;

const int RIGHT_X  = A2;
const int RIGHT_Y  = A3;
const int RIGHT_SW = 3;

void setup() {
  Serial.begin(115200);
  pinMode(LEFT_SW,  INPUT_PULLUP);   // the button connects the pin to GND when pressed
  pinMode(RIGHT_SW, INPUT_PULLUP);
}

// The first reading after switching analog pins can be slightly off,
// so read twice and keep the second value.
int readAxis(int pin) {
  analogRead(pin);
  return analogRead(pin);
}

int isPressed(int pin) {
  return digitalRead(pin) == LOW ? 1 : 0;
}

void loop() {
  Serial.print(readAxis(LEFT_X));    Serial.print(',');
  Serial.print(readAxis(LEFT_Y));    Serial.print(',');
  Serial.print(readAxis(RIGHT_X));   Serial.print(',');
  Serial.print(readAxis(RIGHT_Y));   Serial.print(',');
  Serial.print(isPressed(LEFT_SW));  Serial.print(',');
  Serial.println(isPressed(RIGHT_SW));
  delay(10);
}
