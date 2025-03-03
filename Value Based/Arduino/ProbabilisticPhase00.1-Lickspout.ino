//=========================================================================
//======================== PROBABILISTIC TASK =============================
//=========================================================================
//======================= PHASE 00.1: LICKSPOUT ===========================
//=========================================================================

//Mouse receives water via lickspout every 3-5 seconds.

//Need implement new joystick reading code (mm, moving average, box ID).

//INITIAL SETUP - USE FOR ALL CODES

  //Include necessary libraries
    #include <SoftwareSerial.h> //Should be built in
    #include <Wire.h>      //Download I2C Library here: https://www.arduino.cc/reference/en/libraries/liquidcrystal-i2c/
    #include <Servo.h> 
    
  //Assign Pins:
    int BoxLight = 2; //Enter Box Light Pin
    int MyServo = 9; //Enter Servo Pin
    int LickometerLED = 10; //Enter Lickometer built-in LED Pin
    int LickLED = 11; //Enter Lick LED Pin that separate will light up when mouse licks
    int Lickometer = 12; //Enter Lickometer Pin
    int Pump = 13; //Enter Pump Pin
    int PumpOn = 8; //Enter Pump Pin 1A
    int PumpKeepLow = 7; //Enter Pump Pin 2A - keep this low
    int Joystick1 = A1; //input pin 1 from joystick
    int Joystick3 = A3; //input pin 3 from joystick (the one we care more about)
    int BNCTTL1Pin = 22;
    int BNCTTL2Pin = 23;
        int StartSignalTTL = 29;
    int WhiteNoiseTTL = 31;
    int LowToneTTL = 33;
    int HighToneTTL = 35;
    int TTL1Pin = 41;
    int TTL2Pin = 43;
    int TTL3Pin = 45;
    int TTL4Pin = 47;
    int StartTTLPin = 49;
    int OptoTTL = 51;

  //Servo setup:
    Servo ServoVar;
    int ServoBack = 0;
    int ServoForward = 120;

  //Parameters
    const long ToneDuration = 300; //NOTE! THIS IS THE DURATION OF THE TONES ON THE SOUND CARD
    //YOU CAN'T EDIT THIS ONE UNLESS YOU CHANGE LOAD DIFFERENT SOUNDS ONTO CARD.
    const long ServoDuration = 500; //THIS IS JUST HOW LONG IT TAKES FOR THE SERVO TO RETRACT!
    //YOU CAN'T EDIT THIS UNLESS YOU GET A DIFFERENT SERVO/CHANGE THE RETRACTION DISTANCE.
    const long OnDuration = 40; // ON time for pump (100ms for 10uL; 80ms for 7.5uL; 60ms 5uL; 40ms 2.5uL Last Calibration: 1/23/2022)
    const long MaxTrialDuration = 30000; // Maximum Trial Duration is thirty seconds
    const long InitialDelay = 10000; // Initial Delay is ten seconds
    const long InterTrialDelay = 5000; //Inter-trial Delay is five seconds
    const long TimeOutDelay = 15000; //Delay+timeout after unrewarded trials is 15 seconds
    const long JoyTempSensi = 4000; //set temporal resolution for Joystick reading
    const int JoyAvSensi = 1000; //set tepmoral resolution for computing moving average - 1 kHz (might not be feasible with baud rate)
    long RandSecLower = 3000; //inclusive lower bound of the random interval
    long RandSecUpper = 5001; //exclusive upper bound of the random interval
    const int AvReads = 15; //number of reads forming foundation of moving average

    
  //Variables
    long PreviousMillis = 0; //variable to make snapshot of previous milliseconds
    long CurrentMillis; //variable to make snapshot of current milliseconds
    long RandSec; //repository for random seconds
    int Started = 0; //to register that behavior session has started
    int LickNow = 0; //for sensing lickometer activation
    int LickCounter = 0; //for clustering serial lickometer activation
    long TotalLicks = 0; //for counting individual licks
    int Omissions = 0; //for counting omissions
    int Unrewardeds = 0; //for counting unrewarded trials
    unsigned long UnrewardedDuration; //for measuring duration after unrewarded trials
    int Unrewarded = 0; //temporarily set to 1 if mouse is unrewarded
    unsigned long UnrewardedMillis;
    long ClosedMillis;
    int Rewards = 0; //number of rewards
    int Rewarded = 0; //temporarily set to 1 if mouse is rewarded 
    unsigned long RewardDuration = 0; //for pump
    unsigned long RewardPeriod = 0; //timing period between choice and reward, sum of tone and on duration of pump
    unsigned long RewardMillis;
    int TrialNumber = 0; //for counting trials
    unsigned long TrialDuration = 0;
    unsigned long TrialStartTime = 0; //for writing trial start time
    int TrialDone = 0; //for marking complete trial
    unsigned long TrialDoneTime = 0; //for writing trial done time
    int Tripped = 0; //to mark joystick crossing threshold
    int TrippedPush = 0; //to mark joystick crossing threshold for push
    int TrippedPull = 0; //to mark joystick crossing threshold for pull
    int TonePlayed = 0; //to keep track if tone has been played
    int LastDirectionRead = 0; //to compute last direction
    int LastDirection = 0; //records whether mouse pulled (1) or pushed (2), or neutraled (0) on last trial
    //be careful with lastdirection, it's possible that push and pull will be flipped on some rigs
    int PumpOpen = 0;
    int Rand1 = 0;
    long StartTime;
    int SetMilliJoy;
    int SetMilliJoyAv;
    long MilliJoy; 
    long MilliJoyAv;
    bool LickFlag;
          byte BNCTTL1 = 0; //immediately after choice/no choice 
      byte BNCTTL2 = 0; //immediately when joystick re-extends
      bool BNCTTL1State = 0;
      bool BNCTTL2State = 0;
      bool TTL3PinState = 0;
      bool TTL4PinState = 0;
      bool StartTTLPinState = 0;
      byte TTL3 = 0;
      byte TTL4 = 0;
      byte StartTTL = 0;

    int JoystickArrayA1[AvReads]; //array to collect joystick position information
      int JoystickArrayA3[AvReads]; //array to collect joystick position information
      int JoystickArrayIndex;
      long SumReadsA1;
      long SumReadsA3;
      int A1MovingAverage;
      int A3MovingAverage;
    
    


