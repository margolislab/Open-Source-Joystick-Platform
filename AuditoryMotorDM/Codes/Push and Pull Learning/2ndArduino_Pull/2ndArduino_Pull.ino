  //#include <Adafruit_MPR121.h>

  #include <Wire.h>      // Include I2C communication library

// Define analog sensor input pins (potentiometers)
int sensorPin1 = A1;    // Input for potentiometer 1 (X-axis)
int sensorPin3 = A3;    // Input for potentiometer 2 (Y-axis)

// Interval variable for random timing (unused in this version)
int interval_randomtime = 0;

// Define digital pins for behavioral events and outputs
const int LickPin = 7;          // Digital input for lick detection
unsigned long Time = 0;         // Global time variable for delays
const int Push = 8;             // Digital output for "push" action
const int Pull = 11;            // Digital output for "pull" action

// Trial control digital pins
const int StartTrial = 13;      // Digital input to signal start of trial (original comment: "TrailStart From A0 Input")
const int EndTrial = 12;        // Digital input to signal end of trial (original comment: "TrailEnd From A1 Input")
const int SoundIncomingTTL = 10;// Digital input for incoming sound TTL signal

// Variables to store the state of various inputs
int StartState = 0;
int EndState = 0;
int SoundITTlState = 0;

// "Candado" means "lock" in Spanish. These variables serve as locks/flags to control state changes.
int Candado = 0;
int Candado2 = 0;
int Candado3 = 0;

// Variables for lick sensor and start button states
int LickState = 0;
int ButtonState = 0;
int buttonStart = 2;          // Digital input for a start button

// Function prototype to compute the median from an array of samples
int getMedian(int values[], int size);
const int SamplesforMedian = 100; // Number of samples to use for median filtering

// Variables and arrays for smoothing analog readings (moving average) for the X-axis sensor
const int numReadings = 12;     // Number of readings for smoothing (X-axis)
int readings[numReadings];      // Array to hold readings for X-axis
int readIndex_X = 0;            // Current index in the readings array (X-axis)
int total_X = 0;                // Running total of X-axis readings
int average_X = 0;              // Computed average for X-axis

// Variables and arrays for smoothing analog readings (moving average) for the Y-axis sensor
const int numReadings2 = 12;    // Number of readings for smoothing (Y-axis)
int readings2[numReadings2];    // Array to hold readings for Y-axis
int readIndex_Y = 0;            // Current index in the readings array (Y-axis)
int total_Y = 0;                // Running total of Y-axis readings
int average_Y = 0;              // Computed average for Y-axis

// Variables to store median values for each potentiometer (used as baseline thresholds)
int pot2Median;
int pot1Median;

// Calibration values 
// Note: "10 values are close 1mm displacement" 
int PushValue = 511;
int PushValueYaxis = 514;  
int PullValue = 300; 
int PullValueYaxis = 300;

// Variables to store the current sensor values after smoothing
int sensorValue1 = 0;  // Smoothed sensor value from sensorPin1 (X-axis)
int sensorValue3 = 0;  // Smoothed sensor value from sensorPin3 (Y-axis)

int Start = 0;       // Flag to indicate if the trial has started

//------------------------------------------------------
// Setup function: runs once at startup
//------------------------------------------------------
void setup() {
  Serial.begin(500000); // Initialize serial communication at 500000 baud

  // Set pin modes for inputs and outputs
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

  // Initialize the readings array for the X-axis sensor to zero
  for (int i = 0; i < numReadings; i++) {
    readings[i] = 0;
  }
  
}

