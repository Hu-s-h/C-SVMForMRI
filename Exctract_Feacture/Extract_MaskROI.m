function [Mask, Seg, ROISeg] = Extract_MaskROI(segPath,templatePath,ROIList,removeROIList)

%% Input:
    % segPath, Brain anatomical area map
    % ROIList, area of interest number,if empty, all area
    % removeROIList, area to remove
    % templatePath, result save path
%% Output:
    % Mask, mask area
    % Seg, All areas
    % ROISeg, area of interest
if nargin<4  % number of input parameters
    removeROIList = [];   
end
if nargin<3  
    ROIList = [];   
end

if ~exist(templatePath,'dir')
    mkdir(templatePath);
end
%% read .nii file
Nii=load_nii(segPath);
Segmentation=double(squeeze(Nii.img));
%% Get mask¡¢seg¡¢ROIseg
origin = [91 126 72];
[ Mask, Seg, ROISeg ] = GenerateMaskRemoveRegion( Segmentation,ROIList,removeROIList );
Nii=make_nii(Mask,[],origin);
save_nii(Nii,[templatePath,filesep,'Mask.nii.gz'])
Nii=make_nii(Seg,[],origin);
save_nii(Nii,[templatePath,filesep,'Seg.nii.gz']);
Nii=make_nii(ROISeg,[],origin);
save_nii(Nii,[templatePath,filesep,'ROISeg.nii.gz']);
end

