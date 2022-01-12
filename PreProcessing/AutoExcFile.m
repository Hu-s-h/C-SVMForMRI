clc;
%% subject information table path
filename = uigetfile({'*.xlsx';'*.xls';'*.csv';'*.*'},'Please select Subject Information table');
[subj_num,subj_txt,subj_raw]=xlsread(filename);
subj_desc = subj_raw(1,:);
subj_data = subj_raw(2:end,:);
sub_img_id = subj_data(:,1);
for i=1:length(sub_img_id)
    idl = strsplit(sub_img_id{i},'I');
    sub_img_id{i}=str2double(idl{2});
end
subj_img_id_list = cell2mat(sub_img_id); 
subj_subj_id = subj_data(:,2); 
subj_group = subj_data(:,3); 
%% source file path
dirname=uigetdir(pwd,'Please select the source file path (Note: the subfolder name should exist *_S_*):');

%% dump file path
changename=uigetdir(pwd,'Please select the dump file path');

dirinfo=dir([dirname filesep '*_S_*']);
% subj_dir={};
for i=1:length(dirinfo)
    currname1 = [dirname filesep dirinfo(i).name];
    currinfo1 = dir(currname1);
    currinfo1(1:2)=[];
    for j=1:length(currinfo1)
        currname2 = [currname1 filesep currinfo1(j).name];
        currinfo2 = dir(currname2);
        currinfo2(1:2)=[];
        for k=1:length(currinfo2)
            currname3 = [currname2 filesep currinfo2(k).name];
            currinfo3 = dir(currname3);
            currinfo3(1:2)=[];
            for m=1:length(currinfo3)
                currname4 = [currname3 filesep currinfo3(m).name];
                filelist = dir([currname4 filesep 'ADNI_*_S_*_I*.nii']);
                for n=1:length(filelist)
                    currflie = [currname4 filesep filelist(n).name];
                    str1cell = strsplit(filelist(n).name,'_I');
                    str2cell = strsplit(str1cell{end},'.nii');
                    ind = find(subj_img_id_list==str2double(str2cell{1}));
                    changefile = [changename filesep subj_group{ind} filesep filelist(n).name]; 
                    copyfile(currflie,changefile);  
                    delete(currflie);% delete source file
                end
            end
        end
    end
end