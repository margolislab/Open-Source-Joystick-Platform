%EXTRACCT BLOCK INFO
%Run this to get a sense of how many blocks and trials you have of each
%item of interest.
%extractJoystickTrace;
%extractBouts;

%generate array of all animals you have
animalIDs = [];
for i = 1:size(masterStruct,2)
    animalIDs = [animalIDs; masterStruct(i).animalID];
end

animalIDs = unique(animalIDs);

%generate a block info struct summarizing all the relevant block info per
%animal
for j = 1:size(masterStruct,2)
    if masterStruct(j).phase >=5 | floor(masterStruct(j).phase) == 10
        for k = 1:size(masterStruct(j).trialByTrial,2)
            if k ==1
                masterStruct(j).trialByTrial(k).blockFlag = 1;
                masterStruct(j).trialByTrial(k).trialWithinBlock = 1;
            else
                if floor(masterStruct(j).phase) == 9 && ~isempty(masterStruct(j).trialByTrial(k).rewardDirection) && ~isnan(masterStruct(j).trialByTrial(k).rewardDirection)
                    if masterStruct(j).trialByTrial(k).rewardDirection ~= masterStruct(j).trialByTrial(k-1).rewardDirection & masterStruct(j).trialByTrial(k).raw.limboFlag(1) == 0
                        masterStruct(j).trialByTrial(k).blockFlag = 1;
                        masterStruct(j).trialByTrial(k).trialWithinBlock = 1;
                    else
                        masterStruct(j).trialByTrial(k).blockFlag = 0;
                        masterStruct(j).trialByTrial(k).trialWithinBlock = masterStruct(j).trialByTrial(k-1).trialWithinBlock + 1;
                    end
                else
                    if masterStruct(j).trialByTrial(k).rewardDirection ~= masterStruct(j).trialByTrial(k-1).rewardDirection
                        masterStruct(j).trialByTrial(k).blockFlag = 1;
                        masterStruct(j).trialByTrial(k).trialWithinBlock = 1;
                    else
                        masterStruct(j).trialByTrial(k).blockFlag = 0;
                        masterStruct(j).trialByTrial(k).trialWithinBlock = masterStruct(j).trialByTrial(k-1).trialWithinBlock + 1;
                    end
                end
            end
        end
    end
end


%add information about block type (there are 18 types)
%1. Phase 6 or 10 80:20
%2. Phase 6 or 10 20:80
%3. Phase 7 80:20
%4. Phase 7 20:80
%5. Phase 7 40:10
%6. Phase 7 10:40
%7. Phase 8 80:20 16uL
%8. Phase 8 20:80 16uL
%9. Phase 8 80:20 8uL
%10. Phase 8 20:80 8uL
%11. Phase 8 80:20 4uL
%12. Phase 8 20:80 4uL
%13. Phase 8 40:10 16uL
%14. Phase 8 10:40 16uL
%15. Phase 8 40:10 8uL
%16. Phase 8 10:40 8uL
%17. Phase 8 40:10 4uL
%18. Phase 8 10:40 4uL
%19. All phases 100:0 training
%20. All phases 0:100 training
%21. Phase 8 80:20 2uL
%22. Phase 8 20:80 2uL
%23. Phase 8 40:10 2uL
%24. Phase 8 10:40 2uL
%25. Phase 9 90R:90
%26. Phase 9 90:90R
%27. Phase 9 90:45R
%28. Phase 9 45R:90
%29. Phase 9 90:30R
%30. Phase 9 30R:90
%31. Phase 9 90:22.5R
%32. Phase 9 22.5R:90
%33. Phase 9 70R:70
%34. Phase 9 70:70R
%35. Phase 9 35R:70
%36. Phase 9 70:35R
%37. Phase 9 17.5R:70
%38. Phase 9 70:17.5R
%39. Phase 9 11.7R:70
%40. Phase 9 70:11.7R
%41. Phase 9 46.7R:70
%42. Phase 9 70:46.7R
%43. Phase 9 23.3R:70
%44. Phase 9 70:23.3R
%45. Phase 9 8.8R:70
%46. Phase 9 70:8.8R


