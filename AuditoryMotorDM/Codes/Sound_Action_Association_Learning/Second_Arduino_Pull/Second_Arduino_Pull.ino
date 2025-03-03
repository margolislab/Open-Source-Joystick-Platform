#include <Wire.h>      // I2C Library

// Analog sensor pins (e.g., for a potentiometer or joystick)
int sensorPin1 = A1;    // Input for sensor 1 (X-axis)
int sensorPin3 = A3;    // Input for sensor 2 (Y-axis)

// Global timing variables
unsigned long Time = 0;  
int interval_randomtime = 0;
const unsigned long interval_RJS = 5000; // (Unused) Constant for a fixed interval

// Function prototype for median calculation
int getMedian(int values[], int size);
const int SamplesforMedian = 100;  // Number of samples to compute the median

// Pin definitions for reward and trial signals
const int RewardPin = 7;          // Digital input for reward signal
int RewardState = 0;              // Variable to hold reward pin state

const int Push = 8;               // Digital output for "push" action
const int Pull = 11;              // Digital output for "pull" action

const int StartTrial = 13;        // Digital input for trial start signal
const int EndTrial = 12;          // Digital input for trial end signal
const int SoundIncomingTTL = 10;  // Digital input for receiving sound info (TTL)

// Variables to hold states of various digital inputs
int StartState = 0;
int EndState = 0;
int SoundITTlState = 0;

// "Candado" means "lock" in Spanish; these variables act as flags to control event triggering
int Candado = 0;
int Candado2 = 0;
int Candado3 = 0;
int CandadoSonido = 1;  // "SoundLock": used to impose a grace period for sound-related events

// Other behavioral state variables
int LickState = 0;      // State of the lick sensor (if applicable)
int ButtonState = 0;    // State of the start button
int buttonStart = 2;    // Digital input for the start button

//------------------------
// Variables for Signal Smoothing (Moving Average)
//------------------------

// For X-axis sensor
const int numReadings = 12;       // Number of samples for smoothing (X-axis)
int readings[numReadings];        // Array to store readings for X-axis
int readIndex_X = 0;              // Current index for X-axis array
int total_X = 0;                  // Running total for X-axis readings
int average_X = 0;                // Computed average for X-axis

// For Y-axis sensor
const int numReadings2 = 12;      // Number of samples for smoothing (Y-axis)
int readings2[numReadings2];      // Array to store readings for Y-axis
int readIndex_Y = 0;              // Current index for Y-axis array
int total_Y = 0;                  // Running total for Y-axis readings
int average_Y = 0;                // Computed average for Y-axis

// Variables to store the median baseline values for each sensor
int pot2Median;
int pot1Median;

// (Optional calibration values commented out)
// int PushValue = 506;
// int PushValueYaxis = 517;    
// int PullValue = 499; // (e.g., 494, 509, 498)
// int PullValueYaxis = 511;

// Variables to hold the final smoothed sensor values
int sensorValue1 = 0;  // Smoothed value from sensorPin1
int sensorValue3 = 0;  // Smoothed value from sensorPin3

// Flag indicating if the trial session has started
int Start = 0;

/////////////////////////////////////////////////////////////////////////
// Setup Function: runs once at startup
/////////////////////////////////////////////////////////////////////////
void setup() {
  Serial.begin(500000); // Start serial communication at 500000 baud

  // Configure pin modes
  pinMode(RewardPin, INPUT);
  pinMode(buttonStart, INPUT);
  pinMode(StartTrial, INPUT);
  pinMode(EndTrial, INPUT);
  pinMode(SoundIncomingTTL, INPUT);
  
  pinMode(Push, OUTPUT);
  pinMode(Pull, OUTPUT);
  
  // Initialize outputs to LOW
  digitalWrite(Push, LOW);
  digitalWrite(Pull, LOW);

  // (Optional) Additional initialization for a sound input can be added here.
}

