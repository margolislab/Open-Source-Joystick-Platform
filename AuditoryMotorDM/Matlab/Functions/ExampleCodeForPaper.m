
% Define file path
BehaviourFile = 'N:\SRV\DATA\IvanLin\2P\Boa\PullLF15\Boa_LF_Pull_15r_2p_BehData_151815.txt';
JoystickFile =  'N:\SRV\DATA\IvanLin\2P\Boa\PullLF15\Boa_LF_Pull_15r_2p_JSData_151824.txt';



% Open and read the file (each line is a string)
fid = fopen(BehaviourFile, 'r');
data = textscan(fid, '%s', 'Delimiter', '\n');
fclose(fid);
data = data{1};  % Cell array of strings, one per line
data=data(2:end,1);
nLines = numel(data)-1;

% Preallocate arrays for output variables
millis = zeros(nLines, 1);  % Global computer time in milliseconds
sensor = zeros(nLines, 1);  % Sensor flag (e.g., 21)
value  = zeros(nLines, 1);  % Event value (e.g., 5500)

% Process each line
for i = 1:nLines
    % Split the line using ':' or '.' as delimiters.
    % Expected tokens: {HH, MM, SS, FRACTION, ARDUINO_TIME, SENSOR_FLAG, EVENT_VALUE}
    tokens = regexp(data{i}, '[:\.]', 'split');
    
    if numel(tokens) >= 7
        % Convert time components from string to number
        h    = str2double(tokens{1});
        m    = str2double(tokens{2});
        s    = str2double(tokens{3});
        frac = str2double(tokens{4});  % Fractional part (e.g., microseconds)
        % Note: The Arduino time is tokens{5} if needed
        
        % Sensor flag and event value
        sensor(i) = str2double(tokens{6});
        value(i)  = str2double(tokens{7});
        
        % Convert global computer time into milliseconds
        % (Hours, minutes, and seconds are converted to ms and the fractional part is scaled)
        globalTimeMs = ((h * 3600) + (m * 60) + s) * 1000 + frac / 1000;
        millis(i) = globalTimeMs;
    else
        warning('Line %d is not in the expected format: %s', i, data{i});
    end
end

% Normalize the global time so that it starts at 0
millis = millis - millis(1);

NewData(:,1)=millis;
NewData(:,2)=sensor;
NewData(:,3)=value;

clear millis sensor value data

%% Repeat for the Joystick file


% Open and read the file (each line is a string)
fid = fopen(JoystickFile, 'r');
data = textscan(fid, '%s', 'Delimiter', '\n');
fclose(fid);
data = data{1};  % Cell array of strings, one per line
data=data(2:end,1);
nLines = numel(data);

% Preallocate arrays for output variables
millis = zeros(nLines, 1);  % Global computer time in milliseconds
sensor = zeros(nLines, 1);  % Sensor flag (e.g., 21)
value  = zeros(nLines, 1);  % Event value (e.g., 5500)

% Process each line
for i = 1:nLines
    % Split the line using ':' or '.' as delimiters.
    % Expected tokens: {HH, MM, SS, FRACTION, ARDUINO_TIME, SENSOR_FLAG, EVENT_VALUE}
    tokens = regexp(data{i}, '[:\.]', 'split');
    
    if numel(tokens) >= 7
        % Convert time components from string to number
        h    = str2double(tokens{1});
        m    = str2double(tokens{2});
        s    = str2double(tokens{3});
        frac = str2double(tokens{4});  % Fractional part (e.g., microseconds)
        % Note: The Arduino time is tokens{5} if needed
        
        % Sensor flag and event value
        sensor(i) = str2double(tokens{6});
        value(i)  = str2double(tokens{7});
        
        % Convert global computer time into milliseconds
        % (Hours, minutes, and seconds are converted to ms and the fractional part is scaled)
        globalTimeMs = ((h * 3600) + (m * 60) + s) * 1000 + frac / 1000;
        millis(i) = globalTimeMs;
    else
        warning('Line %d is not in the expected format: %s', i, data{i});
    end
