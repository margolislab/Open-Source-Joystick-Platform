%WTBehaviorFigures
%import
[masterStruct] = importData('C:\Users\walki\Box\grp-psom-fuccillo-lab\Joystick Behavior\CompletedExperiments\WT2CohortDataForAnalysis');

for i = 1:numel(masterStruct)
    masterStruct(i).animalID = masterStruct(i).animalID + 2000;
end

% [masterStruct2] = importData('C:\Users\walki\Box\grp-psom-fuccillo-lab\Joystick Behavior\CompletedExperiments\DataDumpWT1\Enough7and8\Phase08.2');
% 
% for i = 1:numel(masterStruct2)
%     masterStruct2(i).animalID = masterStruct2(i).animalID + 1000;
% end
% 
% [masterStruct3] = importData('C:\Users\walki\Box\grp-psom-fuccillo-lab\Joystick Behavior\CompletedExperiments\DataDumpWT1\Good567');
% for i = 1:numel(masterStruct3)
%     masterStruct3(i).animalID = masterStruct3(i).animalID + 1000;
% end
% 
% 
% 
% masterStruct = [masterStruct masterStruct2 masterStruct3];

%%
assignSex;
performanceBest;
extractJoystickTrace;
extractBouts;
%%
%get animal IDs
animalIDs = [];
for i = 1:numel(masterStruct)
     animalIDs = [animalIDs; masterStruct(i).animalID];
end
animalIDs = unique(animalIDs);


%% 1. Stay-Switch
getStaySwitch;

%A: Get win/lose-stay probabilities per animal
WSLSS = struct();
WSLSArray = [];
for i = 1:numel(animalIDs)
    WSLSS(i).animalID = animalIDs(i,1); %make entry for animal
    %get the WSLS into the struct
    WS = [];
    LS = [];
    sex = 0;
    for j = 1:numel(masterStruct)
        if masterStruct(j).animalID == animalIDs(i,1)
            if (floor(masterStruct(j).phase) == 5 && masterStruct(j).performance >=.65) || (floor(masterStruct(j).phase) == 6 && masterStruct(j).performance >=.65)
                WS = [WS; masterStruct(j).winStayProb floor(masterStruct(j).phase)];
                LS = [LS; masterStruct(j).loseStayProb floor(masterStruct(j).phase)];
                sex = masterStruct(j).sexDouble;
            end
        end
    end
    WSLSS(i).WSArray = WS;
    WSLSS(i).LSArray = LS;
    WSLSS(i).WS = mean(WS(:,1));
    WSLSS(i).LS = mean(LS(:,1));
    WSLSS(i).WS5 = mean(WS(find(WS(:,2) == 5),1));
    WSLSS(i).WS6 = mean(WS(find(WS(:,2) == 6),1));
    WSLSS(i).LS5 = mean(LS(find(LS(:,2) == 5),1));
    WSLSS(i).LS6 = mean(LS(find(LS(:,2) == 6),1));
    WSLSArray = [WSLSArray; animalIDs(i,1) WSLSS(i).WS WSLSS(i).WS5 WSLSS(i).WS6 WSLSS(i).LS WSLSS(i).LS5 WSLSS(i).LS6 sex];
end


[h, p, ci, stats] = ttest2(WSLSArray(:,3),WSLSArray(:,4));
fprintf('WinStay Phase 5 = %f STD = %f WinStay Phase 6 = %f STD = %f\nN = %d\np = %f\n',mean(WSLSArray(:,3)),std(WSLSArray(:,3),0),mean(WSLSArray(:,4)),std(WSLSArray(:,4)),numel(animalIDs),p);

[h, p, ci, stats] = ttest2(WSLSArray(:,6),WSLSArray(:,7));
fprintf('LoseStay Phase 5 = %f STD = %f LoseStay Phase 6 = %f STD = %f\nN = %d\np = %f\n',mean(WSLSArray(:,6)),std(WSLSArray(:,6),0),mean(WSLSArray(:,7)),std(WSLSArray(:,7)),numel(animalIDs),p);


