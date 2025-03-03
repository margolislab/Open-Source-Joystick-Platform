//===================================================================
// Forced_Pull_LF_FirstArdu.ino
// 
// This Arduino sketch controls a behavioral task that involves both 
// push and pull trials, reward delivery via solenoids, and touch input 
// detection using the MPR121 capacitive sensor. It also uses a sound 
// board (Adafruit_Soundboard) to play various sound tracks based on trial 
// events. Timing, random selection of trial types, and TTL signals for 
// event flagging and camera triggering are implemented.
// 
// Note: Some variable names and comments originally in Spanish have been 
// translated to English.
//===================================================================

//------------------------- Sound Board Setup -------------------------//
#include <SoftwareSerial.h>
#include "Adafruit_Soundboard.h"

// Define pins for SoftwareSerial communication with the sound board.
#define SFX_TX 5
#define SFX_RX 6
// Define the reset pin for the sound board.
#define SFX_RST 4

// Initialize SoftwareSerial for the sound board.
SoftwareSerial ss = SoftwareSerial(SFX_TX, SFX_RX);
// Create an instance of the Adafruit_Soundboard using the SoftwareSerial.
// The second argument is for a debug port (not used) and the third for the reset pin.
Adafruit_Soundboard sfx = Adafruit_Soundboard(&ss, NULL, SFX_RST);
// Alternative hardware serial usage is provided as a comment.
// Adafruit_Soundboard sfx = Adafruit_Soundboard(&Serial1, NULL, SFX_RST);

//------------------------- MPR121 & I2C Setup -------------------------//
#include <MPR121.h>
#include <Wire.h>  // I2C communication library

//------------------------- Pin and Constant Definitions -------------------------//

// Pin used to deliver reward signals from the second Arduino.
const int Rew2ndArd = 8;

// Digital inputs for detecting push and pull events.
const int incoming_Pull = 3;
const int incoming_Push = 12;   

// Digital output pins for starting/ending trials and sending sound signals.
const int Start2A = A0;
const int End2A = A1;
const int SendingSoundSA = A2;

// Variables to hold the current state of the push and pull digital inputs.
int PushState = 0;
int PullState = 0;

// Sound track definitions (file names). 
// Note: These are declared as int in the original code but contain string literals.
int Lowtone1 = "T00     WAV";
int Lowtone2 = "T01     WAV";
int Lowtone3 = "T02     WAV";
int Hightone1 = "T03     WAV";
int Hightone2 = "T04     WAV";
int Hightone3 = "T05     WAV";

// Time intervals for inter-trial intervals (in milliseconds).
int Time1 = 3000;
int Time2 = 4500;
int Time3 = 5000;
int Time4 = 5500;
int Time5 = 6000;

// Button to start trials.
int buttonStart = 2;
int ButtonState = 0;
int Start = 0;  // Flag indicating if a trial has started.

// Random number variables.
int randNum;
int randNum2;
int randNum3 = 2;  // Used for selecting trial type.

// Probabilities for transitions and rewards.
int p_Trans = 100;
int p_Reward = 100;
int Time_Reward = 44;  // Reward delivery time (ms).
int SelectedTone;      // Variable to hold the chosen tone (sound file).

// Calibration values for push and pull actions.
int Push = 517;
int Pull2 = 480;
int Pull = 496;

// TTL (Time To Live) event flags for external equipment.
int ttl_EventFlag = 10;
int ttl_LED_Cam = 9;

// Variables for task performance.
int LeftGood = 0;
int RightGood = 0;
int Transition1 = 0;
int RewardCounter = 1;
int AutoRewardCounter = 1;
int Tranistion2 = 0;  // Note: "Tranistion2" is likely a misspelling of "Transition2".
int NumberofTrials2change = 200;
int TemporalStartTrial = 0;

// Variables for chord (sound) generation.
int Chord1;


// Reward probabilities for different outcomes.
int P_SuccessReward = 100;
int P_UnsuccessReward = 20;
int P_AutoReward = 20;

