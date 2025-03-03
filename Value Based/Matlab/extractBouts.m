%extract bouts
for i = 1:size(masterStruct,2)
    for j = 1:size(masterStruct(i).trialByTrial,2)
        boutNumber = 0;
        boutInitiated = 0;
        if isscalar(masterStruct(i).trialByTrial(j).trialOutcome)
            if masterStruct(i).trialByTrial(j).trialOutcome < 3 && masterStruct(i).trialByTrial(j).trialOutcome >=1 && size(masterStruct(i).trialByTrial(j).joyPosArray,2) ==9
                for k = 1:size(masterStruct(i).trialByTrial(j).joyPosArray,1)
                    if masterStruct(i).trialByTrial(j).joyPosArray(k,8) == 1 && masterStruct(i).trialByTrial(j).joyPosArray(k,9) == 0
                        boutInitiated = 1;
                        boutNumber = boutNumber + 1;
                        boutArray = [];
                    end
                    if boutInitiated == 1 && masterStruct(i).trialByTrial(j).joyPosArray(k,9) == 0
                        boutArray = [boutArray; masterStruct(i).trialByTrial(j).joyPosArray(k,:)];
                    end
                    if boutInitiated == 1 && masterStruct(i).trialByTrial(j).joyPosArray(k,9) == 1 && masterStruct(i).trialByTrial(j).joyPosArray(k,8) == 0
                        boutArray = [boutArray; masterStruct(i).trialByTrial(j).joyPosArray(k,:)];
                        boutInitiated = 0;
                        masterStruct(i).trialByTrial(j).boutByBout(boutNumber).raw = boutArray;
                    end
                    if boutInitiated == 1 && masterStruct(i).trialByTrial(j).joyPosArray(k,9) == 1 && masterStruct(i).trialByTrial(j).joyPosArray(k,8) == 1
                        boutArray = [boutArray; masterStruct(i).trialByTrial(j).joyPosArray(k,:)];
                        masterStruct(i).trialByTrial(j).boutByBout(boutNumber).raw = boutArray;
                        boutNumber = boutNumber + 1;
                        boutInitiated = 1;
                        boutArray = masterStruct(i).trialByTrial(j).joyPosArray(k,:);
                    end
                end
            end
        end
    end
end

%%
%determine decisive bout
for i = 1:size(masterStruct,2)
    for j = 1:size(masterStruct(i).trialByTrial,2)
        if ~isempty(masterStruct(i).trialByTrial(j).boutByBout) && isscalar(masterStruct(i).trialByTrial(j).trialOutcome)
            decisiveBouts = 0;
            for k = 1:size(masterStruct(i).trialByTrial(j).boutByBout,2)
                if ~isequal(sign(masterStruct(i).trialByTrial(j).boutByBout(k).raw(1,1)),sign(masterStruct(i).trialByTrial(j).boutByBout(k).raw(size(masterStruct(i).trialByTrial(j).boutByBout(k).raw,1),1)))
                    masterStruct(i).trialByTrial(j).boutByBout(k).decisiveBout = 1;
                    decisiveBouts = decisiveBouts + 1;
                else
                    masterStruct(i).trialByTrial(j).boutByBout(k).decisiveBout = 0;
                end
            end
            masterStruct(i).trialByTrial(j).decisiveBouts = decisiveBouts;
        end
    end
end

%from here on out, exclude trials for which we are unable to pick up a
%decisive bout. 

