%% This method is used to automatically obtain the relevant subject 
%% information of the data in this part of the total set when 
%% some data (AD, CN, MCI) are taken from the total set
% if isempty(strfind( CurrentSystem,'WIN'))
%     separation='/';
% else
%     separation='\';
% end
dirname=uigetdir;
[subj_num,subj_txt,subj_raw]=xlsread('subj_info.xlsx');
[row,column]=size(subj_raw);
dirinfo=dir(dirname);
dirinfo(1:2)=[];
targetdir={};
dirnew={};
for i=1:length(dirinfo)
    if dirinfo(i).isdir==1 && (strcmp(dirinfo(i).name,'AD')|| strcmp(dirinfo(i).name,'CN')|| strcmp(dirinfo(i).name,'MCI'))
        targetdir=[targetdir,[dirname filesep dirinfo(i).name]];
        dirnew=[dirnew,dirinfo(i).name];
    end 
end
for i=1:length(targetdir) 
    targetT1{i}={};
    imaID{i}={};
    T1path=[targetdir{i} filesep];
    filelist=dir([T1path 'ADNI_*_S_*_I*.nii']);% Get .nii file
    for j=1:length(filelist)
        targetT1{i}=[targetT1{i};filelist(j).name];% Take out .nii file name
    end
    dataInfo{i}=cell(length(targetT1{i})+1,5);
    dataInfo{i}(1,1:end)=subj_raw(1,1:5);
    for k=1:length(targetT1{i})
        s=strfind(targetT1{i}{k},'_I');
        num=str2num(targetT1{i}{k}(s+2:end-4));% Get image ID
        for r=2:row
            if(subj_raw{r,1})==num
                dataInfo{i}(k+1,1:end)=subj_raw(r,1:5);
                break;
            end
        end
        imaID{i}=[imaID{i};num];
    end
    xlswrite([T1path dirnew{i} 'Info.xls'],dataInfo{i});% Write the subject information in the respective paths
end
