% batch script for AC-PC reorientation
% This script tries to set AC-PC with 2 steps.
% 1. Set origin to center (utilizing a script by F. Yamashita)
% 2. Coregistration of the image to icbm152.nii under spm/toolbox/DARTEL
% 
% Huang 19/May/2021

% %% Initialize batch
spm_jobman('initcfg');

dirname=uigetdir(pwd,'Please select the MRI file path');
dirinfo=dir(dirname);
dirinfo(1:2)=[];
%% Get the path directory of different types of subjects
targetdir={};
for i=1:length(dirinfo)
    if dirinfo(i).isdir==1 && ismember(dirinfo(i).name,["AD" "CN" "SMC" "EMCI" "LMCI" "MCI"])
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
    for j=1:size(targetMRI{i},1)
        st.vol = spm_vol(targetMRI{i}{j});
        vs = st.vol.mat\eye(4);
        vs(1:3,4) = (st.vol.dim+1)/2;
        spm_get_space(st.vol.fname,inv(vs));
    end
end
%% Prepare the SPM window
% interactive window (bottom-left) to show the progress, 
% and graphics window (right) to show the result of coregistration 
%spm('CreateMenuWin','on'); %Comment out if you want the top-left window.
spm('CreateIntWin','on');
spm_figure('Create','Graphics','Graphics','on');
matlabbatch = {};
use_num = 0;
for i=1:length(targetdir) 
    for j=1:size(targetMRI{i},1)
        use_num = use_num + 1;
        matlabbatch{use_num}.spm.spatial.coreg.estimate.ref = {'D:\MRI_ToolsAndData\Data\myAlg\Template\origalTemplate\icbm152-nliner-sym\mni_icbm152_t1_tal_nlin_sym_09c.nii,1'};
        matlabbatch{use_num}.spm.spatial.coreg.estimate.source = targetMRI{i}(j);
        matlabbatch{use_num}.spm.spatial.coreg.estimate.other = {''};
        matlabbatch{use_num}.spm.spatial.coreg.estimate.eoptions.cost_fun = 'nmi';
        matlabbatch{use_num}.spm.spatial.coreg.estimate.eoptions.sep = [4 2];
        matlabbatch{use_num}.spm.spatial.coreg.estimate.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
        matlabbatch{use_num}.spm.spatial.coreg.estimate.eoptions.fwhm = [7 7];
    end
end
%% Run batch
%spm_jobman('interactive',matlabbatch);
spm_jobman('run',matlabbatch);
