 //#include <Adafruit_MPR121.h>  // (Optional) Library for MPR121 touch sensor (currently not used)
#include <Wire.h>      // Include I2C communication library

// Analog sensor pins for potentiometers (e.g., joystick X and Y)
int sensorPin1 = A1;    // Input for potentiometer 1 (X-axis)
int sensorPin3 = A3;    // Input for potentiometer 2 (Y-axis)
int interval_randomtime = 0;  // Variable for random timing intervals (unused here)

// Digital input/output pins for behavioral events
const int LickPin = 7;          // Digital input for lick detection
unsigned long Time = 0;         // Global time variable for delays
const int Push = 8;             // Digital output for "push" action
const int Pull = 11;            // Digital output for "pull" action

// Trial control pins: used to signal start/end of a trial and incoming sound TTL
const int StartTrial = 13;      // Digital input for trial start 
const int EndTrial = 12;        // Digital input for trial end 
const int SoundIncomingTTL = 10;// Digital input for incoming sound TTL signal

// Variables for storing digital input states
int StartState = 0;
int EndState = 0;
int SoundITTlState = 0;

// "Candado" means "lock" in Spanish. These variables act as flags to prevent repeated actions.
int Candado = 0;
int Candado2 = 0;
int Candado3 = 0;

int LickState = 0;        // State of the lick sensor
int ButtonState = 0;      // State of the start button
int buttonStart = 2;      // Digital input for the start button

// Function prototype to compute the median from an array of samples
int getMedian(int values[], int size);
const int SamplesforMedian = 100;  // Number of samples to use for median filtering

// Variables and arrays for smoothing sensor readings using a moving average

// For X-axis sensor:
const int numReadings = 12;     // Number of readings for moving average (X-axis)
int readings[numReadings];      // Array to hold readings for X-axis
int readIndex_X = 0;            // Current index for X-axis readings
int total_X = 0;                // Running total for X-axis readings
int average_X = 0;              // Computed average for X-axis

// For Y-axis sensor:
const int numReadings2 = 12;    // Number of readings for moving average (Y-axis)
int readings2[numReadings2];    // Array to hold readings for Y-axis
int readIndex_Y = 0;            // Current index for Y-axis readings
int total_Y = 0;                // Running total for Y-axis readings
int average_Y = 0;              // Computed average for Y-axis

// Variables to store the median values (baseline thresholds) of each potentiometer
int pot2Median;
int pot1Median;

// Calibration values (original comment noted: "10 values are closed to 1mm displacement")
// Current calibration values used in the code:
int PushValue = 511;
int PushValueYaxis = 514;
int PullValue = 300;
int PullValueYaxis = 300;

int sensorValue1 = 0;  // Smoothed sensor value from sensorPin1 (X-axis)
int sensorValue3 = 0;  // Smoothed sensor value from sensorPin3 (Y-axis)

int Start = 0;       // Flag indicating that the trial has started

//------------------------------------------------------
// Setup function: runs once at startup
//------------------------------------------------------
void setup() {
  Serial.begin(500000); // Initialize serial communication at 500000 baud

  // Set the pin modes for inputs and outputs
  pinMode(LickPin, INPUT);
  pinMode(buttonStart, INPUT);
  pinMode(StartTrial, INPUT);
  pinMode(EndTrial, INPUT);
  pinMode(SoundIncomingTTL, INPUT);
  pinMode(Push, OUTPUT);
  pinMode(Pull, OUTPUT);

  // Initialize push and pull outputs to LOW
  digitalWrite(Push, LOW);
  digitalWrite(Pull, LOW);

  // Initialize the X-axis readings array with zeros
  for (int i = 0; i < numReadings; i++) {
    readings[i] = 0;
  }
  
  // (Optional) Additional initialization for sound input can be added here
  // pinMode(SoundWN, INPUT);
}

