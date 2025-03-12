%% Download Test Data from GitHub (if not already available)

% Define the raw URLs of the test data on GitHub (replace with your actual URLs)
behaviourURL = 'https://raw.githubusercontent.com/yourusername/yourrepo/main/path/Boa_LF_Pull_15r_2p_BehData_151815.txt';
joystickURL  = 'https://raw.githubusercontent.com/yourusername/yourrepo/main/path/Boa_LF_Pull_15r_2p_JSData_151824.txt';

% Define local filenames for the downloaded files
behaviourFile = 'Boa_LF_Pull_15r_2p_BehData_151815.txt';
joystickFile  = 'Boa_LF_Pull_15r_2p_JSData_151824.txt';

% Check if the behavior file exists; if not, download it
if ~exist(behaviourFile, 'file')
    fprintf('Downloading Behavior Data...\n');
    websave(behaviourFile, behaviourURL);
end

% Check if the joystick file exists; if not, download it
if ~exist(joystickFile, 'file')
    fprintf('Downloading Joystick Data...\n');
    websave(joystickFile, joystickURL);
end

%% (Optional) Let user select a file interactively if desired
% [filename, pathname] = uigetfile({'*.txt', 'Text Files (*.txt)'}, 'Select a Data File');
% if isequal(filename,0)
%     error('No file selected. Exiting demo.');
% else
%     selectedFile = fullfile(pathname, filename);
%     fprintf('Selected file: %s\n', selectedFile);
% end



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
SensorX= (SensorX-round(mean(SensorX)))/8; 
SensorY= (SensorY-round(mean(SensorY)))/8;

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
           % fprintf('Skipping segment [%d - %d]: Candidate local min too close to the end.\n', ...
               % segmentStart, peakLocs(pe));
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

subplot(2,4,2)
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

DisplacementTrialsall{1}=DisplacementTrials;

%% Get pairwise similarity Trajectory similarity tests Frechet!
% Next, compute pairwise Frechet similarity
v=(1:1:length(DisplacementTrials));
bbb=nchoosek(v,2);

for i=1:length(bbb)
     % Extract trajectory data from nested cell arrays 
    P=DisplacementTrials{bbb(i,1), 1}(:,2:end);
    Q=DisplacementTrials{bbb(i,2), 1}(:,2:end);
     % Downsample for computational efficiency.
    P2 = downsample(P,2);
    Q2 = downsample(Q,2);
    try
    FrechetSimilarityDisplacement(i) = frechet(P2(:,1),P2(:,2),Q2(:,1),Q2(:,2));
    catch
    FrechetSimilarityDisplacement(i)=NaN;
    end  
    clear P Q P2 Q2
end
clear v bbb

SimilarityMean=nanmean(FrechetSimilarityDisplacement);

subplot(2,4,6)
hold on
h = histfit(FrechetSimilarityDisplacement,50,'Kernel');
h(2).Color = [0.4660 0.6740 0.1880];
xline(nanmean(FrechetSimilarityDisplacement),'-','Average')
title('Pairwise Displacement Frechet Similarity')
xlabel('Closer to Zero more similar')
ylabel('Frequency')



%% Plot Trials
    
TrialStart=find(NewData(:,2)==4);
TrialStartTimes=NewData(TrialStart,1);
TrialEnds=find(NewData(:,2)==5);
TrialEndsTimes=NewData(TrialEnds,1);
Trails21=find(NewData(:,2)==21);
Trails21Times=NewData(Trails21,1);

% AllTrialsID
TrialSound=find(NewData(:,2)==4);
TrialSoundTimes=NewData(TrialSound,1);

for i=1:length(TrialSound)
Temp13Start2=TrialSound(i);
Temp13End=find(Trails21Times>=NewData(TrialSound(i),1));
if isempty(Temp13End)==0
Temp13End2=Trails21(Temp13End(1));
AllTrialsSound{i,1}=NewData(Temp13Start2:Temp13End2,:);
end
clear Temp13Start Temp13Start2 Temp13End Temp13End2 
end


%% First subplot: Event Raster Plot
subplot(2,4,1)
for i = 1:length(AllTrialsSound)
    y = i;

    % Plot Sound events
    AllTrialsSound{i}(:,1) = AllTrialsSound{i}(:,1) - AllTrialsSound{i}(1,1);
    temp = AllTrialsSound{i}(AllTrialsSound{i}(:,2)==61, 1);
    soundTimes(i) = temp;
    plot(temp, y, '.b', 'MarkerSize', 20)
    hold on

    % Plot Reward events
    temp = AllTrialsSound{i}(AllTrialsSound{i}(:,2)==3, 1);
    if ~isempty(temp)
        RewardTimes(i) = temp;
        plot(temp, y, '.g', 'MarkerSize', 20)
    end

    % Plot Lick events
    temp = AllTrialsSound{i}(AllTrialsSound{i}(:,2)==17, 1);
    if ~isempty(temp)
        plot(temp, y, '.k', 'MarkerSize', 20)
        LickTimes{i,1} = temp;
        numLickperTrial(i) = length(temp);
    end

    % Plot ThresholdAchieve events
    temp = AllTrialsSound{i}(AllTrialsSound{i}(:,3)==5, 1);
    if ~isempty(temp)
        OnsetActionTimes(i) = temp(1);
        plot(temp, y, '.m', 'MarkerSize', 20)
    end

