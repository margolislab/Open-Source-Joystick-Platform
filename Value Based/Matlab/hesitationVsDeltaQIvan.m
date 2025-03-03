%Joystick analyses for Ivan paper

%read in the data
[masterStruct] = importData("C:\Users\walki\Box\grp-psom-fuccillo-lab\Joystick Behavior\CompletedExperiments\WT2CohortDataForAnalysis");

extractBlockInfo;
extractJoystickTrace;
extractBouts;

%reorganize into QStruct
for i = 1:numel(masterStruct)
    if floor(masterStruct(i).phase) == 5
        masterStruct(i).startingPoint = 1;
    elseif ismember(floor(masterStruct(i).phase),[6,7,8,11,12])
        for j = 1:numel(masterStruct(i).trialByTrial)
            if masterStruct(i).trialByTrial(j).blockNumber == 3
                masterStruct(i).startingPoint = j;
            end
        end
    end
end


animals = [];
for i = 1:numel(masterStruct)
    if ismember(floor(masterStruct(i).phase), [6,7,8,11,12])
        animals = [animals; masterStruct(i).animalID];
    end
end
animals = unique(animals);

phases = [];
for i = 1:numel(masterStruct)
    if ismember(floor(masterStruct(i).phase), [6,7,8,11,12])
        phases = [phases; masterStruct(i).phase];
    end
end
phases = unique(phases);

QStruct = [];
for b = 1:numel(phases)
    for a = 1:numel(animals)
        if b == 1
            indNo = a;
        elseif b >1
            indNo = a+b*numel(animals);
        end
        QStruct(indNo).animal = animals(a,1);
        QStruct(indNo).phase = phases(b);
        trialsStruct = [];
        for i = 1:numel(masterStruct)
            if masterStruct(i).animalID == animals(a,1) && masterStruct(i).phase == phases(b) && ~isempty(masterStruct(i).startingPoint)
                for j = masterStruct(i).startingPoint:numel(masterStruct(i).trialByTrial)
                    masterStruct(i).trialByTrial(j).iOrig = i;
                    masterStruct(i).trialByTrial(j).jOrig = j;
                    if j == masterStruct(i).startingPoint
                        masterStruct(i).trialByTrial(j).firstFlag = 1;
                    else
                        masterStruct(i).trialByTrial(j).firstFlag = 0;
                    end
                    trialsStruct = [trialsStruct masterStruct(i).trialByTrial(j)];
                end
            end
        end
        QStruct(indNo).trials = trialsStruct;
    end
end


for a = numel(QStruct):-1:1
    if isempty(QStruct(a).trials)
        QStruct(a) = [];
    end
end

%Run Q with forgetting
for a = 1:numel(QStruct)
    [QStruct] = photometryQFOct2024(a,QStruct);
    fprintf('%d/%d\n',a,numel(QStruct));
end

%Reassign Q outputs to trials
for a = 1:numel(QStruct)
    counter = 0;
    for j = 1:numel(QStruct(a).trials)
        if ismember(QStruct(a).trials(j).trialOutcome,1:1:3)
            counter = counter + 1;
            QStruct(a).trials(j).RPE = sum(QStruct(a).RPEs(counter,:));
            QStruct(a).trials(j).deltaQ = QStruct(a).QDifferences(counter,1);
        end
    end
end

%% TERCILES
%Get joystick parameters animal by animal and organize in joystick struct
%(joyS).

phase = 6;

for i = 1:numel(animalIDs)

    deltaQ = [];
    peakDispl = [];
    peakVel = [];
    meanVel = [];
    tortuosity = [];
    numBouts = [];
    dirConsistency = [];
    totalDistanceTravelled = [];

    for a = 1:numel(QStruct)
        if floor(QStruct(a).phase) == phase & QStruct(a).animal == animalIDs(i,1)
            for j = 1:numel(QStruct(a).trials)
                if ~isempty(QStruct(a).trials(j).peakDispl) & ~isempty(QStruct(a).trials(j).meanVel) & ~isempty(QStruct(a).trials(j).numBouts) & ismember(QStruct(a).trials(j).trialOutcome,[1,2])
                    deltaQ = [deltaQ; abs(QStruct(a).trials(j).deltaQ)];
                    peakDispl = [peakDispl; abs(QStruct(a).trials(j).peakDispl)/1000];
                    peakVel = [peakVel; abs(QStruct(a).trials(j).peakVel)];
                    meanVel = [meanVel; abs(QStruct(a).trials(j).meanVel)];
                    tortuosity = [tortuosity; QStruct(a).trials(j).totalDistanceTravelled/abs(QStruct(a).trials(j).peakDispl)];
                    numBouts = [numBouts; QStruct(a).trials(j).numBouts];
                    dirConsistency = [dirConsistency; QStruct(a).trials(j).dirConsistency];
                    totalDistanceTravelled = [totalDistanceTravelled; QStruct(a).trials(j).totalDistanceTravelled];
                end
            end
        end
    end
    joyS(i).animal = animalIDs(i,1);
    joyS(i).deltaQ = deltaQ;
    joyS(i).peakDispl = peakDispl;
    joyS(i).peakVel = peakVel;
    joyS(i).meanVel = meanVel;
    joyS(i).tortuosity = tortuosity;
    joyS(i).numBouts = numBouts;
    joyS(i).dirConsistency = dirConsistency;
    joyS(i).totalDistanceTravelled = totalDistanceTravelled;
end


%loop through and get averages by tercile
deltaQ = [];
peakDispl = [];
peakVel = [];
meanVel = [];
tortuosity = [];
numBouts = [];
dirConsistency = [];
totalDistanceTravelled = [];

for i = 1:numel(joyS)
    low = find(joyS(i).deltaQ <=prctile(joyS(i).deltaQ,33.3));
    mid = find(joyS(i).deltaQ > prctile(joyS(i).deltaQ,33.3) & joyS(i).deltaQ < prctile(joyS(i).deltaQ,66.7));
    high = find(joyS(i).deltaQ >=prctile(joyS(i).deltaQ,66.7));
    peakDispl = [peakDispl; mean(joyS(i).peakDispl(low)) mean(joyS(i).peakDispl(mid)) mean(joyS(i).peakDispl(high))];
    peakVel = [peakVel; mean(joyS(i).peakVel(low)) mean(joyS(i).peakVel(mid)) mean(joyS(i).peakVel(high))];
    meanVel = [meanVel; mean(joyS(i).meanVel(low)) mean(joyS(i).meanVel(mid)) mean(joyS(i).meanVel(high))];
    tortuosity = [tortuosity; mean(joyS(i).tortuosity(low)) mean(joyS(i).tortuosity(mid)) mean(joyS(i).tortuosity(high))];
    numBouts = [numBouts; mean(joyS(i).numBouts(low)) mean(joyS(i).numBouts(mid)) mean(joyS(i).numBouts(high))];
    dirConsistency = [dirConsistency; mean(joyS(i).dirConsistency(low)) mean(joyS(i).dirConsistency(mid)) mean(joyS(i).dirConsistency(high))];
    totalDistanceTravelled = [totalDistanceTravelled; mean(joyS(i).totalDistanceTravelled(low)) mean(joyS(i).totalDistanceTravelled(mid)) mean(joyS(i).totalDistanceTravelled(high))];
