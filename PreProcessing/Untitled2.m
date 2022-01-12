%% Read files in multi-level folders
dirname=uigetdir;
dirinfo=dir(dirname);
dirinfo(1:2)=[];

%% Get the path directory of different types of subjects
targetdir={};
for i=1:length(dirinfo)
    if dirinfo(i).isdir==1 && ismember(dirinfo(i).name,["AD" "CN" "MCIc" "MCInc" "MCI"])
        currname = [dirname filesep dirinfo(i).name];
        currinfo=dir(currname);
        currinfo(1:2)=[];
        for j=1:length(currinfo) 
            if currinfo(j).isdir==1 && ismember(currinfo(j).name,["TestingSet" "TrainingSet"])
                targetdir=[targetdir,[currname filesep currinfo(j).name]];% Extract all folder names
            end
        end
    end 
end