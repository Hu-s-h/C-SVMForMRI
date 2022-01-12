%% This method is used to automatically obtain important information about subjects in this part of the data set when taking part of the data (AD, MCI, CN, SMC, EMCI, LMCI) from the total set
% if isempty(strfind( CurrentSystem,'WIN'))
%     separation='/';
% else
%     separation='\';
% end
% dirname=uigetdir;
filename = uigetfile({'*.xlsx';'*.xls';'*.csv';'*.*'},'Please select Subject Information Table');
[subj_num,subj_txt,subj_raw]=xlsread(filename);
[row,column]=size(subj_raw);
dirname=uigetdir(pwd,'Please select a file path');
dirinfo=dir(dirname);
dirinfo(1:2)=[];
targetdir={};
dirnew={};
for i=1:length(dirinfo)
    if dirinfo(i).isdir==1 && (strcmp(dirinfo(i).name,'AD')|| strcmp(dirinfo(i).name,'CN')|| strcmp(dirinfo(i).name,'MCI')||strcmp(dirinfo(i).name,'EMCI')||strcmp(dirinfo(i).name,'LMCI')||strcmp(dirinfo(i).name,'SMC'))
        targetdir=[targetdir,[dirname filesep dirinfo(i).name]];
        dirnew=[dirnew,dirinfo(i).name];
    end 
end
for i=1:length(targetdir) 
    targetT1{i}={};
    imaID{i}={};
    T1path=[targetdir{i} filesep];
    filelist=dir([T1path 'ADNI_*_S_*_I*.nii']);
    for j=1:length(filelist)
        targetT1{i}=[targetT1{i};filelist(j).name];
    end
    dataInfo{i}=cell(length(targetT1{i})+1,5);
    dataInfo{i}(1,1:end)=subj_raw(1,1:5);
    for k=1:length(targetT1{i})
        s=strfind(targetT1{i}{k},'_I');
        num=str2double(targetT1{i}{k}(s+2:end-4));
        for r=2:row
            img_id = strsplit(subj_raw{r,1},'I');
            if(str2double(img_id{2}))==num
                dataInfo{i}(k+1,1:end)=subj_raw(r,1:5);
                break;
            end
        end
        imaID{i}=[imaID{i};num];
    end
    xlswrite([T1path dirnew{i} 'Info.xls'],dataInfo{i});
end