end

% Normalize the global time so that it starts at 0
millis = millis - millis(1);

NewDataJS(:,1)=millis;
NewDataJS(:,2)=sensor;
NewDataJS(:,3)=value;



%% Aligned arduino Time

%% Align TTL Times Between Two Data Sets

% --- Rewards from First Arduino ---
% Extract reward event times from NewData where sensor equals 3.
rewardIdx_Arduino1 = find(NewData(:,2) == 3);
TTLRewardFirstArduinoTime = NewData(rewardIdx_Arduino1, 1);

% --- Rewards from Second Arduino ---
% Create a binary vector marking reward events (sensor equals 3)
binaryReward_Arduino2 = double(sensor == 3);
% Use findpeaks to detect reward peaks with a minimum separation of 20 samples.
[~, rewardLocs_Arduino2] = findpeaks(binaryReward_Arduino2, 'MinPeakDistance', 20);
TTLReward2SecondATime2 = millis(rewardLocs_Arduino2);

% --- Append TTL Events (sensor == 50) ---
% Find indices for TTL events marked with sensor value 50 in both data sets.
idxTTL_Arduino1 = find(NewData(:,2) == 50);
idxTTL_Arduino2 = find(NewDataJS(:,2) == 50);

% Append these TTL events to the reward TTL arrays.
TTLRewardFirstArduinoTime = [NewData(idxTTL_Arduino1, 1); TTLRewardFirstArduinoTime];
TTLReward2SecondATime2 = [NewDataJS(idxTTL_Arduino2, 1); TTLReward2SecondATime2];

% --- Equalize the Number of TTL Events ---
% Determine the minimum number of TTL events between the two Arduinos.
minEvents = min(numel(TTLRewardFirstArduinoTime), numel(TTLReward2SecondATime2));
TTLRewardFirstArduinoTime = TTLRewardFirstArduinoTime(1:minEvents);
TTLReward2SecondATime2 = TTLReward2SecondATime2(1:minEvents);

% --- Interpolate to Align Times ---
% Map the second Arduino timestamps onto the first Arduino timeline using linear interpolation.
NewDataJS(:,1) = interp1(TTLReward2SecondATime2, TTLRewardFirstArduinoTime, NewDataJS(:,1), 'linear', 'extrap');

%% Session Performance Calculation
% Define trial outcome indices based on sensor codes:
%   3  => Correct and Rewarded
%   13 => Correct but Not Rewarded
%   23 => Incorrect but Rewarded
%   33 => Incorrect and Not Rewarded

correctAndRewardedIdx   = find(NewData(:,2) == 3);
correctNotRewardedIdx   = find(NewData(:,2) == 13);
incorrectButRewardedIdx = find(NewData(:,2) == 23);
incorrectNotRewardedIdx = find(NewData(:,2) == 33);

% Calculate performance as the ratio of correct trials to total trials.
totalCorrect = numel(correctAndRewardedIdx) + numel(correctNotRewardedIdx);
totalTrials  = totalCorrect + numel(incorrectButRewardedIdx) + numel(incorrectNotRewardedIdx);
Performance  = totalCorrect / totalTrials;
fprintf('Session Performance: %.2f\n', Performance);

%%



%% Joystick Data Extraction and Preparation
  % Extract joystick values and times
SensorXTemp= find(NewDataJS(:,2)==1);
SensorX = NewDataJS(SensorXTemp,3);
SensorXTime=NewDataJS(SensorXTemp,1);
JoystickX=cat(2,SensorXTime,SensorX);

SensorYTemp= find(NewDataJS(:,2)==2);
SensorY = NewDataJS(SensorYTemp,3);
SensorYTime=NewDataJS(SensorXTemp,1);
Joystick_Y=cat(2,SensorYTime,SensorY);

% Normalize sensor signals: subtract mean (rounded) then scale (divide by
% 8) 1mm
% changing to median and divide by 2
SensorX= (SensorX-round(median(SensorX)))/8; 
SensorY= (SensorY-round(median(SensorY)))/8;

