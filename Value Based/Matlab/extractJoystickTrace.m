%extract joystick trace from >1 second before threshold/at beginning of
%trial to before the servo retracts

%Note that this norms to baseline!
for i = 1:size(masterStruct,2)
    for j = 1:size(masterStruct(i).trialByTrial,2)
        if masterStruct(i).trialByTrial(j).trialOutcome < 3
            try
                k0 = find((masterStruct(i).trialByTrial(j).raw.flags == 3)); % note that 2 sets it to GO cue, 3 sets it to threshold!
                kTime = masterStruct(i).trialByTrial(j).raw.runTime(k0);
                k1 = find((masterStruct(i).trialByTrial(j).raw.flags == 1));
                if isempty(k1)
                    k1 = 1;
                end
                k2 = find((masterStruct(i).trialByTrial(j).raw.flags == 4));
                joyPosArray = [];
                for k = k1:k2
                    joyPosArray = [joyPosArray; masterStruct(i).trialByTrial(j).raw.runTime(k)-kTime masterStruct(i).trialByTrial(j).raw.A3PosMovAv(k)-masterStruct(i).trialByTrial(j).raw.A3PosBaseline(1)];
                end
                masterStruct(i).trialByTrial(j).joyPosArray = joyPosArray;
                if ~isempty(masterStruct(i).trialByTrial(j).joyPosArray)
                    if masterStruct(i).trialByTrial(j).pushPull == 1
                        masterStruct(i).trialByTrial(j).peakDispl = max(masterStruct(i).trialByTrial(j).joyPosArray(:,2));
                    end
                    if masterStruct(i).trialByTrial(j).pushPull == 2
                        masterStruct(i).trialByTrial(j).peakDispl = min(masterStruct(i).trialByTrial(j).joyPosArray(:,2));
                    end
                end
            catch
                warning('There was an issue');
            end
        end
    end
    fprintf('%d/%d\n',i,size(masterStruct,2))
end
%%
%extract information about maximum displacement
for i = 1:size(masterStruct,2)
    for j = 1:size(masterStruct(i).trialByTrial,2)
        if ~isempty(masterStruct(i).trialByTrial(j).joyPosArray) & masterStruct(i).trialByTrial(j).trialOutcome < 3 & size(masterStruct(i).trialByTrial(j).joyPosArray,2)>=2
            if masterStruct(i).trialByTrial(j).pushPull == 1 
                masterStruct(i).trialByTrial(j).peakDispl = max(masterStruct(i).trialByTrial(j).joyPosArray(:,2));
            end
            if masterStruct(i).trialByTrial(j).pushPull == 2
                masterStruct(i).trialByTrial(j).peakDispl = min(masterStruct(i).trialByTrial(j).joyPosArray(:,2));
            end
        end
    end
    fprintf('%d/%d\n',i,size(masterStruct,2))
end

%%
%extract information about displacement velocity 
for i = 1:size(masterStruct,2)
    for j = 1:size(masterStruct(i).trialByTrial,2)
        if ~isempty(masterStruct(i).trialByTrial(j).joyPosArray) & masterStruct(i).trialByTrial(j).trialOutcome < 3 & size(masterStruct(i).trialByTrial(j).joyPosArray,2)>=2
            masterStruct(i).trialByTrial(j).joyPosArray = [masterStruct(i).trialByTrial(j).joyPosArray [0; diff(masterStruct(i).trialByTrial(j).joyPosArray(:,2))]];
            for k = 1:size(masterStruct(i).trialByTrial(j).joyPosArray,1)
                if k == 1
                    masterStruct(i).trialByTrial(j).joyPosArray(k,4) = 0;
                else
                    masterStruct(i).trialByTrial(j).joyPosArray(k,4) = masterStruct(i).trialByTrial(j).joyPosArray(k,3)/(masterStruct(i).trialByTrial(j).joyPosArray(k,1)-masterStruct(i).trialByTrial(j).joyPosArray(k-1,1));
                end
            end
            k0 = find((masterStruct(i).trialByTrial(j).joyPosArray(:,1) == 0));
            k1 = find(masterStruct(i).trialByTrial(j).joyPosArray(:,1) < -100,1,'last');
            if isempty(k1)
                k1 = 2;
            end
            if k1 == 1
                k1 = 2;
            end
            k2 = find(masterStruct(i).trialByTrial(j).joyPosArray(:,1) > 100,1);
            if isempty(k2)
                k2 = size(masterStruct(i).trialByTrial(j).joyPosArray,1);
            end
            diffArray = [];
            for k = k1:k2
                if (masterStruct(i).trialByTrial(j).joyPosArray(k,1)-masterStruct(i).trialByTrial(j).joyPosArray(k-1,1)) ~= 0
                    diffArray = [diffArray; masterStruct(i).trialByTrial(j).joyPosArray(k,3)/((masterStruct(i).trialByTrial(j).joyPosArray(k,1)-masterStruct(i).trialByTrial(j).joyPosArray(k-1,1)))];
                else
                    diffArray = [diffArray; NaN];
                end
            end
            if masterStruct(i).trialByTrial(j).pushPull == 1
                masterStruct(i).trialByTrial(j).peakVel = max(diffArray);
            end
            if masterStruct(i).trialByTrial(j).pushPull == 2
                masterStruct(i).trialByTrial(j).peakVel = min(diffArray);
            end
            masterStruct(i).trialByTrial(j).diffArray = diffArray;
        end
    end
    fprintf('%d/%d\n',i,size(masterStruct,2))
