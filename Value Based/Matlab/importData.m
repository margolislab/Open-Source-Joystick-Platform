%IMPORT DATA
%This code generates a struct in which each entry is a behavioral session.

function [masterStruct] = importData(filePath)
%to run, input [masterStruct] = importdata(***WRITE YOUR filePath HERE IN
%''***) into Command Window.

masterStruct = [];

%Load in files
filePath = convertStringsToChars(filePath);
cd(filePath);
files = dir('*.txt');
for i = 1:length(files)
    masterStruct(i).fileName = files(i).name;
    fileEdit = extractAfter(masterStruct(i).fileName, 'Capture ');
    masterStruct(i).date = extractBefore(fileEdit,' ');
    fileEdit = extractAfter(fileEdit, ' ');
    masterStruct(i).time = extractBefore(fileEdit,'_');
    fileEdit = extractAfter(fileEdit,'_');
    masterStruct(i).box = str2num(extractBefore(fileEdit,'_'));
    fileEdit = extractAfter(fileEdit,'_');
    masterStruct(i).animalID = str2num(extractBefore(fileEdit,'_'));
    fileEdit = extractAfter(fileEdit,'_');
    masterStruct(i).phase = str2num(extractBefore(fileEdit,'_'));
    fileEdit = extractAfter(fileEdit,'_');
    masterStruct(i).sessionNumber = str2num(extractBefore(fileEdit,'.txt'));
    myData = importdata(files(i).name); 
    masterStruct(i).raw = array2table(myData(1).data);
    masterStruct(i).raw.Properties.VariableNames = myData(1).colheaders;
    fprintf('%d/%d\n',i,length(files))
end

[masterStruct] = sortByTrial(masterStruct);
[masterStruct] = extractVars(masterStruct);
for i = 1:size(masterStruct,2)
    masterStruct(i).times = masterStruct(i).raw.runTime((size(masterStruct(i).raw,1)-1))
end