// Variable to indicate an incorrect movement.
int WrongMovement = 0;

//------------------------- Hardware Variables -------------------------//

// LED for debugging/indication.
int ledPin = 13;
// The following sensorValue variables are declared but (optionally) used for analog sensors.
// (They are commented out in some parts of the code.)
// int sensorPin1 = A1;    // (Commented out)
// int sensorPin3 = A3;    // (Commented out)
int sensorValue1 = 0;
int sensorValue3 = 0;

// Solenoid outputs for reward delivery.
int solenoid_Left = 7;
int solenoid_Right = 5;

// Counters for trials and events.
int Counter_1 = 1;
int Counter_2 = 0;
int Counter_3 = 0;
int Counter_4 = 1;
int i = 0;  // Trial counter.

int Structure = 1;  // Variable indicating the current structure/phase of the task.

unsigned long previousMillis = 0;
unsigned long currentMillis2 = 0;

// Various time intervals (in milliseconds).
int interval = 1000;             // Timeout interval.
int interval_tone = 500;         // Interval related to tone output.
int interval_responseTime = 6000; // Response time window for trials.
int interval_randomtime = 0;     // Will be set dynamically.
int intervalReward = 300;        // Reward delay interval.

// Flags for trial progress.
int trialStart = 0;
int SuccesfulTrial = 0;  // Note: "Succesful" is a misspelling of "Successful" but kept for core functionality.

int PushTrial = 0;
int PullTrial = 0;

//===================================================================
// Setup Function: runs once at startup
//===================================================================
void setup() {
  // Initialize serial communication for debugging.
  Serial.begin(38400);  
  // Start SoftwareSerial communication with the sound board.
  ss.begin(9600);

  // Set pin modes for outputs and inputs.
  pinMode(Rew2ndArd, OUTPUT);

  // Set digital input pins for push and pull events.
  pinMode(incoming_Push, INPUT); 
  pinMode(incoming_Pull, INPUT);
  
  // Set pin modes for LED and solenoid outputs.
  pinMode(ledPin, OUTPUT);
  pinMode(solenoid_Left, OUTPUT);
  pinMode(solenoid_Right, OUTPUT);
  
  // Set the start button as an input.
  pinMode(buttonStart, INPUT);
  // Set TTL event flag outputs.
  pinMode(ttl_EventFlag, OUTPUT);
  pinMode(ttl_LED_Cam, OUTPUT);
  
  // The following two lines are redundant (already set above) and can be removed.
  // pinMode(incoming_Push, INPUT);
  // pinMode(incoming_Pull, INPUT);
  
  // Set pin modes for trial start/end and sound sending.
  pinMode(Start2A, OUTPUT);
  pinMode(End2A, OUTPUT);
  pinMode(SendingSoundSA, OUTPUT);

  // Start I2C communication.
  Wire.begin();
  
  // Seed the random number generator using an analog reading.
  randomSeed(analogRead(A3)); 
       
  // MPR121 activation sequence:
  // The sensor's I2C address is 0x5A.
  if (!MPR121.begin(0x5A)) {
    Serial.println("error setting up MPR121");
    // Print the specific error.
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
    while (1);  // Halt execution if MPR121 initialization fails.
  }
  
  // Set the MPR121 interrupt pin.
  MPR121.setInterruptPin(11);
  // Set touch threshold (lower value = more sensitive, like a proximity trigger).
  MPR121.setTouchThreshold(15);
  // Set release threshold (must always be lower than the touch threshold).
  MPR121.setReleaseThreshold(10);
  // Update the initial touch data.
  MPR121.updateTouchData();

  // Set trial start/end pins to LOW.
  digitalWrite(Start2A, LOW);
  digitalWrite(End2A, LOW);

  // The second Serial.begin(38400) is redundant and has been removed.
}