% --- Combine X and Y Signals Based on Matching Timestamps ---
% For each time in SensorX, find the matching SensorY value.
for i=1:length(SensorXTime)
tempYtime=find(SensorXTime(i)==SensorYTime(:));
if length(tempYtime)>1
tempYtime=tempYtime(1);
end
if isempty(tempYtime)==0
ComineXYAlltimes(i,1)=SensorXTime(i);
ComineXYAlltimes(i,2)=SensorX(i);
ComineXYAlltimes(i,3)=SensorY(tempYtime);    
end
end

            
% --- Compute Timing Information ---
% Total duration (ms) and average interval between joystick samples.
totalDuration    = ComineXYAlltimes(end,1);
numIntervals     = size(ComineXYAlltimes,1) - 1;
avgInterval_ms   = totalDuration / numIntervals;
fps              = 1000 / avgInterval_ms;  % Frames per second estimate

% Time vector for plotting (modify as needed)
TimeX = 0:1.6901:119;



   %% Motor Onset Detection via Joystick Movement Magnitude
% Compute the magnitude of joystick displacement.
joystickTime = ComineXYAlltimes(:,1);
joystickX    = ComineXYAlltimes(:,2);
joystickY    = ComineXYAlltimes(:,3);
movementMagnitude = sqrt(joystickX.^2 + joystickY.^2);

% Combine time and magnitude into one matrix.
ComineXYAlltimes_magnitude = [joystickTime, movementMagnitude];

% Define peak detection parameters.
minPeakHeight   = 1;
minPeakDistance = 60;  
[~, peakLocs] = findpeaks(ComineXYAlltimes_magnitude(:,2), ...
    'MinPeakHeight', minPeakHeight, 'MinPeakDistance', minPeakDistance);

% For each detected peak, search for a local minimum preceding it to mark onset.
onsetIndices = zeros(size(peakLocs));  % Preallocate onset indices array

for pe = 1:length(peakLocs)
    % For the first peak, search from the beginning; otherwise from the previous peak.
    if pe == 1
        segmentStart = 1;
    else
        segmentStart = peakLocs(pe-1);
    end
    
    % Define the segment up to the current peak.
    segment = ComineXYAlltimes_magnitude(segmentStart:peakLocs(pe), 2);
    
    % Find local minima in the segment.
    localMinFlags   = islocalmin(segment);
    localMinIndices = find(localMinFlags);
    
    if ~isempty(localMinIndices)
        % Choose the last local minimum candidate (closest to the peak)
        candidate = localMinIndices(end);
        % Skip candidate if it is too close to the peak (last 3 samples)
        if candidate > length(segment) - 3
            fprintf('Skipping segment [%d - %d]: Candidate local min too close to the end.\n', ...
                segmentStart, peakLocs(pe));
            continue;
        else
            onsetIdx = segmentStart + candidate - 1;
        end
    else
        % If no local minimum is found, use the segment start as onset.
        onsetIdx = segmentStart;
    end
    
    onsetIndices(pe) = onsetIdx;
end

% Remove any zeros (skipped segments) from onset indices.
onsetIndices = nonzeros(onsetIndices);
onsetMovementTimestamps = ComineXYAlltimes_magnitude(onsetIndices, 1);

%% Plot Joystick Displacement Around Movement Onset
% For each detected movement onset, extract one second before and after,
% then plot the displacement with color mapping to time.

DisplacementTrials = cell(length(onsetMovementTimestamps),1);

