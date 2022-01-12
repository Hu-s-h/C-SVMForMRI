function [GroupLassoOpt]=SetGroupLassoOptions(Path,ClassOpt,XFeature,YLabel)
% Path='D:\MRI_ToolsAndData\Data\newdata\My_method\SPM_Template';
    templateType=ClassOpt.templateType;
    if strcmp(templateType,'AAL')
        SegPath = fullfile(Path,'ROISeg.nii.gz');
        MaskPath = fullfile(Path,'Mask.nii.gz');
        while ~exist(SegPath,'file') || ~exist(MaskPath,'file')
            Path = uigetdir(pwd,'ROISeg and Mask are not found in the file path, please re-select the path');
            SegPath=fullfile(Path,'ROISeg.nii.gz');
            MaskPath=fullfile(Path,'Mask.nii.gz');
            if Path == 0
                error('You have not selected any path')
            end
        end
    elseif strcmp(templateType,'SLIC')
        ClusterMapPath = fullfile(Path,'ClusterMap.nii.gz');
        while ~exist(ClusterMapPath,'file')
            Path = uigetdir(pwd,'ClusterMap is not found in the file path, please select the path again');
            ClusterMapPath = fullfile(Path,'ClusterMap.nii.gz');
            if Path == 0
                error('You have not selected any path')
            end
        end
        if exist(ClusterMapPath,'file')
            SegPath = ClusterMapPath;
            ClusterMapNii = load_nii(ClusterMapPath);
            ClusterMap = double(squeeze(ClusterMapNii.img));
            Mask=double(ClusterMap ~=0);
            Nii=make_nii(Mask,[]);
            MaskPath = fullfile(Path,'Mask.nii.gz');
            save_nii(Nii,MaskPath)                   
        end
    else
        error('Only AAL templates and SLIC templates are supported')
    end     

    Seg0=load_nii(SegPath);
    Mask0=load_nii(MaskPath);
    Seg=Seg0.img;
    Mask=Mask0.img;
    ROI=unique(Seg(:));
    NPPos=find(ROI<=0);
    if ~ isempty(NPPos) 
        ROI(NPPos)=[];
    end
    GroupLassoOpt= Mask_SegToGroupInf(Mask,Seg,XFeature,YLabel,ClassOpt,ROI);
    % SparsityOpt.GroupLassoOpt=GroupLassoOpt;
end