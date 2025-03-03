//=========================================================================
//======================= PROBABILISTIC TASK ==============================
//================= PHASE 06.1: PROBABILISTIC I ===========================
//=========================================================================

//Updated: January 25, 2024

//===========================READ-ME=======================================
  //DESCRIPTION: Collect data on mice ability to find higher reward 
  //probability side and update contingencies at uncued block switches, 
  //using 80:20 blocks (i.e., 80% reward probability with push, 20% reward
  //probability with pull, or vice-versa). 
  
  //DISPLACEMENT THRESHOLD: 3mm
  
  //REWARD VOLUME: 8uL
  
  //CRITERION: Until you have enough data. They should be able to do this 
  //just fine, aim for >65% uncorrected accuracy or >70% preference for 
  //rewarded side for a couple days, with >100 rewards each day.
  
  //SAME DAY SWITCH?: No, no rush.

//=======================INITIAL SETUP=====================================

  //Include necessary libraries
    #include <SoftwareSerial.h> //Should be built in
    #include <Wire.h>      //Download I2C Library here: https://www.arduino.cc/reference/en/libraries/liquidcrystal-i2c/
    #include <Servo.h> 
   
  //Assign Pins:
    byte BoxLight = 2; //Enter Box Light Pin
    byte MyServo = 9; //Enter Servo Pin
    byte LickometerLED = 10; //Enter Lickometer built-in LED Pin
    byte LickLED = 11; //Enter Lick LED Pin that separate will light up when mouse licks
    byte Lickometer = 12; //Enter Lickometer Pin
    byte Pump = 13; //Enter Pump Pin
    byte PumpOn = 8; //Enter Pump Pin 1A
    byte PumpKeepLow = 7; //Enter Pump Pin 2A - keep this low
    byte Joystick1 = A1; //input pin 1 from joystick
    byte Joystick3 = A3; //input pin 3 from joystick (the one we care more about)
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

  //==========================================PARAMETERS==============================================
  //==================================================================================================
  //==========================FIXED=============================
    const int ToneDuration = 0; //set to zero because I won't play the rew+/- tones so don't need to allow time for them
    const int ServoDuration = 500; //THIS IS JUST HOW LONG IT TAKES FOR THE SERVO TO RETRACT

    
  //=====================TEMPORAL===============================
    const int MaxTrialDuration = 10000; // Maximum Trial Duration is ten seconds
    const int InitialDelay = 10000; // Initial Delay is ten seconds
    const int TimeOutDelay = 15000; //Delay+timeout after unrewarded trials is 15 seconds
    const int OnDuration = 80; // ON time for pump (100ms for 10uL; 80ms for 7.5uL; 60ms 5uL; 40ms 2.5uL Last Calibration: 1/23/2022)
    const int ServoReadDelay = 1250; //delay after retraction before reading joystick position - to avoid mice holding onto joystick biasing baseline read
    const int OptoDuration = 2500; //duration of post-choice opto

  //===================JOYSTICK-RELATED=========================
    const int BaselineReadInterval = 50; //when reading joystick baseline position, read position every X milliseconds
    const int ReadTimes = 50; //when reading joystick baseline position, over how many readings do you want to average
    const int InterReadInterval = 15; //when reading joystick inter-trial position, read position every X milliseconds
    const int ReadInterTimes = 15; //when reading joystick inter-trial position, over how many readings do you want to average
    const int NoRetractTrials = 0; //number of initial trials where joystick doesn't retract
    const int Displ = 3000; //set joystick displacement threshold
    const int JoyTempSensi=4000; //set temporal resolution for Joystick reading
    const int JoyAvSensi = 1000; //set tepmoral resolution for computing moving average - 1 kHz (might not be feasible with baud rate)
    const int ServoBack = 0;
    const int ServoForward = 150;
    const int AvReads = 20; //number of reads forming foundation of moving average
    
  //=========EXPONENTIAL DISTRIBUTION PARAMETER SETTINGS========
    //exponential distribution parameter settings (see Expo Distri file) = -log(1-u)/lambda
    //lambda 0.3 upper bound 1 and lower bound 0, minimum 2.5 should give range from 2.5-8sec ITI with mean and median of 3.5ish
    //EXPONENTIAL DISTRIBUTION PARAMETERS FOR ITI
    float Lambda = 0.3; //ITI lambda (on exponential)
    float MinimumITI = 2500; //in msec
    long MaximumITI = 8000; //in msec
    long RandLowerU = 0; //inclusive lower bound of u msec
    long RandUpperU = 1000; //exclusive upper bound of u msec

//    //EXPONENTIAL DISTRIBUTION PARAMETERS FOR PRE-CUE INTERVAL - ONLY VALID FOR PHASE 2 ONWARDS
//    float PreCueLambda = 2; //pre-go-cue lambda (on exponential)
//    float MinimumPreCue = 100; //pre-go-cue minimum duration (msec)
//    int MaximumPreCue = 500; //pre-go-cue maximum duration (msec)
//    long PreCueRandLowerU = 0; //inclusive lower bound of u msec
//    long PreCueRandUpperU = 1000; //exclusive upper bound of u msec
      long PreCueInterval = 100;


  //=========GEOMETRIC DISTRIBUTION PARAMETER SETTINGS========
    long GeoRandLowerPk = 1; //inclusive lower bound of P(k) probability
    long GeoRandUpperPk = 100000; //exclusive upper bound of P(k) probability
    float GeoP = 0.4;
    int MinimumBlockLength = 17; //minimum number of rewarded trials per block

  //========PROBABILISTIC PARAMETER SETTINGS=================
    int HighOdds = 800; //100% is 1000
    int LowOdds = 200; //100% is 1000

  //========FORCED SERIAL REVERSAL BLOCKS====================
    //settings to force two 100:0 serial reversal blocks at outset. 
    bool ForceSerial = 1; //1- forced 100:0 at outset is ON. 0 - forced 100:0 at outset is OFF.
    int ForceSerialBlocks = 2; //number of 100:0 blocks at outset. 

    
  //==========================================VARIABLES===============================================
  //==================================================================================================
    //=============================FLAGS==========================
    bool Started = 0; //flag to mark program has started
      bool Initiated = 0; //flag that marks manual initiation of trial
      bool InitialDelayOccurred = 0; //for marking occurrence of initial delay
      bool StartedBx = 0; //flag to mark that behavior session has started
      bool LickNow = 0; //flag for sensing lickometer activation
      bool SetMilliJoy = 0; //flag for reading joystick position
      bool SetMilliJoyAv = 0; //flag for reading average joystick position
      bool BaselineReadYN = 0; //flag for reading joystick position
      bool InterReadYN = 0; //flag for resetting joystick baseline position between trials
      bool SetMilliRead = 0; //flag for reading joystick position
      bool SetMilliInterRead = 0; //flag for reading joystick position between trials
      bool ServoMove = 0; //flag for servo movement
      bool ServoMoving = 0; //flag for CURRENT servo movement
      bool ServoBackPos = 0; //flag to track servo retraction
      bool StartNextBlock = 0; //flag to keep track of starting next block
      byte Flags = 0; //1 - trial start; 2 - wait period end; 3 - choice registered and outcome starts; 4 - outcome complete; 5 - ITI start; 6 - joystick extends
      byte OutcomeFlags = 0; //1 - rewarded; 2 - unrewarded; 3 - omission; 4 - premature rewarded; 5 - premature unrewarded;
      bool LickFlag;
      bool ReadJoystick;
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

      bool Concluded = 0; //flag to wrap up trial
      bool Unrewarded = 0; //Unrewarded trial flag
      bool Omitted = 0; //Omission flag
      bool Prematured = 0; //Premature flag
      bool Rewarded = 0; //Reward flag
      bool TrialDone = 0; //flag for completed trial
      bool Tripped = 0; //to mark joystick crossing threshold
      bool TrippedPush = 0; //to mark joystick crossing threshold for push
      bool TrippedPull = 0; //to mark joystick crossing threshold for pull
      bool TrippedNothing = 0; //to mark crossing threshold for unrewarded direction
      bool PumpOpen = 0; //to mark if solenoid pump is passing water
      bool CuePlayed = 0; //flag for whether lickometer LED was turned on yet or not
      bool TimeOut = 0; //flag for time-out
      bool Optoed = 0;

      bool ObtainRewardPush;
      bool ObtainRewardPull;
   
    //===========================COUNTERS=========================
    int TotalLicks = 0; //for counting individual licks
    int Omissions = 0; //for counting omissions
    int Unrewardeds = 0; //for counting unrewarded trials
    int Premature = 0; //for counting premature trials (pre-go-cue responding)
    int PrematureRewarded; //for counting within premature trials whether the direction was rewarded
    int PrematureUnrewarded; //for counting within premature trials whether the direction was unrewarded
    int Rewards = 0; //number of rewards
    int BlockRewards = 0; //number of rewards in a given block
    int BlockRewardsAdvSide = 0; //number of rewards on advantageous side in a given block
    int TrialNumber = 0; //for counting trials
    int Pushes = 0; //number of pushes
    int Pulls = 0; //number of pulls
    int BlockNumber = 0; //number of current block
    int HighProbPush; //for pushes when those are the higher-reward-probability direction
    int HighProbPull;  //for counting pulls when those are the higher-reward-probability direction
    int HighProbMov; //for counting number of trials in high probability directions (excluding prematures)
    int LowProbMov; //for counting number of trials in low probability directions (excluding prematures)

    //=========================TIMESTAMPS=========================
    long StartTime = 0; //this is when the program is started
    long TrialStartTime = 0; //this is when the trial "starts", i.e., joystick is finished extending; but before the go cue comes on. 
    long TrialDoneTime = 0; //for writing trial done time
    
    //===========================TIMERS===========================
    long UnrewardedMillis; //for measuring duration after unrewarded trials
    long RewardMillis; //for measuring duration after reward trials
    long OutcomeMillis;
    long TrialDuration = 0; //for measuring trial duration (negative for premature trials)
    long MilliJoy = 0; //for measuring joystick position
    long MilliJoyAv; 
    long MilliRead = 0; //for measuring joystick position
    long MilliInterRead = 0; //for measuring joystick position between trials
    unsigned long ServoStart = 0; //for moving servo
    long ServoBackStart = 0; //for retracting servo
        long SoundTimer = 0;
        long OptoMillis = 0;
    long TTL4Millis = 0;
    
    //==========================FUNCTIONAL========================
    int LickCounter = 0; //for clustering serial lickometer activation
    long RandSec; //repository for random seconds
    int NumRead = 0; //for reading joystick position
    int NumInterRead = 0; //for reading joystick position between trials
    long ReadTotalA1 = 0; //for reading joystick position
    float ReadTotalA3 = 0; //for reading joystick position
    int JoystickBaselineA1 = 0; //for reading joystick position
    int JoystickBaselineA3 = 0; //for reading joystick position
    float FloatInterTrialInterval = 0; //Inter-trial interval to be computed
    long InterTrialInterval = 0; //conversion to long so arduino can parse
    float RandU = 0; //for computing ITI
