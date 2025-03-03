//=========================================================================
//========================= PROBABILISTIC TASK ============================
//=========================================================================
//============================ FLUSH TUBES ================================
//=========================================================================

//Push joystick to start. This code rapidly passes liquid through the tubes
//for cleaning/loading solution.

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
    int OptoTTL = 51;

  //Servo setup:
    Servo ServoVar;

  //Joystick Sensor Thresholds
    int Pull=525; //set sensor sensitivity (Ivan uses 525)
    int Push=475; //set sensor sensitivity (Ivan uses 485)
    int Joystick1Value; 
    int Joystick3Value;
    int ServoBack = 0;
    int ServoForward = 120;

  //Parameters
  const int AvReads = 20; //number of reads forming foundation of moving average
    const long ToneDuration = 300; //NOTE! THIS IS THE DURATION OF THE TONES ON THE SOUND CARD
    //YOU CAN'T EDIT THIS ONE UNLESS YOU CHANGE LOAD DIFFERENT SOUNDS ONTO CARD.
    const long ServoDuration = 500; //THIS IS JUST HOW LONG IT TAKES FOR THE SERVO TO RETRACT!
    //YOU CAN'T EDIT THIS UNLESS YOU GET A DIFFERENT SERVO/CHANGE THE RETRACTION DISTANCE.
    const long OnDuration = 200; // ON time for pump (75ms for 8uL; 40ms 2.5uL; Last Calibration: 12/11/2022)
    const long MaxTrialDuration = 30000; // Maximum Trial Duration is thirty seconds
    const long InitialDelay = 10000; // Initial Delay is ten seconds
    const long InterTrialDelay = 5000; //Inter-trial Delay is five seconds
    const long TimeOutDelay = 15000; //Delay+timeout after unrewarded trials is 15 seconds
    const int JoyTempSensi=4000; //set temporal resolution for Joystick reading
    const int JoyAvSensi = 1000; //set tepmoral resolution for computing moving average - 1 kHz (might not be feasible with baud rate)
    
    
  //Variables
    unsigned long PreviousMillis = 0; //variable to make snapshot of previous milliseconds
    unsigned long CurrentMillis; //variable to make snapshot of current milliseconds
    unsigned long RandSec; //repository for random seconds
    int Started = 0; //to register that behavior session has started
    int LickNow = 0; //for sensing lickometer activation
    int LickCounter = 0; //for clustering serial lickometer activation
    int TotalLicks = 0; //for counting individual licks
    int Omissions = 0; //for counting omissions
    int Unrewardeds = 0; //for counting unrewarded trials
    unsigned long UnrewardedDuration; //for measuring duration after unrewarded trials
    int Unrewarded = 0; //temporarily set to 1 if mouse is unrewarded
    unsigned long UnrewardedMillis;
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
    byte ServoCheck = 0;
    bool SoundTimerCheck = 0;
    long SoundTimer = 0;
    long ServoTimer = 0;

    int NumRead = 0; //for reading joystick position
    int NumInterRead = 0; //for reading joystick position between trials
    long ReadTotalA1 = 0; //for reading joystick position
    float ReadTotalA3 = 0; //for reading joystick position
    int JoystickBaselineA1 = 0; //for reading joystick position
    int JoystickBaselineA3 = 0; //for reading joystick position
    int PrevBaselineA3 = 0; //for alarm
    int JoystickArrayA1[AvReads]; //array to collect joystick position information
    float JoystickArrayA3[AvReads]; //array to collect joystick position information
    int JoystickArrayIndex;
    long SumReadsA1;
    float SumReadsA3;
    int A1MovingAverage;
    int A3MovingAverage;
    long MilliJoy = 0; //for measuring joystick position
    long MilliJoyAv; 
    long MilliRead = 0; //for measuring joystick position
    long MilliInterRead = 0; //for measuring joystick position between trials
    bool SetMilliJoy = 0; //flag for reading joystick position
      bool SetMilliJoyAv = 0; //flag for reading average joystick position
      bool BaselineReadYN = 0; //flag for reading joystick position
      bool InterReadYN = 0; //flag for resetting joystick baseline position between trials
      bool SetMilliRead = 0; //flag for reading joystick position
      bool SetMilliInterRead = 0; //flag for reading joystick position between trials
      bool ReadJoystick;
      float m = 4.55;
      float b = 489.71;

    
    


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
      pinMode(Joystick1, INPUT);
      pinMode(Joystick3, INPUT);
      pinMode(StartSignalTTL,OUTPUT);
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
            pinMode(BNCTTL1Pin, OUTPUT);
      pinMode(BNCTTL2Pin, OUTPUT);
      digitalWrite(BNCTTL1Pin, LOW);
      digitalWrite(BNCTTL2Pin, LOW);
      pinMode(TTL1Pin,OUTPUT);
      pinMode(TTL2Pin,OUTPUT);
      pinMode(TTL3Pin,OUTPUT);
      pinMode(TTL4Pin,OUTPUT);
      pinMode(OptoTTL,OUTPUT);
      digitalWrite(TTL1Pin,LOW);
      digitalWrite(TTL2Pin,LOW);
      digitalWrite(TTL3Pin,LOW);
      digitalWrite(TTL4Pin,LOW);
      digitalWrite(OptoTTL,LOW);
    
    //Set up random seed (to increase randomness or randomization https://www.arduino.cc/reference/en/language/functions/random-numbers/randomseed/):
      randomSeed(analogRead(A0));
      ServoVar.write(ServoForward); //move lever towards mouse
      digitalWrite(BoxLight,HIGH); 
      delay(1000);
      digitalWrite(StartSignalTTL,HIGH);
      delay(1000);
      digitalWrite(StartSignalTTL,LOW);
}