end
xlim([-100 8000])

mReactionTime=mean(OnsetActionTimes);
%% Second subplot: Probability Density Histograms and KDEs


% Plot settings for transparency and line width
alphaVal = 0.3;
lineWidthVal = 2;

%% SoundTimes histogram and KDE
% Histogram with normalization to PDF
subplot(2,4,5)  
hold on
hSound = histogram(soundTimes, 3, 'Normalization', 'probability');
hSound.FaceColor = [0 0 1];
hSound.FaceAlpha = alphaVal;
hSound.EdgeColor = 'none';
% Compute and plot kernel density estimate
% [xSound, fSound] = ksdensity(soundTimes);
% plot(fSound, xSound,'b', 'LineWidth', lineWidthVal)

%% RewardTimes histogram and KDE
RewardTimes = nonzeros(RewardTimes);  % remove zeros if any
hReward = histogram(RewardTimes, 50, 'Normalization', 'probability');
hReward.FaceColor = [0.4660 0.6740 0.1880];
hReward.FaceAlpha = alphaVal;
hReward.EdgeColor = 'none';
% [xReward, fReward] = ksdensity(RewardTimes);
% plot(fReward, xReward, 'Color', [0.4660 0.6740 0.1880], 'LineWidth', lineWidthVal)

%% LickTimes histogram and KDE
AllLicks = vertcat(LickTimes{:});
hLicks = histogram(AllLicks, 30, 'Normalization', 'probability');
hLicks.FaceColor = [0 0 0];
hLicks.FaceAlpha = alphaVal;
hLicks.EdgeColor = 'none';
% [xLicks, fLicks] = ksdensity(AllLicks);
% plot(fLicks,xLicks, 'k', 'LineWidth', lineWidthVal)

%% OnsetActionTimes histogram and KDE
OnsetActionTimes = nonzeros(OnsetActionTimes);
hOnset = histogram(OnsetActionTimes, 30, 'Normalization', 'probability');
hOnset.FaceColor = [1 0 1];
hOnset.FaceAlpha = alphaVal;
hOnset.EdgeColor = 'none';
% [xOnset, ] = ksdensity(OnsetActionTimes);
% plot(fOnset, xOnset, 'm', 'LineWidth', lineWidthVal)
%ylim([0 0.01])
xlim([-100 8000])
xlabel('Time ms')
ylabel('Probability')
%title('Probability Density Functions of Events')
legend({'Sound Hist', 'Reward Hist','Licks Hist', ...
        'Onset Hist', 'Onset KDE'}, 'Location', 'Best')

  %% Get area visited, mean angular deviation, velocities, and tortuosities for the session.

[num_visited_bins, two_d_workspace, mean_angular_devs, velocities, tortuosities] = get_trajectory_metrics(ComineXYAlltimes);
%figure;
subplot(2,4,3)
imagesc(two_d_workspace)
colormap hot;
colorbar;  % Add colorbar to indicate time
xlabel("Bin Number (0.25mm)")
ylabel("Bin Number (0.25mm)")
title("Area Visited")

subplot(2,4,4)
imagesc(mean_angular_devs)
colormap hot;
colorbar;  % Add colorbar to indicate time
xlabel("Bin Number (0.25mm)")
title("Mean Angular Deviation")

subplot(2,4,7)
%histogram(velocities)
h = histfit(velocities,10,'Kernel');
h(2).Color = [0.4660 0.6740 0.1880];
xline(nanmean(velocities),'-','Average')
ylabel("Quantity")
xlabel("Velocity values")
title("Velocity for each trajectory")

subplot(2,4,8)
%histogram(tortuosities)
h = histfit(tortuosities,10,'Kernel');
h(2).Color = [0.4660 0.6740 0.1880];
xline(nanmean(tortuosities),'-','Average')
xlabel("Tortuosity for each trajectory")
title("Tortuosities")

h = histfit(FrechetSimilarityDisplacement,50,'Kernel');
h(2).Color = [0.4660 0.6740 0.1880];
xline(nanmean(FrechetSimilarityDisplacement),'-','Average')

%%
velocitiesAll{1}=velocities;
TortusityAll{1}=tortuosities;
velocitiesm=mean(velocities);
Tortusitym=mean(tortuosities);


Results=struct('Filename',BehaviourFile,'Performance',Performance,'ReactionTime',mReactionTime,'Similarity',SimilarityMean,...
    'Displacements',DisplacementTrialsall,'velocities',velocitiesm,'tortuosities',Tortusitym,'AllVelocities',velocitiesAll,'AllTortuosity',TortusityAll);

fprintf('Session Performance: %.2f\n', Performance);
fprintf('Session Reaction time (ms): %.2f\n', mReactionTime);
fprintf('Session Similarity: %.2f\n', SimilarityMean);
fprintf('Session Velocity mean: %.2f\n', velocitiesm);
fprintf('Session tortuosities mean: %.2f\n', Tortusitym);

clearvars -except Results

% Adecuar para que le den el input del file
% pasarlo por chat
% y probarlo con otors datos




