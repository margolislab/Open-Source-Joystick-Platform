%extract performance
for i = 1:size(masterStruct,2)
    highProb = 0;
    lowProb = 0;
    if masterStruct(i).phase >= 5
        for j = 1:size(masterStruct(i).trialByTrial,2)
            if masterStruct(i).trialByTrial(j).trialOutcome > 0 & masterStruct(i).trialByTrial(j).trialOutcome <=2
                if masterStruct(i).trialByTrial(j).rewardDirection == masterStruct(i).trialByTrial(j).pushPull
                    highProb = highProb + 1;
                end
                if masterStruct(i).trialByTrial(j).rewardDirection ~= masterStruct(i).trialByTrial(j).pushPull
                    lowProb = lowProb + 1;
                end
            end
        end
    end
    if highProb > 0
        masterStruct(i).highProb = highProb;
        masterStruct(i).lowProb = lowProb;
        masterStruct(i).performance = highProb/(highProb + lowProb);
    end
end