void loop() {
  // put your main code here, to run repeatedly:

     
if (analogRead(A3) >550)
{Started = 1;}

if (Started ==1)
{

     

  CurrentMillis = millis();
  if(Rand1 == 0)
    {RandSec = random(300,501);
    Rand1 = 1;}

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
          Serial.print(millis()); 
          Serial.print(","); 
          Serial.print(analogRead(Joystick1));
        Serial.print(F(","));
        Serial.print(analogRead(Joystick3)); 
        Serial.print(F(",")); 
        Serial.print(A1MovingAverage);
        Serial.print(F(","));
        Serial.print(A3MovingAverage);
        Serial.print(F(","));
          Serial.print(RandSec);
          Serial.print(",");
          Serial.print(Rewards);
          Serial.print(",");
          Serial.println(TotalLicks);}}
  //Read joystick every JoyTempSensi milliseconds
    if (SetMilliJoy ==0)
    {
      MilliJoy = micros();
      SetMilliJoy = 1;
    }
    if ((micros() - MilliJoy) >= JoyTempSensi && ReadJoystick == 1)
    {
        Serial.print(millis()); 
          Serial.print(","); 
          Serial.print(analogRead(Joystick1));
        Serial.print(F(","));
        Serial.print(analogRead(Joystick3)); 
        Serial.print(F(",")); 
        Serial.print(A1MovingAverage);
        Serial.print(F(","));
        Serial.print(A3MovingAverage);
        Serial.print(F(","));
          Serial.print(RandSec);
          Serial.print(",");
          Serial.print(Rewards);
          Serial.print(",");
          Serial.println(TotalLicks);
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
          JoystickArrayA3[JoystickArrayIndex] = (analogRead(A3)-b)/m;
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
          A3MovingAverage = int(SumReadsA3*1000/AvReads);
        }
  
  //Count and Print Rewards      
    if((CurrentMillis - PreviousMillis) >= RandSec) {
      RewardMillis = millis();
      Rewarded = 1;
      Rewards = ++Rewards;
      TrialNumber = ++TrialNumber;
      RandSec = random(300,501);
      Serial.print(millis()); 
          Serial.print(","); 
          Serial.print(analogRead(Joystick1));
        Serial.print(F(","));
        Serial.print(analogRead(Joystick3)); 
        Serial.print(F(",")); 
        Serial.print(A1MovingAverage);
        Serial.print(F(","));
        Serial.print(A3MovingAverage);
        Serial.print(F(","));
          Serial.print(RandSec);
          Serial.print(",");
          Serial.print(Rewards);
          Serial.print(",");
          Serial.println(TotalLicks);
      PreviousMillis = CurrentMillis;}
    RewardDuration = millis()-RewardMillis;
    if(RewardDuration<=OnDuration && Rewarded==1 && PumpOpen !=1)
       {
       digitalWrite(Pump, HIGH);
       digitalWrite(PumpOn,LOW); 
       digitalWrite(PumpKeepLow, HIGH); //open pump valve
       digitalWrite(LickometerLED,HIGH);
       PumpOpen = 1;
       }
    if(RewardDuration>OnDuration && Rewarded ==1 && PumpOpen ==1) {
      digitalWrite(Pump,HIGH);
      digitalWrite(PumpOn,LOW);
      digitalWrite(PumpKeepLow,LOW); //close pump valve
      digitalWrite(LickometerLED,LOW);
      PumpOpen = 0;
      Rewarded = 0;
    }

    if (SoundTimerCheck == 0)
    {
      SoundTimerCheck = 1;
      SoundTimer = millis();
      digitalWrite(WhiteNoiseTTL,LOW);
    }
    if ((millis()-SoundTimer) >=10000 && SoundTimerCheck == 1)
    {
      digitalWrite(WhiteNoiseTTL,HIGH);
      SoundTimerCheck = 0;
    }

    if (ServoCheck == 0)
    {
      ServoCheck = 1;
      ServoTimer = millis();
    }
    if ((millis()-ServoTimer) >=10000 && ServoCheck == 1)
    {
      ServoCheck = 2;
      ServoVar.write(ServoBack);
      
    }
    
}

      
}