for i = 1:size(masterStruct,2)
    for j = 1:size(masterStruct(i).trialByTrial,2)
        if masterStruct(i).phase > 5
            if masterStruct(i).trialByTrial(j).blockFlag == 1
                if masterStruct(i).phase >=6
                    if masterStruct(i).trialByTrial(j).raw.rewardProbabilityPush(1) == 1000
                        masterStruct(i).trialByTrial(j).blockType = 19;
                    end
                    if masterStruct(i).trialByTrial(j).raw.rewardProbabilityPull(1) == 1000
                        masterStruct(i).trialByTrial(j).blockType = 20;
                    end
                end
                if floor(masterStruct(i).phase) ==5
                    if masterStruct(i).trialByTrial(j).raw.rewardDirection(1) == 1
                        masterStruct(i).trialByTrial(j).blockType = 19;
                    end
                    if masterStruct(i).trialByTrial(j).raw.rewardDirection(1) == 2
                        masterStruct(i).trialByTrial(j).blockType = 20;
                    end
                end
            end
        end
    end
    if ismember(floor(masterStruct(i).phase),[6,10,11,12])
        for j = 1:size(masterStruct(i).trialByTrial,2)
            if masterStruct(i).trialByTrial(j).blockFlag == 1
                if masterStruct(i).trialByTrial(j).raw.rewardProbabilityPush(1) == 800
                    masterStruct(i).trialByTrial(j).blockType = 1;
                end
                if masterStruct(i).trialByTrial(j).raw.rewardProbabilityPull(1) == 800
                    masterStruct(i).trialByTrial(j).blockType = 1;
                end
            end
        end
    end
    if floor(masterStruct(i).phase) == 7  
        for j = 1:size(masterStruct(i).trialByTrial,2)
            if masterStruct(i).trialByTrial(j).blockFlag == 1
                if masterStruct(i).trialByTrial(j).raw.rewardProbabilityPush(1) == 800
                    masterStruct(i).trialByTrial(j).blockType = 3;
                end
                if masterStruct(i).trialByTrial(j).raw.rewardProbabilityPull(1) == 800
                    masterStruct(i).trialByTrial(j).blockType = 4;
                end
                if masterStruct(i).trialByTrial(j).raw.rewardProbabilityPush(1) == 400
                    masterStruct(i).trialByTrial(j).blockType = 5;
                end
                if masterStruct(i).trialByTrial(j).raw.rewardProbabilityPull(1) == 400
                    masterStruct(i).trialByTrial(j).blockType = 6;
                end
            end
        end
    end
    if floor(masterStruct(i).phase) == 12  
        for j = 1:size(masterStruct(i).trialByTrial,2)
            if masterStruct(i).trialByTrial(j).blockFlag == 1
                if masterStruct(i).trialByTrial(j).raw.rewardProbabilityPush(1) == 600
                    masterStruct(i).trialByTrial(j).blockType = 53;
                end
                if masterStruct(i).trialByTrial(j).raw.rewardProbabilityPull(1) == 600
                    masterStruct(i).trialByTrial(j).blockType = 54;
                end
            end
        end
    end
    if masterStruct(i).phase == 8.0
        for j = 1:size(masterStruct(i).trialByTrial,2)
            if masterStruct(i).trialByTrial(j).blockFlag == 1
                if masterStruct(i).trialByTrial(j).raw.rewardProbabilityPush(1) == 800
                    if masterStruct(i).trialByTrial(j).raw.onDuration == 140
                        masterStruct(i).trialByTrial(j).blockType = 7;
                    end
                    if masterStruct(i).trialByTrial(j).raw.onDuration == 80
                        masterStruct(i).trialByTrial(j).blockType = 9;
                    end
                    if masterStruct(i).trialByTrial(j).raw.onDuration == 50
                        masterStruct(i).trialByTrial(j).blockType = 11;
                    end
                end
                if masterStruct(i).trialByTrial(j).raw.rewardProbabilityPull(1) == 800
                    if masterStruct(i).trialByTrial(j).raw.onDuration == 140
                        masterStruct(i).trialByTrial(j).blockType = 8;
                    end
                    if masterStruct(i).trialByTrial(j).raw.onDuration == 80
                        masterStruct(i).trialByTrial(j).blockType = 10;
                    end
                    if masterStruct(i).trialByTrial(j).raw.onDuration == 50
                        masterStruct(i).trialByTrial(j).blockType = 12;
                    end
                end
                if masterStruct(i).trialByTrial(j).raw.rewardProbabilityPush(1) == 400
                    if masterStruct(i).trialByTrial(j).raw.onDuration == 140
                        masterStruct(i).trialByTrial(j).blockType = 13;
                    end
                    if masterStruct(i).trialByTrial(j).raw.onDuration == 80
                        masterStruct(i).trialByTrial(j).blockType = 15;
                    end
                    if masterStruct(i).trialByTrial(j).raw.onDuration == 50
                        masterStruct(i).trialByTrial(j).blockType = 17;
                    end
                end
                if masterStruct(i).trialByTrial(j).raw.rewardProbabilityPull(1) == 400
                    if masterStruct(i).trialByTrial(j).raw.onDuration == 140
                        masterStruct(i).trialByTrial(j).blockType = 14;
                    end
                    if masterStruct(i).trialByTrial(j).raw.onDuration == 80
                        masterStruct(i).trialByTrial(j).blockType = 16;
                    end
                    if masterStruct(i).trialByTrial(j).raw.onDuration == 50
                        masterStruct(i).trialByTrial(j).blockType = 18;
                    end
                end
            end
        end
    end
    if masterStruct(i).phase >= 8.1 && masterStruct(i).phase < 9
        for j = 1:size(masterStruct(i).trialByTrial,2)
            if masterStruct(i).trialByTrial(j).blockFlag == 1
                if masterStruct(i).trialByTrial(j).raw.rewardProbabilityPush(1) == 800
                    if masterStruct(i).trialByTrial(j).raw.onDuration(1) == 35
                        masterStruct(i).trialByTrial(j).blockType = 21;
                    end
                    if masterStruct(i).trialByTrial(j).raw.onDuration(1) == 80
                        masterStruct(i).trialByTrial(j).blockType = 9;
                    end
                    if masterStruct(i).trialByTrial(j).raw.onDuration(1) == 50
                        masterStruct(i).trialByTrial(j).blockType = 11;
                    end
                end
                if masterStruct(i).trialByTrial(j).raw.rewardProbabilityPull(1) == 800
                    if masterStruct(i).trialByTrial(j).raw.onDuration(1) == 35
                        masterStruct(i).trialByTrial(j).blockType = 22;
                    end
                    if masterStruct(i).trialByTrial(j).raw.onDuration(1) == 80
                        masterStruct(i).trialByTrial(j).blockType = 10;
                    end
                    if masterStruct(i).trialByTrial(j).raw.onDuration(1) == 50
                        masterStruct(i).trialByTrial(j).blockType = 12;
                    end
                end
                if masterStruct(i).trialByTrial(j).raw.rewardProbabilityPush(1) == 400
                    if masterStruct(i).trialByTrial(j).raw.onDuration(1) == 35
                        masterStruct(i).trialByTrial(j).blockType = 23;
                    end
                    if masterStruct(i).trialByTrial(j).raw.onDuration(1) == 80
                        masterStruct(i).trialByTrial(j).blockType = 15;
                    end
                    if masterStruct(i).trialByTrial(j).raw.onDuration(1) == 50
                        masterStruct(i).trialByTrial(j).blockType = 17;
                    end
                end
                if masterStruct(i).trialByTrial(j).raw.rewardProbabilityPull(1) == 400
                    if masterStruct(i).trialByTrial(j).raw.onDuration(1) == 35
                        masterStruct(i).trialByTrial(j).blockType = 24;
                    end
                    if masterStruct(i).trialByTrial(j).raw.onDuration(1) == 80
                        masterStruct(i).trialByTrial(j).blockType = 16;
                    end
                    if masterStruct(i).trialByTrial(j).raw.onDuration(1) == 50
                        masterStruct(i).trialByTrial(j).blockType = 18;
                    end
                end
            end
        end
    end
    if floor(masterStruct(i).phase) == 9
        for j = 1:size(masterStruct(i).trialByTrial,2)
            if masterStruct(i).trialByTrial(j).blockFlag == 1
                if masterStruct(i).trialByTrial(j).raw.rewardProbabilityPush(1) == 900 && masterStruct(i).trialByTrial(j).raw.rewardProbabilityPull(1) == 900
                    if masterStruct(i).trialByTrial(j).raw.rewardVolumePull == 35
                        masterStruct(i).trialByTrial(j).blockType = 25;
                    end
                    if masterStruct(i).trialByTrial(j).raw.rewardVolumePush == 35
                        masterStruct(i).trialByTrial(j).blockType = 26;
                    end
                end
                if masterStruct(i).trialByTrial(j).raw.rewardProbabilityPush(1) == 700 && masterStruct(i).trialByTrial(j).raw.rewardProbabilityPull(1) == 700
                    if masterStruct(i).trialByTrial(j).raw.rewardVolumePull <= 35
                        masterStruct(i).trialByTrial(j).blockType = 33;
                    end
                    if masterStruct(i).trialByTrial(j).raw.rewardVolumePush <= 35
                        masterStruct(i).trialByTrial(j).blockType = 34;
                    end
                end
                if masterStruct(i).trialByTrial(j).raw.rewardProbabilityPush(1) == 450
                    masterStruct(i).trialByTrial(j).blockType = 28;
                end
                if masterStruct(i).trialByTrial(j).raw.rewardProbabilityPull(1) == 450
                    masterStruct(i).trialByTrial(j).blockType = 27;
                end
                if masterStruct(i).trialByTrial(j).raw.rewardProbabilityPush(1) == 300
                    masterStruct(i).trialByTrial(j).blockType = 30;
                end
                if masterStruct(i).trialByTrial(j).raw.rewardProbabilityPull(1) == 300
                    masterStruct(i).trialByTrial(j).blockType = 29;
                end
                if masterStruct(i).trialByTrial(j).raw.rewardProbabilityPush(1) == 225
                    masterStruct(i).trialByTrial(j).blockType = 32;
                end
                if masterStruct(i).trialByTrial(j).raw.rewardProbabilityPull(1) == 225
                    masterStruct(i).trialByTrial(j).blockType = 31;
                end
                if masterStruct(i).trialByTrial(j).raw.rewardProbabilityPush(1) == 350
                    masterStruct(i).trialByTrial(j).blockType = 35;
                end
                if masterStruct(i).trialByTrial(j).raw.rewardProbabilityPull(1) == 350
                    masterStruct(i).trialByTrial(j).blockType = 36;
                end
                if masterStruct(i).trialByTrial(j).raw.rewardProbabilityPush(1) == 175
                    masterStruct(i).trialByTrial(j).blockType = 37;
                end
                if masterStruct(i).trialByTrial(j).raw.rewardProbabilityPull(1) == 175
                    masterStruct(i).trialByTrial(j).blockType = 38;
                end
                if masterStruct(i).trialByTrial(j).raw.rewardProbabilityPush(1) == 117
                    masterStruct(i).trialByTrial(j).blockType = 39;
                end
                if masterStruct(i).trialByTrial(j).raw.rewardProbabilityPull(1) == 117
                    masterStruct(i).trialByTrial(j).blockType = 40;
                end
                if masterStruct(i).trialByTrial(j).raw.rewardProbabilityPush(1) == 467
                    masterStruct(i).trialByTrial(j).blockType = 41;
                end
                if masterStruct(i).trialByTrial(j).raw.rewardProbabilityPull(1) == 467
                    masterStruct(i).trialByTrial(j).blockType = 42;
                end
                if masterStruct(i).trialByTrial(j).raw.rewardProbabilityPush(1) == 233
                    masterStruct(i).trialByTrial(j).blockType = 43;
                end
                if masterStruct(i).trialByTrial(j).raw.rewardProbabilityPull(1) == 233
                    masterStruct(i).trialByTrial(j).blockType = 44;
                end
                if masterStruct(i).trialByTrial(j).raw.rewardProbabilityPush(1) == 88
                    masterStruct(i).trialByTrial(j).blockType = 45;
                end
                if masterStruct(i).trialByTrial(j).raw.rewardProbabilityPull(1) == 88
                    masterStruct(i).trialByTrial(j).blockType = 46;
                end
            end
        end
    end
