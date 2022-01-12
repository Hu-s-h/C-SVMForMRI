%% Read MMSE information from metafile information

dirname=uigetdir(pwd,'Please select the file path (note: the subfolder name should exist in the .xml file):');
dirinfo=dir([dirname filesep 'ADNI_*_S*_I*.xml']);
filename = uigetfile({'*.xlsx';'*.xls';'*.csv';'*.*'},'Please select Subject Information table');
[subj_num,subj_txt,subj_raw]=xlsread(filename);
subj_data = subj_raw(2:end,:);
sidcell = subj_data(:,1);
img_id = [];
for i=1:length(sidcell)
    img_id=[img_id;sidcell{i}];
end
cellArray = {};
cellArray{1,1}='Image Data ID';
cellArray{1,2}='MMSE';
for i=1:length(dirinfo)
    xmlname = dirinfo(i).name;
    d1split = strsplit(xmlname,'_I');
    d2split = strsplit(d1split{end},'.xml');
    curr_img_id = str2double(d2split{1});
    currname = [dirname filesep dirinfo(i).name];
    xmlDoc = xmlread(currname);   % read file  test.xml  
    %% Extract subjectIdentifier and mmse
    MMSEArray = xmlDoc.getElementsByTagName('assessmentScore');  %   Put all the visit nodes into the array VArray  
    try
        MMSE = str2double(MMSEArray.item(0).getFirstChild.getData);
    catch
        MMSE = -1;
    end
    
    if ismember(curr_img_id,img_id)
        cellArray=[cellArray;{curr_img_id,MMSE}];
    end
        
end
fsplit = strsplit(filename,'.');
dirname1=uigetdir(pwd,'Please select the file storage path:');
xlswrite([dirname1 filesep fsplit{1} 'mmse.xlsx'], cellArray);  