end

%%
%smooth the velocity trace
for i = 1:size(masterStruct,2)
    for j = 1:size(masterStruct(i).trialByTrial,2)
        if ~isnan(masterStruct(i).trialByTrial(j).trialOutcome) & masterStruct(i).trialByTrial(j).trialOutcome < 3  & size(masterStruct(i).trialByTrial(j).joyPosArray,2)>=2
            masterStruct(i).trialByTrial(j).joyPosArray = [masterStruct(i).trialByTrial(j).joyPosArray smoothdata(masterStruct(i).trialByTrial(j).joyPosArray(:,4))];
%             %get velocity of smoothed trace
%             masterStruct(i).trialByTrial(j).joyPosArray = [masterStruct(i).trialByTrial(j).joyPosArray [0; diff(masterStruct(i).trialByTrial(j).joyPosArray(:,5))]];
%              for k = 1:size(masterStruct(i).trialByTrial(j).joyPosArray,1)
%                 if k == 1
%                     masterStruct(i).trialByTrial(j).joyPosArray(k,7) = 0;
%                 else
%                     masterStruct(i).trialByTrial(j).joyPosArray(k,7) = masterStruct(i).trialByTrial(j).joyPosArray(k,6)/(masterStruct(i).trialByTrial(j).joyPosArray(k,1)-masterStruct(i).trialByTrial(j).joyPosArray(k-1,1));
%                 end
%            end
        end
    end
end

%%
% for i = 1:size(masterStruct,2)
%     for j = 1:size(masterStruct(i).trialByTrial,2)
%         if ~isnan(masterStruct(i).trialByTrial(j).trialOutcome)
%             while size(masterStruct(i).trialByTrial(j).joyPosArray,2) >=5
%                 masterStruct(i).trialByTrial(j).joyPosArray(:,5) = [];
%             end
%         end
%     end
% end

