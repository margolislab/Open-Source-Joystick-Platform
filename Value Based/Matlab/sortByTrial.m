%test script
function [masterStruct] = sortByTrial(masterStruct)



for k = 1:(size(masterStruct,2))

    %generate trial-by-trial struct
    masterStruct(k).trialByTrial = [];

    %check if table has FLAGS
    hasFlags = strcmp('flags',masterStruct(k).raw.Properties.VariableNames);
    hasFlags = sum(hasFlags);

    %extract data based on FLAGS
    if hasFlags >=1
        try
            flags = find((masterStruct(k).raw.flags == 1));
            %flags = [1; flags];
            for i = 1:size(flags,1)
                masterStruct(k).trialByTrial(i).trialNumber = i;
                if i < size(flags,1)
                    masterStruct(k).trialByTrial(i).raw = masterStruct(k).raw((flags(i,1)):(flags(i+1,1)-1),:);
                else
                    masterStruct(k).trialByTrial(i).raw = masterStruct(k).raw((flags(i,1)):(end-1),:);
                end
            end
        catch
            warning('Problem using function.  Recheck this entry.');
            fprintf('%d/%d\n',k,size(masterStruct,2))
        end
    end
    fprintf('%d/%d\n',k,size(masterStruct,2))
end