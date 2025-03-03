%PDCLZScore - actually we are log transforming and scaling
for i = 1:numel(masterStruct)
    % %PD
    % joyPos = masterStruct(i).raw.A3PosMovAv - masterStruct(i).raw.A3PosBaseline;
    % mPD = mean(joyPos);
    % sPD = std(joyPos,0);
    % for j = 1:numel(masterStruct(i).trialByTrial)
    %     if ~isempty(masterStruct(i).trialByTrial(j).peakDispl)
    %         masterStruct(i).trialByTrial(j).peakDisplZ = (masterStruct(i).trialByTrial(j).peakDispl - mPD)/sPD;
    %     end
    % end
    % %CL
    % CLs = [];
    % for j = 1:numel(masterStruct(i).trialByTrial)
    %     if ~isempty(masterStruct(i).trialByTrial(j).choiceLatency)
    %         if masterStruct(i).trialByTrial(j).choiceLatency > 0 && masterStruct(i).trialByTrial(j).choiceLatency < 21000
    %             CLs = [CLs; masterStruct(i).trialByTrial(j).choiceLatency];
    %         end
    %     end
    % end
    % mCL = mean(CLs);
    % sCL = std(CLs,0);
    % for j = 1:numel(masterStruct(i).trialByTrial)
    %     if ~isempty(masterStruct(i).trialByTrial(j).choiceLatency)
    %         masterStruct(i).trialByTrial(j).choiceLatencyZ = (masterStruct(i).trialByTrial(j).choiceLatency - mCL)/sCL;
    %     end
    % end
    % %PD
    % PDs = [];
    % for j = 1:numel(masterStruct(i).trialByTrial)
    %     if ~isempty(masterStruct(i).trialByTrial(j).peakDispl)
    %         if abs(masterStruct(i).trialByTrial(j).peakDispl) < 20000
    %             PDs = [PDs; abs(masterStruct(i).trialByTrial(j).peakDispl)];
    %         end
    %     end
    % end
    % mPD = nanmean(PDs);
    % sPD = nanstd(PDs,0);
    % for j = 1:numel(masterStruct(i).trialByTrial)
    %     if ~isempty(masterStruct(i).trialByTrial(j).peakDispl)
    %         masterStruct(i).trialByTrial(j).peakDisplZ = (abs(masterStruct(i).trialByTrial(j).peakDispl) - mPD)/sPD;
    %     end
    % end
    % fprintf('%d/%d\n',i,numel(masterStruct));
    %CL
    for j = 1:numel(masterStruct(i).trialByTrial)
        masterStruct(i).trialByTrial(j).choiceLatencyZ = [];
        masterStruct(i).trialByTrial(j).peakDisplZ = [];
    end
    CLs = [];
    for j = 1:numel(masterStruct(i).trialByTrial)
        if ~isempty(masterStruct(i).trialByTrial(j).choiceLatency) & masterStruct(i).trialByTrial(j).trialOutcome < 3
            if masterStruct(i).trialByTrial(j).choiceLatency > 0 & masterStruct(i).trialByTrial(j).choiceLatency < 21000
                CLs = [CLs; masterStruct(i).trialByTrial(j).choiceLatency/1000];
            end
        end
    end
    minCL = min(log10(CLs));
    maxCL = max(log10(CLs));
    for j = 1:numel(masterStruct(i).trialByTrial)
        if ~isempty(masterStruct(i).trialByTrial(j).choiceLatency) & masterStruct(i).trialByTrial(j).choiceLatency > 0 & masterStruct(i).trialByTrial(j).choiceLatency < 21000
            masterStruct(i).trialByTrial(j).choiceLatencyZ = (log10(masterStruct(i).trialByTrial(j).choiceLatency/1000)-minCL)/(maxCL-minCL);
        end
    end
    %PD
    PDs = [];
    for j = 1:numel(masterStruct(i).trialByTrial)
        if ~isempty(masterStruct(i).trialByTrial(j).peakDispl) & masterStruct(i).trialByTrial(j).trialOutcome < 3
            if abs(masterStruct(i).trialByTrial(j).peakDispl) < 20000
                PDs = [PDs; abs(masterStruct(i).trialByTrial(j).peakDispl/1000)];
            end
        end
    end
    minPD = min(log10(PDs-3));
    maxPD = max(log10(PDs-3));
    for j = 1:numel(masterStruct(i).trialByTrial)
        if ~isempty(masterStruct(i).trialByTrial(j).peakDispl) & abs(masterStruct(i).trialByTrial(j).peakDispl)>3000 & masterStruct(i).trialByTrial(j).trialOutcome < 3
            masterStruct(i).trialByTrial(j).peakDisplZ = (log10((abs(masterStruct(i).trialByTrial(j).peakDispl)/1000)-3)-minPD)/(maxPD-minPD);
        end
    end
    fprintf('%d/%d\n',i,numel(masterStruct));
end