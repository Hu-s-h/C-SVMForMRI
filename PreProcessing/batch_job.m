%% Corrected MRI image preprocessing can be directly processed using this file
%% Otherwise use batchPreProcessing.m for AC-PC correction post-processing

dirname=uigetdir(pwd,'Please select the MRI file path');
dirinfo=dir(dirname);
dirinfo(1:2)=[];
[prefile,prefile_path] = uigetfile({'*.mat';'*.*'},'Please select a preset file (usually *.mat file)');
[tem_file,tem_image_path] = uigetfile({'*.nii';'*.nii.gz';'*.*'},'Please select the registration template path');
tem_image = {[[tem_image_path tem_file] ',1']};

%% Get the path directory of different types of subjects
targetdir={};
for i=1:length(dirinfo)
    if dirinfo(i).isdir==1 && ismember(dirinfo(i).name,["AD" "CN" "MCIc" "MCInc" "MCI"])
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
%% Get all image files in the directory
for i=1:length(targetdir) 
    targetMRI{i}={};
    filelist=dir([targetdir{i} filesep 'ADNI_*_S_*_I*.nii']);
    for j=1:length(filelist)
        targetMRI{i}=[targetMRI{i};[targetdir{i} filesep filelist(j).name] ',1'];
    end
    matlabbatch{i}.cfg_basicio.run_ops.runjobs.jobs = {[prefile_path,prefile]};
    matlabbatch{i}.cfg_basicio.run_ops.runjobs.inputs{1}{1}.indir = targetdir(i);
    matlabbatch{i}.cfg_basicio.run_ops.runjobs.inputs{1}{2}.innifti = targetMRI{i};
    matlabbatch{i}.cfg_basicio.run_ops.runjobs.inputs{1}{3}.innifti = tem_image;
    matlabbatch{i}.cfg_basicio.run_ops.runjobs.save.dontsave = false;
    matlabbatch{i}.cfg_basicio.run_ops.runjobs.missing = 'error';

end

%% Run batch
spm_jobman('run',matlabbatch);