void setup() {
  // put your setup code here, to run once:
    Serial.begin(230400);

    //Set up inputs and outputs:
       pinMode(BoxLight, OUTPUT);
      pinMode(MyServo, OUTPUT);
      pinMode(LickLED, OUTPUT);
      pinMode(Lickometer, INPUT);
      pinMode(Pump, OUTPUT);
      pinMode(PumpOn, OUTPUT);
      pinMode(PumpKeepLow, OUTPUT);
      pinMode(BNCTTL1Pin, OUTPUT);
      pinMode(BNCTTL2Pin, OUTPUT);
      pinMode(Joystick1, INPUT);
      pinMode(Joystick3, INPUT);
      pinMode(StartSignalTTL,OUTPUT);
      pinMode(StartSignalTTL,LOW);
      ServoVar.attach(MyServo);
      ServoVar.write(ServoBack);
      digitalWrite(Pump, HIGH);
      digitalWrite(PumpOn, LOW);
      digitalWrite(PumpKeepLow, LOW);
            pinMode(WhiteNoiseTTL,OUTPUT);
      pinMode(HighToneTTL,OUTPUT);
      pinMode(LowToneTTL,OUTPUT);
      digitalWrite(WhiteNoiseTTL,LOW);
      digitalWrite(HighToneTTL,LOW);
      digitalWrite(LowToneTTL,LOW);
      pinMode(TTL1Pin,OUTPUT);
      pinMode(TTL2Pin,OUTPUT);
      pinMode(TTL3Pin,OUTPUT);
      pinMode(TTL4Pin,OUTPUT);
      pinMode(StartTTLPin,OUTPUT);
      digitalWrite(TTL1Pin,LOW);
      digitalWrite(TTL2Pin,LOW);
      digitalWrite(TTL3Pin,LOW);
      digitalWrite(TTL4Pin,LOW);
      digitalWrite(StartTTLPin,LOW);
      pinMode(OptoTTL,OUTPUT);
      digitalWrite(OptoTTL,LOW);
    
    //Set up random seed (to increase randomness or randomization https://www.arduino.cc/reference/en/language/functions/random-numbers/randomseed/):
      randomSeed(analogRead(A0));

      digitalWrite(BoxLight,HIGH);
      ServoVar.write(ServoBack); //move lever towards mouse
}