end


%plot
females = [1,2,23,27,28,21];
males = [9,12,20,25,26,29,34,37];
figure;
tiledlayout(2,4);
% For peakDispl
nexttile;
hold on;
bar([1,2,3],nanmean(peakDispl,1));
for i = 1:numel(animalIDs)
    if ismember(animalIDs(i),males)
        plot([1,2,3],peakDispl(i,:),'bo-');
    elseif ismember(animalIDs(i),females)
        plot([1,2,3],peakDispl(i,:),'ro-');
    end
end
%title('peakDispl');
ylim([3,4.5]);
ylabel('Peak Displacement (mm)');
xticks([1:1:3]);
xlim([.5,3.5]);
xticklabels({'Low |ΔQ|','Mid |ΔQ|','High |ΔQ|'});

% For peakVel
nexttile;
hold on;
bar([1,2,3],nanmean(peakVel,1));
for i = 1:numel(animalIDs)
    if ismember(animalIDs(i),males)
        plot([1,2,3],peakVel(i,:),'bo-');
    elseif ismember(animalIDs(i),females)
        plot([1,2,3],peakVel(i,:),'ro-');
    end
end
%title('peakVel');
xticks([1:1:3]);
ylabel('Peak Joystick Velocity (mm/s)');
xlim([.5,3.5]);
xticklabels({'Low |ΔQ|','Mid |ΔQ|','High |ΔQ|'});

% For meanVel
nexttile;
hold on;
bar([1,2,3],nanmean(meanVel,1));
for i = 1:numel(animalIDs)
    if ismember(animalIDs(i),males)
        plot([1,2,3],meanVel(i,:),'bo-');
    elseif ismember(animalIDs(i),females)
        plot([1,2,3],meanVel(i,:),'ro-');
    end
end
%title('meanVel');
ylabel('Mean Joystick Velocity (mm/s)');
xticks([1:1:3]);
xlim([.5,3.5]);
xticklabels({'Low |ΔQ|','Mid |ΔQ|','High |ΔQ|'});

% For tortuosity
nexttile;
hold on;
bar([1,2,3],nanmean(tortuosity,1));
for i = 1:numel(animalIDs)
    if ismember(animalIDs(i),males)
        plot([1,2,3],tortuosity(i,:),'bo-');
    elseif ismember(animalIDs(i),females)
        plot([1,2,3],tortuosity(i,:),'ro-');
    end
end
%title('tortuosity');
ylabel('Tortuosity (Distance/Displacement)');
xticks([1:1:3]);
xlim([.5,3.5]);
xticklabels({'Low |ΔQ|','Mid |ΔQ|','High |ΔQ|'});

% For numBouts
nexttile;
hold on;
bar([1,2,3],nanmean(numBouts,1));
for i = 1:numel(animalIDs)
    if ismember(animalIDs(i),males)
        plot([1,2,3],numBouts(i,:),'bo-');
    elseif ismember(animalIDs(i),females)
        plot([1,2,3],numBouts(i,:),'ro-');
    end
end
%title('numBouts');
ylabel('Number of Bouts of Movement');
xticks([1:1:3]);
xlim([.5,3.5]);
xticklabels({'Low |ΔQ|','Mid |ΔQ|','High |ΔQ|'});

% For dirConsistency
nexttile;
hold on;
bar([1,2,3],nanmean(dirConsistency,1));
for i = 1:numel(animalIDs)
    if ismember(animalIDs(i),males)
        plot([1,2,3],dirConsistency(i,:),'bo-');
    elseif ismember(animalIDs(i),females)
        plot([1,2,3],dirConsistency(i,:),'ro-');
    end
end
%title('dirConsistency');
ylabel('Consistency in Direction of Movement Bouts');
xticks([1:1:3]);
xlim([.5,3.5]);
xticklabels({'Low |ΔQ|','Mid |ΔQ|','High |ΔQ|'});

% For totalDistanceTravelled
nexttile;
hold on;
bar([1,2,3],nanmean(totalDistanceTravelled./1000,1));
for i = 1:numel(animalIDs)
    if ismember(animalIDs(i),males)
        plot([1,2,3],totalDistanceTravelled(i,:)./1000,'bo-');
    elseif ismember(animalIDs(i),females)
        plot([1,2,3],totalDistanceTravelled(i,:)./1000,'ro-');
    end
end
%title('totalDistanceTravelled');
ylabel('Total Distance Travelled (mm)')
xticks([1:1:3]);
xlim([.5,3.5]);
xticklabels({'Low |ΔQ|','Mid |ΔQ|','High |ΔQ|'});