/////////////////////////////////////////////////////////////////////////
// Main Loop: runs repeatedly
/////////////////////////////////////////////////////////////////////////
void loop() {
  unsigned long currentMillis = millis();  // Get the current time

  // Read the state of the start button
  ButtonState = digitalRead(buttonStart);

  // If the start button is pressed, begin the session
  if (ButtonState == HIGH) {
    Start = 1;
    Serial.print(currentMillis); Serial.print("."); Serial.print(50); Serial.print("."); Serial.println(1);
    // Optionally, a sound could be played here (commented out)
    // sfx.playTrack("T06     WAV");

    // Capture a series of samples to compute the median baseline values for smoothing
    unsigned long startTime = millis();
    int pot1Samples[SamplesforMedian];
    int pot2Samples[SamplesforMedian];

    for (int i = 0; i < SamplesforMedian; i++) {
      pot1Samples[i] = analogRead(sensorPin1);
      pot2Samples[i] = analogRead(sensorPin3);
      // A delay here was commented out
      // delay(500);
    }

    // Calculate median values from the samples
    pot1Median = getMedian(pot1Samples, SamplesforMedian);
    pot2Median = getMedian(pot2Samples, SamplesforMedian);

    // (Debug prints for median values are commented out)
    /*
    Serial.print("Pot 1 Basl Value (Median):");
    Serial.println(pot1Median);
    Serial.print("Pot 2 Basl Value (Median):");
    Serial.println(pot2Median);
    delay(4000);
    */

    // (Optional delay to complete the remainder of an interval is commented out)
    // unsigned long elapsedTime = millis() - startTime;
    // if (elapsedTime < interval_RJS) {
    //   delay(interval_RJS - elapsedTime);
    // }
  }

  // Once the session has started, continuously process trial events
  while (Start == 1) {
    // (Analog sensor readings are updated in the Joystick() function)
    RewardState = digitalRead(RewardPin);
    StartState = digitalRead(StartTrial);
    EndState = digitalRead(EndTrial);
    SoundITTlState = digitalRead(SoundIncomingTTL);

    // Update the joystick sensor values (smoothing is applied)
    Joystick();
    currentMillis = millis();  // Update time after processing joystick

    // If the trial start signal is detected and a lock flag (Candado2) is not set,
    // log the event and set lock flags.
    if (StartState == HIGH && Candado2 == 0) {
      Serial.print(currentMillis); Serial.print("."); Serial.print(10); Serial.print("."); Serial.println(1);
      delay(100);
      Candado = 1;
      Candado2 = 1;
      Candado3 = 1;
      Joystick();  // Update sensor readings again
    }

    // When a sound TTL signal is received and lock flag (Candado3) is active:
    // This branch creates a grace period imposed by the sound card.
    if (SoundITTlState == HIGH && Candado3 == 1) {
      Serial.print(currentMillis); Serial.print("."); Serial.print(30); Serial.print("."); Serial.println(1);
      delay(50);
      Interval();  // Wait for a fixed interval (grace period)
      CandadoSonido = 1;
      Candado3 = 0;
    }
 
    // If sensor values indicate a push action:
    // Condition: sensorValue1 is at least 43 units below its median and sensorValue3 is at or below its median,
    // and the event lock (Candado) and sound lock (CandadoSonido) are active.
    if (sensorValue1 <= pot1Median - 43 && sensorValue3 <= pot2Median && Candado == 1 && CandadoSonido == 1) {
      Joystick();
      digitalWrite(Push, HIGH);
      Serial.print(currentMillis); Serial.print("."); Serial.print(55); Serial.print("."); Serial.println(1);
      delay(100);
      digitalWrite(Push, LOW);
      // Uncommenting the following line would reset the lock flag, but it is left commented intentionally.
      // Candado = 0;
      CandadoSonido = 0;  // Reset sound lock after a push action
    }
    // If sensor values indicate a pull action:
    // Condition: sensorValue1 is at or above its median and sensorValue3 is at least 3 units above its median.
    if (sensorValue1 >= pot1Median && sensorValue3 >= pot2Median + 3 && Candado == 1 && CandadoSonido == 1) {
      Joystick();
      digitalWrite(Pull, HIGH);
      Serial.print(currentMillis); Serial.print("."); Serial.print(66); Serial.print("."); Serial.println(1);
      delay(100);
      digitalWrite(Pull, LOW);
      // Reset sound lock after a pull action.
      CandadoSonido = 0;
    }

    // If the trial end signal is detected and the lock flag is set:
    if (EndState == HIGH && Candado2 == 1) {
      Serial.print(currentMillis); Serial.print("."); Serial.print(10); Serial.print("."); Serial.println(2);
      delay(50);
      // Reset all lock flags.
      Candado = 0;
      Candado2 = 0;
      CandadoSonido = 0;
    }                                           

    // If a reward signal is detected (e.g., LED indicator for reward),
    // log the reward event.
    if (RewardState == HIGH) {
      Serial.print(currentMillis); Serial.print("."); Serial.print(3); Serial.print("."); Serial.println(1);
    }
  } // End while(Start==1)
}

