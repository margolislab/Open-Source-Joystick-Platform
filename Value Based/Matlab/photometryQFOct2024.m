%% Photometry QF

function [animalStruct] = photometryQFOct2024(a,animalStruct)

choices = [];
rewards = [];
flags = [];

for j = 1:numel(animalStruct(a).trials)
    if ismember(animalStruct(a).trials(j).trialOutcome,1:1:3)
        choices = [choices; animalStruct(a).trials(j).pushPull];
        flags = [flags; animalStruct(a).trials(j).firstFlag];
        switch animalStruct(a).trials(j).trialOutcome
            case 1
                switch floor(animalStruct(a).phase)
                    case 6
                        vol = 8;
                    case 8
                        switch animalStruct(a).trials(j).raw.onDuration(1)
                            case 35
                                vol = 2;
                            case 50
                                vol = 4;
                            case 80
                                vol = 8;
                        end
                end

                switch animalStruct(a).trials(j).pushPull
                    case 1
                        rewards = [rewards; vol 0];
                    case 2
                        rewards = [rewards; 0 vol];
                end
            otherwise
                rewards = [rewards; 0 0];
        end
    end
end
%%

% Initiate parameters for fitting
Aeq=[];
beq=[];
Aineq=[];
bineq=[];
lb = [0 .1];    % lower limits for alpha, beta
ub = [1 10];  % upper limits for alpha, beta
inx = [rand(1) (rand(1)*9.9 + .1)]; % starting points to fit from (shouldn't matter)

options = optimset('Display','on','MaxIter',5000000,'TolFun',1e-15,'TolX',1e-15,...
    'DiffMaxChange',1e-2,'DiffMinChange',1e-6,'MaxFunEvals',5000000,...
    'LargeScale','off');
% Define algorithm and options for fitting
% Inputs(1:4) are alpha, beta, decay rate, and inverse alpha
tester = @(inputs)compareModelFit_Photo(inputs(1), inputs(2), choices, rewards, flags);
problem = createOptimProblem('fmincon','objective',tester,'x0', inx,...
    'lb',lb,'ub',ub,'Aeq',Aeq,'beq',beq,'Aineq',Aineq,'bineq',bineq,'options',options);
ms = MultiStart;
k = 20;

warning off;
% Fit parameters according to the model and behavioral data
[inputs, loglike, exitflag, output, solutions] = run(ms,problem,k);
%% Create output for results

[choiceProbabilities, Qvalues,RPEs]=Photo_QF_Softmax_VB(inputs(1),inputs(2),choices,rewards,flags);


QSums=zeros(size(choices,1),1);
QDiffs=zeros(size(choices,1),1);
for i=1:size(Qvalues,1)
    QSums(i)=Qvalues(i,1)+Qvalues(i,2);
    QDiffs(i)=Qvalues(i,1)-Qvalues(i,2);
end

animalStruct(a).alpha = inputs(1);
animalStruct(a).beta = inputs(2);
animalStruct(a).choiceProbabilities = choiceProbabilities;
animalStruct(a).RPEs = RPEs;
animalStruct(a).Qvalues = Qvalues;
animalStruct(a).QSums = QSums;
animalStruct(a).QDifferences = QDiffs;
animalStruct(a).likelihood = loglike;
animalStruct(a).choices = choices;
animalStruct(a).rewards = rewards;