for i = 1:length(onsetMovementTimestamps)
    % Find the index corresponding to the onset timestamp in the combined data.
    onsetIdxInData = find(ComineXYAlltimes(:,1) == onsetMovementTimestamps(i), 1, 'last');
    
    % Define window indices: one second before and after using fps.
    idxStart = max(onsetIdxInData - round(fps), 1);
    idxEnd   = min(onsetIdxInData + round(fps), size(ComineXYAlltimes,1));
    trialData = ComineXYAlltimes(idxStart:idxEnd, :);
    
    % Normalize time relative to the beginning of the trial window.
    trialData(:,1) = trialData(:,1) - trialData(1,1);
    DisplacementTrials{i} = trialData;
    
    % Plot the displacement trajectory.
    patch(trialData(:,2), trialData(:,3), TimeX, ...
        'FaceColor', 'none', 'EdgeColor', 'interp', 'LineWidth', 2);
    xlabel('X');
    ylabel('Y');
    colormap hot;
    colorbar;  % Add colorbar to indicate time
    hold on;
end

%% Get pairwise similarity Trajectory similarity tests Frechet!

v=(1:1:length(DisplacementTrials));
bbb=nchoosek(v,2);

for i=1:length(bbb)
    tic
    P=DisplacementTrials{bbb(i,1), 1}(:,2:end);
    Q=DisplacementTrials{bbb(i,2), 1}(:,2:end);
    P2 = downsample(P,20);
    Q2 = downsample(Q,20);
    try
    FrechetSimilarityDisplacement(i) = frechet(P2(:,1),P2(:,2),Q2(:,1),Q2(:,2));
    catch
    FrechetSimilarityDisplacement(i)=NaN;
    end
    toc
    clear P Q P2 Q2
end
clear v bbb

%{
figure()
hold on
h = histfit(FrechetSimilarityDisplacement,50,'Kernel');
h(2).Color = [0.4660 0.6740 0.1880];
xline(nanmean(FrechetSimilarityDisplacement),'-','Average')
title('Pairwise Displacement Frechet Similarity')
xlabel('Closer to Zero more similar')
ylabel('Frequency')
%}



  %% Get area visited, mean angular deviation, velocities, and tortuosities for the session.

[num_visited_bins, two_d_workspace, mean_angular_devs, velocities, tortuosities] = get_trajectory_metrics(ComineXYAlltimes);
figure;
subplot(2,2,1)
imagesc(two_d_workspace)
xlabel("Bin Number (0.25cm)")
ylabel("Bin Number (0.25cm)")
title("Area Visited")

subplot(2,2,2)
imagesc(mean_angular_devs)
xlabel("Bin Number (0.25cm)")
title("Mean Angular Deviation")

subplot(2,2,3)
histogram(velocities)
ylabel("Quantity")
xlabel("Velocity values")
title("Velocity for each trajectory")

subplot(2,2,4)
histogram(tortuosities)
xlabel("Tortuosity for each trajectory")
title("Tortuosities")


% I need to get 
% PTSH
% performance.
% Area visited.Plot and data
% Pushh and Pull trajectories in a plot3
% Pairwise Trajecoty similarity.
% Velocity
% Tortuosity
% Mad
% Reaction time onset. 
% 


