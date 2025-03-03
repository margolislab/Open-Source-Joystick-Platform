%getStaySwitch

for i = 1:size(masterStruct,2)
    winStay = 0;
    winSwitch = 0;
    loseStay = 0;
    loseSwitch = 0;
        fprintf('%d\n',i);
        for j = 2:size(masterStruct(i).trialByTrial,2)
            if isscalar(masterStruct(i).trialByTrial(j-1).trialOutcome) && isscalar(masterStruct(i).trialByTrial(j).trialOutcome)
                switch masterStruct(i).trialByTrial(j-1).trialOutcome 
                    case 1 %win
                        if masterStruct(i).trialByTrial(j).pushPull ~= 0 
                            if masterStruct(i).trialByTrial(j).pushPull == masterStruct(i).trialByTrial(j-1).pushPull
                                winStay = winStay + 1;
                            elseif masterStruct(i).trialByTrial(j).pushPull ~= masterStruct(i).trialByTrial(j-1).pushPull
                                winSwitch = winSwitch + 1;
                            end
                        end
                    case 2 %lose
                        if masterStruct(i).trialByTrial(j).pushPull ~= 0 
                            if masterStruct(i).trialByTrial(j).pushPull == masterStruct(i).trialByTrial(j-1).pushPull
                                loseStay = loseStay + 1;
                            elseif masterStruct(i).trialByTrial(j).pushPull ~= masterStruct(i).trialByTrial(j-1).pushPull
                                loseSwitch = loseSwitch + 1;
                            end
                        end
                end
            end
        end
        masterStruct(i).WSt = winStay;
        masterStruct(i).WSw = winSwitch;
        masterStruct(i).LSt = loseStay;
        masterStruct(i).LSw = loseSwitch;
        masterStruct(i).winStayProb = winStay/(winStay+winSwitch);
        masterStruct(i).loseSwitchProb = loseSwitch/(loseStay+loseSwitch);
        masterStruct(i).loseStayProb = loseStay/(loseStay+loseSwitch);
end