[h, p, ci, stats] = ttest2((WSLSArray(find(WSLSArray(:,8)==1),2)),(WSLSArray(find(WSLSArray(:,8)==0),2)));
fprintf('WinStay Females = %f STD = %f WinStay Males = %f STD = %f \nNfemales = %d,Nmales = %d\np = %f\n',mean(WSLSArray(find(WSLSArray(:,8)==1),2)),std(WSLSArray(find(WSLSArray(:,8)==1),2),0),mean(WSLSArray(find(WSLSArray(:,8)==0),2)),std(WSLSArray(find(WSLSArray(:,8)==0),2),0),numel(WSLSArray(find(WSLSArray(:,8)==1),2)),numel(WSLSArray(find(WSLSArray(:,8)==0),2)),p);

[h, p, ci, stats] = ttest2((WSLSArray(find(WSLSArray(:,8)==1),5)),(WSLSArray(find(WSLSArray(:,8)==0),5)));
fprintf('LoseStay Females = %f STD = %f LoseStay Males = %f STD = %f \nNfemales = %d,Nmales = %d\np = %f\n',mean(WSLSArray(find(WSLSArray(:,8)==1),5)),std(WSLSArray(find(WSLSArray(:,8)==1),5),0),mean(WSLSArray(find(WSLSArray(:,8)==0),5)),std(WSLSArray(find(WSLSArray(:,8)==0),5),0),numel(WSLSArray(find(WSLSArray(:,8)==1),5)),numel(WSLSArray(find(WSLSArray(:,8)==0),5)),p);