end


%add block number info.
for i = 1:size(masterStruct,2)
    if masterStruct(i).phase > 5
        for j = 1:size(masterStruct(i).trialByTrial,2)
            if masterStruct(i).trialByTrial(j).blockFlag == 1
                masterStruct(i).trialByTrial(j).blockNumber = masterStruct(i).trialByTrial(j).raw.blockNumber(1);
            end
        end
    end
end
%%
%add block length to blockflag row
for i = 1:size(masterStruct,2)
    if masterStruct(i).phase > 5
        blockNumber = 1;
        lastBlockFlag = 0;
        for j = 1:size(masterStruct(i).trialByTrial,2)
            if j == 1
                masterStruct(i).trialByTrial(j).blockLength = 0;
                lastBlockFlag = j;
            end
            if (j < size(masterStruct(i).trialByTrial,2)) && (j > 1)
                if masterStruct(i).trialByTrial(j).blockFlag == 1
                    masterStruct(i).trialByTrial(lastBlockFlag).blockLength = masterStruct(i).trialByTrial(j-1).trialWithinBlock;
                    lastBlockFlag = j;
                end
            end
            if j == size(masterStruct(i).trialByTrial,2)
                if masterStruct(i).trialByTrial(j).blockFlag == 1
                    masterStruct(i).trialByTrial(lastBlockFlag).blockLength = masterStruct(i).trialByTrial(j-1).trialWithinBlock;
                    masterStruct(i).trialByTrial(j).blockLength = 1;
                    lastBlockFlag = j;
                else
                    masterStruct(i).trialByTrial(lastBlockFlag).blockLength = masterStruct(i).trialByTrial(j).trialWithinBlock;
                end
            end
        end
    end
