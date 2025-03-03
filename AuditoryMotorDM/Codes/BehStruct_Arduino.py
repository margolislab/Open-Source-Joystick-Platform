# Libraries for serial communication and threading
import serial
import time
from datetime import datetime, timedelta
import threading

# Initialize serial port for Arduino communication.
# Make sure to set the correct COM port and baud rate.
arduino = serial.Serial('COM8', 38400, timeout=1.0)
arduino.setDTR(False)
arduino.flushInput()
arduino.setDTR(True)

###########################################################################
# Class ThreadOutput
# This thread continuously reads data from the Arduino over the serial port,
# processes the received string, appends a timestamp, and writes the data to a text file.
#
# The data format from Arduino is expected to be a string in the format:
#   <time>.<sensor>.<action>
#
# The thread stops reading when the sensor value equals 666.
###########################################################################

class ThreadOutput(threading.Thread):
    def __init__(self):
        threading.Thread.__init__(self)

    def run(self):
        # Get the current time for naming the output file and for timestamping data.
        current_time = datetime.now()
        file_name = "AnimalNameID_BehData_" + current_time.strftime("%H%M%S") + ".txt"
        file_out = open(file_name, "w")

        # Initialize a reference time. Here, we start with a default data line "0.0.0".
        # This simulates an initial reading with zero values.
        initial_data = "0.0.0"
        parts = initial_data.split(".")
        if len(parts) == 3:
            elapsed_time = int(parts[0])  # Expected to be 0 initially
            sensor_value = int(parts[1])
            action_value = int(parts[2])
            # Calculate the timestamp based on the reference time and elapsed milliseconds.
            timestamp = current_time + timedelta(milliseconds=elapsed_time)
            # Create the output string (time formatted to milliseconds)
            output_str = timestamp.strftime('%H:%M:%S.%f')[:-3] + "." + str(sensor_value) + "." + str(action_value)
            print(output_str)
            file_out.write(output_str + "\n")
            # Set the reference timestamp for subsequent calculations.
            reference_time = timestamp
        else:
            reference_time = current_time

        # Update the current time after initialization.
        current_time = datetime.now()

        # Continue reading until the sensor value equals 666.
        # The value 666 is used as a termination flag.
        while sensor_value != 666:
            try:
                # Read a line from Arduino, decode it, and strip the newline character.
                arduino_line = arduino.readline().decode().rstrip('\n')
                data_line = arduino_line
                parts = data_line.split(".")
                if len(parts) == 3:
                    # Parse the three expected components.
                    elapsed_time = int(parts[0])
                    sensor_value = int(parts[1])
                    action_value = int(parts[2])
                    # Use the current time as the timestamp for the data.
                    timestamp = datetime.now()
                    # Construct the output string with a full timestamp and the data.
                    output_str = timestamp.strftime('%H:%M:%S.%f') + "." + str(elapsed_time) + "." + str(sensor_value) + "." + str(action_value)
                    print(output_str)
                    file_out.write(output_str + "\n")
                    # Update the reference timestamp.
                    reference_time = timestamp
            except Exception as e:
                # Print any exception that occurs during serial reading.
                print("Error reading from Arduino:", e)

        # Close the file when done.
        file_out.close()

if __name__ == '__main__':
    new_thread = ThreadOutput()
    new_thread.start()
