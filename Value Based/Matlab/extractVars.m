%Extract trial-relevant variables
function [masterStruct] = extractVars(masterStruct)
%can call both input and output masterStruct 
%run sortByTrial(masterStruct) first!

%trial-by-trial outcomes
for i = 1:size(masterStruct,2)
    if masterStruct(i).phase >=1
        masterStruct(i).numRewards = 0;
        masterStruct(i).numOmissions = 0;
        masterStruct(i).numUnrewardeds = 0;
        masterStruct(i).numPrematures = 0;
        masterStruct(i).numPrematuresRewarded = 0;
        masterStruct(i).numPrematuresUnrewarded = 0;
        masterStruct(i).numTrials = 0;
        hasFlags = strcmp('flags',masterStruct(i).raw.Properties.VariableNames); 
        hasFlags = sum(hasFlags);
    
        if ~isempty(masterStruct(i).trialByTrial) & hasFlags >=1
             %delete first and last trial
    %          try
    %             masterStruct(i).trialByTrial(size(masterStruct(i).trialByTrial,2)) = [];
    %          catch
    %              warning('Could not delete last trial.')
    %          end
    %          try
    %             masterStruct(i).trialByTrial(1) = [];
    %          catch
    %              warning('Could not delete first trial.')
    %          end
            for j = 1:size(masterStruct(i).trialByTrial,2)
    
                %trial duration
                masterStruct(i).trialByTrial(j).trialDuration = max(masterStruct(i).trialByTrial(j).raw.runTime)-min(masterStruct(i).trialByTrial(j).raw.runTime);
               
                %ITI duration
                if ~isempty(find((masterStruct(i).trialByTrial(j).raw.flags == 5)))
                    masterStruct(i).trialByTrial(j).ITIDuration = max(masterStruct(i).trialByTrial(j).raw.runTime)-masterStruct(i).trialByTrial(j).raw.runTime(find((masterStruct(i).trialByTrial(j).raw.flags == 5)));
                else 
                    masterStruct(i).trialByTrial(j).ITIDuration = NaN;
                end
                
                %wait duration
                if masterStruct(i).phase >=4
                    if ~isempty(find((masterStruct(i).trialByTrial(j).raw.flags == 2)))
                        masterStruct(i).trialByTrial(j).waitDuration = masterStruct(i).trialByTrial(j).raw.runTime(find((masterStruct(i).trialByTrial(j).raw.flags == 2)))-min(masterStruct(i).trialByTrial(j).raw.runTime);
                    else
                        if ~isempty(masterStruct(i).trialByTrial(j).raw)
                            masterStruct(i).trialByTrial(j).waitDuration = masterStruct(i).trialByTrial(j).raw.preCueInterval(1);
                        else
                            masterStruct(i).trialByTrial(j).waitDuration = NaN;
                        end
                    end
                else
                    masterStruct(i).trialByTrial(j).waitDuration = NaN;
                end
                
                %trial outcome
                if ~isempty(find((masterStruct(i).trialByTrial(j).raw.flags == 3)))
                    if masterStruct(i).phase >=4
                        masterStruct(i).trialByTrial(j).trialOutcome = masterStruct(i).trialByTrial(j).raw.outcomeFlags(find((masterStruct(i).trialByTrial(j).raw.flags == 3)));
                    end
                    if masterStruct(i).phase <4
                        masterStruct(i).trialByTrial(j).trialOutcome = 1;
                    end
                    if masterStruct(i).phase >=5
                        try
                            masterStruct(i).trialByTrial(j).rewardDirection = masterStruct(i).trialByTrial(j).raw.rewardDirection(find((masterStruct(i).trialByTrial(j).raw.flags == 3)));
                        catch
                            warning('Failed for whatever fucking reason')
                        end
                    end
                    if masterStruct(i).trialByTrial(j).trialOutcome == 3
                        masterStruct(i).trialByTrial(j).pushPull = 0;
                    else
                        masterStruct(i).trialByTrial(j).pushPull = masterStruct(i).trialByTrial(j).raw.lastDirection(find((masterStruct(i).trialByTrial(j).raw.flags == 3)));
                    end
                else
                    masterStruct(i).trialByTrial(j).trialOutcome = NaN;
                end
    
                %global outcomes
                if masterStruct(i).trialByTrial(j).trialOutcome ==1
                    masterStruct(i).numRewards = masterStruct(i).numRewards+1;
                    masterStruct(i).numTrials = masterStruct(i).numTrials+1;
                end
                if masterStruct(i).trialByTrial(j).trialOutcome ==2
                    masterStruct(i).numUnrewardeds = masterStruct(i).numUnrewardeds +1;
                    masterStruct(i).numTrials = masterStruct(i).numTrials+1;
                end
                if masterStruct(i).trialByTrial(j).trialOutcome ==3
                    masterStruct(i).numOmissions = masterStruct(i).numOmissions + 1;
                    masterStruct(i).numTrials = masterStruct(i).numTrials+1;
                end
                if masterStruct(i).trialByTrial(j).trialOutcome >=4
                    masterStruct(i).numPrematures = masterStruct(i).numPrematures + 1;
                    if masterStruct(i).trialByTrial(j).trialOutcome ==4
                        masterStruct(i).numPrematuresRewarded = masterStruct(i).numPrematuresRewarded + 1;
                    end
                    if masterStruct(i).trialByTrial(j).trialOutcome ==5
                        masterStruct(i).numPrematuresUnrewarded = masterStruct(i).numPrematuresUnrewarded + 1;
                    end
                    masterStruct(i).numTrials = masterStruct(i).numTrials+1;
                end
    
                %response latency (relative to trial start - time between 1 and 3)
                if ~isempty(find((masterStruct(i).trialByTrial(j).raw.flags == 1)))
                    masterStruct(i).trialByTrial(j).responseLatency = masterStruct(i).trialByTrial(j).raw.runTime(find((masterStruct(i).trialByTrial(j).raw.flags == 3))) - masterStruct(i).trialByTrial(j).raw.runTime(find((masterStruct(i).trialByTrial(j).raw.flags == 1)));
                else
                    masterStruct(i).trialByTrial(j).responseLatency = NaN;
                end
    
                %choice latency (relative to go cue - time between 2 and 3)
                if ~isnan(masterStruct(i).trialByTrial(j).responseLatency) & ~isnan(masterStruct(i).trialByTrial(j).waitDuration)
                    masterStruct(i).trialByTrial(j).choiceLatency = masterStruct(i).trialByTrial(j).responseLatency - masterStruct(i).trialByTrial(j).waitDuration;
    %                 if masterStruct(i).trialByTrial(j).choiceLatency < 0 
    %                     masterStruct(i).trialByTrial(j).choiceLatency = NaN;
    %                 end
                end
    
                fprintf('%d/%d/%d\n',j,i,size(masterStruct,2)) %useful for debugging
            end
    
    
            
            
        else
            masterStruct(i).numRewards = max(masterStruct(i).raw.numRewards);
            masterStruct(i).numTrials = masterStruct(i).numTrials + masterStruct(i).numRewards;
            if masterStruct(i).phase >=3
                masterStruct(i).numOmissions = max(masterStruct(i).raw.numOmissions);
                masterStruct(i).numTrials = masterStruct(i).numTrials +masterStruct(i).numOmissions;
            else
                masterStruct(i).numOmissions = NaN;
            end
            if masterStruct(i).phase >=3
                masterStruct(i).numUnrewardeds = max(masterStruct(i).raw.numUnrewardeds);
                masterStruct(i).numTrials = masterStruct(i).numTrials +masterStruct(i).numUnrewardeds;
            else
                masterStruct(i).numUnrewardeds = NaN;
            end
            if masterStruct(i).phase >=2
                masterStruct(i).numPrematures = max(masterStruct(i).raw.numPrematures);
                masterStruct(i).numTrials = masterStruct(i).numTrials +masterStruct(i).numPrematures;
            else
                masterStruct(i).numPrematures = NaN;
            end
        end
    end
