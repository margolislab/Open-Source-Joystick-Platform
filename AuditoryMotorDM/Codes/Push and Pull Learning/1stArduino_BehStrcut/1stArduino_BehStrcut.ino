#include <MPR121.h>             // Library for capacitive touch sensor MPR121
#include <Wire.h>               // I2C communication library

//------------------------
// Global Variables
//------------------------

// Random reward parameters
int randNum2;            
int p_Trans = 100;       // (Unused) transition probability parameter
int p_Reward = 100;      // (Unused) reward probability parameter
int NumberOfRewards = 100;  // Maximum number of rewards before changing trial structure

// Pin definitions for sensors and buttons
int ReadLicks = 8;       // Digital pin used for sending a pulse when a lick is detected
int buttonStart = 2;     // Digital input pin for the start button
int ButtonState = 0;     // Variable to store state of start button

int Time_Reward = 44;    // Delay time (in milliseconds) for reward activation


// Variables for tracking states and transitions
int LeftGood = 0;
int RightGood = 0;
int Transition1 = 0;
int Tranistion2 = 0;     // (Note: likely a misspelling of "Transition2")

// Incoming digital signals for push and pull events
const int incoming_Pull = 3;
const int incoming_Push = 12;

// Variables to hold the state of push and pull inputs
int PushState = 0;
int PullState = 0;

unsigned long Time = 0;         // General time variable for delays/timeouts
int TimeChangeState = 0;        // (Unused) variable for state change timing

// Analog sensor pins (e.g., for a joystick or potentiometer)
int sensorPin1 = A1;    // Analog input for sensor 1 (X-axis)
int sensorPin3 = A3;    // Analog input for sensor 2 (Y-axis)

// LED for debugging/indication
int ledPin = 13;      // On-board LED pin
int sensorValue1 = 0; // Variable to store analog value from sensorPin1
int sensorValue3 = 0; // Variable to store analog value from sensorPin3

// Solenoid pins for reward delivery (e.g., activating a valve or motor)
int solenoid_Left = 7;    // Digital output for left solenoid (reward)
int solenoid_Right = 5;   // Digital output for right solenoid (reward)

// Reward and structure counters
int Counter_1 = 0;
int Counter_2 = 0;
int Counter_3 = 0;
int Counter_4 = 0;
int Start = 0;            // Flag indicating if the trial has started
int Structure = 1;        // Variable to manage different trial phases

unsigned long previousMillis = 0;
unsigned long currentMillis2 = 0;
int interval = 1000;      // Interval (in milliseconds) for time-out periods

//------------------------
// Setup Function
//------------------------
void setup() {
  // Initialize serial communications for debugging
  Serial.begin(38400);

  // Set pin modes for outputs and inputs
  pinMode(ledPin, OUTPUT);
  pinMode(solenoid_Left, OUTPUT);
  pinMode(solenoid_Right, OUTPUT);
  pinMode(ReadLicks, OUTPUT);
  pinMode(incoming_Push, INPUT);
  pinMode(incoming_Pull, INPUT);
  // Note: Ensure the start button (buttonStart) is wired correctly (mode may be set externally)

  // Start I2C communication
  Wire.begin();
  
  // Seed the random number generator using an analog pin reading
  randomSeed(analogRead(2));
       
  // MPR121 activation sequence:
  // Use I2C address 0x5A for the MPR121 sensor
  if (!MPR121.begin(0x5A)) {
    Serial.println("error setting up MPR121");
    // Print error details based on the error code from MPR121
    switch (MPR121.getError()) {
      case NO_ERROR:
        Serial.println("no error");
        break;
      case ADDRESS_UNKNOWN:
        Serial.println("incorrect address");
        break;
      case READBACK_FAIL:
        Serial.println("readback failure");
        break;
      case OVERCURRENT_FLAG:
        Serial.println("overcurrent on REXT pin");
        break;
      case OUT_OF_RANGE:
        Serial.println("electrode out of range");
        break;
      case NOT_INITED:
        Serial.println("not initialised");
        break;
      default:
        Serial.println("unknown error");
        break;
    }
    while (1);  // Halt execution if MPR121 initialization fails
  }
  
  // Set up the MPR121 interrupt pin (digital pin 11)
  MPR121.setInterruptPin(11);
  
  // Set the touch threshold (lower value increases sensitivity)
  MPR121.setTouchThreshold(20);
  
  // Set the release threshold (must be lower than the touch threshold)
  MPR121.setReleaseThreshold(10);
  
  // Perform an initial update of touch data
  MPR121.updateTouchData();
}

