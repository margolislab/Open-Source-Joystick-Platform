//#include <Adafruit_MPR121.h>

#include <Wire.h>      // Include I2C communication library

// Define analog sensor pins (e.g., for a joystick or potentiometer)
int sensorPin1 = A1;    // Analog input for sensor 1 (X-axis)
int sensorPin3 = A3;    // Analog input for sensor 2 (Y-axis)

// Global timing variables
unsigned long Time = 0;  
int interval_randomtime = 0;
const unsigned long interval_RJS = 5000;  // (Unused) Fixed interval constant

// Function prototype for median calculation
int getMedian(int values[], int size);
const int SamplesforMedian = 100;  // Number of samples to compute the median

// Pin definitions for trial and reward signals
const int RewardPin = 7;             // Digital input for reward signal
int RewardState = 0;                 // Variable to store reward pin state

const int Push = 8;                  // Digital output for "push" action
const int Pull = 11;                 // Digital output for "pull" action

const int StartTrial = 13;           // Digital input for trial start signal
const int EndTrial = 12;             // Digital input for trial end signal
const int SoundIncomingTTL = 10;     // Digital input for receiving sound information (TTL)

// Variables for storing the state of digital signals
int StartState = 0;
int EndState = 0;
int SoundITTlState = 0;

// "Candado" means "lock" in Spanish. These flags prevent repeated triggering.
// CandadoSonido: sound lock (grace period imposed by the sound card)
int Candado = 0;
int Candado2 = 0;
int Candado3 = 0;
int CandadoSonido = 1;

int LickState = 0;      // (Optional) State for lick detection if used
int ButtonState = 0;    // State of the start button
int buttonStart = 2;    // Digital input for the start button

//---------------------------------------------------------------------
// Variables for signal smoothing using a moving average filter
//---------------------------------------------------------------------

// For the X-axis sensor:
const int numReadings = 12;          // Number of readings for smoothing (X-axis)
int readings[numReadings];           // Array to store X-axis readings
int readIndex_X = 0;                 // Current index for X-axis array
int total_X = 0;                     // Running total of X-axis readings
int average_X = 0;                   // Computed average for X-axis

// For the Y-axis sensor:
const int numReadings2 = 12;         // Number of readings for smoothing (Y-axis)
int readings2[numReadings2];         // Array to store Y-axis readings
int readIndex_Y = 0;                 // Current index for Y-axis array
int total_Y = 0;                     // Running total of Y-axis readings
int average_Y = 0;                   // Computed average for Y-axis

// Baseline median values for each sensor
int pot2Median;
int pot1Median;

// Variables to hold the smoothed sensor values
int sensorValue1 = 0;  // Smoothed value from sensorPin1
int sensorValue3 = 0;  // Smoothed value from sensorPin3

// Flag to indicate when the trial session has started
int Start = 0;

////////////////////////////////////////////////////////////////////////
// Setup Function: runs once at startup
////////////////////////////////////////////////////////////////////////
void setup() {
  Serial.begin(500000);  // Initialize serial communication at 500000 baud

  // Configure pin modes for inputs and outputs
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

  // (Optional) Pin for sound noise input is commented out
}