void loop() {
  // put your main code here, to run repeatedly:  
if (analogRead(A3) <400 && Started ==0)
{ Serial.println(F("ProbabilisticPhase00.1-Lickspout"));
  Serial.print(F("runTime"));
  Serial.print(F(","));
  Serial.print(F("A1Pos"));
  Serial.print(F(","));
  Serial.print(F("A3Pos")); 
  Serial.print(F(",")); 
  Serial.print(F("A1PosMovAv"));
  Serial.print(F(","));
  Serial.print(F("A3PosMovAv")); 
  Serial.print(F(",")); 
  Serial.print(F("trialNumber"));
  Serial.print(F(","));
  Serial.print(F("randomInterval"));
  Serial.print(F(","));
  Serial.print(F("numRewards"));
  Serial.print(F(","));
  Serial.print(F("currentLick"));
  Serial.print(F(","));
  Serial.print(F("totalLicks"));
  Serial.print(F(","));
  Serial.print(F("BNCTTL1"));
  Serial.print(F(","));
  Serial.println(F("BNCTTL2"));
  StartTime = millis();
  Started = 1;
  digitalWrite(StartSignalTTL,HIGH);
  digitalWrite(StartTTLPin,HIGH);
          StartTTLPinState = 1;
  }

if (Started ==1)
{
  

  //Count and Print Licks
    LickNow = digitalRead(Lickometer);
    if(LickNow == 1)
      {digitalWrite(LickLED,HIGH);}
      else
      {digitalWrite(LickLED,LOW);}
    if(LickNow == 1)
      {LickCounter++;
      }
      else
        {if(LickCounter >=1)
          {++TotalLicks;
          LickCounter=0;
          LickFlag = 1;
          Serial.print(millis()-StartTime);
          Serial.print(F(","));
          Serial.print(analogRead(Joystick1));
          Serial.print(F(","));
          Serial.print(analogRead(Joystick3)); 
          Serial.print(F(","));
          Serial.print(A1MovingAverage);
          Serial.print(F(","));
          Serial.print(A3MovingAverage);
          Serial.print(F(","));
          Serial.print(TrialNumber);
          Serial.print(F(","));
          Serial.print(RandSec);
          Serial.print(F(","));
          Serial.print(Rewards);
          Serial.print(F(","));
          Serial.print(LickFlag);
          Serial.print(F(","));
          Serial.print(TotalLicks);
          Serial.print(F(","));
          Serial.print(BNCTTL1);
          Serial.print(F(","));
          Serial.println(BNCTTL2);
          LickFlag = 0;
          }}
          
  //Read joystick every JoyTempSensi milliseconds
    if (SetMilliJoy ==0)
    {
      MilliJoy = micros();
      SetMilliJoy = 1;
    }
    if ((micros() - MilliJoy) >= JoyTempSensi)
    {
      Serial.print(millis()-StartTime);
      Serial.print(F(","));
      Serial.print(analogRead(Joystick1));
      Serial.print(F(","));
      Serial.print(analogRead(Joystick3)); 
      Serial.print(F(","));
      Serial.print(A1MovingAverage);
      Serial.print(F(","));
      Serial.print(A3MovingAverage);
      Serial.print(F(","));
      Serial.print(TrialNumber);
      Serial.print(F(","));
      Serial.print(RandSec);
      Serial.print(F(","));
      Serial.print(Rewards);
      Serial.print(F(","));
      Serial.print(LickFlag);
      Serial.print(F(","));
          Serial.print(TotalLicks);
          Serial.print(F(","));
          Serial.print(BNCTTL1);
          Serial.print(F(","));
          Serial.println(BNCTTL2);
      SetMilliJoy = 0;
    }

    //calculate moving average joystick position
      if (SetMilliJoyAv ==0)
        {
          MilliJoyAv = micros();
          SetMilliJoyAv = 1;
        }
        if ((micros() - MilliJoyAv) >= JoyAvSensi)
        {
          JoystickArrayA1[JoystickArrayIndex] = analogRead(A1);
          JoystickArrayA3[JoystickArrayIndex] = analogRead(A3);
          ++JoystickArrayIndex;
          if (JoystickArrayIndex >=AvReads)
          {
            JoystickArrayIndex = 0;
          }
          SumReadsA1 = 0;
          SumReadsA3 = 0;
          for (int i = 0; i < AvReads; ++i)
          {
            SumReadsA1 += JoystickArrayA1[i];
            SumReadsA3 += JoystickArrayA3[i];
          }
          A1MovingAverage = SumReadsA1/AvReads;
          A3MovingAverage = SumReadsA3/AvReads;
        }

//turn off TTLs after 1 second of being on
    if (BNCTTL1State ==1 && millis()-RewardMillis >=1000)
    {
      digitalWrite(BNCTTL1Pin, LOW);
      digitalWrite(TTL1Pin,LOW);
      BNCTTL1State = 0;
      BNCTTL1 = 2;
      Serial.print(millis()-StartTime);
      Serial.print(F(","));
      Serial.print(analogRead(Joystick1));
      Serial.print(F(","));
      Serial.print(analogRead(Joystick3)); 
      Serial.print(F(",")); 
      Serial.print(A1MovingAverage);
      Serial.print(F(","));
      Serial.print(A3MovingAverage);
      Serial.print(F(","));
      Serial.print(TrialNumber);
      Serial.print(F(","));
      Serial.print(RandSec);
      Serial.print(F(","));
      Serial.print(Rewards);
      Serial.print(F(","));
      Serial.print(LickFlag);
      Serial.print(F(","));
          Serial.print(TotalLicks);
          Serial.print(F(","));
          Serial.print(BNCTTL1);
          Serial.print(F(","));
          Serial.println(BNCTTL2);
          BNCTTL1 = 0;
    }

    if (BNCTTL2State ==1 && millis()-ClosedMillis >=1000)
    {
      digitalWrite(BNCTTL2Pin, LOW);
      digitalWrite(TTL2Pin,LOW);
      BNCTTL2State = 0;
      BNCTTL2 = 2;
            Serial.print(millis()-StartTime);
      Serial.print(F(","));
      Serial.print(analogRead(Joystick1));
      Serial.print(F(","));
      Serial.print(analogRead(Joystick3)); 
      Serial.print(F(",")); 
      Serial.print(A1MovingAverage);
      Serial.print(F(","));
      Serial.print(A3MovingAverage);
      Serial.print(F(","));
      Serial.print(TrialNumber);
      Serial.print(F(","));
      Serial.print(RandSec);
      Serial.print(F(","));
      Serial.print(Rewards);
      Serial.print(F(","));
      Serial.print(LickFlag);
      Serial.print(F(","));
          Serial.print(TotalLicks);
          Serial.print(F(","));
          Serial.print(BNCTTL1);
          Serial.print(F(","));
          Serial.println(BNCTTL2);
          BNCTTL2 = 0;
    }

    if (StartTTLPinState ==1 && millis()-StartTime >=1000)
        {
          digitalWrite(StartTTLPin, LOW);
          StartTTLPinState = 0;
          StartTTL = 2;
          Serial.print(millis()-StartTime);
      Serial.print(F(","));
      Serial.print(analogRead(Joystick1));
      Serial.print(F(","));
      Serial.print(analogRead(Joystick3)); 
      Serial.print(F(",")); 
      Serial.print(A1MovingAverage);
      Serial.print(F(","));
      Serial.print(A3MovingAverage);
      Serial.print(F(","));
      Serial.print(TrialNumber);
      Serial.print(F(","));
      Serial.print(RandSec);
      Serial.print(F(","));
      Serial.print(Rewards);
      Serial.print(F(","));
      Serial.print(LickFlag);
      Serial.print(F(","));
          Serial.print(TotalLicks);
          Serial.print(F(","));
          Serial.print(BNCTTL1);
          Serial.print(F(","));
          Serial.println(BNCTTL2);
          StartTTL = 0;
        }
        
    CurrentMillis = millis();
  if(Rand1 == 0)
    {RandSec = random(RandSecLower,RandSecUpper);
    Rand1 = 1;}
  //Count and Print Rewards      
    if((CurrentMillis - PreviousMillis) >= RandSec) {
      RewardMillis = millis();
      Rewarded = 1;
      Rewards = ++Rewards;
      TrialNumber = ++TrialNumber;
      RandSec = random(RandSecLower,RandSecUpper);
      BNCTTL1 = 1;
            digitalWrite(BNCTTL1Pin, HIGH);
            digitalWrite(TTL1Pin,HIGH);
            BNCTTL1State = 1;
      Serial.print(millis()-StartTime);
      Serial.print(F(","));
      Serial.print(analogRead(Joystick1));
      Serial.print(F(","));
      Serial.print(analogRead(Joystick3)); 
      Serial.print(F(",")); 
      Serial.print(A1MovingAverage);
      Serial.print(F(","));
      Serial.print(A3MovingAverage);
      Serial.print(F(","));
      Serial.print(TrialNumber);
      Serial.print(F(","));
      Serial.print(RandSec);
      Serial.print(F(","));
      Serial.print(Rewards);
      Serial.print(F(","));
      Serial.print(LickFlag);
      Serial.print(F(","));
          Serial.print(TotalLicks);
          Serial.print(F(","));
          Serial.print(BNCTTL1);
          Serial.print(F(","));
          Serial.println(BNCTTL2);
          BNCTTL1 = 0;
      PreviousMillis = CurrentMillis;}
    RewardDuration = millis()-RewardMillis;
    if(RewardDuration<=OnDuration && Rewarded==1 && PumpOpen !=1)
       {
       digitalWrite(Pump, HIGH);
       digitalWrite(PumpOn,LOW); 
       digitalWrite(PumpKeepLow, HIGH); //open pump valve
       //digitalWrite(LickometerLED,HIGH);
       PumpOpen = 1;
       }
    if(RewardDuration>OnDuration && Rewarded ==1 && PumpOpen ==1) {
      digitalWrite(Pump,HIGH);
      digitalWrite(PumpOn,LOW);
      digitalWrite(PumpKeepLow,LOW); //close pump valve
      ClosedMillis = millis();
      BNCTTL2 = 1;
            digitalWrite(BNCTTL2Pin, HIGH);
            digitalWrite(TTL2Pin,HIGH);
            BNCTTL2State = 1;
                  Serial.print(millis()-StartTime);
      Serial.print(F(","));
      Serial.print(analogRead(Joystick1));
      Serial.print(F(","));
      Serial.print(analogRead(Joystick3)); 
      Serial.print(F(",")); 
      Serial.print(A1MovingAverage);
      Serial.print(F(","));
      Serial.print(A3MovingAverage);
      Serial.print(F(","));
      Serial.print(TrialNumber);
      Serial.print(F(","));
      Serial.print(RandSec);
      Serial.print(F(","));
      Serial.print(Rewards);
      Serial.print(F(","));
      Serial.print(LickFlag);
      Serial.print(F(","));
          Serial.print(TotalLicks);
          Serial.print(F(","));
          Serial.print(BNCTTL1);
          Serial.print(F(","));
          Serial.println(BNCTTL2);
          BNCTTL2 = 0;
      //digitalWrite(LickometerLED,LOW);
      PumpOpen = 0;
      Rewarded = 0;
    }
}

      
}
