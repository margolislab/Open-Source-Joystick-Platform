%assignSex
males = [9,12,20,25,26,29,34,37,2009,2012,2020,2025,2026,2029,2034,2037];
males = [males 1000:1050];
females = [1,2,23,27,28,21,2001,2002,2023,2027,2028,2021];
for i = 1:numel(masterStruct)
    if ismember(masterStruct(i).animalID,males)
        masterStruct(i).sex = 'M';
        masterStruct(i).sexDouble = 0;
    end
    if ismember(masterStruct(i).animalID,females)
        masterStruct(i).sex = 'F';
        masterStruct(i).sexDouble = 1;
    end
end