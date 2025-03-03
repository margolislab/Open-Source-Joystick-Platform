%get probs
function [choices] = getProbs(masterStruct,direction,phase,performance,mouse)
performanceBest;
%direction here is defined as the direction of the beginning trial. So 1 is
%pull -> push, 2 is push -> pull

trials = (-10:1:10)';
choices = cell(size(trials, 1), 1);

for i = 1:size(masterStruct,2)
    if floor(masterStruct(i).phase) == phase && masterStruct(i).performance >= performance && masterStruct(i).animalID == mouse
        for j = 11:size(masterStruct(i).trialByTrial, 2)
            if masterStruct(i).trialByTrial(j).blockFlag == 1 && masterStruct(i).trialByTrial(j).rewardDirection == direction
                for k = 1:size(trials, 1)
                    index = j + trials(k);
                    if index >= 1 && index <= numel(masterStruct(i).trialByTrial)
                        % Ensure choices{k} is properly initialized as an empty array
                        if isempty(choices{k})
                            choices{k} = [];
                        end
                        if isscalar(masterStruct(i).trialByTrial(index).pushPull)
                            switch masterStruct(i).trialByTrial(index).pushPull
                                case 1
                                    choices{k} = [choices{k} 1];
                                case 2
                                    choices{k} = [choices{k} 0];
                            end
                        end
                    end
                end
            end
        end
    end
end