//------------------------------------------------------
// Main loop: runs repeatedly
//------------------------------------------------------
void loop() {
  // Get the current time in milliseconds
  unsigned long currentMillis = millis();

  // Read the state of the start button
  ButtonState = digitalRead(buttonStart);

  // If the start button is pressed, begin the trial sequence
  if (ButtonState == HIGH) {
    Start = 1;
    // Log trial start event (format: timestamp.eventCode.value)
    Serial.print(currentMillis); Serial.print("."); Serial.print(50); Serial.print("."); Serial.println(1);
    // Example: sfx.playTrack("T06     WAV");  // Trigger a sound effect (currently commented out)

    // Capture multiple samples to determine the baseline (median) for each sensor
    int pot1Samples[SamplesforMedian];
    int pot2Samples[SamplesforMedian];
    for (int i = 0; i < SamplesforMedian; i++) {
      pot1Samples[i] = analogRead(sensorPin1);
      pot2Samples[i] = analogRead(sensorPin3);
    }
    // Calculate median values to use as baseline thresholds
    pot1Median = getMedian(pot1Samples, SamplesforMedian);
    pot2Median = getMedian(pot2Samples, SamplesforMedian);

    // Main trial loop: continues as long as the Start flag is true
    while (Start == 1) {
      // Read current sensor values and digital states
      sensorValue1 = analogRead(sensorPin1);
      sensorValue3 = analogRead(sensorPin3);
      LickState = digitalRead(LickPin);
      StartState = digitalRead(StartTrial);
      EndState = digitalRead(EndTrial);
      SoundITTlState = digitalRead(SoundIncomingTTL);

      // Update the smoothed sensor values using a moving average and log them
      Joystick();
      currentMillis = millis();  // Update current time
      

      // Set the lock flag to allow one action per cycle
      Candado = 1;

      // Check for a "push" event:
      // If the X-axis sensor value is slightly below its baseline (median minus 4 units)
      // and the Y-axis sensor is at or below its baseline, then execute the push action.
      if (sensorValue1 <= pot1Median - 4 && sensorValue3 <= pot2Median && Candado == 1) {
        Joystick();           // Update joystick values
        Candado = 0;          // Lock to prevent immediate repeated action
        digitalWrite(Push, HIGH);  // Activate push output
        Serial.print(currentMillis); Serial.print("."); Serial.print(55); Serial.print("."); Serial.println(1); 
        delay(40);            // Brief delay while push is active
        digitalWrite(Push, LOW);   // Deactivate push output
        
        // Wait for 3000 ms while continuously updating joystick values
        Time = millis();
        while (millis() - Time <= 3000) {
          Joystick();
        }
      }
      
      // Check for a "pull" event:
      // If the X-axis sensor value is at or above its baseline and the Y-axis sensor value 
      // is significantly above its baseline (by 70 units), then execute the pull action.
      if (sensorValue1 >= pot1Median && sensorValue3 >= pot2Median + 70 && Candado == 1) {
        Joystick();           // Update joystick values
        Candado = 0;          // Lock to prevent immediate repeated action
        digitalWrite(Pull, HIGH);  // Activate pull output
        Serial.print(currentMillis); Serial.print("."); Serial.print(66); Serial.print("."); Serial.println(1); 
        delay(40);            // Brief delay while pull is active
        digitalWrite(Pull, LOW);   // Deactivate pull output
        
        // Wait for 3000 ms while continuously updating joystick values
        Time = millis();
        while (millis() - Time <= 3000) {
          Joystick();
        }
      }
      

      // Check if the lick sensor is activated; if so, log the event
      if (LickState == HIGH) {
        Serial.print(currentMillis); Serial.print("."); Serial.print(17); Serial.print("."); Serial.println(1);
      }
      // (No action is taken when the lick sensor is not active)
    }
  }
}

//------------------------------------------------------
// Function: getMedian
// Purpose: Calculate the median of an array of integer values.
// The function sorts the array and returns the median value.
//------------------------------------------------------
int getMedian(int values[], int size) {
  // Sort the array using a simple bubble sort algorithm
  for (int i = 0; i < size - 1; i++) {
    for (int j = i + 1; j < size; j++) {
      if (values[i] > values[j]) {
        int temp = values[i];
        values[i] = values[j];
        values[j] = temp;
      }
    }
  }

  // Calculate and return the median
  if (size % 2 == 0) {
    return (values[size / 2 - 1] + values[size / 2]) / 2;
  } else {
    return values[size / 2];
  }
}

//------------------------------------------------------
// Function: Joystick
// Purpose: Smooth the analog sensor readings for both X and Y axes using a moving average filter.
//          The function updates the sensor values and logs them via serial.
//------------------------------------------------------
void Joystick() {
  unsigned long currentMillis = millis();

  // Subtract the oldest reading from the totals
  total_X = total_X - readings[readIndex_X];
  total_Y = total_Y - readings2[readIndex_Y];
  
  // Read new sensor values from the analog inputs
  readings[readIndex_X] = analogRead(sensorPin1);
  readings2[readIndex_Y] = analogRead(sensorPin3);
  
  // Add the new readings to the totals
  total_X = total_X + readings[readIndex_X];
  total_Y = total_Y + readings2[readIndex_Y];
  
  // Advance to the next index in the arrays
  readIndex_X++;
  readIndex_Y++;
  
  // Wrap around to the beginning of the arrays if the end is reached
  if (readIndex_X >= numReadings) {
    readIndex_X = 0;
  }
  if (readIndex_Y >= numReadings2) {
    readIndex_Y = 0;
  }
  
  // Calculate the moving averages for both sensors
  average_X = total_X / numReadings;
  average_Y = total_Y / numReadings2;
  
  // Update the sensor values with the computed averages
  sensorValue1 = average_X;
  sensorValue3 = average_Y;
  
  // Log the smoothed sensor values via serial with timestamps
  Serial.print(currentMillis); Serial.print("."); Serial.print(1); Serial.print("."); Serial.println(sensorValue1);
  Serial.print(currentMillis); Serial.print("."); Serial.print(2); Serial.print("."); Serial.println(sensorValue3);
  
  // (Optional) Debugging prints are commented out below:
  // Serial.print("JS_X:");
  // Serial.print(average_X);
  // Serial.print(",");
  // Serial.print("JS_Y:");
  // Serial.println(average_Y);
  // delay(20);
}

//------------------------------------------------------
// Function: Interval
// Purpose: Maintain a delay interval while continuously updating joystick readings.
//------------------------------------------------------
void Interval() {
  Time = millis();
  interval_randomtime = 1000;  // Set the interval duration to 1000 ms
  while (millis() - Time <= interval_randomtime) {
    Joystick();  // Continuously update joystick values during the interval
  }
}