%% 2. Logistic Regression
betas = [];
SEs = [];
for i = 1:numel(animalIDs)
    [predictor,outcome] = getLogisticData(masterStruct,6,.7,animalIDs(i,1));
    mdl = fitglm(predictor, outcome, 'Distribution', 'binomial', 'Link', 'logit');
    betas = [betas; mdl.Coefficients.Estimate(2:11)'];
    SEs = [SEs; mdl.Coefficients.SE(2:11)'];
end
n1 = numel(animalIDs);
weights = 1./(SEs.^2);
wBetaMean = sum(betas.*weights)./sum(weights);
SEwBetaMean = sqrt(1 ./ sum(weights));
wBeta1 = wBetaMean;
SE1 = SEwBetaMean;
clf
hold on
errorbar([1:1:5],wBetaMean(1,1:5),SEwBetaMean(1,1:5),'b','LineWidth',1.5);
errorbar([1:1:5],wBetaMean(1,6:10),SEwBetaMean(1,6:10),'b--','LineWidth',1.5);


betas = [];
SEs = [];
for i = 1:numel(animalIDs)
    [predictor,outcome] = getLogisticData(masterStruct,5,.75,animalIDs(i,1));
    mdl = fitglm(predictor, outcome, 'Distribution', 'binomial', 'Link', 'logit');
    betas = [betas; mdl.Coefficients.Estimate(2:11)'];
    SEs = [SEs; mdl.Coefficients.SE(2:11)'];
end
n2 = numel(animalIDs);
weights = 1./(SEs.^2);
wBetaMean = sum(betas.*weights)./sum(weights);
SEwBetaMean = sqrt(1 ./ sum(weights));
wBeta2 = wBetaMean;
SE2 = SEwBetaMean;

errorbar([1:1:5],wBetaMean(1,1:5),SEwBetaMean(1,1:5),'r','LineWidth',1.5);
errorbar([1:1:5],wBetaMean(1,6:10),SEwBetaMean(1,6:10),'r--','LineWidth',1.5);
xlabel('Trials prior');
ylabel('Regression weight');
xlim([0.5,5.5]);
xticks(1:1:5);
yticks()
yline(0,'k--');

text('Units', 'normalized', 'Position', [0.8, 0.9], 'String', 'Deterministic', 'Color', 'r','HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
text('Units', 'normalized', 'Position', [0.8, 0.8], 'String', 'Probabilistic', 'Color', 'b','HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');

t_stats = zeros(1, 10);
p_values = zeros(1, 10);
dfs = zeros(1, 10);
for i = 1:10
    % Calculate the t-statistic
    t_stats(i) = (wBeta1(i) - wBeta2(i)) / sqrt(SE1(i)^2 + SE2(i)^2);
    
    % Calculate degrees of freedom using the Welch-Satterthwaite equation
    dfs(i) = ((SE1(i)^2 + SE2(i)^2)^2) / ((SE1(i)^4 / (n1 - 1)) + (SE2(i)^4 / (n2 - 1)));
    
    % Calculate the two-tailed p-value using the t-distribution
    p_values(i) = 2 * tcdf(-abs(t_stats(i)), dfs(i));
end

% Display the results
disp('T-statistics:');
disp(t_stats);
disp('Degrees of freedom:');
disp(dfs);
disp('P-values:');
disp(p_values);

%%
figure;
betas = [];
SEs = [];
for i = 1:numel(females)
    [predictor,outcome] = getLogisticData(masterStruct,[6],.65,females(1,i));
    mdl = fitglm(predictor, outcome, 'Distribution', 'binomial', 'Link', 'logit');
    betas = [betas; mdl.Coefficients.Estimate(2:11)'];
    SEs = [SEs; mdl.Coefficients.SE(2:11)'];
end

n1 = numel(females);
weights = 1./(SEs.^2);
wBetaMean = sum(betas.*weights)./sum(weights);
SEwBetaMean = sqrt(1 ./ sum(weights));
wBeta1 = wBetaMean;
SE1 = SEwBetaMean;
errorbar([1:1:5],wBetaMean(1,1:5),SEwBetaMean(1,1:5),'o-','LineWidth',1,'Color',[0.988, 0.235, 1],"MarkerFaceColor",[1 1 1],'MarkerSize', 4);
hold on
errorbar([1:1:5],wBetaMean(1,6:10),SEwBetaMean(1,6:10),'o--','LineWidth',1,'Color',[0.988, 0.235, 1],"MarkerFaceColor",[1 1 1],'MarkerSize', 4);
betas = [];
SEs = [];
for i = 1:numel(males)
    [predictor,outcome] = getLogisticData(masterStruct,[6],.65,males(1,i));
    mdl = fitglm(predictor, outcome, 'Distribution', 'binomial', 'Link', 'logit');
    betas = [betas; mdl.Coefficients.Estimate(2:11)'];
    SEs = [SEs; mdl.Coefficients.SE(2:11)'];
end
n2 = numel(males);
weights = 1./(SEs.^2);
wBetaMean = sum(betas.*weights)./sum(weights);
SEwBetaMean = sqrt(1 ./ sum(weights));
wBeta2 = wBetaMean;
SE2 = SEwBetaMean;
hold on
errorbar([1:1:5],wBetaMean(1,1:5),SEwBetaMean(1,1:5),'o-','LineWidth',1,'Color',[0.02, 0.329, 0.988],"MarkerFaceColor",[1 1 1],'MarkerSize', 4);
errorbar([1:1:5],wBetaMean(1,6:10),SEwBetaMean(1,6:10),'o--','LineWidth',1,'Color',[0.02, 0.329, 0.988],"MarkerFaceColor",[1 1 1],'MarkerSize', 4);
xlabel('Trials prior');
ylabel('Regression weight');
yline(0,'k--');
xlim([0.5,5.5]);
xticks(1:1:5);
text('Units', 'normalized', 'Position', [0.8, 0.9], 'String', 'Females (N = 6)', 'Color',[0.988, 0.235, 1],'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
text('Units', 'normalized', 'Position', [0.8, 0.8], 'String', 'Males (N = 8)', 'Color',[0.02, 0.329, 0.988],'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');


%%
t_stats = zeros(1, 10);
p_values = zeros(1, 10);
dfs = zeros(1, 10);
for i = 1:10
    % Calculate the t-statistic
    t_stats(i) = (wBeta1(i) - wBeta2(i)) / sqrt(SE1(i)^2 + SE2(i)^2);
    
    % Calculate degrees of freedom using the Welch-Satterthwaite equation
    dfs(i) = ((SE1(i)^2 + SE2(i)^2)^2) / ((SE1(i)^4 / (n1 - 1)) + (SE2(i)^4 / (n2 - 1)));
    
    % Calculate the two-tailed p-value using the t-distribution
    p_values(i) = 2 * tcdf(-abs(t_stats(i)), dfs(i));
end

% Display the results
disp('T-statistics:');
disp(t_stats);
disp('Degrees of freedom:');
disp(dfs);
disp('P-values:');
disp(p_values);

%% 3. Updating
%get your probabilities first (1 is pull -> push, 2 is push -> pull)
pushProbCombF = arrayfun(@(x) [], (1:21)', 'UniformOutput', false);
pushProbCombM = arrayfun(@(x) [], (1:21)', 'UniformOutput', false);
for i = 1:numel(females)
    [pushProbF] = getProbsMF(masterStruct,1,6,.65,females(1,i));
    [pullProbF] = getProbsMF(masterStruct,2,6,.65,females(1,i));
    pushProbComb =  cellfun(@(x, y) [x, ~y], pushProbF, pullProbF, 'UniformOutput', false);
    pushProbCombF = cellfun(@(x, y) [x, y], pushProbCombF, pushProbComb, 'UniformOutput', false);
end
for i = 1:numel(males)
    [pushProbM] = getProbsMF(masterStruct,1,6,.65,males(1,i));
    [pullProbM] = getProbsMF(masterStruct,2,6,.65,males(1,i));
    pushProbComb =  cellfun(@(x, y) [x, ~y], pushProbM, pullProbM, 'UniformOutput', false);
    pushProbCombM = cellfun(@(x, y) [x, y], pushProbCombM, pushProbComb, 'UniformOutput', false);
end

figure;
e = errorbar([-10:1:10],cellfun(@mean, pushProbCombF),cellfun(@std,pushProbCombF)./sqrt(cellfun(@numel,pushProbCombF)),'o-','LineWidth',1,'Color',[0.988, 0.235, 1],"MarkerFaceColor",[1 1 1],'MarkerSize', 4);
hold on
f = errorbar([-10:1:10],cellfun(@mean, pushProbCombM),cellfun(@std,pushProbCombM)./sqrt(cellfun(@numel,pushProbCombM)),'o-','LineWidth',1,'Color',[0.02, 0.329, 0.988],"MarkerFaceColor",[1 1 1],'MarkerSize', 4);
ylabel('P(high probability choice)');
xlabel('Trials from block switch');
xline(0,'k:');


%% 4. Vigor
PDCLZscore;
vigorS = struct();
PDMeans = [];
CLMeans = [];
PDNormMeans = [];
CLNormMeans = [];
for i = 1:numel(animalIDs)
    vigorS(i).animal = animalIDs(i,1);
    PD = [];
    CL = [];
    PDNorm = [];
    CLNorm = [];
    for j = 1:numel(masterStruct)
        if masterStruct(j).animalID == animalIDs(i,1) & floor(masterStruct(j).phase) == 8
            for k = 1:numel(masterStruct(j).trialByTrial)
                if ismember(masterStruct(j).trialByTrial(k).trialOutcome,[1,2])
                    if ~ismember(masterStruct(j).trialByTrial(k).blockType,[19,20]) & ~isempty(masterStruct(j).trialByTrial(k).peakDispl) & ~isempty(masterStruct(j).trialByTrial(k).choiceLatency)
                        if masterStruct(j).trialByTrial(k).choiceLatency <= 25000 & masterStruct(j).trialByTrial(k).choiceLatency > 0
                            switch masterStruct(j).trialByTrial(k).raw.onDuration(1)
                                case 80
                                    rewVol = 8;
                                case 50
                                    rewVol = 4;
                                case 35
                                    rewVol = 2;
                            end
                            PD = [PD; abs(masterStruct(j).trialByTrial(k).peakDispl) rewVol];
                            CL = [CL; masterStruct(j).trialByTrial(k).choiceLatency rewVol];
                            PDNorm = [PDNorm; masterStruct(j).trialByTrial(k).peakDisplZ rewVol];
                            CLNorm = [CLNorm; masterStruct(j).trialByTrial(k).choiceLatencyZ rewVol];
                        end
                    end
                end
            end
        end
    end
    vigorS(i).PD = PD;
    vigorS(i).CL = CL;
    vigorS(i).PDNorm = PDNorm;
    vigorS(i).CLNorm = CLNorm;
    vigorS(i).PDMeans = [mean(PD(PD(:,2)==2,1)) mean(PD(PD(:,2)==4,1)) mean(PD(PD(:,2)==8,1))];
    vigorS(i).CLMeans = [mean(CL(CL(:,2)==2,1)) mean(CL(CL(:,2)==4,1)) mean(CL(CL(:,2)==8,1))];
    vigorS(i).PDNormMeans = [mean(PDNorm(PDNorm(:,2)==2,1)) mean(PDNorm(PDNorm(:,2)==4,1)) mean(PDNorm(PDNorm(:,2)==8,1))];
    vigorS(i).CLNormMeans = [mean(CLNorm(CLNorm(:,2)==2,1)) mean(CLNorm(CLNorm(:,2)==4,1)) mean(CLNorm(CLNorm(:,2)==8,1))];
    PDMeans = [PDMeans; vigorS(i).PDMeans animalIDs(i,1)];
    CLMeans = [CLMeans; vigorS(i).CLMeans animalIDs(i,1)];
    PDNormMeans = [PDNormMeans; vigorS(i).PDNormMeans animalIDs(i,1)];
    CLNormMeans = [CLNormMeans; vigorS(i).CLNormMeans animalIDs(i,1)];
end

%%

figure;
errorbar([2,4,8],mean(CLMeans(:,1:3)./1000),std(CLMeans(:,1:3)./1000,0)./sqrt(numel(animalIDs)),'k','LineWidth',1.5);
xlabel('Reward Volume (uL)')
ylabel('Choice Latency (s)')
ylim([0,2.5]);
title('Choice Latency by Reward Volume')


figure;
errorbar([2,4,8],mean(PDMeans(:,1:3)./1000),std(PDMeans(:,1:3)./1000,0)./sqrt(numel(animalIDs)),'k','LineWidth',1.5);
xlabel('Reward Volume (uL)')
ylabel('Peak Joystick Displacement (mm)')
title('Peak Joystick Displacement by Reward Volume')
ylim([3,4]);

%%
figure;
hold on
scatter(1,CLMeans(ismember(animalIDs,females),1)./1000,'ro','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.988, 0.235, 1]);
scatter(2,CLMeans(ismember(animalIDs,females),2)./1000,'ro','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.988, 0.235, 1]);
scatter(3,CLMeans(ismember(animalIDs,females),3)./1000,'ro','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.988, 0.235, 1]);
scatter(1,CLMeans(ismember(animalIDs,males),1)./1000,'bo','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.02, 0.329, 0.988]);
scatter(2,CLMeans(ismember(animalIDs,males),2)./1000,'bo','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.02, 0.329, 0.988]);
scatter(3,CLMeans(ismember(animalIDs,males),3)./1000,'bo','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.02, 0.329, 0.988]);
errorbar([1,2,3],mean(CLMeans(ismember(animalIDs,females),1:3)./1000),std(CLMeans(ismember(animalIDs,females),1:3)./1000,0)./sqrt(numel(females)),'o-','LineWidth',1,'Color',[0.988, 0.235, 1],"MarkerFaceColor",[1 1 1],'MarkerSize', 4);
errorbar([1,2,3],mean(CLMeans(ismember(animalIDs,males),1:3)./1000),std(CLMeans(ismember(animalIDs,males),1:3)./1000,0)./sqrt(numel(males)),'o-','LineWidth',1,'Color',[0.02, 0.329, 0.988],"MarkerFaceColor",[1 1 1],'MarkerSize', 4);
%title('Choice Latency by Reward Volume')
xlabel('Reward Volume (uL)')
ylabel('Choice Latency (s)')
ylim([0,5.5]);
yticks([1:1:5]);
xticks([1:1:3]);
xlim([.5,3.5]);
xticklabels({'2','4','8'});
text('Units', 'normalized', 'Position', [0.8, 0.9], 'String', 'Females (N = 6)', 'Color',[0.988, 0.235, 1],'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
text('Units', 'normalized', 'Position', [0.8, 0.8], 'String', 'Males (N = 8)', 'Color',[0.02, 0.329, 0.988],'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
ax = gca; % Get current axes handle
ax.XLabel.Color = 'k';  % Set X-axis label color to black
ax.YLabel.Color = 'k';  % Set Y-axis label color to black
ax.Title.Color = 'k';   % Set title color to black

% Optionally: Set tick labels to black
ax.XColor = 'k';        % Set X-axis ticks to black
ax.YColor = 'k';        % Set Y-axis ticks to black


figure;
hold on
scatter(1,PDMeans(ismember(animalIDs,females),1)./1000,'o','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.988, 0.235, 1]);
scatter(2,PDMeans(ismember(animalIDs,females),2)./1000,'o','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.988, 0.235, 1]);
scatter(3,PDMeans(ismember(animalIDs,females),3)./1000,'o','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.988, 0.235, 1]);
scatter(1,PDMeans(ismember(animalIDs,males),1)./1000,'o','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.02, 0.329, 0.988]);
scatter(2,PDMeans(ismember(animalIDs,males),2)./1000,'o','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.02, 0.329, 0.988]);
scatter(3,PDMeans(ismember(animalIDs,males),3)./1000,'o','MarkerEdgeAlpha', 0.5,'SizeData', 10,'MarkerEdgeColor',[0.02, 0.329, 0.988]);
errorbar([1,2,3],mean(PDMeans(ismember(animalIDs,females),1:3)./1000),std(PDMeans(ismember(animalIDs,females),1:3)./1000,0)./sqrt(numel(females)),'o-','LineWidth',1,'Color',[0.988, 0.235, 1],"MarkerFaceColor",[1 1 1],'MarkerSize', 4);
errorbar([1,2,3],mean(PDMeans(ismember(animalIDs,males),1:3)./1000),std(PDMeans(ismember(animalIDs,males),1:3)./1000,0)./sqrt(numel(males)),'o-','LineWidth',1,'Color',[0.02, 0.329, 0.988],"MarkerFaceColor",[1 1 1],'MarkerSize', 4);
%title('Peak Joystick Displacement by Reward Volume')
xlabel('Reward Volume (uL)')
ylabel('Peak Joystick Displacement (mm)')
ylim([3,4.2]);
xlim([.5,3.5]);
xticks([1:1:3]);
yticks([3:.2:4.2]);
xticklabels({'2','4','8'});
text('Units', 'normalized', 'Position', [0.8, 0.9], 'String', 'Females (N = 6)', 'Color',[0.988, 0.235, 1],'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
text('Units', 'normalized', 'Position', [0.8, 0.8], 'String', 'Males (N = 8)', 'Color',[0.02, 0.329, 0.988],'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
ax = gca; % Get current axes handle
ax.XLabel.Color = 'k';  % Set X-axis label color to black
ax.YLabel.Color = 'k';  % Set Y-axis label color to black
ax.Title.Color = 'k';   % Set title color to black

% Optionally: Set tick labels to black
ax.XColor = 'k';        % Set X-axis ticks to black
ax.YColor = 'k';        % Set Y-axis ticks to black


% %% NORMALIZED 
% figure;
% errorbar([2,4,8],mean(CLNormMeans(ismember(animalIDs,females),1:3)./1000),std(CLNormMeans(ismember(animalIDs,females),1:3)./1000,0)./sqrt(numel(females)),'r','LineWidth',1.5);
% hold on
% scatter(2,CLNormMeans(ismember(animalIDs,females),1)./1000,'r');
% scatter(4,CLNormMeans(ismember(animalIDs,females),2)./1000,'r');
% scatter(8,CLNormMeans(ismember(animalIDs,females),3)./1000,'r');
% errorbar([2,4,8],mean(CLNormMeans(ismember(animalIDs,males),1:3)./1000),std(CLNormMeans(ismember(animalIDs,males),1:3)./1000,0)./sqrt(numel(males)),'b','LineWidth',1.5);
% scatter(2,CLNormMeans(ismember(animalIDs,males),1)./1000,'b');
% scatter(4,CLNormMeans(ismember(animalIDs,males),2)./1000,'b');
% scatter(8,CLNormMeans(ismember(animalIDs,males),3)./1000,'b');
% title('Z-scored Choice Latency by Reward Volume')
% xlabel('Reward Volume (uL)')
% ylabel('Z-scored Choice Latency')
% %ylim([0,5.5]);
% text('Units', 'normalized', 'Position', [0.8, 0.9], 'String', 'Females (N = 6)', 'Color', 'r','HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
% text('Units', 'normalized', 'Position', [0.8, 0.8], 'String', 'Males (N = 8)', 'Color', 'b','HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
% 
% 
% 
% 
% figure;
% errorbar([2,4,8],mean(PDNormMeans(ismember(animalIDs,females),1:3)./1000),std(PDNormMeans(ismember(animalIDs,females),1:3)./1000,0)./sqrt(numel(females)),'r','LineWidth',1.5);
% hold on
% scatter(2,PDNormMeans(ismember(animalIDs,females),1)./1000,'r');
% scatter(4,PDNormMeans(ismember(animalIDs,females),2)./1000,'r');
% scatter(8,PDNormMeans(ismember(animalIDs,females),3)./1000,'r');
% errorbar([2,4,8],mean(PDNormMeans(ismember(animalIDs,males),1:3)./1000),std(PDNormMeans(ismember(animalIDs,males),1:3)./1000,0)./sqrt(numel(males)),'b','LineWidth',1.5);
% scatter(2,PDNormMeans(ismember(animalIDs,males),1)./1000,'b');
% scatter(4,PDNormMeans(ismember(animalIDs,males),2)./1000,'b');
% scatter(8,PDNormMeans(ismember(animalIDs,males),3)./1000,'b');
% title('Z-scored Peak Joystick Displacement by Reward Volume')
% xlabel('Reward Volume (uL)')
% ylabel('Z-scored Peak Joystick Displacement')
% %ylim([3,4]);
% text('Units', 'normalized', 'Position', [0.8, 0.9], 'String', 'Females (N = 6)', 'Color', 'r','HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
% text('Units', 'normalized', 'Position', [0.8, 0.8], 'String', 'Males (N = 8)', 'Color', 'b','HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');

%% Two-way ANOVA for vigor stuff (by animal)


fprintf('Choice Latency\n');
MaleData = CLMeans(ismember(animalIDs,males),:);
FemaleData = CLMeans(ismember(animalIDs,females),:);

% Example wide-format data for repeated measures
% One row per animal, three columns for ΔQ conditions
% Males (8 animals) and Females (6 animals)
Combined_low = [MaleData(:,1); FemaleData(:,1)];   % Column vector of means at 2uL for each animal
Combined_mid = [MaleData(:,2); FemaleData(:,2)];    % Column vector of means at 4uL for each animal
Combined_high = [MaleData(:,3); FemaleData(:,3)];  % Column vector of means at 8uL for each animal
Sex = {'Male','Male','Male','Male','Male','Male','Male','Male','Female','Female','Female','Female','Female','Female'};
Sex = Sex';

t = table(Sex, Combined_low, Combined_mid, Combined_high, ...
          'VariableNames', {'Sex','V2uL','V4uL','V8uL'});

% Define the within-subject factor
within = table({'V2uL';'V4uL';'V8uL'}, 'VariableNames', {'RewVol'});

% Fit repeated measures model
rm = fitrm(t, 'V2uL-V8uL~Sex', 'WithinDesign', within);

% Run repeated measures ANOVA
tbl = ranova(rm, 'WithinModel','RewVol');
disp(tbl);

% Create logical indices for males and females
maleMask = strcmp(t.Sex, 'Male');
femaleMask = strcmp(t.Sex, 'Female');

% Run t-tests for each ΔQ level
[~, p_low] = ttest2(t.V2uL(maleMask), t.V2uL(femaleMask));
[~, p_mid] = ttest2(t.V4uL(maleMask), t.V4uL(femaleMask));
[~, p_high] = ttest2(t.V8uL(maleMask), t.V8uL(femaleMask));

% Display the results
fprintf('Comparing Male vs Female at 2uL: p = %.4f\n', p_low);
fprintf('Comparing Male vs Female at 4uL: p = %.4f\n', p_mid);
fprintf('Comparing Male vs Female at 8uL: p = %.4f\n', p_high);

fprintf('Peak Displacement\n');
MaleData = PDMeans(ismember(animalIDs,males),:);
FemaleData = PDMeans(ismember(animalIDs,females),:);

% Example wide-format data for repeated measures
% One row per animal, three columns for ΔQ conditions
% Males (8 animals) and Females (6 animals)
Combined_low = [MaleData(:,1); FemaleData(:,1)];   % Column vector of means at 2uL for each animal
Combined_mid = [MaleData(:,2); FemaleData(:,2)];    % Column vector of means at 4uL for each animal
Combined_high = [MaleData(:,3); FemaleData(:,3)];  % Column vector of means at 8uL for each animal
Sex = {'Male','Male','Male','Male','Male','Male','Male','Male','Female','Female','Female','Female','Female','Female'};
Sex = Sex';

t = table(Sex, Combined_low, Combined_mid, Combined_high, ...
          'VariableNames', {'Sex','V2uL','V4uL','V8uL'});

% Define the within-subject factor
within = table({'V2uL';'V4uL';'V8uL'}, 'VariableNames', {'RewVol'});

% Fit repeated measures model
rm = fitrm(t, 'V2uL-V8uL~Sex', 'WithinDesign', within);

% Run repeated measures ANOVA
tbl = ranova(rm, 'WithinModel','RewVol');
disp(tbl);

% Create logical indices for males and females
maleMask = strcmp(t.Sex, 'Male');
femaleMask = strcmp(t.Sex, 'Female');

% Run t-tests for each ΔQ level
[~, p_low] = ttest2(t.V2uL(maleMask), t.V2uL(femaleMask));
[~, p_mid] = ttest2(t.V4uL(maleMask), t.V4uL(femaleMask));
[~, p_high] = ttest2(t.V8uL(maleMask), t.V8uL(femaleMask));

% Display the results
fprintf('Comparing Male vs Female at 2uL: p = %.4f\n', p_low);
fprintf('Comparing Male vs Female at 4uL: p = %.4f\n', p_mid);
fprintf('Comparing Male vs Female at 8uL: p = %.4f\n', p_high);