////////////////////////////////////////////////////////////////////////
// Main Loop: runs repeatedly
////////////////////////////////////////////////////////////////////////
void loop() {
  unsigned long currentMillis = millis();  // Get current time in milliseconds

  // Read start button state
  ButtonState = digitalRead(buttonStart);

  // If the start button is pressed, begin the session
  if (ButtonState == HIGH) {
    Start = 1;
    // Log start event: Format -> timestamp.50.1
    Serial.print(currentMillis); Serial.print("."); Serial.print(50); Serial.print("."); Serial.println(1);
    // (Optional) Play a sound (commented out)

    // Collect samples to compute median baseline for smoothing:
    unsigned long startTime = millis();
    int pot1Samples[SamplesforMedian];
    int pot2Samples[SamplesforMedian];

    for (int i = 0; i < SamplesforMedian; i++) {
      pot1Samples[i] = analogRead(sensorPin1);
      pot2Samples[i] = analogRead(sensorPin3);
      // A delay here was commented out.
    }

    // Compute the median baseline values for each sensor
    pot1Median = getMedian(pot1Samples, SamplesforMedian);
    pot2Median = getMedian(pot2Samples, SamplesforMedian);

    // (Debug prints for median values are commented out)
  }

  // Once the session is started, continuously process trial events.
  while (Start == 1) {
    // Read digital inputs for reward, trial start/end, and sound info.
    RewardState = digitalRead(RewardPin);
    StartState = digitalRead(StartTrial);
    EndState = digitalRead(EndTrial);
    SoundITTlState = digitalRead(SoundIncomingTTL);

    // Update the joystick (smoothed sensor) readings.
    Joystick();
    currentMillis = millis();  // Update current time after sensor update

    // If the trial start signal is active and the lock (Candado2) is not set:
    if (StartState == HIGH && Candado2 == 0) {             
      Serial.print(currentMillis); Serial.print("."); Serial.print(10); Serial.print("."); Serial.println(1);
      delay(100);
      Candado = 1;
      Candado2 = 1;
      Candado3 = 1;
      Joystick();  // Update sensor readings again
    }

    // If a sound TTL signal is received (implying a sound event) and the lock (Candado3) is active:
    // This branch creates a grace period imposed by the sound card.
    if (SoundITTlState == HIGH && Candado3 == 1) {             
      Serial.print(currentMillis); Serial.print("."); Serial.print(30); Serial.print("."); Serial.println(1);
      delay(50);
      Interval();  // Wait for a fixed interval (grace period)
      CandadoSonido = 1;
      Candado3 = 0;                       
    }
 
    // If sensor values indicate a push action:
    // Condition: sensorValue1 is at least 4 units below its median AND sensorValue3 is at or below its median,
    // and both event lock (Candado) and sound lock (CandadoSonido) are active.
    if (sensorValue1 <= pot1Median - 4 && sensorValue3 <= pot2Median && Candado == 1 && CandadoSonido == 1) {
      Joystick();
      digitalWrite(Push, HIGH);
      Serial.print(currentMillis); Serial.print("."); Serial.print(55); Serial.print("."); Serial.println(1);
      delay(100);
      digitalWrite(Push, LOW);
      // Optionally, resetting Candado could be done here.
      CandadoSonido = 0;  // Reset sound lock after push event                             
    }
    
    // If sensor values indicate a pull action:
    // Condition: sensorValue1 is at or above its median AND sensorValue3 is at least 43 units above its median,
    // and both event lock and sound lock are active.
    if (sensorValue1 >= pot1Median && sensorValue3 >= pot2Median + 43 && Candado == 1 && CandadoSonido == 1) {
      Joystick();
      digitalWrite(Pull, HIGH);
      Serial.print(currentMillis); Serial.print("."); Serial.print(66); Serial.print("."); Serial.println(1);
      delay(100);
      digitalWrite(Pull, LOW);
      // Optionally, resetting Candado could be done here.
      CandadoSonido = 0;        
    }

    // If the trial end signal is active and the lock flag (Candado2) is set:
    if (EndState == HIGH && Candado2 == 1) {
      Serial.print(currentMillis); Serial.print("."); Serial.print(10); Serial.print("."); Serial.println(2);
      delay(50);
      // Reset all lock flags.
      Candado = 0;
      Candado2 = 0;
      CandadoSonido = 0;
    }                                           

    // If a reward signal is detected, log the reward event.
    if (RewardState == HIGH) {
      Serial.print(currentMillis); Serial.print("."); Serial.print(3); Serial.print("."); Serial.println(1);
    } 
  }
}

////////////////////////////////////////////////////////////////////////
// Function: getMedian
// Purpose: Calculate and return the median value from an array of integers.
// Uses a simple bubble sort to sort the array.
////////////////////////////////////////////////////////////////////////
int getMedian(int values[], int size) {
  // Sort the array in ascending order
  for (int i = 0; i < size - 1; i++) {
    for (int j = i + 1; j < size; j++) {
      if (values[i] > values[j]) {
        int temp = values[i];
        values[i] = values[j];
        values[j] = temp;
      }
    }
  }
  // Return the median value based on whether the sample count is even or odd
  if (size % 2 == 0) {
    return (values[size / 2 - 1] + values[size / 2]) / 2;
  } else {
    return values[size / 2];
  }
}

////////////////////////////////////////////////////////////////////////
// Function: Joystick
// Purpose: Smooth the analog sensor readings using a moving average filter.
// It subtracts the oldest reading, adds the newest reading, then calculates the average.
////////////////////////////////////////////////////////////////////////
void Joystick() {
  unsigned long currentMillis = millis();

  // Subtract the oldest reading from the running totals
  total_X = total_X - readings[readIndex_X];
  total_Y = total_Y - readings2[readIndex_Y];
  
  // Read new sensor values
  readings[readIndex_X] = analogRead(sensorPin1);
  readings2[readIndex_Y] = analogRead(sensorPin3);
  
  // Add new readings to the totals
  total_X = total_X + readings[readIndex_X];
  total_Y = total_Y + readings2[readIndex_Y];
  
  // Advance the index and wrap around if needed
  readIndex_X = (readIndex_X + 1) % numReadings;
  readIndex_Y = (readIndex_Y + 1) % numReadings2;
  
  // Calculate moving average for both sensors
  average_X = total_X / numReadings;
  average_Y = total_Y / numReadings2;
  
  // Update the global sensor values with the averages
  sensorValue1 = average_X;
  sensorValue3 = average_Y;
  
  // Log the smoothed sensor values for debugging purposes
  Serial.print(currentMillis); Serial.print("."); Serial.print(1); Serial.print("."); Serial.println(sensorValue1);
  Serial.print(currentMillis); Serial.print("."); Serial.print(2); Serial.print("."); Serial.println(sensorValue3);

  // (Optional debug prints for raw joystick values are commented out)
  /*
  Serial.print("JS_X:");
  Serial.print(average_X);
  Serial.print(",");
  Serial.print("JS_Y:");
  Serial.println(average_Y);
  delay(20);
  */
}

////////////////////////////////////////////////////////////////////////
// Function: Interval
// Purpose: Create a fixed grace period (1000 ms) during which the joystick 
// readings are continuously updated. This delay is imposed by the sound card.
////////////////////////////////////////////////////////////////////////
void Interval() {
  Time = millis();
  interval_randomtime = 1000;  // Set interval to 1000 ms
  while ((unsigned long)millis() - Time <= interval_randomtime) {
    Joystick();
  }
}