//    float FloatPreCueInterval = 0; //Pre-cue interval to be computed
//    long PreCueInterval = 0; //conversion to long so arduino can parse
    float PreCueRandU = 0; //for computing pre-cue interval
    int LastDirection = 0; //records whether mouse pushed (1) or pulled (2) or did not register (0) on most recent trial
    int RewardDirection; //1 is push; 2 is pull, updated during the task
    int RewardPush; //probability of receiving reward from push
    int RewardPull; //probability of receiving reward from pull
    float GeoRandPk; //random P(k) from geometric distribution with p = defined above
    float GeoLengthFloat; //for computing geometrically distributed length variable
    int BlockLength;
    int PrevBaselineA3 = 0; //for alarm
    int JoystickArrayA1[AvReads]; //array to collect joystick position information
    float JoystickArrayA3[AvReads]; //array to collect joystick position information
    int JoystickArrayIndex;
    long SumReadsA1;
    float SumReadsA3;
    int A1MovingAverage;
    int A3MovingAverage;
    int Box;
    float m;
    float b; 
    int BoxEntered;
    int RewardDiceDirPush;
    int RewardDiceDirPull;
    int RewProbPush;
    int RewProbPull;

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
            pinMode(BNCTTL1Pin, OUTPUT);
      pinMode(BNCTTL2Pin, OUTPUT);
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
    
    //Set up random seed (to increase randomness of randomization https://www.arduino.cc/reference/en/language/functions/random-numbers/randomseed/):
      randomSeed(analogRead(A0));

    //Turn on box light
    digitalWrite(BoxLight,HIGH); 
}

