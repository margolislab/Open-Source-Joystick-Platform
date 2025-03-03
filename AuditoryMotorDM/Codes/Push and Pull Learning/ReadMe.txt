Instructions for Using the Files

Acclimating Animals
In the initial training phase, acclimate the animals to the head-fix setup by providing water at random intervals. This phase is designed to familiarize the mice with the two primary joystick movements—pushing and pulling. Conduct two training sessions per day without using any auditory cues.

Arduino Code for Joystick Movements

Selecting and Uploading the Code:
Choose one of the second Arduino code files (either for push or pull, as needed) and upload it to your Arduino board.
Adjusting Reward Parameters:
In this code, you can modify the amplitude of the displacement required to trigger a reward and the reward size.
Task Structure Settings:
The overall task structure—including the number of rewards and the reward size—is defined in the file named 1stArduino_BehStrcut. Adjust these parameters as needed for your experiment.
Serial Communication Data Logging

Using the Python Scripts(BehStruct_Arduino_2, Read_Joystick_2ndArduino):
To save the serial communication data, run the provided Python files in Spyder after uploading the Arduino code.
COM Port Configuration:
Ensure that the COM port specified in the Python script matches the one used by the Arduino board.
Alternative Options:
If you prefer not to use the Python scripts, any tool capable of reading and saving data from the COM port will work.
Customizing the Python File
You can change the name of the output file within the Python script as needed.

Additional Notes:

Verify that all hardware connections are secure before uploading any code.
Double-check the COM port settings in both the Arduino IDE and the Python script to avoid connection issues.
Double check that Baud rate on Arduino and python match, if it doesn't match no file will be saved.
It is recommended to perform a trial run to confirm that the reward system and data logging are functioning correctly before commencing your experiments.