//------------------------
// Main Loop
//------------------------
void loop() {
  unsigned long currentMillis = millis();  // Get current time in milliseconds
  Time = millis();                         // Update the general time variable
  
  // Read the state of the start button
  ButtonState = digitalRead(buttonStart);
  
  // Ensure both solenoids are turned off at the start of each loop iteration
  digitalWrite(solenoid_Left, LOW);
  digitalWrite(solenoid_Right, LOW);
  
  // If the start button is pressed, set the trial start flag and log the event
  if (ButtonState == HIGH) {
    Start = 1;
    Serial.print(currentMillis); Serial.print("."); Serial.print(50);
    Serial.print("."); Serial.println(1);
  }
 
  // If the trial has started, proceed with sensor readings and reward logic
  if (Start == 1) {
    // Read the current states of the incoming push and pull signals
    PushState = digitalRead(incoming_Push);
    PullState = digitalRead(incoming_Pull);

    // Read analog values from sensors (e.g., joystick/potentiometer)
    sensorValue1 = analogRead(sensorPin1);
    sensorValue3 = analogRead(sensorPin3);

    // Ensure solenoids are off (reinforcing no accidental activation)
    digitalWrite(solenoid_Left, LOW);
    digitalWrite(solenoid_Right, LOW);

    // Process lick inputs using the MPR121 touch sensor
    Licks();
        
    // If the reward counter reaches the set limit, change the trial structure
    if (Counter_1 == NumberOfRewards) {
      Structure = 2;
      Counter_1 = 0;
    }
        
    // Process events when the current trial structure equals 1
    if (Structure == 1) {
      //----- Handle Push Event -----
      if (PushState == HIGH) {
        randNum2 = random(1, 100);
        // Common transition (99% chance)
        if (randNum2 < 99) {
          // Log event details (common transition)
          Serial.print(currentMillis); Serial.print("."); Serial.print(10);
          Serial.print("."); Serial.println(10);
          Serial.print(currentMillis); Serial.print("."); Serial.print(8);
          Serial.print("."); Serial.println(sensorValue1);
          Serial.print(currentMillis); Serial.print("."); Serial.print(15);
          Serial.print("."); Serial.println(Counter_1);
          
          // Deliver reward via the left solenoid
          randNum2 = random(1, 100);
          if (randNum2 < 90) {
            digitalWrite(solenoid_Left, HIGH);
            Serial.print(currentMillis); Serial.print("."); Serial.print(3);
            Serial.print("."); Serial.println(1);
            delay(Time_Reward);
            digitalWrite(solenoid_Left, LOW);
          } else {
            digitalWrite(solenoid_Left, HIGH);
            Serial.print(currentMillis); Serial.print("."); Serial.print(14);
            Serial.print("."); Serial.println(1);
            delay(Time_Reward);
            digitalWrite(solenoid_Left, LOW);
          }
          Counter_1 = Counter_1 + 1;
          // Time-out period: continue processing lick inputs
          Time = millis();
          while (millis() - Time <= interval) {
            Licks();
          }
        }
        // Rare transition branch (1% chance)
        else {
          // Log event details (rare transition)
          Serial.print(currentMillis); Serial.print("."); Serial.print(10);
          Serial.print("."); Serial.println(10);
          Serial.print(currentMillis); Serial.print("."); Serial.print(8);
          Serial.print("."); Serial.println(sensorValue1);
          Serial.print(currentMillis); Serial.print("."); Serial.print(16);
          Serial.print("."); Serial.println(Counter_1);
          
          // Deliver reward via the left solenoid
          randNum2 = random(1, 100);
          if (randNum2 < 90) {
            digitalWrite(solenoid_Left, HIGH);
            Serial.print(currentMillis); Serial.print("."); Serial.print(3);
            Serial.print("."); Serial.println(Structure);
            delay(Time_Reward);
            digitalWrite(solenoid_Left, LOW);
          } else {
            digitalWrite(solenoid_Left, HIGH);
            Serial.print(currentMillis); Serial.print("."); Serial.print(14);
            Serial.print("."); Serial.println(Structure);
            delay(Time_Reward);
            digitalWrite(solenoid_Left, LOW);
          }
          Counter_1 = Counter_1 + 1;
          // Time-out period: process lick inputs
          Time = millis();
          while (millis() - Time <= interval) {
            Licks();
          }
        }
      }
                    
      //----- Handle Pull Event -----
      if (PullState == HIGH) {
        randNum2 = random(1, 100);
        // Common transition (99% chance)
        if (randNum2 < 99) {
          // Log event details (common transition)
          Serial.print(currentMillis); Serial.print("."); Serial.print(20);
          Serial.print("."); Serial.println(20);
          Serial.print(currentMillis); Serial.print("."); Serial.print(9);
          Serial.print("."); Serial.println(sensorValue1);
          Serial.print(currentMillis); Serial.print("."); Serial.print(15);
          Serial.print("."); Serial.println(Counter_1);
          
          // Deliver reward via the left solenoid
          randNum2 = random(1, 100);
          if (randNum2 < 99) {
            digitalWrite(solenoid_Left, HIGH);
            Serial.print(currentMillis); Serial.print("."); Serial.print(3);
            Serial.print("."); Serial.println(Counter_1);
            delay(Time_Reward);
            digitalWrite(solenoid_Left, LOW);
          } else {
            digitalWrite(solenoid_Left, HIGH);
            Serial.print(currentMillis); Serial.print("."); Serial.print(14);
            Serial.print("."); Serial.println(Counter_1);
            delay(Time_Reward);
            digitalWrite(solenoid_Left, LOW);
          }
          Counter_1 = Counter_1 + 1;
          // Time-out period: process lick inputs
          Time = millis();
          while (millis() - Time <= interval) {
            Licks();
          }
        }
        // Rare transition branch (1% chance)
        else {
          // Log event details (rare transition)
          Serial.print(currentMillis); Serial.print("."); Serial.print(20);
          Serial.print("."); Serial.println(20);
          Serial.print(currentMillis); Serial.print("."); Serial.print(9);
          Serial.print("."); Serial.println(sensorValue1);
          Serial.print(currentMillis); Serial.print("."); Serial.print(16);
          Serial.print("."); Serial.println(Counter_1);
          
          // Deliver reward via the left solenoid
          randNum2 = random(1, 100);
          if (randNum2 < 90) {
            digitalWrite(solenoid_Left, HIGH);
            Serial.print(currentMillis); Serial.print("."); Serial.print(13);
            Serial.print("."); Serial.println(Structure);
            delay(Time_Reward);
            digitalWrite(solenoid_Left, LOW);
          } else {
            digitalWrite(solenoid_Left, HIGH);
            Serial.print(currentMillis); Serial.print("."); Serial.print(14);
            Serial.print("."); Serial.println(Structure);
            delay(Time_Reward);
            digitalWrite(solenoid_Left, LOW);
          }
          Counter_1 = Counter_1 + 1;
          // Time-out period: process lick inputs
          Time = millis();
          while (millis() - Time <= interval) {
            Licks();
          }
        }
      }
    }
  }
}

//------------------------
// Function: Licks
// Purpose: Process touch input from the MPR121 sensor and log "lick" events.
// (A "lick" here refers to a contact event detected by the touch electrodes.)
//------------------------
void Licks() {
  unsigned long currentMillis = millis();
  // Check if there has been any change in touch status
  if (MPR121.touchStatusChanged()) {
    // Update the touch data from the sensor
    MPR121.updateTouchData();
    // If electrode 0 registers a new touch event:
    if (MPR121.isNewTouch(0)) {
      Serial.print(currentMillis); Serial.print(".");
      Serial.print(17); Serial.print(".");
      Serial.println(1);
      digitalWrite(ReadLicks, HIGH);
      delay(1);
      digitalWrite(ReadLicks, LOW);
    }
    // If electrode 1 registers a new touch event:
    if (MPR121.isNewTouch(1)) {
      Serial.print(currentMillis); Serial.print(".");
      Serial.print(18); Serial.print(".");
      Serial.println(1);
    }
  }
}

//------------------------
}