void loop() {
  // put your main code here, to run repeatedly:

  
  //Prompt user to enter box number 
    if (Started == 0 && BoxEntered == 0)
    {
    Serial.print(F("Enter box number: "));
    while (Serial.available() == 0)
    {
    }
    Box = Serial.parseInt();
    Serial.println(Box);
    if (Box == 1)
    {
      m = 4.55;
      b = 489.71;
      BoxEntered = 1;
      delay(2000);
    }
    if (Box == 2)
    {
      m = 4.73;
      b = 487.79;
      BoxEntered = 1;
      delay(2000);
    }
    if (Box == 3)
    {
      m = 4.90;
      b = 497.43;
      BoxEntered = 1;
      delay(2000);
    }
    if (Box == 4)
    {
      m = 3.67;
      b = 498.40;
      BoxEntered = 1;
      delay(2000);
    }
    if (Box == 5)
    {
      m = 4.22;
      b = 467.97;
      BoxEntered = 1;
      delay(2000);
    }
    if (Box > 5 || Box < 1)
    {
      Serial.println(F("Invalid entry! Box number must be 1, 2, 3, 4, or 5. Please try again."));
      BoxEntered = 0;
    }
    }
    
    
  if (analogRead(A3) <400 && Started == 0 && BoxEntered ==1)
  { 
      Serial.println(F("ProbabilisticPhase06.1-ProbabilisticI"));
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
      Serial.print(F("servoMoving"));
      Serial.print(F(","));
      Serial.print(F("A1PosBaseline"));
      Serial.print(F(","));
      Serial.print(F("A3PosBaseline"));
      Serial.print(F(","));
      Serial.print(F("rewardDirection"));
      Serial.print(F(","));
      Serial.print(F("rewardProbabilityPush"));
      Serial.print(F(","));
      Serial.print(F("rewardProbabilityPull"));
      Serial.print(F(","));
      Serial.print(F("obtainRewardPush"));
      Serial.print(F(","));
      Serial.print(F("obtainRewardPull"));
      Serial.print(F(","));
      Serial.print(F("lastDirection"));
      Serial.print(F(","));
      Serial.print(F("trialNumber"));
      Serial.print(F(","));
      Serial.print(F("blockNumber"));
      Serial.print(F(","));
      Serial.print(F("blockLength"));
      Serial.print(F(","));
      Serial.print(F("rewardsThisBlock"));
      Serial.print(F(","));
      Serial.print(F("rewardsThisBlockAdvSide"));
      Serial.print(F(","));
      Serial.print(F("trialDuration"));
      Serial.print(F(","));
      Serial.print(F("ITI"));
      Serial.print(F(","));
      Serial.print(F("preCueInterval"));
      Serial.print(F(","));
      Serial.print(F("pushes"));
      Serial.print(F(","));
      Serial.print(F("pulls"));
      Serial.print(F(","));
      Serial.print(F("highProb"));
      Serial.print(F(","));
      Serial.print(F("lowProb"));
      Serial.print(F(","));
      Serial.print(F("numRewards"));
      Serial.print(F(","));
      Serial.print(F("numOmissions"));
      Serial.print(F(","));
      Serial.print(F("numUnrewardeds"));
      Serial.print(F(","));
      Serial.print(F("numPrematures"));
      Serial.print(F(","));
      Serial.print(F("numPrematuresRewarded"));
      Serial.print(F(","));
      Serial.print(F("numPrematuresUnrewarded"));
      Serial.print(F(","));
      Serial.print(F("currentLick"));
      Serial.print(F(","));
      Serial.print(F("totalLicks"));
      Serial.print(F(","));
      Serial.print(F("outcomeFlags"));
      Serial.print(F(","));
        Serial.print(F("flags"));
        Serial.print(F(","));
        Serial.print(F("BNCTTL1"));
        Serial.print(F(","));
        Serial.print(F("BNCTTL2"));
        Serial.print(F(","));
        Serial.print(F("OptoStart"));
        Serial.print(F(","));
        Serial.println(F("OptoStop"));
      Started = 1;
      digitalWrite(StartSignalTTL,HIGH);
  }

  if (Started ==1)
    {
      //read joystick baseline position
      if (InitialDelayOccurred == 0)
      {
        delay(2000);
        InitialDelayOccurred = 1;
        digitalWrite(StartSignalTTL,LOW);
        ReadJoystick = 0;
      }
      if (BaselineReadYN == 0)
      {
        if (SetMilliRead == 0)
        {
          MilliRead = millis();
          SetMilliRead = 1;
          digitalWrite(LickometerLED,HIGH);
        }
        if ((millis() - MilliRead >= BaselineReadInterval)&& (NumRead < ReadTimes))
        {
          ReadTotalA1 = ReadTotalA1 + analogRead(A1);
          ReadTotalA3 = ReadTotalA3 + ((analogRead(A3)-b)/m);
          NumRead = NumRead + 1;
          SetMilliRead = 0; 
        }
        if (NumRead >= ReadTimes)
        {
          JoystickBaselineA1 = ReadTotalA1/NumRead;
          JoystickBaselineA3 = int(ReadTotalA3*1000/NumRead);
          BaselineReadYN = 1;
          Initiated = 1;
          digitalWrite(StartTTLPin,HIGH);
          StartTTLPinState = 1;
          StartTime = millis();
          NumRead = 0;
          digitalWrite(LickometerLED,LOW);
        }
      }
    }
  if (Initiated == 1)
  {
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
      {
        ++TotalLicks;
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
        Serial.print(ServoMoving);
        Serial.print(F(","));
        Serial.print(JoystickBaselineA1);
        Serial.print(F(","));
        Serial.print(JoystickBaselineA3);
        Serial.print(F(","));
        Serial.print(RewardDirection);
        Serial.print(F(","));
        Serial.print(RewProbPush);
        Serial.print(F(","));
        Serial.print(RewProbPull);
        Serial.print(F(","));
        Serial.print(ObtainRewardPush);
        Serial.print(F(","));
        Serial.print(ObtainRewardPull);
        Serial.print(F(","));
        Serial.print(LastDirection);
        Serial.print(F(","));
        Serial.print(TrialNumber);
        Serial.print(F(","));
        Serial.print(BlockNumber);
        Serial.print(F(","));
        Serial.print(BlockLength);
        Serial.print(F(","));
        Serial.print(BlockRewards);
        Serial.print(F(","));
        Serial.print(BlockRewardsAdvSide);
        Serial.print(F(","));
        Serial.print(TrialDuration);
        Serial.print(F(","));
        Serial.print(InterTrialInterval);
        Serial.print(F(","));
        Serial.print(PreCueInterval);
        Serial.print(F(","));
        Serial.print(Pushes);
        Serial.print(F(","));
        Serial.print(Pulls);
        Serial.print(F(","));
        Serial.print(HighProbMov);
        Serial.print(F(","));
        Serial.print(LowProbMov);
        Serial.print(F(","));
        Serial.print(Rewards);
        Serial.print(F(","));
        Serial.print(Omissions);
        Serial.print(F(","));
        Serial.print(Unrewardeds);
        Serial.print(F(","));
        Serial.print(Premature);
        Serial.print(F(","));
        Serial.print(PrematureRewarded);
        Serial.print(F(","));
        Serial.print(PrematureUnrewarded);
        Serial.print(F(","));
        Serial.print(LickFlag);
        Serial.print(F(","));
        Serial.print(TotalLicks);
        Serial.print(F(","));
        Serial.print(OutcomeFlags);
        Serial.print(F(","));
        Serial.print(Flags);
        Serial.print(F(","));
        Serial.print(BNCTTL1);
        Serial.print(F(","));
        Serial.print(BNCTTL2);
        Serial.print(F(","));
        Serial.print(TTL3);
        Serial.print(F(","));
        Serial.println(TTL4);
        LickFlag = 0;
      }
    }

    //Read joystick every JoyTempSensi milliseconds
    if (SetMilliJoy ==0)
    {
      MilliJoy = micros();
      SetMilliJoy = 1;
    }
    if ((micros() - MilliJoy) >= JoyTempSensi && ReadJoystick ==1)
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
        Serial.print(ServoMoving);
        Serial.print(F(","));
        Serial.print(JoystickBaselineA1);
        Serial.print(F(","));
        Serial.print(JoystickBaselineA3);
        Serial.print(F(","));
        Serial.print(RewardDirection);
        Serial.print(F(","));
        Serial.print(RewProbPush);
        Serial.print(F(","));
        Serial.print(RewProbPull);
        Serial.print(F(","));
        Serial.print(ObtainRewardPush);
        Serial.print(F(","));
        Serial.print(ObtainRewardPull);
        Serial.print(F(","));
        Serial.print(LastDirection);
        Serial.print(F(","));
        Serial.print(TrialNumber);
        Serial.print(F(","));
        Serial.print(BlockNumber);
        Serial.print(F(","));
        Serial.print(BlockLength);
        Serial.print(F(","));
        Serial.print(BlockRewards);
        Serial.print(F(","));
        Serial.print(BlockRewardsAdvSide);
        Serial.print(F(","));
        Serial.print(TrialDuration);
        Serial.print(F(","));
        Serial.print(InterTrialInterval);
        Serial.print(F(","));
        Serial.print(PreCueInterval);
        Serial.print(F(","));
        Serial.print(Pushes);
        Serial.print(F(","));
        Serial.print(Pulls);
        Serial.print(F(","));
        Serial.print(HighProbMov);
        Serial.print(F(","));
        Serial.print(LowProbMov);
        Serial.print(F(","));
        Serial.print(Rewards);
        Serial.print(F(","));
        Serial.print(Omissions);
        Serial.print(F(","));
        Serial.print(Unrewardeds);
        Serial.print(F(","));
        Serial.print(Premature);
        Serial.print(F(","));
        Serial.print(PrematureRewarded);
        Serial.print(F(","));
        Serial.print(PrematureUnrewarded);
        Serial.print(F(","));
        Serial.print(LickFlag);
        Serial.print(F(","));
        Serial.print(TotalLicks);
        Serial.print(F(","));
        Serial.print(OutcomeFlags);
        Serial.print(F(","));
        Serial.print(Flags);
        Serial.print(F(","));
        Serial.print(BNCTTL1);
        Serial.print(F(","));
        Serial.print(BNCTTL2);
        Serial.print(F(","));
        Serial.print(TTL3);
        Serial.print(F(","));
        Serial.println(TTL4);
        SetMilliJoy = 0;
    }

 //turn off TTLs after 1 second of being on
    if (BNCTTL1State ==1 && millis()-OutcomeMillis >=1000)
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
        Serial.print(ServoMoving);
        Serial.print(F(","));
        Serial.print(JoystickBaselineA1);
        Serial.print(F(","));
        Serial.print(JoystickBaselineA3);
        Serial.print(F(","));
        Serial.print(RewardDirection);
        Serial.print(F(","));
        Serial.print(RewProbPush);
        Serial.print(F(","));
        Serial.print(RewProbPull);
        Serial.print(F(","));
        Serial.print(ObtainRewardPush);
        Serial.print(F(","));
        Serial.print(ObtainRewardPull);
        Serial.print(F(","));
        Serial.print(LastDirection);
        Serial.print(F(","));
        Serial.print(TrialNumber);
        Serial.print(F(","));
        Serial.print(BlockNumber);
        Serial.print(F(","));
        Serial.print(BlockLength);
        Serial.print(F(","));
        Serial.print(BlockRewards);
        Serial.print(F(","));
        Serial.print(BlockRewardsAdvSide);
        Serial.print(F(","));
        Serial.print(TrialDuration);
        Serial.print(F(","));
        Serial.print(InterTrialInterval);
        Serial.print(F(","));
        Serial.print(PreCueInterval);
        Serial.print(F(","));
        Serial.print(Pushes);
        Serial.print(F(","));
        Serial.print(Pulls);
        Serial.print(F(","));
        Serial.print(HighProbMov);
        Serial.print(F(","));
        Serial.print(LowProbMov);
        Serial.print(F(","));
        Serial.print(Rewards);
        Serial.print(F(","));
        Serial.print(Omissions);
        Serial.print(F(","));
        Serial.print(Unrewardeds);
        Serial.print(F(","));
        Serial.print(Premature);
        Serial.print(F(","));
        Serial.print(PrematureRewarded);
        Serial.print(F(","));
        Serial.print(PrematureUnrewarded);
        Serial.print(F(","));
        Serial.print(LickFlag);
        Serial.print(F(","));
        Serial.print(TotalLicks);
        Serial.print(F(","));
        Serial.print(OutcomeFlags);
        Serial.print(F(","));
        Serial.print(Flags);
        Serial.print(F(","));
        Serial.print(BNCTTL1);
        Serial.print(F(","));
        Serial.print(BNCTTL2);
        Serial.print(F(","));
        Serial.print(TTL3);
        Serial.print(F(","));
        Serial.println(TTL4);
        BNCTTL1 = 0;
    }
    if (BNCTTL2State ==1 && millis()-ServoStart >=1000)
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
        Serial.print(ServoMoving);
        Serial.print(F(","));
        Serial.print(JoystickBaselineA1);
        Serial.print(F(","));
        Serial.print(JoystickBaselineA3);
        Serial.print(F(","));
        Serial.print(RewardDirection);
        Serial.print(F(","));
        Serial.print(RewProbPush);
        Serial.print(F(","));
        Serial.print(RewProbPull);
        Serial.print(F(","));
        Serial.print(ObtainRewardPush);
        Serial.print(F(","));
        Serial.print(ObtainRewardPull);
        Serial.print(F(","));
        Serial.print(LastDirection);
        Serial.print(F(","));
        Serial.print(TrialNumber);
        Serial.print(F(","));
        Serial.print(BlockNumber);
        Serial.print(F(","));
        Serial.print(BlockLength);
        Serial.print(F(","));
        Serial.print(BlockRewards);
        Serial.print(F(","));
        Serial.print(BlockRewardsAdvSide);
        Serial.print(F(","));
        Serial.print(TrialDuration);
        Serial.print(F(","));
        Serial.print(InterTrialInterval);
        Serial.print(F(","));
        Serial.print(PreCueInterval);
        Serial.print(F(","));
        Serial.print(Pushes);
        Serial.print(F(","));
        Serial.print(Pulls);
        Serial.print(F(","));
        Serial.print(HighProbMov);
        Serial.print(F(","));
        Serial.print(LowProbMov);
        Serial.print(F(","));
        Serial.print(Rewards);
        Serial.print(F(","));
        Serial.print(Omissions);
        Serial.print(F(","));
        Serial.print(Unrewardeds);
        Serial.print(F(","));
        Serial.print(Premature);
        Serial.print(F(","));
        Serial.print(PrematureRewarded);
        Serial.print(F(","));
        Serial.print(PrematureUnrewarded);
        Serial.print(F(","));
        Serial.print(LickFlag);
        Serial.print(F(","));
        Serial.print(TotalLicks);
        Serial.print(F(","));
        Serial.print(OutcomeFlags);
        Serial.print(F(","));
        Serial.print(Flags);
        Serial.print(F(","));
        Serial.print(BNCTTL1);
        Serial.print(F(","));
        Serial.print(BNCTTL2);
        Serial.print(F(","));
        Serial.print(TTL3);
        Serial.print(F(","));
        Serial.println(TTL4);
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
        Serial.print(ServoMoving);
        Serial.print(F(","));
        Serial.print(JoystickBaselineA1);
        Serial.print(F(","));
        Serial.print(JoystickBaselineA3);
        Serial.print(F(","));
        Serial.print(RewardDirection);
        Serial.print(F(","));
        Serial.print(RewProbPush);
        Serial.print(F(","));
        Serial.print(RewProbPull);
        Serial.print(F(","));
        Serial.print(ObtainRewardPush);
        Serial.print(F(","));
        Serial.print(ObtainRewardPull);
        Serial.print(F(","));
        Serial.print(LastDirection);
        Serial.print(F(","));
        Serial.print(TrialNumber);
        Serial.print(F(","));
        Serial.print(BlockNumber);
        Serial.print(F(","));
        Serial.print(BlockLength);
        Serial.print(F(","));
        Serial.print(BlockRewards);
        Serial.print(F(","));
        Serial.print(BlockRewardsAdvSide);
        Serial.print(F(","));
        Serial.print(TrialDuration);
        Serial.print(F(","));
        Serial.print(InterTrialInterval);
        Serial.print(F(","));
        Serial.print(PreCueInterval);
        Serial.print(F(","));
        Serial.print(Pushes);
        Serial.print(F(","));
        Serial.print(Pulls);
        Serial.print(F(","));
        Serial.print(HighProbMov);
        Serial.print(F(","));
        Serial.print(LowProbMov);
        Serial.print(F(","));
        Serial.print(Rewards);
        Serial.print(F(","));
        Serial.print(Omissions);
        Serial.print(F(","));
        Serial.print(Unrewardeds);
        Serial.print(F(","));
        Serial.print(Premature);
        Serial.print(F(","));
        Serial.print(PrematureRewarded);
        Serial.print(F(","));
        Serial.print(PrematureUnrewarded);
        Serial.print(F(","));
        Serial.print(LickFlag);
        Serial.print(F(","));
        Serial.print(TotalLicks);
        Serial.print(F(","));
        Serial.print(OutcomeFlags);
        Serial.print(F(","));
        Serial.print(Flags);
        Serial.print(F(","));
        Serial.print(BNCTTL1);
        Serial.print(F(","));
        Serial.print(BNCTTL2);
        Serial.print(F(","));
        Serial.print(TTL3);
        Serial.print(F(","));
        Serial.println(TTL4);
      StartTTL = 0;
    }

    if (TTL3PinState ==1 && millis()-OptoMillis >=1000)
    {
      digitalWrite(TTL3Pin, LOW);
      TTL3PinState = 0;
      TTL3 = 2;
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
        Serial.print(ServoMoving);
        Serial.print(F(","));
        Serial.print(JoystickBaselineA1);
        Serial.print(F(","));
        Serial.print(JoystickBaselineA3);
        Serial.print(F(","));
        Serial.print(RewardDirection);
        Serial.print(F(","));
        Serial.print(RewProbPush);
        Serial.print(F(","));
        Serial.print(RewProbPull);
        Serial.print(F(","));
        Serial.print(ObtainRewardPush);
        Serial.print(F(","));
        Serial.print(ObtainRewardPull);
        Serial.print(F(","));
        Serial.print(LastDirection);
        Serial.print(F(","));
        Serial.print(TrialNumber);
        Serial.print(F(","));
        Serial.print(BlockNumber);
        Serial.print(F(","));
        Serial.print(BlockLength);
        Serial.print(F(","));
        Serial.print(BlockRewards);
        Serial.print(F(","));
        Serial.print(BlockRewardsAdvSide);
        Serial.print(F(","));
        Serial.print(TrialDuration);
        Serial.print(F(","));
        Serial.print(InterTrialInterval);
        Serial.print(F(","));
        Serial.print(PreCueInterval);
        Serial.print(F(","));
        Serial.print(Pushes);
        Serial.print(F(","));
        Serial.print(Pulls);
        Serial.print(F(","));
        Serial.print(HighProbMov);
        Serial.print(F(","));
        Serial.print(LowProbMov);
        Serial.print(F(","));
        Serial.print(Rewards);
        Serial.print(F(","));
        Serial.print(Omissions);
        Serial.print(F(","));
        Serial.print(Unrewardeds);
        Serial.print(F(","));
        Serial.print(Premature);
        Serial.print(F(","));
        Serial.print(PrematureRewarded);
        Serial.print(F(","));
        Serial.print(PrematureUnrewarded);
        Serial.print(F(","));
        Serial.print(LickFlag);
        Serial.print(F(","));
        Serial.print(TotalLicks);
        Serial.print(F(","));
        Serial.print(OutcomeFlags);
        Serial.print(F(","));
        Serial.print(Flags);
        Serial.print(F(","));
        Serial.print(BNCTTL1);
        Serial.print(F(","));
        Serial.print(BNCTTL2);
        Serial.print(F(","));
        Serial.print(TTL3);
        Serial.print(F(","));
        Serial.println(TTL4);
      TTL3 = 0;
    }

    if (TTL4PinState == 0 && millis()-OptoMillis >=OptoDuration && Optoed == 1)
    {
      Optoed = 0;
      digitalWrite(TTL4Pin, HIGH);
      TTL4PinState = 1;
      TTL4 = 1;
      TTL4Millis = millis();
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
        Serial.print(ServoMoving);
        Serial.print(F(","));
        Serial.print(JoystickBaselineA1);
        Serial.print(F(","));
        Serial.print(JoystickBaselineA3);
        Serial.print(F(","));
        Serial.print(RewardDirection);
        Serial.print(F(","));
        Serial.print(RewProbPush);
        Serial.print(F(","));
        Serial.print(RewProbPull);
        Serial.print(F(","));
        Serial.print(ObtainRewardPush);
        Serial.print(F(","));
        Serial.print(ObtainRewardPull);
        Serial.print(F(","));
        Serial.print(LastDirection);
        Serial.print(F(","));
        Serial.print(TrialNumber);
        Serial.print(F(","));
        Serial.print(BlockNumber);
        Serial.print(F(","));
        Serial.print(BlockLength);
        Serial.print(F(","));
        Serial.print(BlockRewards);
        Serial.print(F(","));
        Serial.print(BlockRewardsAdvSide);
        Serial.print(F(","));
        Serial.print(TrialDuration);
        Serial.print(F(","));
        Serial.print(InterTrialInterval);
        Serial.print(F(","));
        Serial.print(PreCueInterval);
        Serial.print(F(","));
        Serial.print(Pushes);
        Serial.print(F(","));
        Serial.print(Pulls);
        Serial.print(F(","));
        Serial.print(HighProbMov);
        Serial.print(F(","));
        Serial.print(LowProbMov);
        Serial.print(F(","));
        Serial.print(Rewards);
        Serial.print(F(","));
        Serial.print(Omissions);
        Serial.print(F(","));
        Serial.print(Unrewardeds);
        Serial.print(F(","));
        Serial.print(Premature);
        Serial.print(F(","));
        Serial.print(PrematureRewarded);
        Serial.print(F(","));
        Serial.print(PrematureUnrewarded);
        Serial.print(F(","));
        Serial.print(LickFlag);
        Serial.print(F(","));
        Serial.print(TotalLicks);
        Serial.print(F(","));
        Serial.print(OutcomeFlags);
        Serial.print(F(","));
        Serial.print(Flags);
        Serial.print(F(","));
        Serial.print(BNCTTL1);
        Serial.print(F(","));
        Serial.print(BNCTTL2);
        Serial.print(F(","));
        Serial.print(TTL3);
        Serial.print(F(","));
        Serial.println(TTL4);
      TTL4 = 0;
    }

    if (TTL4PinState == 1 && millis()-TTL4Millis >=1000)
    {
      digitalWrite(TTL4Pin, LOW);
      TTL4PinState = 0;
      TTL4 = 2;
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
        Serial.print(ServoMoving);
        Serial.print(F(","));
        Serial.print(JoystickBaselineA1);
        Serial.print(F(","));
        Serial.print(JoystickBaselineA3);
        Serial.print(F(","));
        Serial.print(RewardDirection);
        Serial.print(F(","));
        Serial.print(RewProbPush);
        Serial.print(F(","));
        Serial.print(RewProbPull);
        Serial.print(F(","));
        Serial.print(ObtainRewardPush);
        Serial.print(F(","));
        Serial.print(ObtainRewardPull);
        Serial.print(F(","));
        Serial.print(LastDirection);
        Serial.print(F(","));
        Serial.print(TrialNumber);
        Serial.print(F(","));
        Serial.print(BlockNumber);
        Serial.print(F(","));
        Serial.print(BlockLength);
        Serial.print(F(","));
        Serial.print(BlockRewards);
        Serial.print(F(","));
        Serial.print(BlockRewardsAdvSide);
        Serial.print(F(","));
        Serial.print(TrialDuration);
        Serial.print(F(","));
        Serial.print(InterTrialInterval);
        Serial.print(F(","));
        Serial.print(PreCueInterval);
        Serial.print(F(","));
        Serial.print(Pushes);
        Serial.print(F(","));
        Serial.print(Pulls);
        Serial.print(F(","));
        Serial.print(HighProbMov);
        Serial.print(F(","));
        Serial.print(LowProbMov);
        Serial.print(F(","));
        Serial.print(Rewards);
        Serial.print(F(","));
        Serial.print(Omissions);
        Serial.print(F(","));
        Serial.print(Unrewardeds);
        Serial.print(F(","));
        Serial.print(Premature);
        Serial.print(F(","));
        Serial.print(PrematureRewarded);
        Serial.print(F(","));
        Serial.print(PrematureUnrewarded);
        Serial.print(F(","));
        Serial.print(LickFlag);
        Serial.print(F(","));
        Serial.print(TotalLicks);
        Serial.print(F(","));
        Serial.print(OutcomeFlags);
        Serial.print(F(","));
        Serial.print(Flags);
        Serial.print(F(","));
        Serial.print(BNCTTL1);
        Serial.print(F(","));
        Serial.print(BNCTTL2);
        Serial.print(F(","));
        Serial.print(TTL3);
        Serial.print(F(","));
        Serial.println(TTL4);
      TTL4 = 0;
    }

    if (millis()-SoundTimer >= 30)
    {
      digitalWrite(WhiteNoiseTTL,LOW);
      digitalWrite(HighToneTTL,LOW);
      digitalWrite(LowToneTTL,LOW);
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
    
    //START FIRST TRIAL
    //allow for ServoDuration time for servo to extend
    if(millis()>(InitialDelay+StartTime) && TrialNumber ==0 && ServoMove == 0) 
    {
      ServoVar.write(ServoForward); //move lever towards mouse
      ReadJoystick = 1;
      ServoStart = millis();
      ServoMove = 1;
      ServoMoving = 1;
      
//      //compute Go cue duration during this time
//      PreCueRandU = random(PreCueRandLowerU,PreCueRandUpperU);
//      FloatPreCueInterval = MinimumPreCue-((log10(1-(PreCueRandU/1000))/PreCueLambda)*1000);
//      PreCueInterval = min(MaximumPreCue,long(FloatPreCueInterval));

      //compute ITI that will follow outcome, drawn from exponential distribution
      RandU = random(RandLowerU,RandUpperU);
      FloatInterTrialInterval = MinimumITI-((log10(1-(RandU/1000))/Lambda)*1000);
      InterTrialInterval = min(MaximumITI,long(FloatInterTrialInterval));

      //Calculate reward direction for first block
      RewardDirection = random(1,3); //from uniform distribution

      //Assign reward probabilities for the block
      if (ForceSerial == 0)
      {
        if (RewardDirection ==1)
        {
          RewProbPush = HighOdds;
          RewProbPull = LowOdds;
        }
  
        if (RewardDirection ==2)
        {
          RewProbPush = LowOdds;
          RewProbPull = HighOdds;
        }
      }
      if (ForceSerial == 1)
      {
        if (RewardDirection ==1)
        {
          RewProbPush = 1000;
          RewProbPull = 0;
        }
  
        if (RewardDirection ==2)
        {
          RewProbPush = 0;
          RewProbPull = 1000;
        }
      }
      
      //Calculate first block length (in terms of number of REWARDED trials per Witten protocols - Parker papers)
      GeoRandPk = random(GeoRandLowerPk,GeoRandUpperPk);
      GeoRandPk = GeoRandPk/100000;
      GeoLengthFloat = -0.000001+(log10(1-GeoRandPk)/log10(1-GeoP));
      BlockLength = int(GeoLengthFloat)+MinimumBlockLength;

      //Calculate for each direction whether it will be rewarded or unrewarded on this trial
      RewardDiceDirPush = random(1,1001);
      RewardDiceDirPull = random(1,1001);
      if (RewardDiceDirPush>RewProbPush)
      {
        ObtainRewardPush = 0;
      }
      if (RewardDiceDirPull>RewProbPull)
      {
        ObtainRewardPull = 0;
      }
      if (RewardDiceDirPush<=RewProbPush)
      {
        ObtainRewardPush = 1;
      }
      if (RewardDiceDirPull<=RewProbPull)
      {
        ObtainRewardPull = 1;
      }

      
    }
    
    //once servo is extended, start the trial
    if((millis() - ServoStart) > ServoDuration && TrialNumber ==0 && ServoMove ==1)
    {
      TrialStartTime = millis();
      ++TrialNumber;
      ++BlockNumber;
      ServoMoving = 0;
      ServoMove = 0;
      CuePlayed = 0;
      Flags = 1;
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
        Serial.print(ServoMoving);
        Serial.print(F(","));
        Serial.print(JoystickBaselineA1);
        Serial.print(F(","));
        Serial.print(JoystickBaselineA3);
        Serial.print(F(","));
        Serial.print(RewardDirection);
        Serial.print(F(","));
        Serial.print(RewProbPush);
        Serial.print(F(","));
        Serial.print(RewProbPull);
        Serial.print(F(","));
        Serial.print(ObtainRewardPush);
        Serial.print(F(","));
        Serial.print(ObtainRewardPull);
        Serial.print(F(","));
        Serial.print(LastDirection);
        Serial.print(F(","));
        Serial.print(TrialNumber);
        Serial.print(F(","));
        Serial.print(BlockNumber);
        Serial.print(F(","));
        Serial.print(BlockLength);
        Serial.print(F(","));
        Serial.print(BlockRewards);
        Serial.print(F(","));
        Serial.print(BlockRewardsAdvSide);
        Serial.print(F(","));
        Serial.print(TrialDuration);
        Serial.print(F(","));
        Serial.print(InterTrialInterval);
        Serial.print(F(","));
        Serial.print(PreCueInterval);
        Serial.print(F(","));
        Serial.print(Pushes);
        Serial.print(F(","));
        Serial.print(Pulls);
        Serial.print(F(","));
        Serial.print(HighProbMov);
        Serial.print(F(","));
        Serial.print(LowProbMov);
        Serial.print(F(","));
        Serial.print(Rewards);
        Serial.print(F(","));
        Serial.print(Omissions);
        Serial.print(F(","));
        Serial.print(Unrewardeds);
        Serial.print(F(","));
        Serial.print(Premature);
        Serial.print(F(","));
        Serial.print(PrematureRewarded);
        Serial.print(F(","));
        Serial.print(PrematureUnrewarded);
        Serial.print(F(","));
        Serial.print(LickFlag);
        Serial.print(F(","));
        Serial.print(TotalLicks);
        Serial.print(F(","));
        Serial.print(OutcomeFlags);
        Serial.print(F(","));
        Serial.print(Flags);
        Serial.print(F(","));
        Serial.print(BNCTTL1);
        Serial.print(F(","));
        Serial.print(BNCTTL2);
        Serial.print(F(","));
        Serial.print(TTL3);
        Serial.print(F(","));
        Serial.println(TTL4);
      Flags = 0;
      StartedBx = 1;
    }
    if(StartedBx == 1) 
    {
      //Check Pre-Cue Interval
      if((millis() - TrialStartTime) > PreCueInterval && CuePlayed == 0 && TimeOut == 0)
      {
        digitalWrite(LickometerLED,HIGH);
        Flags = 2;
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
        Serial.print(ServoMoving);
        Serial.print(F(","));
        Serial.print(JoystickBaselineA1);
        Serial.print(F(","));
        Serial.print(JoystickBaselineA3);
        Serial.print(F(","));
        Serial.print(RewardDirection);
        Serial.print(F(","));
        Serial.print(RewProbPush);
        Serial.print(F(","));
        Serial.print(RewProbPull);
        Serial.print(F(","));
        Serial.print(ObtainRewardPush);
        Serial.print(F(","));
        Serial.print(ObtainRewardPull);
        Serial.print(F(","));
        Serial.print(LastDirection);
        Serial.print(F(","));
        Serial.print(TrialNumber);
        Serial.print(F(","));
        Serial.print(BlockNumber);
        Serial.print(F(","));
        Serial.print(BlockLength);
        Serial.print(F(","));
        Serial.print(BlockRewards);
        Serial.print(F(","));
        Serial.print(BlockRewardsAdvSide);
        Serial.print(F(","));
        Serial.print(TrialDuration);
        Serial.print(F(","));
        Serial.print(InterTrialInterval);
        Serial.print(F(","));
        Serial.print(PreCueInterval);
        Serial.print(F(","));
        Serial.print(Pushes);
        Serial.print(F(","));
        Serial.print(Pulls);
        Serial.print(F(","));
        Serial.print(HighProbMov);
        Serial.print(F(","));
        Serial.print(LowProbMov);
        Serial.print(F(","));
        Serial.print(Rewards);
        Serial.print(F(","));
        Serial.print(Omissions);
        Serial.print(F(","));
        Serial.print(Unrewardeds);
        Serial.print(F(","));
        Serial.print(Premature);
        Serial.print(F(","));
        Serial.print(PrematureRewarded);
        Serial.print(F(","));
        Serial.print(PrematureUnrewarded);
        Serial.print(F(","));
        Serial.print(LickFlag);
        Serial.print(F(","));
        Serial.print(TotalLicks);
        Serial.print(F(","));
        Serial.print(OutcomeFlags);
        Serial.print(F(","));
        Serial.print(Flags);
        Serial.print(F(","));
        Serial.print(BNCTTL1);
        Serial.print(F(","));
        Serial.print(BNCTTL2);
        Serial.print(F(","));
        Serial.print(TTL3);
        Serial.print(F(","));
        Serial.println(TTL4);
        Flags = 0;
        CuePlayed = 1;
      }

      //JOYSTICK MOVEMENT FLAGS
      if((A3MovingAverage > (JoystickBaselineA3 + Displ)) && Tripped == 0 && TrialDone == 0 && Rewarded == 0 && Unrewarded == 0)
      {
        Tripped = 1;
        TrippedPush = 1;
        LastDirection = 1;
        ++Pushes;

      }
      if((A3MovingAverage < (JoystickBaselineA3 - Displ)) && Tripped == 0 && TrialDone == 0 && Rewarded == 0 && Unrewarded == 0)
      {
        Tripped = 1;
        TrippedPull = 1;
        LastDirection = 2;
        ++Pulls;
      }

      //=========OUTCOME FLAGS============
      //REWARDED OUTCOME FLAG
      //Set to rewarded if movement is aftr go cue
      if ((TrippedPush == 1 && ObtainRewardPush == 1) || (TrippedPull == 1 && ObtainRewardPull == 1)) 
      {
        if(Rewarded == 0 && CuePlayed ==1 && TimeOut == 0 && TrialDone == 0) 
        {
          digitalWrite(LickometerLED,LOW);
          //sfx.playTrack("T08     WAV"); //play reward tone
          RewardMillis = millis();
          Rewarded = 1;
          ++Rewards;
          
          if (TrippedPush ==1 && RewardDirection ==1)
          {
            ++HighProbPush;
            ++HighProbMov;
            ++BlockRewardsAdvSide;
          }
          if (TrippedPull ==1 && RewardDirection==2)
          {
            ++HighProbPull;
            ++HighProbMov;
            ++BlockRewardsAdvSide;
          }
          if (TrippedPush ==1 && RewardDirection ==2)
          {
            ++LowProbMov;
          }
          if (TrippedPull ==1 && RewardDirection==1)
          {
            ++LowProbMov;
          }
          ++BlockRewards;
          Flags = 3;
          OutcomeFlags = 1;
          OutcomeMillis = millis();
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
        Serial.print(ServoMoving);
        Serial.print(F(","));
        Serial.print(JoystickBaselineA1);
        Serial.print(F(","));
        Serial.print(JoystickBaselineA3);
        Serial.print(F(","));
        Serial.print(RewardDirection);
        Serial.print(F(","));
        Serial.print(RewProbPush);
        Serial.print(F(","));
        Serial.print(RewProbPull);
        Serial.print(F(","));
        Serial.print(ObtainRewardPush);
        Serial.print(F(","));
        Serial.print(ObtainRewardPull);
        Serial.print(F(","));
        Serial.print(LastDirection);
        Serial.print(F(","));
        Serial.print(TrialNumber);
        Serial.print(F(","));
        Serial.print(BlockNumber);
        Serial.print(F(","));
        Serial.print(BlockLength);
        Serial.print(F(","));
        Serial.print(BlockRewards);
        Serial.print(F(","));
        Serial.print(BlockRewardsAdvSide);
        Serial.print(F(","));
        Serial.print(TrialDuration);
        Serial.print(F(","));
        Serial.print(InterTrialInterval);
        Serial.print(F(","));
        Serial.print(PreCueInterval);
        Serial.print(F(","));
        Serial.print(Pushes);
        Serial.print(F(","));
        Serial.print(Pulls);
        Serial.print(F(","));
        Serial.print(HighProbMov);
        Serial.print(F(","));
        Serial.print(LowProbMov);
        Serial.print(F(","));
        Serial.print(Rewards);
        Serial.print(F(","));
        Serial.print(Omissions);
        Serial.print(F(","));
        Serial.print(Unrewardeds);
        Serial.print(F(","));
        Serial.print(Premature);
        Serial.print(F(","));
        Serial.print(PrematureRewarded);
        Serial.print(F(","));
        Serial.print(PrematureUnrewarded);
        Serial.print(F(","));
        Serial.print(LickFlag);
        Serial.print(F(","));
        Serial.print(TotalLicks);
        Serial.print(F(","));
        Serial.print(OutcomeFlags);
        Serial.print(F(","));
        Serial.print(Flags);
        Serial.print(F(","));
        Serial.print(BNCTTL1);
        Serial.print(F(","));
        Serial.print(BNCTTL2);
        Serial.print(F(","));
        Serial.print(TTL3);
        Serial.print(F(","));
        Serial.println(TTL4);
        BNCTTL1 = 0;
          Flags = 0;
          OutcomeFlags = 0;
        }
      }

      //UNREWARDED OUTCOME FLAG
      if ((TrippedPush == 1 && ObtainRewardPush == 0) || (TrippedPull == 1 && ObtainRewardPull == 0))
      {
        if(Unrewarded == 0 && CuePlayed == 1 && TimeOut ==0) 
        {
          digitalWrite(LickometerLED,LOW);
          digitalWrite(BoxLight,LOW);
          //sfx.playTrack("T07     WAV"); //play unrewarded tone
          UnrewardedMillis = millis();
          Unrewarded = 1;
          ++Unrewardeds;
          if (TrippedPush ==1 && RewardDirection ==1)
          {
            ++HighProbMov;
          }
          if (TrippedPull ==1 && RewardDirection==2)
          {
            ++HighProbMov;
          }
          if (TrippedPush ==1 && RewardDirection ==2)
          {
            ++LowProbMov;
          }
          if (TrippedPull ==1 && RewardDirection==1)
          {
            ++LowProbMov;
          }
          Flags = 3;
          OutcomeFlags = 2;
          OutcomeMillis = millis();
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
        Serial.print(ServoMoving);
        Serial.print(F(","));
        Serial.print(JoystickBaselineA1);
        Serial.print(F(","));
        Serial.print(JoystickBaselineA3);
        Serial.print(F(","));
        Serial.print(RewardDirection);
        Serial.print(F(","));
        Serial.print(RewProbPush);
        Serial.print(F(","));
        Serial.print(RewProbPull);
        Serial.print(F(","));
        Serial.print(ObtainRewardPush);
        Serial.print(F(","));
        Serial.print(ObtainRewardPull);
        Serial.print(F(","));
        Serial.print(LastDirection);
        Serial.print(F(","));
        Serial.print(TrialNumber);
        Serial.print(F(","));
        Serial.print(BlockNumber);
        Serial.print(F(","));
        Serial.print(BlockLength);
        Serial.print(F(","));
        Serial.print(BlockRewards);
        Serial.print(F(","));
        Serial.print(BlockRewardsAdvSide);
        Serial.print(F(","));
        Serial.print(TrialDuration);
        Serial.print(F(","));
        Serial.print(InterTrialInterval);
        Serial.print(F(","));
        Serial.print(PreCueInterval);
        Serial.print(F(","));
        Serial.print(Pushes);
        Serial.print(F(","));
        Serial.print(Pulls);
        Serial.print(F(","));
        Serial.print(HighProbMov);
        Serial.print(F(","));
        Serial.print(LowProbMov);
        Serial.print(F(","));
        Serial.print(Rewards);
        Serial.print(F(","));
        Serial.print(Omissions);
        Serial.print(F(","));
        Serial.print(Unrewardeds);
        Serial.print(F(","));
        Serial.print(Premature);
        Serial.print(F(","));
        Serial.print(PrematureRewarded);
        Serial.print(F(","));
        Serial.print(PrematureUnrewarded);
        Serial.print(F(","));
        Serial.print(LickFlag);
        Serial.print(F(","));
        Serial.print(TotalLicks);
        Serial.print(F(","));
        Serial.print(OutcomeFlags);
        Serial.print(F(","));
        Serial.print(Flags);
        Serial.print(F(","));
        Serial.print(BNCTTL1);
        Serial.print(F(","));
        Serial.print(BNCTTL2);
        Serial.print(F(","));
        Serial.print(TTL3);
        Serial.print(F(","));
        Serial.println(TTL4);
        BNCTTL1 = 0;
          Flags = 0;
          OutcomeFlags = 0;
        }
      }

      //PREMATURE OUTCOME FLAG
      if(Tripped == 1 && Rewarded == 0 && Unrewarded == 0 && CuePlayed ==0 && Prematured == 0 && TimeOut ==0)
      {
        digitalWrite(BoxLight,LOW); //turn off boxlight
        digitalWrite(LickometerLED,LOW);
        digitalWrite(WhiteNoiseTTL,HIGH);
        SoundTimer = millis();
        
        Prematured = 1;
        ++Premature;
        TimeOut = 1;
        
        if ((TrippedPush == 1 && ObtainRewardPush == 1) || (TrippedPull == 1 && ObtainRewardPull == 1))
        {
            ++PrematureRewarded;
            OutcomeFlags = 4;
        }
        if ((TrippedPush == 1 && ObtainRewardPush == 0) || (TrippedPull == 1 && ObtainRewardPull == 0))
        {
            ++PrematureUnrewarded;
            OutcomeFlags = 5;
        }
        Flags = 3;
        OutcomeMillis = millis();
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
        Serial.print(ServoMoving);
        Serial.print(F(","));
        Serial.print(JoystickBaselineA1);
        Serial.print(F(","));
        Serial.print(JoystickBaselineA3);
        Serial.print(F(","));
        Serial.print(RewardDirection);
        Serial.print(F(","));
        Serial.print(RewProbPush);
        Serial.print(F(","));
        Serial.print(RewProbPull);
        Serial.print(F(","));
        Serial.print(ObtainRewardPush);
        Serial.print(F(","));
        Serial.print(ObtainRewardPull);
        Serial.print(F(","));
        Serial.print(LastDirection);
        Serial.print(F(","));
        Serial.print(TrialNumber);
        Serial.print(F(","));
        Serial.print(BlockNumber);
        Serial.print(F(","));
        Serial.print(BlockLength);
        Serial.print(F(","));
        Serial.print(BlockRewards);
        Serial.print(F(","));
        Serial.print(BlockRewardsAdvSide);
        Serial.print(F(","));
        Serial.print(TrialDuration);
        Serial.print(F(","));
        Serial.print(InterTrialInterval);
        Serial.print(F(","));
        Serial.print(PreCueInterval);
        Serial.print(F(","));
        Serial.print(Pushes);
        Serial.print(F(","));
        Serial.print(Pulls);
        Serial.print(F(","));
        Serial.print(HighProbMov);
        Serial.print(F(","));
        Serial.print(LowProbMov);
        Serial.print(F(","));
        Serial.print(Rewards);
        Serial.print(F(","));
        Serial.print(Omissions);
        Serial.print(F(","));
        Serial.print(Unrewardeds);
        Serial.print(F(","));
        Serial.print(Premature);
        Serial.print(F(","));
        Serial.print(PrematureRewarded);
        Serial.print(F(","));
        Serial.print(PrematureUnrewarded);
        Serial.print(F(","));
        Serial.print(LickFlag);
        Serial.print(F(","));
        Serial.print(TotalLicks);
        Serial.print(F(","));
        Serial.print(OutcomeFlags);
        Serial.print(F(","));
        Serial.print(Flags);
        Serial.print(F(","));
        Serial.print(BNCTTL1);
        Serial.print(F(","));
        Serial.print(BNCTTL2);
        Serial.print(F(","));
        Serial.print(TTL3);
        Serial.print(F(","));
        Serial.println(TTL4);
        BNCTTL1 = 0;
          Flags = 0;
          OutcomeFlags = 0;
      }

      //OMISSION OUTCOME FLAG
      if (((millis() - TrialStartTime) > (PreCueInterval + MaxTrialDuration)) && Rewarded == 0 && Unrewarded == 0 && Omitted == 0 && TrialDone == 0)
      {
        digitalWrite(BoxLight,LOW); //turn off boxlight
        digitalWrite(LickometerLED,LOW);
        digitalWrite(WhiteNoiseTTL,HIGH);
        SoundTimer = millis();

        Omitted = 1;
        LastDirection = 0;
        ++Omissions;
        TimeOut = 1;
        OutcomeFlags = 3;
        Flags = 3;
        OutcomeMillis = millis();
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
        Serial.print(ServoMoving);
        Serial.print(F(","));
        Serial.print(JoystickBaselineA1);
        Serial.print(F(","));
        Serial.print(JoystickBaselineA3);
        Serial.print(F(","));
        Serial.print(RewardDirection);
        Serial.print(F(","));
        Serial.print(RewProbPush);
        Serial.print(F(","));
        Serial.print(RewProbPull);
        Serial.print(F(","));
        Serial.print(ObtainRewardPush);
        Serial.print(F(","));
        Serial.print(ObtainRewardPull);
        Serial.print(F(","));
        Serial.print(LastDirection);
        Serial.print(F(","));
        Serial.print(TrialNumber);
        Serial.print(F(","));
        Serial.print(BlockNumber);
        Serial.print(F(","));
        Serial.print(BlockLength);
        Serial.print(F(","));
        Serial.print(BlockRewards);
        Serial.print(F(","));
        Serial.print(BlockRewardsAdvSide);
        Serial.print(F(","));
        Serial.print(TrialDuration);
        Serial.print(F(","));
        Serial.print(InterTrialInterval);
        Serial.print(F(","));
        Serial.print(PreCueInterval);
        Serial.print(F(","));
        Serial.print(Pushes);
        Serial.print(F(","));
        Serial.print(Pulls);
        Serial.print(F(","));
        Serial.print(HighProbMov);
        Serial.print(F(","));
        Serial.print(LowProbMov);
        Serial.print(F(","));
        Serial.print(Rewards);
        Serial.print(F(","));
        Serial.print(Omissions);
        Serial.print(F(","));
        Serial.print(Unrewardeds);
        Serial.print(F(","));
        Serial.print(Premature);
        Serial.print(F(","));
        Serial.print(PrematureRewarded);
        Serial.print(F(","));
        Serial.print(PrematureUnrewarded);
        Serial.print(F(","));
        Serial.print(LickFlag);
        Serial.print(F(","));
        Serial.print(TotalLicks);
        Serial.print(F(","));
        Serial.print(OutcomeFlags);
        Serial.print(F(","));
        Serial.print(Flags);
        Serial.print(F(","));
        Serial.print(BNCTTL1);
        Serial.print(F(","));
        Serial.print(BNCTTL2);
        Serial.print(F(","));
        Serial.print(TTL3);
        Serial.print(F(","));
        Serial.println(TTL4);
        BNCTTL1 = 0;
        Flags = 0;
        OutcomeFlags = 0;
      }


      
      //===========OUTCOMES======================
      //REWARDED
      if(((millis()-RewardMillis) > ToneDuration) && ((millis()-RewardMillis)<=(ToneDuration + OnDuration)) &&Rewarded ==1 && PumpOpen != 1)
      {
        digitalWrite(Pump, HIGH);
        digitalWrite(PumpOn,LOW); //open pump valve
        digitalWrite(PumpKeepLow, HIGH);
        digitalWrite(LickLED,HIGH);
        PumpOpen = 1;
      }
      if(((millis()-RewardMillis)>(OnDuration+ToneDuration)) && Rewarded==1 && PumpOpen ==1)
      {
        digitalWrite(Pump, HIGH);
        digitalWrite(PumpOn,LOW); //close pump valve
        digitalWrite(PumpKeepLow, LOW);
        PumpOpen = 0;
        Rewarded = 0;
        TrialDoneTime = millis();
        TrialDuration = TrialDoneTime-(TrialStartTime+PreCueInterval);
        TrialDone = 1;
        
      }

      //UNREWARDED
      if (((millis()-UnrewardedMillis) > ToneDuration) && Unrewarded == 1 && TimeOut ==0) //possible issue here, make sure unrewarded is otherwise never 1 while timeout is 0 
      {
        Unrewarded = 0;
        TrialDoneTime = millis();
        TrialDuration = TrialDoneTime-(TrialStartTime+PreCueInterval);
        TrialDone = 1;
      }

      //TIME-OUT     
      if(TimeOut == 1 && (Prematured == 1 || Omitted ==1) && Rewarded == 0 && Unrewarded == 0 && TrialDone == 0)
      {
        TrialDone = 1;
        TrialDoneTime = millis();
        TrialDuration = TrialDoneTime - (TrialStartTime+PreCueInterval); //This number will be negative for premature trials
      }

      //=========CONCLUDE OUTCOME==========
      if (TrialDone == 1 && Concluded == 0)
      {
        Concluded = 1;
        Flags = 4;
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
        Serial.print(ServoMoving);
        Serial.print(F(","));
        Serial.print(JoystickBaselineA1);
        Serial.print(F(","));
        Serial.print(JoystickBaselineA3);
        Serial.print(F(","));
        Serial.print(RewardDirection);
        Serial.print(F(","));
        Serial.print(RewProbPush);
        Serial.print(F(","));
        Serial.print(RewProbPull);
        Serial.print(F(","));
        Serial.print(ObtainRewardPush);
        Serial.print(F(","));
        Serial.print(ObtainRewardPull);
        Serial.print(F(","));
        Serial.print(LastDirection);
        Serial.print(F(","));
        Serial.print(TrialNumber);
        Serial.print(F(","));
        Serial.print(BlockNumber);
        Serial.print(F(","));
        Serial.print(BlockLength);
        Serial.print(F(","));
        Serial.print(BlockRewards);
        Serial.print(F(","));
        Serial.print(BlockRewardsAdvSide);
        Serial.print(F(","));
        Serial.print(TrialDuration);
        Serial.print(F(","));
        Serial.print(InterTrialInterval);
        Serial.print(F(","));
        Serial.print(PreCueInterval);
        Serial.print(F(","));
        Serial.print(Pushes);
        Serial.print(F(","));
        Serial.print(Pulls);
        Serial.print(F(","));
        Serial.print(HighProbMov);
        Serial.print(F(","));
        Serial.print(LowProbMov);
        Serial.print(F(","));
        Serial.print(Rewards);
        Serial.print(F(","));
        Serial.print(Omissions);
        Serial.print(F(","));
        Serial.print(Unrewardeds);
        Serial.print(F(","));
        Serial.print(Premature);
        Serial.print(F(","));
        Serial.print(PrematureRewarded);
        Serial.print(F(","));
        Serial.print(PrematureUnrewarded);
        Serial.print(F(","));
        Serial.print(LickFlag);
        Serial.print(F(","));
        Serial.print(TotalLicks);
        Serial.print(F(","));
        Serial.print(OutcomeFlags);
        Serial.print(F(","));
        Serial.print(Flags);
        Serial.print(F(","));
        Serial.print(BNCTTL1);
        Serial.print(F(","));
        Serial.print(BNCTTL2);
        Serial.print(F(","));
        Serial.print(TTL3);
        Serial.print(F(","));
        Serial.println(TTL4);
        Flags = 0;

        //reset flags
        Tripped = 0;
        Unrewarded = 0;
        Omitted = 0;
        Prematured = 0;
        Rewarded = 0;
        Tripped = 0;
        TrippedPush = 0;
        TrippedPull = 0;
        
        //Tell servo to move back and trip flag
        if(ServoBackPos == 0)
        {
          ServoVar.write(ServoBack);
          ServoMoving = 1;
          ServoBackStart = millis();
          ServoBackPos = 1;
          ReadTotalA1 = 0;
          ReadTotalA3 = 0;
          NumInterRead = 0;
        }
      }
      


      //Read retracted joystick position if joystick retracted flag is set to 1. 
      if (ServoBackPos == 1 && ((millis() - ServoBackStart) > ServoDuration) && InterReadYN == 0 && ServoMoving ==1)
      {
        ServoMoving = 0;
        ReadJoystick = 0;
        Flags = 5;
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
        Serial.print(ServoMoving);
        Serial.print(F(","));
        Serial.print(JoystickBaselineA1);
        Serial.print(F(","));
        Serial.print(JoystickBaselineA3);
        Serial.print(F(","));
        Serial.print(RewardDirection);
        Serial.print(F(","));
        Serial.print(RewProbPush);
        Serial.print(F(","));
        Serial.print(RewProbPull);
        Serial.print(F(","));
        Serial.print(ObtainRewardPush);
        Serial.print(F(","));
        Serial.print(ObtainRewardPull);
        Serial.print(F(","));
        Serial.print(LastDirection);
        Serial.print(F(","));
        Serial.print(TrialNumber);
        Serial.print(F(","));
        Serial.print(BlockNumber);
        Serial.print(F(","));
        Serial.print(BlockLength);
        Serial.print(F(","));
        Serial.print(BlockRewards);
        Serial.print(F(","));
        Serial.print(BlockRewardsAdvSide);
        Serial.print(F(","));
        Serial.print(TrialDuration);
        Serial.print(F(","));
        Serial.print(InterTrialInterval);
        Serial.print(F(","));
        Serial.print(PreCueInterval);
        Serial.print(F(","));
        Serial.print(Pushes);
        Serial.print(F(","));
        Serial.print(Pulls);
        Serial.print(F(","));
        Serial.print(HighProbMov);
        Serial.print(F(","));
        Serial.print(LowProbMov);
        Serial.print(F(","));
        Serial.print(Rewards);
        Serial.print(F(","));
        Serial.print(Omissions);
        Serial.print(F(","));
        Serial.print(Unrewardeds);
        Serial.print(F(","));
        Serial.print(Premature);
        Serial.print(F(","));
        Serial.print(PrematureRewarded);
        Serial.print(F(","));
        Serial.print(PrematureUnrewarded);
        Serial.print(F(","));
        Serial.print(LickFlag);
        Serial.print(F(","));
        Serial.print(TotalLicks);
        Serial.print(F(","));
        Serial.print(OutcomeFlags);
        Serial.print(F(","));
        Serial.print(Flags);
        Serial.print(F(","));
        Serial.print(BNCTTL1);
        Serial.print(F(","));
        Serial.print(BNCTTL2);
        Serial.print(F(","));
        Serial.print(TTL3);
        Serial.print(F(","));
        Serial.println(TTL4);
        Flags = 0;
      }
      if (ServoBackPos == 1 && ((millis() - ServoBackStart)) > (ServoDuration+ServoReadDelay) && InterReadYN == 0)
      {
        if (SetMilliInterRead == 0)
        {
          MilliInterRead = millis();
          SetMilliInterRead = 1;
        }
        if ((millis() - MilliInterRead >= InterReadInterval) && (NumInterRead < ReadInterTimes))
        {
          ReadTotalA1 = ReadTotalA1 + analogRead(A1);
          ReadTotalA3 = ReadTotalA3 + (analogRead(A3)-b)/m;
          NumInterRead = NumInterRead + 1;
          SetMilliInterRead = 0; 
        }
        if (NumInterRead >= ReadInterTimes)
        {
          PrevBaselineA3 = JoystickBaselineA3;
          JoystickBaselineA1 = ReadTotalA1/NumInterRead;
          JoystickBaselineA3 = int(ReadTotalA3*1000/NumInterRead);
          InterReadYN = 1;
        if ((JoystickBaselineA3 - PrevBaselineA3) > 6000 || (JoystickBaselineA3 - PrevBaselineA3) < -6000)
        {
          JoystickBaselineA3 = PrevBaselineA3;
          digitalWrite(LowToneTTL,HIGH);
          SoundTimer = 0;
          
        }
        }
      }

    //EXTEND JOYSTICK AFTER ITI
    //Extend joystick in time to be forward at end of ITI (so 500 msec before trial starts) after REWARDED trial. 
    if(TrialDone ==1 && (millis()-(TrialDoneTime))>=(InterTrialInterval+(ServoDuration-ServoDuration)) && ServoMove ==0 && ServoBackPos ==1 && TimeOut == 0)
     {
        ServoVar.write(ServoForward); //move lever towards mouse
        ReadJoystick = 1;
        ServoStart = millis();
        ServoMove = 1;
        ServoMoving = 1;
        Flags = 6; //joystick extending flag
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
        Serial.print(ServoMoving);
        Serial.print(F(","));
        Serial.print(JoystickBaselineA1);
        Serial.print(F(","));
        Serial.print(JoystickBaselineA3);
        Serial.print(F(","));
        Serial.print(RewardDirection);
        Serial.print(F(","));
        Serial.print(RewProbPush);
        Serial.print(F(","));
        Serial.print(RewProbPull);
        Serial.print(F(","));
        Serial.print(ObtainRewardPush);
        Serial.print(F(","));
        Serial.print(ObtainRewardPull);
        Serial.print(F(","));
        Serial.print(LastDirection);
        Serial.print(F(","));
        Serial.print(TrialNumber);
        Serial.print(F(","));
        Serial.print(BlockNumber);
        Serial.print(F(","));
        Serial.print(BlockLength);
        Serial.print(F(","));
        Serial.print(BlockRewards);
        Serial.print(F(","));
        Serial.print(BlockRewardsAdvSide);
        Serial.print(F(","));
        Serial.print(TrialDuration);
        Serial.print(F(","));
        Serial.print(InterTrialInterval);
        Serial.print(F(","));
        Serial.print(PreCueInterval);
        Serial.print(F(","));
        Serial.print(Pushes);
        Serial.print(F(","));
        Serial.print(Pulls);
        Serial.print(F(","));
        Serial.print(HighProbMov);
        Serial.print(F(","));
        Serial.print(LowProbMov);
        Serial.print(F(","));
        Serial.print(Rewards);
        Serial.print(F(","));
        Serial.print(Omissions);
        Serial.print(F(","));
        Serial.print(Unrewardeds);
        Serial.print(F(","));
        Serial.print(Premature);
        Serial.print(F(","));
        Serial.print(PrematureRewarded);
        Serial.print(F(","));
        Serial.print(PrematureUnrewarded);
        Serial.print(F(","));
        Serial.print(LickFlag);
        Serial.print(F(","));
        Serial.print(TotalLicks);
        Serial.print(F(","));
        Serial.print(OutcomeFlags);
        Serial.print(F(","));
        Serial.print(Flags);
        Serial.print(F(","));
        Serial.print(BNCTTL1);
        Serial.print(F(","));
        Serial.print(BNCTTL2);
        Serial.print(F(","));
        Serial.print(TTL3);
        Serial.print(F(","));
        Serial.println(TTL4);
        BNCTTL2 = 0;
        Flags = 0;
        
        //Compute ITI
        RandU = random(RandLowerU,RandUpperU);
        FloatInterTrialInterval = MinimumITI-(log10(1-(RandU/1000))/Lambda)*1000;
        InterTrialInterval = min(MaximumITI,long(FloatInterTrialInterval));
        NumInterRead = 0;
        InterReadYN = 0;
        ServoBackPos = 0;

//        //compute Go cue duration during this time
//        PreCueRandU = random(PreCueRandLowerU,PreCueRandUpperU);
//        FloatPreCueInterval = MinimumPreCue-((log10(1-(PreCueRandU/1000))/PreCueLambda)*1000);
//        PreCueInterval = min(MaximumPreCue,long(FloatPreCueInterval));

        //start next block if BlockRewardsAdvSide >= BlockLength - only relevant after rewarded trial because this is the only thing that can trigger next block
        if (BlockRewardsAdvSide >= BlockLength && StartNextBlock ==0)
        {
          StartNextBlock = 1;
          
          
          if (RewardDirection ==1)
          {
            RewardDirection =2;
          }
          else
          {
            RewardDirection = 1;
          }

          //Assign reward probabilities for the block
          if (ForceSerial == 0)
          {
            if (RewardDirection ==1)
            {
              RewProbPush = HighOdds;
              RewProbPull = LowOdds;
            }
      
            if (RewardDirection ==2)
            {
              RewProbPush = LowOdds;
              RewProbPull = HighOdds;
            }
          }

          if (ForceSerial == 1 && (BlockNumber >= ForceSerialBlocks))
          {
            if (RewardDirection ==1)
            {
              RewProbPush = HighOdds;
              RewProbPull = LowOdds;
            }
      
            if (RewardDirection ==2)
            {
              RewProbPush = LowOdds;
              RewProbPull = HighOdds;
            }
          }
          if (ForceSerial == 1 && (BlockNumber < ForceSerialBlocks))
          {
            if (RewardDirection ==1)
            {
              RewProbPush = 1000;
              RewProbPull = 0;
            }
      
            if (RewardDirection ==2)
            {
              RewProbPush = 0;
              RewProbPull = 1000;
            }
          }
          
        //Calculate next block length (in terms of number of REWARDED trials per Witten protocols - Parker papers)
        GeoRandPk = random(GeoRandLowerPk,GeoRandUpperPk);
        GeoRandPk = GeoRandPk/100000;
        GeoLengthFloat = -0.000001+(log10(1-GeoRandPk)/log10(1-GeoP));
        BlockLength = int(GeoLengthFloat)+MinimumBlockLength;
        BlockRewards = 0;
        BlockRewardsAdvSide = 0;
        ++BlockNumber;

        }
      
      //Calculate for each direction whether it will be rewarded or unrewarded on this trial
      RewardDiceDirPush = random(1,1001);
      RewardDiceDirPull = random(1,1001);
      if (RewardDiceDirPush>RewProbPush)
      {
        ObtainRewardPush = 0;
      }
      if (RewardDiceDirPull>RewProbPull)
      {
        ObtainRewardPull = 0;
      }
      if (RewardDiceDirPush<=RewProbPush)
      {
        ObtainRewardPush = 1;
      }
      if (RewardDiceDirPull<=RewProbPull)
      {
        ObtainRewardPull = 1;
      }
          
     }

     //EXTEND JOYSTICK AFTER TIMEOUT
      if(TrialDone ==1 && millis()-TrialDoneTime>=(TimeOutDelay + ServoDuration) && ServoMove ==0 && TimeOut == 1)
     {
        ServoVar.write(ServoForward); //move lever towards mouse
        ReadJoystick = 1;
        ServoMoving = 1;
        ServoStart = millis();
        ServoMove = 1;
        Flags = 6; //joystick extending flag
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
        Serial.print(ServoMoving);
        Serial.print(F(","));
        Serial.print(JoystickBaselineA1);
        Serial.print(F(","));
        Serial.print(JoystickBaselineA3);
        Serial.print(F(","));
        Serial.print(RewardDirection);
        Serial.print(F(","));
        Serial.print(RewProbPush);
        Serial.print(F(","));
        Serial.print(RewProbPull);
        Serial.print(F(","));
        Serial.print(ObtainRewardPush);
        Serial.print(F(","));
        Serial.print(ObtainRewardPull);
        Serial.print(F(","));
        Serial.print(LastDirection);
        Serial.print(F(","));
        Serial.print(TrialNumber);
        Serial.print(F(","));
        Serial.print(BlockNumber);
        Serial.print(F(","));
        Serial.print(BlockLength);
        Serial.print(F(","));
        Serial.print(BlockRewards);
        Serial.print(F(","));
        Serial.print(BlockRewardsAdvSide);
        Serial.print(F(","));
        Serial.print(TrialDuration);
        Serial.print(F(","));
        Serial.print(InterTrialInterval);
        Serial.print(F(","));
        Serial.print(PreCueInterval);
        Serial.print(F(","));
        Serial.print(Pushes);
        Serial.print(F(","));
        Serial.print(Pulls);
        Serial.print(F(","));
        Serial.print(HighProbMov);
        Serial.print(F(","));
        Serial.print(LowProbMov);
        Serial.print(F(","));
        Serial.print(Rewards);
        Serial.print(F(","));
        Serial.print(Omissions);
        Serial.print(F(","));
        Serial.print(Unrewardeds);
        Serial.print(F(","));
        Serial.print(Premature);
        Serial.print(F(","));
        Serial.print(PrematureRewarded);
        Serial.print(F(","));
        Serial.print(PrematureUnrewarded);
        Serial.print(F(","));
        Serial.print(LickFlag);
        Serial.print(F(","));
        Serial.print(TotalLicks);
        Serial.print(F(","));
        Serial.print(OutcomeFlags);
        Serial.print(F(","));
        Serial.print(Flags);
        Serial.print(F(","));
        Serial.print(BNCTTL1);
        Serial.print(F(","));
        Serial.print(BNCTTL2);
        Serial.print(F(","));
        Serial.print(TTL3);
        Serial.print(F(","));
        Serial.println(TTL4);
         BNCTTL2 = 0;
        Flags = 0;

        //Compute ITI
        RandU = random(RandLowerU,RandUpperU);
        FloatInterTrialInterval = MinimumITI-(log10(1-(RandU/1000))/Lambda)*1000;
        InterTrialInterval = min(MaximumITI,long(FloatInterTrialInterval));
        NumInterRead = 0;
        InterReadYN = 0;
        ServoBackPos = 0;

//        //compute Go cue duration during this time
//        PreCueRandU = random(PreCueRandLowerU,PreCueRandUpperU);
//        FloatPreCueInterval = MinimumPreCue-((log10(1-(PreCueRandU/1000))/PreCueLambda)*1000);
//        PreCueInterval = min(MaximumPreCue,long(FloatPreCueInterval));

        //Calculate for each direction whether it will be rewarded or unrewarded on this trial
        RewardDiceDirPush = random(1,1001);
        RewardDiceDirPull = random(1,1001);
        if (RewardDiceDirPush>RewProbPush)
        {
          ObtainRewardPush = 0;
        }
        if (RewardDiceDirPull>RewProbPull)
        {
          ObtainRewardPull = 0;
        }
        if (RewardDiceDirPush<=RewProbPush)
        {
          ObtainRewardPush = 1;
        }
        if (RewardDiceDirPull<=RewProbPull)
        {
          ObtainRewardPull = 1;
        }
     }

     //==========START SUBSEQUENT TRIALS===============
     //START AFTER ITI
     if((millis() - ServoStart) > ServoDuration && TrialDone ==1 && ServoMove ==1 && TimeOut == 0)
     {        
        TrialStartTime = millis();
        digitalWrite(BoxLight,HIGH); //turn on light
        ++TrialNumber;
        Flags = 1; //trial start flag
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
        Serial.print(ServoMoving);
        Serial.print(F(","));
        Serial.print(JoystickBaselineA1);
        Serial.print(F(","));
        Serial.print(JoystickBaselineA3);
        Serial.print(F(","));
        Serial.print(RewardDirection);
        Serial.print(F(","));
        Serial.print(RewProbPush);
        Serial.print(F(","));
        Serial.print(RewProbPull);
        Serial.print(F(","));
        Serial.print(ObtainRewardPush);
        Serial.print(F(","));
        Serial.print(ObtainRewardPull);
        Serial.print(F(","));
        Serial.print(LastDirection);
        Serial.print(F(","));
        Serial.print(TrialNumber);
        Serial.print(F(","));
        Serial.print(BlockNumber);
        Serial.print(F(","));
        Serial.print(BlockLength);
        Serial.print(F(","));
        Serial.print(BlockRewards);
        Serial.print(F(","));
        Serial.print(BlockRewardsAdvSide);
        Serial.print(F(","));
        Serial.print(TrialDuration);
        Serial.print(F(","));
        Serial.print(InterTrialInterval);
        Serial.print(F(","));
        Serial.print(PreCueInterval);
        Serial.print(F(","));
        Serial.print(Pushes);
        Serial.print(F(","));
        Serial.print(Pulls);
        Serial.print(F(","));
        Serial.print(HighProbMov);
        Serial.print(F(","));
        Serial.print(LowProbMov);
        Serial.print(F(","));
        Serial.print(Rewards);
        Serial.print(F(","));
        Serial.print(Omissions);
        Serial.print(F(","));
        Serial.print(Unrewardeds);
        Serial.print(F(","));
        Serial.print(Premature);
        Serial.print(F(","));
        Serial.print(PrematureRewarded);
        Serial.print(F(","));
        Serial.print(PrematureUnrewarded);
        Serial.print(F(","));
        Serial.print(LickFlag);
        Serial.print(F(","));
        Serial.print(TotalLicks);
        Serial.print(F(","));
        Serial.print(OutcomeFlags);
        Serial.print(F(","));
        Serial.print(Flags);
        Serial.print(F(","));
        Serial.print(BNCTTL1);
        Serial.print(F(","));
        Serial.print(BNCTTL2);
        Serial.print(F(","));
        Serial.print(TTL3);
        Serial.print(F(","));
        Serial.println(TTL4);
        Flags = 0;

        //reset flags
        CuePlayed = 0;
        Tripped = 0;
        ServoMove = 0;
        ServoMoving = 0;
        Concluded = 0; 
        TimeOut = 0;
        Unrewarded = 0;
        Omitted = 0;
        Prematured = 0;
        Rewarded = 0;
        Tripped = 0;
        TrippedPush = 0;
        TrippedPull = 0;
        TrialDone = 0;
        StartNextBlock = 0;
     }
     
     //START AFTER TIME-OUT
     if((millis() - ServoStart) > ServoDuration && TrialDone ==1 && ServoMove ==1 && TimeOut == 1)
     {        
        TrialStartTime = millis();
        digitalWrite(BoxLight,HIGH); //turn on light
        ++TrialNumber;
        Flags = 1; //trial start flag
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
        Serial.print(ServoMoving);
        Serial.print(F(","));
        Serial.print(JoystickBaselineA1);
        Serial.print(F(","));
        Serial.print(JoystickBaselineA3);
        Serial.print(F(","));
        Serial.print(RewardDirection);
        Serial.print(F(","));
        Serial.print(RewProbPush);
        Serial.print(F(","));
        Serial.print(RewProbPull);
        Serial.print(F(","));
        Serial.print(ObtainRewardPush);
        Serial.print(F(","));
        Serial.print(ObtainRewardPull);
        Serial.print(F(","));
        Serial.print(LastDirection);
        Serial.print(F(","));
        Serial.print(TrialNumber);
        Serial.print(F(","));
        Serial.print(BlockNumber);
        Serial.print(F(","));
        Serial.print(BlockLength);
        Serial.print(F(","));
        Serial.print(BlockRewards);
        Serial.print(F(","));
        Serial.print(BlockRewardsAdvSide);
        Serial.print(F(","));
        Serial.print(TrialDuration);
        Serial.print(F(","));
        Serial.print(InterTrialInterval);
        Serial.print(F(","));
        Serial.print(PreCueInterval);
        Serial.print(F(","));
        Serial.print(Pushes);
        Serial.print(F(","));
        Serial.print(Pulls);
        Serial.print(F(","));
        Serial.print(HighProbMov);
        Serial.print(F(","));
        Serial.print(LowProbMov);
        Serial.print(F(","));
        Serial.print(Rewards);
        Serial.print(F(","));
        Serial.print(Omissions);
        Serial.print(F(","));
        Serial.print(Unrewardeds);
        Serial.print(F(","));
        Serial.print(Premature);
        Serial.print(F(","));
        Serial.print(PrematureRewarded);
        Serial.print(F(","));
        Serial.print(PrematureUnrewarded);
        Serial.print(F(","));
        Serial.print(LickFlag);
        Serial.print(F(","));
        Serial.print(TotalLicks);
        Serial.print(F(","));
        Serial.print(OutcomeFlags);
        Serial.print(F(","));
        Serial.print(Flags);
        Serial.print(F(","));
        Serial.print(BNCTTL1);
        Serial.print(F(","));
        Serial.print(BNCTTL2);
        Serial.print(F(","));
        Serial.print(TTL3);
        Serial.print(F(","));
        Serial.println(TTL4);
        Flags = 0;

        //reset flags
        CuePlayed = 0;
        Tripped = 0;
        ServoMove = 0;
        ServoMoving = 0;
        TimeOut = 0;
        Concluded = 0; 
        Unrewarded = 0;
        Omitted = 0;
        Prematured = 0;
        Rewarded = 0;
        Tripped = 0;
        TrippedPush = 0;
        TrippedPull = 0;
        TrialDone = 0;
     }
  }
  }
}
