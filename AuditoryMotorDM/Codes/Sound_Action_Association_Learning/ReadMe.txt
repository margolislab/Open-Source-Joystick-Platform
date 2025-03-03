Sound Motor Association

During this training phase, animals learn to associate a specific sound with a corresponding action. The system is configured so that low-frequency sounds waits for a pull response, and high-frequency sounds trigger waits for a push response. Although only one sound is used per association by default, the code can be configured to use up to three sounds per association. You can adjust the joystick displacement threshold, the reward size, and the probabilities for receiving a reward based on the outcome of each trial.

Arduino Code for Joystick Movements

Selecting and Uploading the Code:

Choose one of the second Arduino code files (either for push or pull, depending on your desired association) and upload it to your Arduino board.
Also, select the corresponding code for the first Arduino that matches the desired association (pull or push).
Adjusting Reward Parameters:

In the selected code, you can modify both the amplitude of the displacement required to trigger a reward and the reward size.
Task Structure Settings:

The overall task structure—including the inter-trial interval, sound trigger, licking, and rewards—is defined in the file named Pull_LF_FirstArdu or Push_HF_FirstArdu. Adjust these parameters as needed for your experiment.
Serial Communication Data Logging

The second Arduino file collects the joystick data and sends it to the first Arduino once a threshold is reached, but only during the trial period following the sound. It also processes the analog readout to provide normalized data and reduce noise.

Using the Python Scripts (BehStruct_Arduino_2, Read_Joystick_2ndArduino):

To save the serial communication data, run the provided Python scripts in Spyder after uploading the Arduino code.
COM Port Configuration:

Ensure that the COM port specified in the Python script matches the one used by the Arduino board.
Alternative Options:

If you prefer not to use the Python scripts, any tool that can read and save data from the COM port will work.
Customizing the Python File:

You can change the name of the output file within the Python script as needed.
Additional Notes

Verify that all hardware connections are secure before uploading any code.
Double-check the COM port settings in both the Arduino IDE and the Python script to avoid connection issues.
Ensure that the baud rate settings on the Arduino and in the Python script match; mismatched settings will prevent data from being saved.
It is recommended to perform a trial run to confirm that the reward system and data logging are functioning correctly before beginning your experiments.