//===================================================================
// Main Loop: runs repeatedly
//===================================================================
void loop() {
  unsigned long currentMillis = millis();
  Time = millis(); // Update global time variable.
  
  // Ensure solenoids are off at the start of each loop iteration.
  digitalWrite(solenoid_Left, LOW);
  digitalWrite(solenoid_Right, LOW);

  // Read the state of the start button.
  ButtonState = digitalRead(buttonStart);
  // Read digital inputs for push and pull.
  PushState = digitalRead(incoming_Push);
  PullState = digitalRead(incoming_Pull);

  // If the start button is pressed, set the Start flag and log the event.
  if (ButtonState == HIGH) {
    Start = 1;
    Serial.print(currentMillis); Serial.print("."); Serial.print(50); Serial.print("."); Serial.println(1);
    digitalWrite(13, HIGH);  // TTL Start Begin (using built-in LED as indicator).
    delay(100);
    digitalWrite(13, LOW);
  }

  if (Start == 1) {
    // Process touch inputs.
    Licks();

    //////////////// Trial Selection ////////////////
    if (randNum3 == 1) {
      PushTrial = 1;
      PullTrial = 0;
      i = 1;
      Serial.print(currentMillis); Serial.print("."); Serial.print(55); Serial.print("."); Serial.println(1);
      // (Originally labeled as "Pull_HTRIAL" in Spanish comment; now using English)
    }
    if (randNum3 == 2) {
      PushTrial = 0;
      PullTrial = 1;
      i = 1;
      Serial.print(currentMillis); Serial.print("."); Serial.print(66); Serial.print("."); Serial.println(1);
      // (Originally labeled "PUSH_TRIAL")
    }

    //////////////// Handling Push Trials ////////////////
    if (PushTrial == 1 && PullTrial == 0) {
      while (i <= NumberofTrials2change) {
        TTLSEventFlagStart();
        T2START2ndA();
        // Log trial start if needed (commented out debug print remains).
        // Reset trial type flags.
        PushTrial = 0;
        PullTrial = 0;
        InterTimeTrialInterval(); // Wait for a randomized inter-trial interval.
        currentMillis = millis();
        Time = millis();
        Licks();
        randNum2 = random(1, 4);
        Serial.print(currentMillis); Serial.print("."); Serial.print(99); Serial.print("."); Serial.println(RewardCounter);
        delay(1000);
        TTLSEventFlag_Sound_LowFreq();
        TTLSound2SecondA();
        Serial.print(currentMillis); Serial.print("."); Serial.print(4); Serial.print("."); Serial.println(Counter_4);
        Serial.print(currentMillis); Serial.print("."); Serial.print(61); Serial.print("."); Serial.println(Chord1);
        Time = millis();
        Serial.print(currentMillis); Serial.print("."); Serial.print(44); Serial.print("."); Serial.println(Counter_1);

        // Play a sound based on a random selection (three possibilities, all play T01, you can change it if you want to use more than one sound).
        if (randNum2 == 1) {
          sfx.playTrack("T01     WAV");
          Chord1 = 3000;
          Licks();
        }
        if (randNum2 == 2) {
          sfx.playTrack("T01     WAV");
          Chord1 = 3000;
          Licks();
        }
        if (randNum2 == 3) {
          sfx.playTrack("T01     WAV");
          Chord1 = 3000;
          Licks();
        }
                                    
        trialStart = 1; // Begin the trial response window.
                                
        //////////////// Interval Response Time for Push Trials ////////////////
        if (trialStart == 1) {  // PUSH TRIAL
          SuccesfulTrial = 0;
          WrongMovement = 0;
          Time = millis();
          while ((unsigned long)millis() - Time <= interval_responseTime) {
            currentMillis = millis();
            Licks();
            PushState = digitalRead(incoming_Push);
            PullState = digitalRead(incoming_Pull);
                                                  
            // If the push input is detected:
            if (PushState == HIGH) {
              randNum2 = random(1, 100);
              if (randNum2 < P_SuccessReward) {  // Successful trial with reward
                currentMillis = millis();
                RewardDelay();
                TTLSReward();
                digitalWrite(solenoid_Left, HIGH);
                digitalWrite(Rew2ndArd, HIGH);
                Serial.print(currentMillis); Serial.print("."); Serial.print(3); Serial.print("."); Serial.println(RewardCounter);
                delay(Time_Reward);
                digitalWrite(Rew2ndArd, LOW);
                digitalWrite(solenoid_Left, LOW);
                RewardCounter = RewardCounter + 1;
                Counter_4 = Counter_4 + 1;
                i = i + 1;
                SuccesfulTrial = 1;
                TimeOut();
                TTLSEventFlagOff();
                T2END2ndA();
                Serial.print(currentMillis); Serial.print("."); Serial.print(5); Serial.print("."); Serial.println(i);
                Counter_4 = Counter_4 + 1;
                if (i == NumberofTrials2change) {
                  randNum3 = 2;  // Change trial type after required number of trials.
                }
                break;
              } else {  // Successful trial but unsuccessful reward (error case)
                currentMillis = millis();
                Serial.print(currentMillis); Serial.print("."); Serial.print(13); Serial.print("."); Serial.println(1);
                Serial.print(currentMillis); Serial.print("."); Serial.print(5); Serial.print("."); Serial.println(i);
                Counter_4 = Counter_4 + 1;
                SuccesfulTrial = 1;
                TimeOut();
                TTLSEventFlagOff();
                T2END2ndA();
                break;
              }
            }
                                                  
            // If the pull input is detected during a push trial:
            if (PullState == HIGH) {
              randNum2 = random(1, 100);
              if (randNum2 < P_UnsuccessReward) {
                currentMillis = millis();
                TTLSAuto_Reward();
                digitalWrite(solenoid_Left, HIGH);
                Serial.print(currentMillis); Serial.print("."); Serial.print(24); Serial.print("."); Serial.println(AutoRewardCounter);
                delay(Time_Reward);
                digitalWrite(solenoid_Left, LOW);
                Serial.print(currentMillis); Serial.print("."); Serial.print(5); Serial.print("."); Serial.println(i);
                Counter_4 = Counter_4 + 1;
                AutoRewardCounter = AutoRewardCounter + 1;
                TimeOut();
                TTLSEventFlagOff();
                T2END2ndA();
                WrongMovement = 1;
                break;
              } else {
                currentMillis = millis();
                Serial.print(currentMillis); Serial.print("."); Serial.print(34); Serial.print("."); Serial.println(1);
                Serial.print(currentMillis); Serial.print("."); Serial.print(6); Serial.print("."); Serial.println(1);
                Serial.print(currentMillis); Serial.print("."); Serial.print(5); Serial.print("."); Serial.println(i);
                Counter_4 = Counter_4 + 1;
                TTLSWhiteNoise();
                sfx.playTrack("T06     WAV");
                WrongMovement = 1;
                TimeOut();
                TTLSEventFlagOff();
                T2END2ndA();
                break;
              }
              break;  // Exit the response window loop.
            }
            Counter_1 = Counter_1 + 1;
            trialStart = 0;
          } // End of response time window.
                                                  
          // If no response was classified as successful or wrong:
          if (SuccesfulTrial == 0 && WrongMovement == 0) {
            randNum2 = random(1, 100);
            if (randNum2 < P_AutoReward) {
              currentMillis = millis();
              TTLSAuto_Reward();  
              digitalWrite(solenoid_Left, HIGH);
              Serial.print(currentMillis); Serial.print("."); Serial.print(23); Serial.print("."); Serial.println(AutoRewardCounter);
              delay(Time_Reward);
              digitalWrite(solenoid_Left, LOW);
              AutoRewardCounter = AutoRewardCounter + 1;
              Serial.print(currentMillis); Serial.print("."); Serial.print(5); Serial.print("."); Serial.println(i);
              Counter_4 = Counter_4 + 1;
              TTLSEventFlagOff();
              T2END2ndA();
              break;
            } else {
              currentMillis = millis();
              Serial.print(currentMillis); Serial.print("."); Serial.print(33); Serial.print("."); Serial.println(1);
              Serial.print(currentMillis); Serial.print("."); Serial.print(6); Serial.print("."); Serial.println(1);
              Serial.print(currentMillis); Serial.print("."); Serial.print(5); Serial.print("."); Serial.println(i);
              Counter_4 = Counter_4 + 1;
              TTLSWhiteNoise();
              sfx.playTrack("T06     WAV");
              TTLSEventFlagOff();
              T2END2ndA();
              break;
            }
          }
        } // End while loop for PushTrial.
      } // End if(PushTrial==1 && PullTrial==0)
      
      //////////////// Handling Pull Trials ////////////////
      if (PushTrial == 0 && PullTrial == 1) {
        while (i <= NumberofTrials2change) {
          TTLSEventFlagStart();
          T2START2ndA();
          InterTimeTrialInterval();
          PushState = digitalRead(incoming_Push);
          PullState = digitalRead(incoming_Pull);
          currentMillis = millis();
          Time = millis();
          Licks();
          randNum2 = random(1, 4);
          Serial.print(currentMillis); Serial.print("."); Serial.print(99); Serial.print("."); Serial.println(RewardCounter);
          delay(1000);
          TTLSEventFlag_Sound_HighFreq();
          TTLSound2SecondA();
          Serial.print(currentMillis); Serial.print("."); Serial.print(4); Serial.print("."); Serial.println(Counter_4);
          Serial.print(currentMillis); Serial.print("."); Serial.print(61); Serial.print("."); Serial.println(Chord1);
          Serial.print(currentMillis); Serial.print("."); Serial.print(44); Serial.print("."); Serial.println(Counter_1);
          Time = millis();

          if (randNum2 == 1) {
            sfx.playTrack("T04     WAV");
            Chord1 = 7000;
            Licks();
          }
          if (randNum2 == 2) {
            sfx.playTrack("T04     WAV");
            Chord1 = 7000;
            Licks();
          }
          if (randNum2 == 3) {
            sfx.playTrack("T04     WAV");
            Chord1 = 7000;
            Licks();
          }
          SelectedTone = 0;
          trialStart = 1;
                                
          //////////////// Interval Response Time for Pull Trials ////////////////
          if (trialStart == 1) {
            SuccesfulTrial = 0;
            WrongMovement = 0;
            Time = millis();
            while ((unsigned long)millis() - Time <= interval_responseTime) {
              currentMillis = millis();
              Licks();
              PushState = digitalRead(incoming_Push);
              PullState = digitalRead(incoming_Pull);
              // If pull input is detected:
              if (PullState == HIGH) {
                randNum2 = random(1, 100);
                if (randNum2 < P_SuccessReward) {
                  currentMillis = millis();
                  RewardDelay();
                  TTLSReward();
                  digitalWrite(solenoid_Left, HIGH);
                  digitalWrite(Rew2ndArd, HIGH);
                  Serial.print(currentMillis); Serial.print("."); Serial.print(3); Serial.print("."); Serial.println(RewardCounter);
                  delay(Time_Reward);
                  digitalWrite(Rew2ndArd, LOW);
                  digitalWrite(solenoid_Left, LOW);
                  RewardCounter = RewardCounter + 1;
                  i = i + 1;
                  SuccesfulTrial = 1;
                  TimeOut();
                  TTLSEventFlagOff();
                  T2END2ndA();
                  Serial.print(currentMillis); Serial.print("."); Serial.print(5); Serial.print("."); Serial.println(i);
                  Counter_4 = Counter_4 + 1;
                  if (i == NumberofTrials2change) {
                    randNum3 = 1;
                  }
                  break;
                } else {
                  currentMillis = millis();
                  Serial.print(currentMillis); Serial.print("."); Serial.print(13); Serial.print("."); Serial.println(1);
                  Serial.print(currentMillis); Serial.print("."); Serial.print(5); Serial.print("."); Serial.println(i);
                  Counter_4 = Counter_4 + 1;
                  SuccesfulTrial = 1;
                  TimeOut();
                  TTLSEventFlagOff();
                  T2END2ndA();
                  break;
                }
              }
              // If push input is detected during a pull trial:
              if (PushState == HIGH) {
                randNum2 = random(1, 100);
                if (randNum2 < P_UnsuccessReward) {
                  currentMillis = millis();
                  TTLSAuto_Reward();
                  digitalWrite(solenoid_Left, HIGH);
                  Serial.print(currentMillis); Serial.print("."); Serial.print(24); Serial.print("."); Serial.println(AutoRewardCounter);
                  delay(Time_Reward);
                  digitalWrite(solenoid_Left, LOW);
                  Serial.print(currentMillis); Serial.print("."); Serial.print(5); Serial.print("."); Serial.println(1);
                  AutoRewardCounter = AutoRewardCounter + 1;
                  Counter_4 = Counter_4 + 1;
                  WrongMovement = 1;
                  TimeOut();
                  TTLSEventFlagOff();
                  T2END2ndA();
                  break;
                } else {
                  currentMillis = millis();
                  Serial.print(currentMillis); Serial.print("."); Serial.print(34); Serial.print("."); Serial.println(1);
                  Serial.print(currentMillis); Serial.print("."); Serial.print(6); Serial.print("."); Serial.println(1);
                  Serial.print(currentMillis); Serial.print("."); Serial.print(5); Serial.print("."); Serial.println(1);
                  Counter_4 = Counter_4 + 1;
                  TTLSWhiteNoise();
                  sfx.playTrack("T06     WAV");
                  WrongMovement = 1;
                  TimeOut();
                  TTLSEventFlagOff();
                  T2END2ndA();
                  break;
                }
                break;
              }
              Counter_1 = Counter_1 + 1;
              trialStart = 0;
            }
            if (SuccesfulTrial == 0 && WrongMovement == 0) {
              randNum2 = random(1, 100);
              if (randNum2 < P_AutoReward) {
                currentMillis = millis();
                TTLSAuto_Reward();
                digitalWrite(solenoid_Left, HIGH);
                Serial.print(currentMillis); Serial.print("."); Serial.print(23); Serial.print("."); Serial.println(AutoRewardCounter);
                delay(Time_Reward);
                digitalWrite(solenoid_Left, LOW);
                AutoRewardCounter = AutoRewardCounter + 1;
                Serial.print(currentMillis); Serial.print("."); Serial.print(5); Serial.print("."); Serial.println(i);
                Counter_4 = Counter_4 + 1;
                TTLSEventFlagOff();
                T2END2ndA();
                break;
              } else {
                currentMillis = millis();
                Serial.print(currentMillis); Serial.print("."); Serial.print(33); Serial.print("."); Serial.println(1);
                Serial.print(currentMillis); Serial.print("."); Serial.print(6); Serial.print("."); Serial.println(1);
                Serial.print(currentMillis); Serial.print("."); Serial.print(5); Serial.print("."); Serial.println(i);
                Counter_4 = Counter_4 + 1;
                TTLSWhiteNoise();
                sfx.playTrack("T06     WAV");
                TTLSEventFlagOff();
                T2END2ndA();
                break;
              }
            }
          } // End while loop for PullTrial.
        } // End if(PushTrial==0 && PullTrial==1)
      } // End if(Start==1)
  }
}

//===================================================================
// Function: Licks
// Purpose: Check for touch changes using the MPR121 sensor and log "lick" events.
// (A "lick" refers to a contact event detected by one of the electrodes.)
//===================================================================
void Licks() {
  unsigned long currentMillis = millis();
  if (MPR121.touchStatusChanged()) {
    // Read the updated touch data.
    MPR121.updateTouchData();
    if (MPR121.isNewTouch(0)) {
      Serial.print(currentMillis); Serial.print("."); Serial.print(17); Serial.print("."); Serial.println(1);
    }
    if (MPR121.isNewTouch(1)) {
      Serial.print(currentMillis); Serial.print("."); Serial.print(18); Serial.print("."); Serial.println(1);
    }
  }          
}

//===================================================================
// Function: TimeOut
// Purpose: Maintain a timeout period while continuously processing lick inputs.
//===================================================================
void TimeOut() {
  Time = millis();
  unsigned long currentMillis = millis();
  while ((unsigned long)millis() - Time <= interval) {
    unsigned long currentMillis = millis(); 
    Licks();
  }
}

//===================================================================
// Function: RewardDelay
// Purpose: Wait for a specified reward delay while processing lick inputs.
//===================================================================
void RewardDelay() {
  Time = millis();
  unsigned long currentMillis = millis();
  while ((unsigned long)millis() - Time <= intervalReward) {
    unsigned long currentMillis = millis(); 
    Licks();
  }
}

//===================================================================
// Function: InterTimeTrialInterval
// Purpose: Wait for a randomized interval between trials while processing lick inputs.
//===================================================================
void InterTimeTrialInterval() {
  randNum2 = random(1, 6);
  unsigned long currentMillis = millis();
           
  if (randNum2 == 1) {
    Time = millis();
    interval_randomtime = Time1;
    Serial.print(currentMillis); Serial.print("."); Serial.print(21); Serial.print("."); Serial.println(interval_randomtime);
    while ((unsigned long)millis() - Time <= interval_randomtime) {
      Licks(); 
    }
  }
  if (randNum2 == 2) {
    Time = millis();
    interval_randomtime = Time2;
    Serial.print(currentMillis); Serial.print("."); Serial.print(21); Serial.print("."); Serial.println(interval_randomtime);            
    while ((unsigned long)millis() - Time <= interval_randomtime) {
      Licks();
    }
  }
  if (randNum2 == 3) {
    Time = millis();
    interval_randomtime = Time3;
    Serial.print(currentMillis); Serial.print("."); Serial.print(21); Serial.print("."); Serial.println(interval_randomtime);            
    while ((unsigned long)millis() - Time <= interval_randomtime) {
      Licks();
    }
  }
  if (randNum2 == 4) {
    Time = millis();
    interval_randomtime = Time4;
    Serial.print(currentMillis); Serial.print("."); Serial.print(21); Serial.print("."); Serial.println(interval_randomtime);            
    while ((unsigned long)millis() - Time <= interval_randomtime) {
      Licks();
    }    
  }
  if (randNum2 == 5) {
    Time = millis();
    interval_randomtime = Time5;
    Serial.print(currentMillis); Serial.print("."); Serial.print(21); Serial.print("."); Serial.println(interval_randomtime);            
    while ((unsigned long)millis() - Time <= interval_randomtime) {
      Licks();
    }
  }
}

//===================================================================
// TTL and Event Flag Functions
// These functions control external TTL signals (e.g., for camera triggering)
// and log the events via serial communication.
//===================================================================

void TTLSEventFlagStart() {
  unsigned long currentMillis = millis();
  digitalWrite(ttl_EventFlag, HIGH);
  digitalWrite(ttl_LED_Cam, HIGH);
  Serial.print(currentMillis); Serial.print("."); Serial.print(81); Serial.print("."); Serial.println(1);
  Serial.print(currentMillis); Serial.print("."); Serial.print(82); Serial.print("."); Serial.println(1);
  delay(100);
  digitalWrite(ttl_EventFlag, LOW);
  digitalWrite(ttl_LED_Cam, LOW);
}

void TTLSEventFlagOff() {
  unsigned long currentMillis = millis();
  digitalWrite(ttl_EventFlag, HIGH);
  digitalWrite(ttl_LED_Cam, HIGH);
  Serial.print(currentMillis); Serial.print("."); Serial.print(81); Serial.print("."); Serial.println(2);
  Serial.print(currentMillis); Serial.print("."); Serial.print(82); Serial.print("."); Serial.println(2);
  delay(100);
  digitalWrite(ttl_EventFlag, LOW);
  digitalWrite(ttl_LED_Cam, LOW);
}

void TTLSEventFlag_Sound_HighFreq() {
  unsigned long currentMillis = millis();
  digitalWrite(ttl_EventFlag, HIGH);
  digitalWrite(ttl_LED_Cam, HIGH);
  Serial.print(currentMillis); Serial.print("."); Serial.print(81); Serial.print("."); Serial.println(3);
  Serial.print(currentMillis); Serial.print("."); Serial.print(82); Serial.print("."); Serial.println(3);
  delay(100);
  digitalWrite(ttl_EventFlag, LOW);
  digitalWrite(ttl_LED_Cam, LOW);
} 

void TTLSEventFlag_Sound_LowFreq() {
  unsigned long currentMillis = millis();
  digitalWrite(ttl_EventFlag, HIGH);
  digitalWrite(ttl_LED_Cam, HIGH);
  Serial.print(currentMillis); Serial.print("."); Serial.print(81); Serial.print("."); Serial.println(4);
  Serial.print(currentMillis); Serial.print("."); Serial.print(82); Serial.print("."); Serial.println(4);
  delay(100);
  digitalWrite(ttl_EventFlag, LOW);
  digitalWrite(ttl_LED_Cam, LOW);
} 

void TTLSReward() {
  unsigned long currentMillis = millis();
  digitalWrite(ttl_EventFlag, HIGH);
  digitalWrite(ttl_LED_Cam, HIGH);
  Serial.print(currentMillis); Serial.print("."); Serial.print(81); Serial.print("."); Serial.println(5);
  Serial.print(currentMillis); Serial.print("."); Serial.print(82); Serial.print("."); Serial.println(5);
  delay(100);
  digitalWrite(ttl_EventFlag, LOW);
  digitalWrite(ttl_LED_Cam, LOW);
}

void TTLSAuto_Reward() {
  unsigned long currentMillis = millis();
  digitalWrite(ttl_EventFlag, HIGH);
  digitalWrite(ttl_LED_Cam, HIGH);
  Serial.print(currentMillis); Serial.print("."); Serial.print(81); Serial.print("."); Serial.println(7);
  Serial.print(currentMillis); Serial.print("."); Serial.print(82); Serial.print("."); Serial.println(7);
  delay(100);
  digitalWrite(ttl_EventFlag, LOW);
  digitalWrite(ttl_LED_Cam, LOW);
}

void TTLSWhiteNoise() {
  unsigned long currentMillis = millis();
  digitalWrite(ttl_EventFlag, HIGH);
  digitalWrite(ttl_LED_Cam, HIGH);
  Serial.print(currentMillis); Serial.print("."); Serial.print(81); Serial.print("."); Serial.println(6);
  Serial.print(currentMillis); Serial.print("."); Serial.print(82); Serial.print("."); Serial.println(6);
  delay(100);
  digitalWrite(ttl_EventFlag, LOW);
  digitalWrite(ttl_LED_Cam, LOW);
}

//===================================================================
// Trial Start/End and Sound Sending Functions
// These functions control digital outputs that signal the start and 
// end of a trial, and the sending of a sound command to the second Arduino.
//===================================================================

void T2START2ndA() {
  unsigned long currentMillis = millis();
  digitalWrite(Start2A, HIGH);
  Serial.print(currentMillis); Serial.print("."); Serial.print(68); Serial.print("."); Serial.println(1);
  delay(50);
  digitalWrite(Start2A, LOW);
}

void T2END2ndA() {
  unsigned long currentMillis = millis();
  digitalWrite(End2A, HIGH);
  Serial.print(currentMillis); Serial.print("."); Serial.print(69); Serial.print("."); Serial.println(1);
  delay(50);
  digitalWrite(End2A, LOW);
}

void TTLSound2SecondA() {
  unsigned long currentMillis = millis();
  digitalWrite(SendingSoundSA, HIGH);
  Serial.print(currentMillis); Serial.print("."); Serial.print(70); Serial.print("."); Serial.println(1);
  delay(50);
  digitalWrite(SendingSoundSA, LOW);
}