%% Example Plotting
% Here we plot events for a specific sensor flag (e.g., sensor==70 for Trial Start)
trialStartIdx = sensor == 70;
figure; hold on;
plot(millis(trialStartIdx), ones(sum(trialStartIdx), 1), '.r', 'MarkerSize', 10);
xlabel('Time (ms)'); ylabel('Trial Start');
title('Behavioral Events');
grid on;








                              %   P1_temp= find(sensor==1);
                            %   P1 = millis(P1_temp);
                            %   y(1:length(P1),1)=1;
                            %   plot(P1,y,'+k')
                            %   hold on
                            %   
                            %   P2_temp= find(sensor==2);
                            %   P2 = millis(P2_temp); 
                            %   y2(1:length(P2),1)=2;
                            %   plot(P2,y2,'+b')
                            %   hold on
                            
                            %Trial Start
                             R_temp= find(sensor==70);
                             Tstart = millis(R_temp);
                             yStart(1:length(Tstart),1)=1;
                             plot(Tstart,yStart,'.r','MarkerSize',10)
                                hold on


                             %Trial Sound
                             R_temp= find(sensor==61);
                             TSound = millis(R_temp);
                             yTSound(1:length(TSound),1)=1;
                             plot(TSound,yTSound,'.b','MarkerSize',10)   
                        
                              %Reward
                                  R_temp= find(sensor==3);
                                  T_R = millis(R_temp);
                                  y_T_R(1:length(T_R),1)=1;
                                  plot(T_R,y_T_R,'.g','MarkerSize',10)
                             % hold on
                    
                        
                        
                              %Licks
                              No_R = length(R_temp);
                              %hold on
                              Licks_temp= find(sensor==17);
                              Licks = millis(Licks_temp);
                              yLicks(1:length(Licks),1)=1;
                              plot(Licks,yLicks,'.k','MarkerSize',10)
                             % hold on
                            %   

                              %WhiteNoise

                              R_temp= find(sensor==6);
                              T_Wn = millis(R_temp);
                              y_T_Wn(1:length(T_Wn),1)=1;
                              plot(T_Wn,y_T_Wn,'.m','MarkerSize',10)
                             % hold on

                            %   End Trial
                              LED2_temp= find(sensor==5);
                              LED2 = millis(LED2_temp);
                              y6_Led(1:length(LED2),1)=4.1;
                              plot(LED2,y6_Led,'or','MarkerSize',10)
                          %    hold on

                        
%                              % Start Trial       
%                               LED1_temp= find(sensor==4);
%                               LED1 = millis(LED1_temp);
%                               y5(1:length(LED1),1)=4.1;
%                            %     plot(LED1,y5,'og','MarkerSize',10)
%                               No_LED1 = length(LED1_temp);
%                               %hold on
%                         

%                         
%                             % Joystick
%                               Joystick_temp= find(sensor==1);
%                               Joystick2 = millis(Joystick_temp);
%                               y7(1:length(Joystick2),1)=3.8;
%                            %     plot(Joystick2,y7,'.k')
%                             %  hold on
%                         
%                               %Sound
%                              Sound_temp= find(sensor==6);
%                               Sound = millis(Sound_temp);
%                               y8(1:length(Sound),1)=4.3;
%                           %      plot(Sound,y8,'*','MarkerSize',20,'Color','#D95319')
%                           %    hold on
                        
                               %Sensor1
                               SensorXTemp= find(sensor==1);
                              SensorX = Value(SensorXTemp);
                              meanX=mean(SensorX);
                                modeX=mode(SensorX);%%%%%;
                                  medianX=median(SensorX);
                                     stdX=std(SensorX);
                                       madX=mad(SensorX);
                        
                        
                        
                        
                              %Sensor2
                             SensorYTemp= find(sensor==2);
                              SensorY = Value(SensorYTemp);
                              meanY=mean(SensorY);
                                modeY=mode(SensorY);%%%%%%%%%%;
                                  medianY=median(SensorY);
                                      stdY=std(SensorY);
                                        madY=mad(SensorY);
                                        
                               %TTL2P %1 trial Start %TrialEnds %Sound happen
                          
                          TTL2P_temp= find(sensor==81);
                          TTL2P = millis(TTL2P_temp);
                          TTL2P_Value= Value(TTL2P_temp);
                          TTL2P_All=cat(2,TTL2P,TTL2P_Value);
                          y81(1:length(TTL2P),1)=4.1;
                          %plot(TTL2P,y81,'or','MarkerSize',10)
                          %hold on
                        
                        
                        %       axis([0 max(R) 2 5])
                        
                    
                        
                        
                              NewData(:,1)=millis;
                                NewData(:,2)=sensor;
                                  NewData(:,3)=Value;
                                    TrialStart=find(NewData(:,2)==4);
                                      TrialStartTimes=NewData(TrialStart,1);
                                        TrialEnds=find(NewData(:,2)==5);
                                          TrialEndsTimes=NewData(TrialEnds,1);
                                            Trails21=find(NewData(:,2)==21);
                                                Trails21Times=NewData(Trails21,1);
                        