%%
%extract bouts
boutSignk = 0;
for i = 1:size(masterStruct,2)
    for j = 1:size(masterStruct(i).trialByTrial,2)
        boutStarted = 0;
        boutCounter = 0;
        boutOngoing = 0;
        setBoutCounter = 0;
        tooSlow = 0;
        if ~isnan(masterStruct(i).trialByTrial(j).trialOutcome) & masterStruct(i).trialByTrial(j).trialOutcome < 3  & size(masterStruct(i).trialByTrial(j).joyPosArray,2)>=2
            for k = 1:size(masterStruct(i).trialByTrial(j).joyPosArray,1)
                if abs(masterStruct(i).trialByTrial(j).joyPosArray(k,5)) >= 7.5 && boutStarted == 0
                    boutStarted = 1;
                    if k>1
                        boutCounter = masterStruct(i).trialByTrial(j).joyPosArray(k,1) - masterStruct(i).trialByTrial(j).joyPosArray(k-1,1);
                    else
                        boutCounter = 1;
                    end
                    boutStartk = k; 
                    boutSignk = sign(masterStruct(i).trialByTrial(j).joyPosArray(k,5));
                    masterStruct(i).trialByTrial(j).joyPosArray(k,6) = 1;
                    masterStruct(i).trialByTrial(j).joyPosArray(k,7) = 1;
                end
                if abs(masterStruct(i).trialByTrial(j).joyPosArray(k,5)) <= 2.5 && boutStarted == 1
                    tooSlow = tooSlow +  masterStruct(i).trialByTrial(j).joyPosArray(k,1) - masterStruct(i).trialByTrial(j).joyPosArray(k-1,1);
                end
                if abs(masterStruct(i).trialByTrial(j).joyPosArray(k,5)) >= 2.5 && boutStarted == 1
                    if k>1
                        boutCounter = boutCounter + masterStruct(i).trialByTrial(j).joyPosArray(k,1) - masterStruct(i).trialByTrial(j).joyPosArray(k-1,1);
                    end
                    if k == 1
                        boutCounter = 1;
                    end
                    if (boutSignk == 1 && sign(masterStruct(i).trialByTrial(j).joyPosArray(k,5)) == -1) || (boutSignk == -1 && sign(masterStruct(i).trialByTrial(j).joyPosArray(k,5)) == 1) && boutOngoing ==0
                        boutCounter = 0;
                        boutStarted = 0;
                    end
                    masterStruct(i).trialByTrial(j).joyPosArray(k,6) = 1;
                    masterStruct(i).trialByTrial(j).joyPosArray(k,7) = 0;
                end
                %mark the start of a bout given the criterion that it last
                %longer than 50 msec
                if boutCounter >= 50 && setBoutCounter == 0
                    masterStruct(i).trialByTrial(j).joyPosArray(boutStartk,8) = 1;
                    boutOngoing = 1;
                    setBoutCounter = 1;
                end
                %a started bout is concluded by either the withdrawal of 
                %joystick or by crossing 0 velocity by significant amount,
                %or too slow (<=2.5mm/s) for >50msec
                if boutOngoing == 1 && (k == size(masterStruct(i).trialByTrial(j).joyPosArray,1) || tooSlow >=50 || ((k>1) && ~isequal(sign(masterStruct(i).trialByTrial(j).joyPosArray(k-1,5)),sign(masterStruct(i).trialByTrial(j).joyPosArray(k,5))) && abs(masterStruct(i).trialByTrial(j).joyPosArray(k-1,5)-masterStruct(i).trialByTrial(j).joyPosArray(k,5))>1.8))
                    masterStruct(i).trialByTrial(j).joyPosArray(k,9) = 1;
                    boutOngoing = 0;
                    boutStarted = 0;
                    boutCounter = 0;
                    setBoutCounter = 0;
                    tooSlow = 0;
                end

                %the movement as the joystick crosses threshold will be
                %considered a bout regardless of the criteria above
                if size(masterStruct(i).trialByTrial(j).joyPosArray,2) >5
                    if abs(masterStruct(i).trialByTrial(j).joyPosArray(k,1)) <= 50 && boutOngoing == 0 && abs(masterStruct(i).trialByTrial(j).joyPosArray(k,5)) >=2.5 & k < size(masterStruct(i).trialByTrial(j).joyPosArray,1)
                            masterStruct(i).trialByTrial(j).joyPosArray(k,8) = 1;
                            boutStarted = 1;
                            boutOngoing = 1;
                            setBoutCounter = 1;
                            boutStartk = k; 
                            masterStruct(i).trialByTrial(j).joyPosArray(k,6) = 1;
                            masterStruct(i).trialByTrial(j).joyPosArray(k,7) = 1;
                    end
                    if abs(masterStruct(i).trialByTrial(j).joyPosArray(k,1)) <= 50 && boutOngoing == 1 && abs(masterStruct(i).trialByTrial(j).joyPosArray(k,5)) >=2.5 
                            masterStruct(i).trialByTrial(j).joyPosArray(k,6) = 1;
                            masterStruct(i).trialByTrial(j).joyPosArray(k,7) = 0;
                    end
                end
            end
            if size(masterStruct(i).trialByTrial(j).joyPosArray,2) >= 9
                masterStruct(i).trialByTrial(j).boutsStarted = sum(masterStruct(i).trialByTrial(j).joyPosArray(:,8));
                masterStruct(i).trialByTrial(j).boutsCompleted = sum(masterStruct(i).trialByTrial(j).joyPosArray(:,9));
            end
        end
    end
end


%%
%check traces
% i = 2;
% j = 170;
% hold off
% plot(masterStruct(i).trialByTrial(j).joyPosArray(:,1),masterStruct(i).trialByTrial(j).joyPosArray(:,2));
% hold on
% plot(masterStruct(i).trialByTrial(j).joyPosArray(:,1),masterStruct(i).trialByTrial(j).joyPosArray(:,8)*1000);
% plot(masterStruct(i).trialByTrial(j).joyPosArray(:,1),masterStruct(i).trialByTrial(j).joyPosArray(:,9)*1000);
% 