//------------------------------------------------------
// Main loop: runs repeatedly
//------------------------------------------------------
void loop() {
  // Get current time in milliseconds
  unsigned long currentMillis = millis();

  // Read the state of the start button
  ButtonState = digitalRead(buttonStart);

  // If the start button is pressed, begin the trial sequence
  if (ButtonState == HIGH) {
    Start = 1;
    // Log the trial start event (format: timestamp.code.value)
    Serial.print(currentMillis); Serial.print("."); Serial.print(50); Serial.print("."); Serial.println(1);
    // Example: sfx.playTrack("T06     WAV");  // Sound effect trigger (currently commented out)

    // Collect multiple samples to determine the baseline (median) for each sensor
    int pot1Samples[SamplesforMedian];
    int pot2Samples[SamplesforMedian];
    for (int i = 0; i < SamplesforMedian; i++) {
      pot1Samples[i] = analogRead(sensorPin1);
      pot2Samples[i] = analogRead(sensorPin3);
    }
    // Calculate median values to smooth the baseline readings
    pot1Median = getMedian(pot1Samples, SamplesforMedian);
    pot2Median = getMedian(pot2Samples, SamplesforMedian);

    // Main trial loop: remains active while Start flag is true
    while (Start == 1) {
      // Read current analog sensor values and digital states
      sensorValue1 = analogRead(sensorPin1);
      sensorValue3 = analogRead(sensorPin3);
      LickState = digitalRead(LickPin);
      StartState = digitalRead(StartTrial);
      EndState = digitalRead(EndTrial);
      SoundITTlState = digitalRead(SoundIncomingTTL);

      // Update joystick (smoothed sensor) values and log them
      Joystick();
      currentMillis = millis();  // Update current time

      // Set the lock variable to allow one action per event
      Candado = 1;

      // Check for a "push" event:
      // If the X sensor value is at least 50 units below its median and the Y sensor is at or below its median,
      // then execute the push action.
      if (sensorValue1 <= pot1Median - 50 && sensorValue3 <= pot2Median && Candado == 1) {
        Joystick();           // Update joystick readings again
        Candado = 0;          // Lock to prevent repeat action immediately
        digitalWrite(Push, HIGH);  // Activate push output
        Serial.print(currentMillis); Serial.print("."); Serial.print(55); Serial.print("."); Serial.println(1); 
        delay(40);            // Brief delay while push is active
        digitalWrite(Push, LOW);   // Deactivate push output
        
        // Wait for 2000 ms while continuing to update joystick values
        Time = millis();
        while (millis() - Time <= 2000) {
          Joystick();
        }
      }
      
      // Check for a "pull" event:
      // If the X sensor value is at or above its median and the Y sensor is at least 4 units above its median,
      // then execute the pull action.
      if (sensorValue1 >= pot1Median && sensorValue3 >= pot2Median + 4 && Candado == 1) {
        Joystick();           // Update joystick readings again
        Candado = 0;          // Lock to prevent repeat action immediately
        digitalWrite(Pull, HIGH);  // Activate pull output
        Serial.print(currentMillis); Serial.print("."); Serial.print(66); Serial.print("."); Serial.println(1); 
        delay(40);            // Brief delay while pull is active
        digitalWrite(Pull, LOW);   // Deactivate pull output
        
        // Wait for 2000 ms while continuing to update joystick values
        Time = millis();
        while (millis() - Time <= 2000) {
          Joystick();
        }
      }
      
      // --- Commented-out code for handling trial end ---
      // if (EndState == HIGH && Candado2 == 1) {
      //     Serial.print(currentMillis); Serial.print("."); Serial.print(10); Serial.print("."); Serial.println(2);
      //     delay(50); 
      //     Candado = 0; 
      //     Candado2 = 0; 
      // }

      // Check if the lick sensor is activated; log the event if true
      if (LickState == HIGH) {
        Serial.print(currentMillis); Serial.print("."); Serial.print(17); Serial.print("."); Serial.println(1);
      }
      // (Else branch is empty, meaning no action when the lick sensor is off)
    }
  }
}

//------------------------------------------------------
// Function: getMedian
// Purpose: Calculate the median of an integer array.
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
// Purpose: Smooth the analog readings for both sensors (X and Y) using a moving average.
//          The function updates the smoothed sensor values and logs them via serial.
//------------------------------------------------------
void Joystick() {
  unsigned long currentMillis = millis();

  // Subtract the oldest readings from the totals
  total_X = total_X - readings[readIndex_X];
  total_Y = total_Y - readings2[readIndex_Y];
  
  // Read new sensor values and store them in the arrays
  readings[readIndex_X] = analogRead(sensorPin1);
  readings2[readIndex_Y] = analogRead(sensorPin3);
  
  // Add the new readings to the totals
  total_X = total_X + readings[readIndex_X];
  total_Y = total_Y + readings2[readIndex_Y];
  
  // Advance to the next position in the arrays
  readIndex_X++;
  readIndex_Y++;
  
  // Wrap around to the beginning of the array if needed
  if (readIndex_X >= numReadings) {
    readIndex_X = 0;
  }
  if (readIndex_Y >= numReadings2) {
    readIndex_Y = 0;
  }

  // Calculate the moving average for both sensors
  average_X = total_X / numReadings;
  average_Y = total_Y / numReadings2;
  
  // Update the sensor values with the smoothed (averaged) readings
  sensorValue1 = average_X;
  sensorValue3 = average_Y;
  
  // Log the smoothed sensor values via serial
  Serial.print(currentMillis); Serial.print("."); Serial.print(1); Serial.print("."); Serial.println(sensorValue1);
  Serial.print(currentMillis); Serial.print("."); Serial.print(2); Serial.print("."); Serial.println(sensorValue3);
  
  // (Optional debugging prints commented out below)
  // Serial.print("JS_X:");
  // Serial.print(average_X);
  // Serial.print(",");
  // Serial.print("JS_Y:");
  // Serial.println(average_Y);
  // delay(20);
}

//------------------------------------------------------
// Function: Interval
// Purpose: Maintain a delay period while continuously updating joystick readings.
//------------------------------------------------------
void Interval() {
  Time = millis();
  interval_randomtime = 1000;  // Set interval duration to 1000 ms
  while (millis() - Time <= interval_randomtime) {
    Joystick();  // Continuously update joystick values during the interval
  }
}