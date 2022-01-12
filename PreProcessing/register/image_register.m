
%% register the original image
clc;
RegExeFileName='reg_aladin.exe';
RegExeFilePath=fullfile('D:\DiffusionKit\',RegExeFileName);
if ~exist('RegExeFilePath','file')==0
   disp(["The default path does not exist ",RegExeFileName,", please reselect the file."]);
   [regfile,regfile_path] = uigetfile({'reg_aladin.exe'},'Please select a file');
   RegExeFilePath = [regfile_path,regfile];
end
[temfile,temfile_path]= uigetfile({'*.nii'},'Please select a template file'); % MNI152
templateFile = [temfile_path,temfile];
TemplatePara=[' ','-ref',' ',templateFile];%Template file
dirname = uigetdir(pwd,'Please select the MRI file path');%Set open path
dirinfo=dir(dirname);
dirinfo(1:2)=[];
%% Get the path directory of different types of subjects
targetdir={};
for i=1:length(dirinfo)
    if dirinfo(i).isdir==1 && ismember(dirinfo(i).name,["AD" "CN" "MCI" "SMC" "EMCI" "LMCI"])
        currname = [dirname filesep dirinfo(i).name];
        currinfo=dir(currname);
        currinfo(1:2)=[];
        flag=1;
        for j=1:length(currinfo) 
            if currinfo(j).isdir==1 && ismember(currinfo(j).name,["TestingSet" "TrainingSet"])
                flag=0;
                targetdir=[targetdir,[currname filesep currinfo(j).name]];
            end
        end
        if flag==1
            targetdir=[targetdir,[dirname filesep dirinfo(i).name]];
        end
    end 
end
err_fileList = {};
%% Get all image files in the directory
for i=1:length(targetdir) 
    filelist=dir([targetdir{i} filesep 'ADNI_*_S_*_I*.nii']);
    for j=1:length(filelist)
        dirsplit = strsplit(filelist(j).name,'.');
        fileName = dirsplit{1};
        filefolder=[targetdir{i} filesep 'Reg']; 
        if exist(filefolder,'dir')==0 
            mkdir(filefolder);  
        end
        SourcePara=[' ','-flo',' ',[targetdir{i} filesep filelist(j).name]];% source image
        ResultPara=[' ','-res',' ',[filefolder filesep ['r',filelist(j).name]]];% processed image
        AffinePara=[' ','-aff',' ',[filefolder filesep ['r',fileName,'_Affine.txt']]];% Affine result after processing
        Cmd=[RegExeFilePath ,TemplatePara ,SourcePara, ResultPara, AffinePara];
        try
            system(Cmd);
            disp([filelist(j).name,'Processing is complete!'])
        catch
            err_fileList = [err_fileList,[targetdir{i} filesep filelist(j).name]];
            disp([filelist(j).name,'Processing error!'])
        end
    end
end