end


% for i = 1:size(masterStruct,2)
%     masterStruct(i).numTrials = max(masterStruct(i).raw.trialNumber-1)
%     masterStruct(i).runTime = max(masterStruct(i).raw.runTime)/(1000*60);
%     trials = [1:1:masterStruct(i).numTrials]';
%     masterStruct(i).trialByTrial = table(trials);
%     if masterStruct(i).phase >=1
%         masterStruct(i).raw.numOutcomes = masterStruct(i).raw.numRewards + masterStruct(i).raw.numOmissions + masterStruct(i).raw.numUnrewardeds;
%         if masterStruct(i).phase >=2 
%             masterStruct(i).raw.numOutcomes = masterStruct(i).raw.numOutcomes + masterStruct(i).raw.numPrematures;
%         end
%     end
%     if masterStruct(i).phase >=1 && masterStruct(i).numTrials >=2
%         followingITI = [0];
%     end
%     if masterStruct(i).phase >=2 && masterStruct(i).numTrials >=2
%         preCueInterval = [];
%     end
%     if masterStruct(i).phase >=1 && masterStruct(i).numTrials >=2
%         for j = 1:size(masterStruct(i).trialByTrial,1)
%             idx = find(masterStruct(i).raw.trialNumber == j,1);
%             followingITI(j,1) = masterStruct(i).raw.ITI(idx);
%             if masterStruct(i).phase >=2 && masterStruct(i).numTrials >=2
%                 preCueInterval(j,1) = masterStruct(i).raw.preCueInterval(idx);
%             end
%         end
%     end
%     if masterStruct(i).phase >= 1 && masterStruct(i).phase < 2 && masterStruct(i).numTrials >=2
%         masterStruct(i).trialByTrial = table(trials,followingITI);
%     end
%     if masterStruct(i).phase >=2 && masterStruct(i).numTrials >=2
%         masterStruct(i).trialByTrial = table(trials,followingITI,preCueInterval);
%     end
%     fprintf('%d/%d\n',i,size(masterStruct,2))
% end