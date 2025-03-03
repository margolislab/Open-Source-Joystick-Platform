%get logistic data

function [predictorMatrix,outcomeMatrix] = getLogisticData(masterStruct,phase,performance,animal)

%First, we will get inputs for the function log(C(i)/(1-C(i)) = beta0 +
%sum(from j = 1 out to n = 5) of betajR * R(i-j) + sum(from j = 1 out to n
%=5 of bretajU * U(i-j) + error.

%The R(i-j) and U(i-j) terms encompass previous choices and outcomes. R is
%+1 when animals is rewarded with push, and -1 when animal is rewarded with
%pull; 0 otherwise. U is the same but for UNREWARDED. Let's try 0ing
%everything out for omissions and premature trials for now.

%For choices, 1 is push and 0 is pull.
performanceBest;
predictorMatrix = [];
outcomeMatrix = [];
for i = 1:size(masterStruct,2)
    %fprintf('%d\n',i);
    Rval = [];
    Uval = [];
    if ismember(floor(masterStruct(i).phase), phase) && masterStruct(i).performance >= performance && masterStruct(i).animalID == animal
        for j = 1:size(masterStruct(i).trialByTrial,2)
            if isscalar(masterStruct(i).trialByTrial(j).trialOutcome)
                switch masterStruct(i).trialByTrial(j).trialOutcome
                    case 1
                        switch masterStruct(i).trialByTrial(j).pushPull
                            case 1
                                Rval = [Rval; 1];
                                Uval = [Uval; 0];
                            case 2
                                Rval = [Rval; -1];
                                Uval = [Uval; 0];
                            otherwise
                                Rval = [Rval; 0];
                                Uval = [Uval; 0];
                        end
                    case 2
                        switch masterStruct(i).trialByTrial(j).pushPull
                            case 1
                                Rval = [Rval; 0];
                                Uval = [Uval; 1];
                            case 2
                                Rval = [Rval; 0];
                                Uval = [Uval; -1];
                            otherwise
                                Rval = [Rval; 0];
                                Uval = [Uval; 0];
                        end
                    otherwise
                        Rval = [Rval; 0];
                        Uval = [Uval; 0];
                end
            end
        end
    
        for j = 1:size(masterStruct(i).trialByTrial,2) 
            if j>=6 && ~isempty(masterStruct(i).trialByTrial(j).pushPull)
                if isscalar(masterStruct(i).trialByTrial(j).pushPull)
                    predictorMatrix = [predictorMatrix; Rval(j-1,1) Rval(j-2,1) Rval(j-3,1) Rval(j-4,1) Rval(j-5,1) Uval(j-1,1) Uval(j-2,1) Uval(j-3,1) Uval(j-4,1) Uval(j-5,1)];
                    switch masterStruct(i).trialByTrial(j).pushPull
                        case 1
                            outcomeMatrix = [outcomeMatrix; 1];
                        case 2 
                            outcomeMatrix = [outcomeMatrix; 0];
                        otherwise
                            outcomeMatrix = [outcomeMatrix; 0.5];
                    end
                end
            end
        end
    end
end