end


%extract info to an "animalStruct"
animalStruct = [];
for i = 1:size(animalIDs,1)
    if masterStruct(i).phase > 5
        blocksArray = [];
        for j = 1:size(masterStruct,2)
            if masterStruct(j).animalID == animalIDs(i,1)
                for k = 1:size(masterStruct(j).trialByTrial,2)
                    if masterStruct(j).trialByTrial(k).blockFlag == 1
                        blocksArray = [blocksArray; masterStruct(j).trialByTrial(k).blockType masterStruct(j).trialByTrial(k).blockLength];
                    end
                end
            end
        end
        animalStruct(i).animalID = animalIDs(i,1);
        animalStruct(i).blocksArray = blocksArray;
    end
end


%count number of each block
for i = 1:size(animalStruct,2)
    for j = 1:24
        blocksFieldName = strcat('blocks',string(j));
        trialsArrayFieldName = strcat('trialsArray',string(j));
        trialsSumFieldName = strcat('trialsSum',string(j));
        indicesNeeded = find(animalStruct(i).blocksArray == j);
        trialsArray = [];
        for k = 1:size(animalStruct(i).blocksArray,1)
            if animalStruct(i).blocksArray(k,1) == j
                trialsArray = [trialsArray; animalStruct(i).blocksArray(k,2)];
            end
        end
        trialsSum = sum(trialsArray);
        animalStruct(i).(blocksFieldName) = size(indicesNeeded,1);
        animalStruct(i).(trialsArrayFieldName) = trialsArray;
        animalStruct(i).(trialsSumFieldName) = trialsSum;
    end
end

%extractBouts;