/////////////////////////////////////////////////////////////////////////
// Function: getMedian
// Purpose: Calculate and return the median value from an array of integers.
// The function sorts the array using a simple bubble sort algorithm.
/////////////////////////////////////////////////////////////////////////
int getMedian(int values[], int size) {
  // Sort the array
  for (int i = 0; i < size - 1; i++) {
    for (int j = i + 1; j < size; j++) {
      if (values[i] > values[j]) {
        int temp = values[i];
        values[i] = values[j];
        values[j] = temp;
      }
    }
  }
  // Return median value depending on even/odd number of samples
  if (size % 2 == 0) {
    return (values[size / 2 - 1] + values[size / 2]) / 2;
  } else {
    return values[size / 2];
  }
}

/////////////////////////////////////////////////////////////////////////
// Function: Joystick
// Purpose: Smooth the analog sensor signals using a moving average filter.
// It subtracts the oldest reading, adds the new reading, and then calculates the average.
/////////////////////////////////////////////////////////////////////////
void Joystick() {
  unsigned long currentMillis = millis();

  // Subtract the oldest reading from the running totals
  total_X = total_X - readings[readIndex_X];
  total_Y = total_Y - readings2[readIndex_Y];
  
  // Read the new values from the sensors
  readings[readIndex_X] = analogRead(sensorPin1);
  readings2[readIndex_Y] = analogRead(sensorPin3);
  
  // Add the new readings to the totals
  total_X = total_X + readings[readIndex_X];
  total_Y = total_Y + readings2[readIndex_Y];
  
  // Move to the next index (wrap around if at end of array)
  readIndex_X = (readIndex_X + 1) % numReadings;
  readIndex_Y = (readIndex_Y + 1) % numReadings2;
  
  // Calculate the moving average for each sensor
  average_X = total_X / numReadings;
  average_Y = total_Y / numReadings2;
  
  // Update global sensor values with the smoothed averages
  sensorValue1 = average_X;
  sensorValue3 = average_Y;
  
  // Log the smoothed sensor values to Serial (for debugging)
  Serial.print(currentMillis); Serial.print("."); Serial.print(1); Serial.print("."); Serial.println(sensorValue1);
  Serial.print(currentMillis); Serial.print("."); Serial.print(2); Serial.print("."); Serial.println(sensorValue3);
  
  // Optionally, raw joystick values can be printed here (currently commented out)
  /*
  Serial.print("JS_X:");
  Serial.print(average_X);
  Serial.print(",");
  Serial.print("JS_Y:");
  Serial.println(average_Y);
  delay(20);
  */
}

/////////////////////////////////////////////////////////////////////////
// Function: Interval
// Purpose: Wait for a fixed time interval (here, 1000 ms) while continuously 
// updating the joystick readings. This is used as a grace period imposed by the sound card.
/////////////////////////////////////////////////////////////////////////
void Interval() {
  Time = millis();
  interval_randomtime = 1000;  // Set the interval to 1000 ms
  while ((unsigned long)millis() - Time <= interval_randomtime) {
    Joystick();
  }
}