%%
%for each bout, compute peak displacement, peak velocity, average velocity,
%distance traveled, and tortuosity
for i = 1:size(masterStruct,2)
    for j = 1:size(masterStruct(i).trialByTrial,2)
        if ~isempty(masterStruct(i).trialByTrial(j).boutByBout) && masterStruct(i).trialByTrial(j).decisiveBouts == 1  && isscalar(masterStruct(i).trialByTrial(j).trialOutcome)
            for k = 1:size(masterStruct(i).trialByTrial(j).boutByBout,2)
                distanceTravelled = 0;
                displacementTravelled = 0;
                if mean(masterStruct(i).trialByTrial(j).boutByBout(k).raw(:,5)) > 0
                    masterStruct(i).trialByTrial(j).boutByBout(k).boutType = 1;
                end
                if mean(masterStruct(i).trialByTrial(j).boutByBout(k).raw(:,5)) < 0
                    masterStruct(i).trialByTrial(j).boutByBout(k).boutType = 2;
                end
                if mean(masterStruct(i).trialByTrial(j).boutByBout(k).raw(:,5)) == 0
                    masterStruct(i).trialByTrial(j).boutByBout(k).boutType = 0;
                end
                if masterStruct(i).trialByTrial(j).boutByBout(k).boutType == 1
                    masterStruct(i).trialByTrial(j).boutByBout(k).peakDispl = max(masterStruct(i).trialByTrial(j).boutByBout(k).raw(:,2));
                    masterStruct(i).trialByTrial(j).boutByBout(k).peakVel = max(masterStruct(i).trialByTrial(j).boutByBout(k).raw(:,5));
                end
                if masterStruct(i).trialByTrial(j).boutByBout(k).boutType == 2
                    masterStruct(i).trialByTrial(j).boutByBout(k).peakDispl = min(masterStruct(i).trialByTrial(j).boutByBout(k).raw(:,2));
                    masterStruct(i).trialByTrial(j).boutByBout(k).peakVel = min(masterStruct(i).trialByTrial(j).boutByBout(k).raw(:,5));
                end
                masterStruct(i).trialByTrial(j).boutByBout(k).meanVel = mean(masterStruct(i).trialByTrial(j).boutByBout(k).raw(:,5));
                for l = 1:size(masterStruct(i).trialByTrial(j).boutByBout(k).raw,1)
                    distanceTravelled = distanceTravelled + abs(masterStruct(i).trialByTrial(j).boutByBout(k).raw(l,3));
                end
                displacementTravelled = abs(masterStruct(i).trialByTrial(j).boutByBout(k).raw(1,2)-masterStruct(i).trialByTrial(j).boutByBout(k).raw(size(masterStruct(i).trialByTrial(j).boutByBout(k).raw,1),2));
                masterStruct(i).trialByTrial(j).boutByBout(k).distanceTravelled = distanceTravelled;
                masterStruct(i).trialByTrial(j).boutByBout(k).tortuosity = distanceTravelled/displacementTravelled;
            end
        end
    end
end

%%
%for each trial, extract: 1) peak displacement, peak velocity, mean
%velocity, and tortuosity of the decisive bout; 2) number of bouts; 3)
%directional consistency of bouts (percentage of bouts in ultimate choice
%direction); 4) distance travelled during all bouts. 

for i = 1:size(masterStruct,2)
    for j = 1:size(masterStruct(i).trialByTrial,2)
        if isscalar(masterStruct(i).trialByTrial(j).trialOutcome)
            if masterStruct(i).trialByTrial(j).trialOutcome < 3 && masterStruct(i).trialByTrial(j).trialOutcome >= 1 && size(masterStruct(i).trialByTrial(j).joyPosArray,2) ==9 && masterStruct(i).trialByTrial(j).decisiveBouts == 1 
                boutType = 0;
                for k = 1:size(masterStruct(i).trialByTrial(j).boutByBout,2)
                    if masterStruct(i).trialByTrial(j).boutByBout(k).decisiveBout == 1
                        masterStruct(i).trialByTrial(j).peakDispl = masterStruct(i).trialByTrial(j).boutByBout(k).peakDispl;
                        masterStruct(i).trialByTrial(j).peakVel = masterStruct(i).trialByTrial(j).boutByBout(k).peakVel;
                        masterStruct(i).trialByTrial(j).meanVel = masterStruct(i).trialByTrial(j).boutByBout(k).meanVel;
                        masterStruct(i).trialByTrial(j).tortuosity = masterStruct(i).trialByTrial(j).boutByBout(k).tortuosity;
                        boutType = masterStruct(i).trialByTrial(j).boutByBout(k).boutType;
                    end
                end
                masterStruct(i).trialByTrial(j).numBouts = size(masterStruct(i).trialByTrial(j).boutByBout,2);
                boutsPush = 0;
                boutsPull = 0;
                for k = 1:size(masterStruct(i).trialByTrial(j).boutByBout,2)
                    if masterStruct(i).trialByTrial(j).boutByBout(k).boutType == 1
                        boutsPush = boutsPush + 1;
                    end
                    if masterStruct(i).trialByTrial(j).boutByBout(k).boutType == 2
                        boutsPull = boutsPull + 1;
                    end
                end
                if boutType == 1
                    masterStruct(i).trialByTrial(j).dirConsistency = boutsPush/masterStruct(i).trialByTrial(j).numBouts;
                end
                if boutType == 2
                    masterStruct(i).trialByTrial(j).dirConsistency = boutsPull/masterStruct(i).trialByTrial(j).numBouts;
                end
                distanceTravelled = 0;
                for k = 1:size(masterStruct(i).trialByTrial(j).boutByBout,2)
                    distanceTravelled = distanceTravelled + masterStruct(i).trialByTrial(j).boutByBout(k).distanceTravelled;
                end
                masterStruct(i).trialByTrial(j).totalDistanceTravelled = distanceTravelled;
            end
        end
    end
end