%%
%mean velocity
figure;
hold on
scatter(1,meanVel(ismember(animalIDs,females),1),'ro','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.988, 0.235, 1]);
scatter(2,meanVel(ismember(animalIDs,females),2),'ro','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.988, 0.235, 1]);
scatter(3,meanVel(ismember(animalIDs,females),3),'ro','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.988, 0.235, 1]);
scatter(1,meanVel(ismember(animalIDs,males),1),'bo','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.02, 0.329, 0.988]);
scatter(2,meanVel(ismember(animalIDs,males),2),'bo','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.02, 0.329, 0.988]);
scatter(3,meanVel(ismember(animalIDs,males),3),'bo','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.02, 0.329, 0.988]);
errorbar([1,2,3],mean(meanVel(ismember(animalIDs,females),1:3)),std(meanVel(ismember(animalIDs,females),1:3),0)./sqrt(numel(females)),'o-','LineWidth',1,'Color',[0.988, 0.235, 1],"MarkerFaceColor",[1 1 1],'MarkerSize', 4);
errorbar([1,2,3],mean(meanVel(ismember(animalIDs,males),1:3)),std(meanVel(ismember(animalIDs,males),1:3),0)./sqrt(numel(males)),'o-','LineWidth',1,'Color',[0.02, 0.329, 0.988],"MarkerFaceColor",[1 1 1],'MarkerSize', 4);
%title('Choice Latency by Reward Volume')
ylabel('Mean Velocity (mm/s)')
ylim([10,25]);
yticks([10:5:25]);
xticks([1:1:3]);
xlim([.5,3.5]);
xticklabels({'Low |ΔQ|','Mid |ΔQ|','High |ΔQ|'});
text('Units', 'normalized', 'Position', [0.8, 0.9], 'String', 'Females (N = 6)', 'Color',[0.988, 0.235, 1],'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
text('Units', 'normalized', 'Position', [0.8, 0.8], 'String', 'Males (N = 8)', 'Color',[0.02, 0.329, 0.988],'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
ax = gca; % Get current axes handle
ax.XLabel.Color = 'k';  % Set X-axis label color to black
ax.YLabel.Color = 'k';  % Set Y-axis label color to black
ax.Title.Color = 'k';   % Set title color to black

% Optionally: Set tick labels to black
ax.XColor = 'k';        % Set X-axis ticks to black
ax.YColor = 'k';        % Set Y-axis ticks to black

%%

%tortuosity
figure;
hold on
scatter(1,tortuosity(ismember(animalIDs,females),1),'ro','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.988, 0.235, 1]);
scatter(2,tortuosity(ismember(animalIDs,females),2),'ro','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.988, 0.235, 1]);
scatter(3,tortuosity(ismember(animalIDs,females),3),'ro','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.988, 0.235, 1]);
scatter(1,tortuosity(ismember(animalIDs,males),1),'bo','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.02, 0.329, 0.988]);
scatter(2,tortuosity(ismember(animalIDs,males),2),'bo','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.02, 0.329, 0.988]);
scatter(3,tortuosity(ismember(animalIDs,males),3),'bo','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.02, 0.329, 0.988]);
errorbar([1,2,3],mean(tortuosity(ismember(animalIDs,females),1:3)),std(tortuosity(ismember(animalIDs,females),1:3),0)./sqrt(numel(females)),'o-','LineWidth',1,'Color',[0.988, 0.235, 1],"MarkerFaceColor",[1 1 1],'MarkerSize', 4);
errorbar([1,2,3],mean(tortuosity(ismember(animalIDs,males),1:3)),std(tortuosity(ismember(animalIDs,males),1:3),0)./sqrt(numel(males)),'o-','LineWidth',1,'Color',[0.02, 0.329, 0.988],"MarkerFaceColor",[1 1 1],'MarkerSize', 4);
%title('Choice Latency by Reward Volume')
ylabel('Tortuosity (distance/displacement)')
ylim([1,2.5]);
yticks([1:.5:2.5]);
xticks([1:1:3]);
xlim([.5,3.5]);
xticklabels({'Low |ΔQ|','Mid |ΔQ|','High |ΔQ|'});
text('Units', 'normalized', 'Position', [0.8, 0.9], 'String', 'Females (N = 6)', 'Color',[0.988, 0.235, 1],'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
text('Units', 'normalized', 'Position', [0.8, 0.8], 'String', 'Males (N = 8)', 'Color',[0.02, 0.329, 0.988],'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
ax = gca; % Get current axes handle
ax.XLabel.Color = 'k';  % Set X-axis label color to black
ax.YLabel.Color = 'k';  % Set Y-axis label color to black
ax.Title.Color = 'k';   % Set title color to black

% Optionally: Set tick labels to black
ax.XColor = 'k';        % Set X-axis ticks to black
ax.YColor = 'k';        % Set Y-axis ticks to black

%% Peak Displacement
figure;
hold on
scatter(1,peakDispl(ismember(animalIDs,females),1),'ro','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.988, 0.235, 1]);
scatter(2,peakDispl(ismember(animalIDs,females),2),'ro','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.988, 0.235, 1]);
scatter(3,peakDispl(ismember(animalIDs,females),3),'ro','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.988, 0.235, 1]);
scatter(1,peakDispl(ismember(animalIDs,males),1),'bo','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.02, 0.329, 0.988]);
scatter(2,peakDispl(ismember(animalIDs,males),2),'bo','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.02, 0.329, 0.988]);
scatter(3,peakDispl(ismember(animalIDs,males),3),'bo','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.02, 0.329, 0.988]);
errorbar([1,2,3],mean(peakDispl(ismember(animalIDs,females),1:3)),std(peakDispl(ismember(animalIDs,females),1:3),0)./sqrt(numel(females)),'o-','LineWidth',1,'Color',[0.988, 0.235, 1],"MarkerFaceColor",[1 1 1],'MarkerSize', 4);
errorbar([1,2,3],mean(peakDispl(ismember(animalIDs,males),1:3)),std(peakDispl(ismember(animalIDs,males),1:3),0)./sqrt(numel(males)),'o-','LineWidth',1,'Color',[0.02, 0.329, 0.988],"MarkerFaceColor",[1 1 1],'MarkerSize', 4);
%title('Choice Latency by Reward Volume')
ylabel('Peak Displacement (mm)')
ylim([3,4.5]);
yticks([3:.5:4.5]);
xticks([1:1:3]);
xlim([.5,3.5]);
xticklabels({'Low |ΔQ|','Mid |ΔQ|','High |ΔQ|'});
text('Units', 'normalized', 'Position', [0.8, 0.9], 'String', 'Females (N = 6)', 'Color',[0.988, 0.235, 1],'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
text('Units', 'normalized', 'Position', [0.8, 0.8], 'String', 'Males (N = 8)', 'Color',[0.02, 0.329, 0.988],'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
ax = gca; % Get current axes handle
ax.XLabel.Color = 'k';  % Set X-axis label color to black
ax.YLabel.Color = 'k';  % Set Y-axis label color to black
ax.Title.Color = 'k';   % Set title color to black

% Optionally: Set tick labels to black
ax.XColor = 'k';        % Set X-axis ticks to black
ax.YColor = 'k';        % Set Y-axis ticks to black


%% Distance travelled
figure;
hold on
scatter(1,totalDistanceTravelled(ismember(animalIDs,females),1)./1000,'ro','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.988, 0.235, 1]);
scatter(2,totalDistanceTravelled(ismember(animalIDs,females),2)./1000,'ro','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.988, 0.235, 1]);
scatter(3,totalDistanceTravelled(ismember(animalIDs,females),3)./1000,'ro','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.988, 0.235, 1]);
scatter(1,totalDistanceTravelled(ismember(animalIDs,males),1)./1000,'bo','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.02, 0.329, 0.988]);
scatter(2,totalDistanceTravelled(ismember(animalIDs,males),2)./1000,'bo','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.02, 0.329, 0.988]);
scatter(3,totalDistanceTravelled(ismember(animalIDs,males),3)./1000,'bo','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.02, 0.329, 0.988]);
errorbar([1,2,3],mean(totalDistanceTravelled(ismember(animalIDs,females),1:3))./1000,std(totalDistanceTravelled(ismember(animalIDs,females),1:3)./1000,0)./sqrt(numel(females)),'o-','LineWidth',1,'Color',[0.988, 0.235, 1],"MarkerFaceColor",[1 1 1],'MarkerSize', 4);
errorbar([1,2,3],mean(totalDistanceTravelled(ismember(animalIDs,males),1:3))./1000,std(totalDistanceTravelled(ismember(animalIDs,males),1:3)./1000,0)./sqrt(numel(males)),'o-','LineWidth',1,'Color',[0.02, 0.329, 0.988],"MarkerFaceColor",[1 1 1],'MarkerSize', 4);
%title('Choice Latency by Reward Volume')
ylabel('Total Distance Travelled')
ylim([3,8]);
yticks([3:1:8]);
xticks([1:1:3]);
xlim([.5,3.5]);
xticklabels({'Low |ΔQ|','Mid |ΔQ|','High |ΔQ|'});
text('Units', 'normalized', 'Position', [0.8, 0.9], 'String', 'Females (N = 6)', 'Color',[0.988, 0.235, 1],'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
text('Units', 'normalized', 'Position', [0.8, 0.8], 'String', 'Males (N = 8)', 'Color',[0.02, 0.329, 0.988],'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
ax = gca; % Get current axes handle
ax.XLabel.Color = 'k';  % Set X-axis label color to black
ax.YLabel.Color = 'k';  % Set Y-axis label color to black
ax.Title.Color = 'k';   % Set title color to black

% Optionally: Set tick labels to black
ax.XColor = 'k';        % Set X-axis ticks to black
ax.YColor = 'k';        % Set Y-axis ticks to black

%% Number of bouts

figure;
hold on
scatter(1,numBouts(ismember(animalIDs,females),1),'ro','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.988, 0.235, 1]);
scatter(2,numBouts(ismember(animalIDs,females),2),'ro','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.988, 0.235, 1]);
scatter(3,numBouts(ismember(animalIDs,females),3),'ro','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.988, 0.235, 1]);
scatter(1,numBouts(ismember(animalIDs,males),1),'bo','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.02, 0.329, 0.988]);
scatter(2,numBouts(ismember(animalIDs,males),2),'bo','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.02, 0.329, 0.988]);
scatter(3,numBouts(ismember(animalIDs,males),3),'bo','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.02, 0.329, 0.988]);
errorbar([1,2,3],mean(numBouts(ismember(animalIDs,females),1:3)),std(numBouts(ismember(animalIDs,females),1:3),0)./sqrt(numel(females)),'o-','LineWidth',1,'Color',[0.988, 0.235, 1],"MarkerFaceColor",[1 1 1],'MarkerSize', 4);
errorbar([1,2,3],mean(numBouts(ismember(animalIDs,males),1:3)),std(numBouts(ismember(animalIDs,males),1:3),0)./sqrt(numel(males)),'o-','LineWidth',1,'Color',[0.02, 0.329, 0.988],"MarkerFaceColor",[1 1 1],'MarkerSize', 4);
%title('Choice Latency by Reward Volume')
ylabel('Number of Bouts of Movement')
ylim([1,5]);
yticks([1:1:5]);
xticks([1:1:3]);
xlim([.5,3.5]);
xticklabels({'Low |ΔQ|','Mid |ΔQ|','High |ΔQ|'});
text('Units', 'normalized', 'Position', [0.8, 0.9], 'String', 'Females (N = 6)', 'Color',[0.988, 0.235, 1],'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
text('Units', 'normalized', 'Position', [0.8, 0.8], 'String', 'Males (N = 8)', 'Color',[0.02, 0.329, 0.988],'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
ax = gca; % Get current axes handle
ax.XLabel.Color = 'k';  % Set X-axis label color to black
ax.YLabel.Color = 'k';  % Set Y-axis label color to black
ax.Title.Color = 'k';   % Set title color to black

% Optionally: Set tick labels to black
ax.XColor = 'k';        % Set X-axis ticks to black
ax.YColor = 'k';        % Set Y-axis ticks to black

%% Directional Consistency

figure;
hold on
scatter(1,dirConsistency(ismember(animalIDs,females),1),'ro','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.988, 0.235, 1]);
scatter(2,dirConsistency(ismember(animalIDs,females),2),'ro','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.988, 0.235, 1]);
scatter(3,dirConsistency(ismember(animalIDs,females),3),'ro','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.988, 0.235, 1]);
scatter(1,dirConsistency(ismember(animalIDs,males),1),'bo','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.02, 0.329, 0.988]);
scatter(2,dirConsistency(ismember(animalIDs,males),2),'bo','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.02, 0.329, 0.988]);
scatter(3,dirConsistency(ismember(animalIDs,males),3),'bo','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.02, 0.329, 0.988]);
errorbar([1,2,3],mean(dirConsistency(ismember(animalIDs,females),1:3)),std(dirConsistency(ismember(animalIDs,females),1:3),0)./sqrt(numel(females)),'o-','LineWidth',1,'Color',[0.988, 0.235, 1],"MarkerFaceColor",[1 1 1],'MarkerSize', 4);
errorbar([1,2,3],mean(dirConsistency(ismember(animalIDs,males),1:3)),std(dirConsistency(ismember(animalIDs,males),1:3),0)./sqrt(numel(males)),'o-','LineWidth',1,'Color',[0.02, 0.329, 0.988],"MarkerFaceColor",[1 1 1],'MarkerSize', 4);
%title('Choice Latency by Reward Volume')
ylabel('Directional Consistency')
ylim([.5,1]);
yticks([0.5:.1:1]);
xticks([1:1:3]);
xlim([.5,3.5]);
xticklabels({'Low |ΔQ|','Mid |ΔQ|','High |ΔQ|'});
text('Units', 'normalized', 'Position', [0.8, 0.9], 'String', 'Females (N = 6)', 'Color',[0.988, 0.235, 1],'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
text('Units', 'normalized', 'Position', [0.8, 0.8], 'String', 'Males (N = 8)', 'Color',[0.02, 0.329, 0.988],'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
ax = gca; % Get current axes handle
ax.XLabel.Color = 'k';  % Set X-axis label color to black
ax.YLabel.Color = 'k';  % Set Y-axis label color to black
ax.Title.Color = 'k';   % Set title color to black

% Optionally: Set tick labels to black
ax.XColor = 'k';        % Set X-axis ticks to black
ax.YColor = 'k';        % Set Y-axis ticks to black

%% Looking at individual traces
a = 7;
j = 140;
tiledlayout(2,1);
nexttile;
hold on;
plot(QStruct(a).trials(j).joyPosArray(:,1)./1000,QStruct(a).trials(j).joyPosArray(:,2)./1000);
for i = 1:numel(QStruct(a).trials(j).boutByBout)
    xline(min(QStruct(a).trials(j).boutByBout(i).raw(:,1))/1000,'g');
    xline(max(QStruct(a).trials(j).boutByBout(i).raw(:,1))/1000,'r');
end
ylim([-4.5,4.5])
xlim([-1.5,0.1]);
ylabel('Joystick Displacement (mm)');
yline(0,'k--');
nexttile;
hold on;
plot(QStruct(a).trials(j).joyPosArray(:,1)./1000,QStruct(a).trials(j).joyPosArray(:,5));
yline(0,'k--');
for i = 1:numel(QStruct(a).trials(j).boutByBout)
    xline(min(QStruct(a).trials(j).boutByBout(i).raw(:,1))/1000,'g');
    xline(max(QStruct(a).trials(j).boutByBout(i).raw(:,1))/1000,'r');
end
ylim([-40,40]);
xlim([-1.5,0.1]);
ylabel('Joystick Velocity (mm/s)');
xlabel('Time relative to choice (s)');



% %% QUARTILES
% 
% % Loop through and get averages by quartile
% deltaQ = [];
% peakDispl = [];
% peakVel = [];
% meanVel = [];
% tortuosity = [];
% numBouts = [];
% dirConsistency = [];
% totalDistanceTravelled = [];
% 
% for i = 1:numel(joyS)
%     % Define quartile boundaries
%     low = find(joyS(i).deltaQ <= prctile(joyS(i).deltaQ, 25));
%     midLow = find(joyS(i).deltaQ > prctile(joyS(i).deltaQ, 25) & joyS(i).deltaQ <= prctile(joyS(i).deltaQ, 50));
%     midHigh = find(joyS(i).deltaQ > prctile(joyS(i).deltaQ, 50) & joyS(i).deltaQ <= prctile(joyS(i).deltaQ, 75));
%     high = find(joyS(i).deltaQ > prctile(joyS(i).deltaQ, 75));
% 
%     % Update the data arrays
%     peakDispl = [peakDispl; mean(joyS(i).peakDispl(low)), mean(joyS(i).peakDispl(midLow)), ...
%                  mean(joyS(i).peakDispl(midHigh)), mean(joyS(i).peakDispl(high))];
%     peakVel = [peakVel; mean(joyS(i).peakVel(low)), mean(joyS(i).peakVel(midLow)), ...
%                mean(joyS(i).peakVel(midHigh)), mean(joyS(i).peakVel(high))];
%     meanVel = [meanVel; mean(joyS(i).meanVel(low)), mean(joyS(i).meanVel(midLow)), ...
%                mean(joyS(i).meanVel(midHigh)), mean(joyS(i).meanVel(high))];
%     tortuosity = [tortuosity; mean(joyS(i).tortuosity(low)), mean(joyS(i).tortuosity(midLow)), ...
%                   mean(joyS(i).tortuosity(midHigh)), mean(joyS(i).tortuosity(high))];
%     numBouts = [numBouts; mean(joyS(i).numBouts(low)), mean(joyS(i).numBouts(midLow)), ...
%                 mean(joyS(i).numBouts(midHigh)), mean(joyS(i).numBouts(high))];
%     dirConsistency = [dirConsistency; mean(joyS(i).dirConsistency(low)), mean(joyS(i).dirConsistency(midLow)), ...
%                       mean(joyS(i).dirConsistency(midHigh)), mean(joyS(i).dirConsistency(high))];
%     totalDistanceTravelled = [totalDistanceTravelled; mean(joyS(i).totalDistanceTravelled(low)), ...
%                               mean(joyS(i).totalDistanceTravelled(midLow)), ...
%                               mean(joyS(i).totalDistanceTravelled(midHigh)), ...
%                               mean(joyS(i).totalDistanceTravelled(high))];
% end
% 
% females = [1,2,23,27,28,21];
% males = [9,12,20,25,26,29,34,37];
% tiledlayout(2,4);
% 
% % For peakDispl
% nexttile;
% hold on;
% bar([1,2,3,4],nanmean(peakDispl,1));
% for i = 1:numel(animalIDs)
%     if ismember(animalIDs(i),males)
%         plot([1,2,3,4],peakDispl(i,:),'bo-');
%     elseif ismember(animalIDs(i),females)
%         plot([1,2,3,4],peakDispl(i,:),'ro-');
%     end
% end
% title('Peak Displacement');
% ylim([3,4.5]);
% ylabel('Peak Displacement (mm)');
% xticks(1:4);
% xlim([0.5,4.5]);
% xticklabels({'Low |ΔQ|','Mid-Low |ΔQ|','Mid-High |ΔQ|','High |ΔQ|'});
% 
% % For peakVel
% nexttile;
% hold on;
% bar([1,2,3,4],nanmean(peakVel,1));
% for i = 1:numel(animalIDs)
%     if ismember(animalIDs(i),males)
%         plot([1,2,3,4],peakVel(i,:),'bo-');
%     elseif ismember(animalIDs(i),females)
%         plot([1,2,3,4],peakVel(i,:),'ro-');
%     end
% end
% title('Peak Velocity');
% ylabel('Peak Joystick Velocity (mm/s)');
% xticks(1:4);
% xlim([0.5,4.5]);
% xticklabels({'Low |ΔQ|','Mid-Low |ΔQ|','Mid-High |ΔQ|','High |ΔQ|'});
% 
% % For meanVel
% nexttile;
% hold on;
% bar([1,2,3,4],nanmean(meanVel,1));
% for i = 1:numel(animalIDs)
%     if ismember(animalIDs(i),males)
%         plot([1,2,3,4],meanVel(i,:),'bo-');
%     elseif ismember(animalIDs(i),females)
%         plot([1,2,3,4],meanVel(i,:),'ro-');
%     end
% end
% title('Mean Velocity');
% ylabel('Mean Joystick Velocity (mm/s)');
% xticks(1:4);
% xlim([0.5,4.5]);
% xticklabels({'Low |ΔQ|','Mid-Low |ΔQ|','Mid-High |ΔQ|','High |ΔQ|'});
% 
% % For tortuosity
% nexttile;
% hold on;
% bar([1,2,3,4],nanmean(tortuosity,1));
% for i = 1:numel(animalIDs)
%     if ismember(animalIDs(i),males)
%         plot([1,2,3,4],tortuosity(i,:),'bo-');
%     elseif ismember(animalIDs(i),females)
%         plot([1,2,3,4],tortuosity(i,:),'ro-');
%     end
% end
% title('Tortuosity');
% ylabel('Tortuosity (Distance/Displacement)');
% xticks(1:4);
% xlim([0.5,4.5]);
% xticklabels({'Low |ΔQ|','Mid-Low |ΔQ|','Mid-High |ΔQ|','High |ΔQ|'});
% 
% % For numBouts
% nexttile;
% hold on;
% bar([1,2,3,4],nanmean(numBouts,1));
% for i = 1:numel(animalIDs)
%     if ismember(animalIDs(i),males)
%         plot([1,2,3,4],numBouts(i,:),'bo-');
%     elseif ismember(animalIDs(i),females)
%         plot([1,2,3,4],numBouts(i,:),'ro-');
%     end
% end
% title('Number of Bouts');
% ylabel('Number of Bouts of Movement');
% xticks(1:4);
% xlim([0.5,4.5]);
% xticklabels({'Low |ΔQ|','Mid-Low |ΔQ|','Mid-High |ΔQ|','High |ΔQ|'});
% 
% % For dirConsistency
% nexttile;
% hold on;
% bar([1,2,3,4],nanmean(dirConsistency,1));
% for i = 1:numel(animalIDs)
%     if ismember(animalIDs(i),males)
%         plot([1,2,3,4],dirConsistency(i,:),'bo-');
%     elseif ismember(animalIDs(i),females)
%         plot([1,2,3,4],dirConsistency(i,:),'ro-');
%     end
% end
% title('Direction Consistency');
% ylabel('Consistency in Direction of Movement Bouts');
% xticks(1:4);
% xlim([0.5,4.5]);
% xticklabels({'Low |ΔQ|','Mid-Low |ΔQ|','Mid-High |ΔQ|','High |ΔQ|'});
% 
% % For totalDistanceTravelled
% nexttile;
% hold on;
% bar([1,2,3,4],nanmean(totalDistanceTravelled./1000,1));
% for i = 1:numel(animalIDs)
%     if ismember(animalIDs(i),males)
%         plot([1,2,3,4],totalDistanceTravelled(i,:)./1000,'bo-');
%     elseif ismember(animalIDs(i),females)
%         plot([1,2,3,4],totalDistanceTravelled(i,:)./1000,'ro-');
%     end
% end
% title('Total Distance Travelled');
% ylabel('Total Distance Travelled (mm)');
% xticks(1:4);
% xlim([0.5,4.5]);
% xticklabels({'Low |ΔQ|','Mid-Low |ΔQ|','Mid-High |ΔQ|','High |ΔQ|'});
% 
% %% HALVES
% % Initialize variables
% deltaQ = [];
% peakDispl = [];
% peakVel = [];
% meanVel = [];
% tortuosity = [];
% numBouts = [];
% dirConsistency = [];
% totalDistanceTravelled = [];
% 
% for i = 1:numel(joyS)
%     % Define halves
%     low = find(joyS(i).deltaQ <= prctile(joyS(i).deltaQ, 50));
%     high = find(joyS(i).deltaQ > prctile(joyS(i).deltaQ, 50));
% 
%     % Update the data arrays
%     peakDispl = [peakDispl; mean(joyS(i).peakDispl(low)), mean(joyS(i).peakDispl(high))];
%     peakVel = [peakVel; mean(joyS(i).peakVel(low)), mean(joyS(i).peakVel(high))];
%     meanVel = [meanVel; mean(joyS(i).meanVel(low)), mean(joyS(i).meanVel(high))];
%     tortuosity = [tortuosity; mean(joyS(i).tortuosity(low)), mean(joyS(i).tortuosity(high))];
%     numBouts = [numBouts; mean(joyS(i).numBouts(low)), mean(joyS(i).numBouts(high))];
%     dirConsistency = [dirConsistency; mean(joyS(i).dirConsistency(low)), mean(joyS(i).dirConsistency(high))];
%     totalDistanceTravelled = [totalDistanceTravelled; mean(joyS(i).totalDistanceTravelled(low)), ...
%                               mean(joyS(i).totalDistanceTravelled(high))];
% end
% 
% 
% females = [1,2,23,27,28,21];
% males = [9,12,20,25,26,29,34,37];
% tiledlayout(2,4);
% 
% % For peakDispl
% nexttile;
% hold on;
% bar([1,2],nanmean(peakDispl,1));
% for i = 1:numel(animalIDs)
%     if ismember(animalIDs(i),males)
%         plot([1,2],peakDispl(i,:),'bo-');
%     elseif ismember(animalIDs(i),females)
%         plot([1,2],peakDispl(i,:),'ro-');
%     end
% end
% title('Peak Displacement');
% ylim([3,4.5]);
% ylabel('Peak Displacement (mm)');
% xticks(1:2);
% xlim([0.5,2.5]);
% xticklabels({'Low |ΔQ|','High |ΔQ|'});
% 
% % For peakVel
% nexttile;
% hold on;
% bar([1,2],nanmean(peakVel,1));
% for i = 1:numel(animalIDs)
%     if ismember(animalIDs(i),males)
%         plot([1,2],peakVel(i,:),'bo-');
%     elseif ismember(animalIDs(i),females)
%         plot([1,2],peakVel(i,:),'ro-');
%     end
% end
% title('Peak Velocity');
% ylabel('Peak Joystick Velocity (mm/s)');
% xticks(1:2);
% xlim([0.5,2.5]);
% xticklabels({'Low |ΔQ|','High |ΔQ|'});
% 
% % For meanVel
% nexttile;
% hold on;
% bar([1,2],nanmean(meanVel,1));
% for i = 1:numel(animalIDs)
%     if ismember(animalIDs(i),males)
%         plot([1,2],meanVel(i,:),'bo-');
%     elseif ismember(animalIDs(i),females)
%         plot([1,2],meanVel(i,:),'ro-');
%     end
% end
% title('Mean Velocity');
% ylabel('Mean Joystick Velocity (mm/s)');
% xticks(1:2);
% xlim([0.5,2.5]);
% xticklabels({'Low |ΔQ|','High |ΔQ|'});
% 
% % For tortuosity
% nexttile;
% hold on;
% bar([1,2],nanmean(tortuosity,1));
% for i = 1:numel(animalIDs)
%     if ismember(animalIDs(i),males)
%         plot([1,2],tortuosity(i,:),'bo-');
%     elseif ismember(animalIDs(i),females)
%         plot([1,2],tortuosity(i,:),'ro-');
%     end
% end
% title('Tortuosity');
% ylabel('Tortuosity (Distance/Displacement)');
% xticks(1:2);
% xlim([0.5,2.5]);
% xticklabels({'Low |ΔQ|','High |ΔQ|'});
% 
% % For numBouts
% nexttile;
% hold on;
% bar([1,2],nanmean(numBouts,1));
% for i = 1:numel(animalIDs)
%     if ismember(animalIDs(i),males)
%         plot([1,2],numBouts(i,:),'bo-');
%     elseif ismember(animalIDs(i),females)
%         plot([1,2],numBouts(i,:),'ro-');
%     end
% end
% title('Number of Bouts');
% ylabel('Number of Bouts of Movement');
% xticks(1:2);
% xlim([0.5,2.5]);
% xticklabels({'Low |ΔQ|','High |ΔQ|'});
% 
% % For dirConsistency
% nexttile;
% hold on;
% bar([1,2],nanmean(dirConsistency,1));
% for i = 1:numel(animalIDs)
%     if ismember(animalIDs(i),males)
%         plot([1,2],dirConsistency(i,:),'bo-');
%     elseif ismember(animalIDs(i),females)
%         plot([1,2],dirConsistency(i,:),'ro-');
%     end
% end
% title('Direction Consistency');
% ylabel('Consistency in Direction of Movement Bouts');
% xticks(1:2);
% xlim([0.5,2.5]);
% xticklabels({'Low |ΔQ|','High |ΔQ|'});
% 
% % For totalDistanceTravelled
% nexttile;
% hold on;
% bar([1,2],nanmean(totalDistanceTravelled./1000,1));
% for i = 1:numel(animalIDs)
%     if ismember(animalIDs(i),males)
%         plot([1,2],totalDistanceTravelled(i,:)./1000,'bo-');
%     elseif ismember(animalIDs(i),females)
%         plot([1,2],totalDistanceTravelled(i,:)./1000,'ro-');
%     end
% end
% title('Total Distance Travelled');
% ylabel('Total Distance Travelled (mm)');
% xticks(1:2);
% xlim([0.5,2.5]);
% xticklabels({'Low |ΔQ|','High |ΔQ|'});


%% Perform ANOVAs (animal-level)

fprintf('Mean Velocity\n');
MaleData = meanVel(ismember(animalIDs,males),:);
FemaleData = meanVel(ismember(animalIDs,females),:);

% Example wide-format data for repeated measures
% One row per animal, three columns for ΔQ conditions
% Males (8 animals) and Females (6 animals)
Combined_low = [MaleData(:,1); FemaleData(:,1)];   % Column vector of means at low ΔQ for each animal
Combined_mid = [MaleData(:,2); FemaleData(:,2)];    % Column vector of means at mid ΔQ for each animal
Combined_high = [MaleData(:,3); FemaleData(:,3)];  % Column vector of means at high ΔQ for each animal
Sex = {'Male','Male','Male','Male','Male','Male','Male','Male','Female','Female','Female','Female','Female','Female'};
Sex = Sex';

t = table(Sex, Combined_low, Combined_mid, Combined_high, ...
          'VariableNames', {'Sex','Low','Mid','High'});

% Define the within-subject factor
within = table({'low |ΔQ|';'mid |ΔQ|';'high |ΔQ|'}, 'VariableNames', {'DeltaQ'});

% Fit repeated measures model
rm = fitrm(t, 'Low-High~Sex', 'WithinDesign', within);

% Run repeated measures ANOVA
tbl = ranova(rm, 'WithinModel','DeltaQ');
disp(tbl);

% Create logical indices for males and females
maleMask = strcmp(t.Sex, 'Male');
femaleMask = strcmp(t.Sex, 'Female');

% Run t-tests for each ΔQ level
[~, p_low] = ttest2(t.Low(maleMask), t.Low(femaleMask));
[~, p_mid] = ttest2(t.Mid(maleMask), t.Mid(femaleMask));
[~, p_high] = ttest2(t.High(maleMask), t.High(femaleMask));

% Display the results
fprintf('Comparing Male vs Female at low |ΔQ|: p = %.4f\n', p_low);
fprintf('Comparing Male vs Female at mid |ΔQ|: p = %.4f\n', p_mid);
fprintf('Comparing Male vs Female at high |ΔQ|: p = %.4f\n', p_high);

fprintf('Tortuosity\n');
MaleData = tortuosity(ismember(animalIDs,males),:);
FemaleData = tortuosity(ismember(animalIDs,females),:);

% Example wide-format data for repeated measures
% One row per animal, three columns for ΔQ conditions
% Males (8 animals) and Females (6 animals)
Combined_low = [MaleData(:,1); FemaleData(:,1)];   % Column vector of means at low ΔQ for each animal
Combined_mid = [MaleData(:,2); FemaleData(:,2)];    % Column vector of means at mid ΔQ for each animal
Combined_high = [MaleData(:,3); FemaleData(:,3)];  % Column vector of means at high ΔQ for each animal
Sex = {'Male','Male','Male','Male','Male','Male','Male','Male','Female','Female','Female','Female','Female','Female'};
Sex = Sex';

t = table(Sex, Combined_low, Combined_mid, Combined_high, ...
          'VariableNames', {'Sex','Low','Mid','High'});

% Define the within-subject factor
within = table({'low |ΔQ|';'mid |ΔQ|';'high |ΔQ|'}, 'VariableNames', {'DeltaQ'});

% Fit repeated measures model
rm = fitrm(t, 'Low-High~Sex', 'WithinDesign', within);

% Run repeated measures ANOVA
tbl = ranova(rm, 'WithinModel','DeltaQ');
disp(tbl);

% Create logical indices for males and females
maleMask = strcmp(t.Sex, 'Male');
femaleMask = strcmp(t.Sex, 'Female');

% Run t-tests for each ΔQ level
[~, p_low] = ttest2(t.Low(maleMask), t.Low(femaleMask));
[~, p_mid] = ttest2(t.Mid(maleMask), t.Mid(femaleMask));
[~, p_high] = ttest2(t.High(maleMask), t.High(femaleMask));

% Display the results
fprintf('Comparing Male vs Female at low |ΔQ|: p = %.4f\n', p_low);
fprintf('Comparing Male vs Female at mid |ΔQ|: p = %.4f\n', p_mid);
fprintf('Comparing Male vs Female at high |ΔQ|: p = %.4f\n', p_high);

fprintf('Peak Displacement\n');
MaleData = peakDispl(ismember(animalIDs,males),:);
FemaleData = peakDispl(ismember(animalIDs,females),:);

% Example wide-format data for repeated measures
% One row per animal, three columns for ΔQ conditions
% Males (8 animals) and Females (6 animals)
Combined_low = [MaleData(:,1); FemaleData(:,1)];   % Column vector of means at low ΔQ for each animal
Combined_mid = [MaleData(:,2); FemaleData(:,2)];    % Column vector of means at mid ΔQ for each animal
Combined_high = [MaleData(:,3); FemaleData(:,3)];  % Column vector of means at high ΔQ for each animal
Sex = {'Male','Male','Male','Male','Male','Male','Male','Male','Female','Female','Female','Female','Female','Female'};
Sex = Sex';

t = table(Sex, Combined_low, Combined_mid, Combined_high, ...
          'VariableNames', {'Sex','Low','Mid','High'});

% Define the within-subject factor
within = table({'low |ΔQ|';'mid |ΔQ|';'high |ΔQ|'}, 'VariableNames', {'DeltaQ'});

% Fit repeated measures model
rm = fitrm(t, 'Low-High~Sex', 'WithinDesign', within);

% Run repeated measures ANOVA
tbl = ranova(rm, 'WithinModel','DeltaQ');
disp(tbl);

% Create logical indices for males and females
maleMask = strcmp(t.Sex, 'Male');
femaleMask = strcmp(t.Sex, 'Female');

% Run t-tests for each ΔQ level
[~, p_low] = ttest2(t.Low(maleMask), t.Low(femaleMask));
[~, p_mid] = ttest2(t.Mid(maleMask), t.Mid(femaleMask));
[~, p_high] = ttest2(t.High(maleMask), t.High(femaleMask));

% Display the results
fprintf('Comparing Male vs Female at low |ΔQ|: p = %.4f\n', p_low);
fprintf('Comparing Male vs Female at mid |ΔQ|: p = %.4f\n', p_mid);
fprintf('Comparing Male vs Female at high |ΔQ|: p = %.4f\n', p_high);

fprintf('Number of Bouts\n');
MaleData = numBouts(ismember(animalIDs,males),:);
FemaleData = numBouts(ismember(animalIDs,females),:);

% Example wide-format data for repeated measures
% One row per animal, three columns for ΔQ conditions
% Males (8 animals) and Females (6 animals)
Combined_low = [MaleData(:,1); FemaleData(:,1)];   % Column vector of means at low ΔQ for each animal
Combined_mid = [MaleData(:,2); FemaleData(:,2)];    % Column vector of means at mid ΔQ for each animal
Combined_high = [MaleData(:,3); FemaleData(:,3)];  % Column vector of means at high ΔQ for each animal
Sex = {'Male','Male','Male','Male','Male','Male','Male','Male','Female','Female','Female','Female','Female','Female'};
Sex = Sex';

t = table(Sex, Combined_low, Combined_mid, Combined_high, ...
          'VariableNames', {'Sex','Low','Mid','High'});

% Define the within-subject factor
within = table({'low |ΔQ|';'mid |ΔQ|';'high |ΔQ|'}, 'VariableNames', {'DeltaQ'});

% Fit repeated measures model
rm = fitrm(t, 'Low-High~Sex', 'WithinDesign', within);

% Run repeated measures ANOVA
tbl = ranova(rm, 'WithinModel','DeltaQ');
disp(tbl);

% Create logical indices for males and females
maleMask = strcmp(t.Sex, 'Male');
femaleMask = strcmp(t.Sex, 'Female');

% Run t-tests for each ΔQ level
[~, p_low] = ttest2(t.Low(maleMask), t.Low(femaleMask));
[~, p_mid] = ttest2(t.Mid(maleMask), t.Mid(femaleMask));
[~, p_high] = ttest2(t.High(maleMask), t.High(femaleMask));

% Display the results
fprintf('Comparing Male vs Female at low |ΔQ|: p = %.4f\n', p_low);
fprintf('Comparing Male vs Female at mid |ΔQ|: p = %.4f\n', p_mid);
fprintf('Comparing Male vs Female at high |ΔQ|: p = %.4f\n', p_high);

fprintf('Directional Consistency\n');
MaleData = dirConsistency(ismember(animalIDs,males),:);
FemaleData = dirConsistency(ismember(animalIDs,females),:);

% Example wide-format data for repeated measures
% One row per animal, three columns for ΔQ conditions
% Males (8 animals) and Females (6 animals)
Combined_low = [MaleData(:,1); FemaleData(:,1)];   % Column vector of means at low ΔQ for each animal
Combined_mid = [MaleData(:,2); FemaleData(:,2)];    % Column vector of means at mid ΔQ for each animal
Combined_high = [MaleData(:,3); FemaleData(:,3)];  % Column vector of means at high ΔQ for each animal
Sex = {'Male','Male','Male','Male','Male','Male','Male','Male','Female','Female','Female','Female','Female','Female'};
Sex = Sex';

t = table(Sex, Combined_low, Combined_mid, Combined_high, ...
          'VariableNames', {'Sex','Low','Mid','High'});

% Define the within-subject factor
within = table({'low |ΔQ|';'mid |ΔQ|';'high |ΔQ|'}, 'VariableNames', {'DeltaQ'});

% Fit repeated measures model
rm = fitrm(t, 'Low-High~Sex', 'WithinDesign', within);

% Run repeated measures ANOVA
tbl = ranova(rm, 'WithinModel','DeltaQ');
disp(tbl);

% Create logical indices for males and females
maleMask = strcmp(t.Sex, 'Male');
femaleMask = strcmp(t.Sex, 'Female');

% Run t-tests for each ΔQ level
[~, p_low] = ttest2(t.Low(maleMask), t.Low(femaleMask));
[~, p_mid] = ttest2(t.Mid(maleMask), t.Mid(femaleMask));
[~, p_high] = ttest2(t.High(maleMask), t.High(femaleMask));

% Display the results
fprintf('Comparing Male vs Female at low |ΔQ|: p = %.4f\n', p_low);
fprintf('Comparing Male vs Female at mid |ΔQ|: p = %.4f\n', p_mid);
fprintf('Comparing Male vs Female at high |ΔQ|: p = %.4f\n', p_high);