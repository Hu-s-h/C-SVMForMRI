% SegPath Brain anatomical area map
% SegPath = 'D:\MRI_ToolsAndData\Data\MRI_Alg_hsh\Template\groupTemplate\AAL\ch2_Atlas.nii';
SegPath = 'D:\MRI_ToolsAndData\Data\MRI_Alg_hsh\Template\groupTemplate\AAL\aal.nii';
% SegPath = 'D:\MRI_ToolsAndData\Data\TestData\MySLIC\ADNI_ac_SLIC_templete_new\ClusterMap.nii.gz';
% ROIs, area of interest number,if empty, all area
% ROIs=[37,38,41,42]; 
ROIs=[];
% RemoveROIs, area to remove
RemoveROIs=[];
% folder_template is result save path
folder_template = uigetdir(pwd,'Please enter the template result save path');

% Extract Mask, ROI
[Mask, Seg, ROISeg] = Extract_MaskROI(SegPath,folder_template,ROIs,RemoveROIs);

% read the preprocessed .nii file path
dirname=uigetdir(pwd,'Please select the path where MRI images are stored');
dirinfo=dir(dirname);
dirinfo(1:2)=[];
% Get the path directory of different types of subjects
targetdir={};
for i=1:length(dirinfo)
    if dirinfo(i).isdir==1 & ismember(dirinfo(i).name,["AD" "MCI" "MCIc" "MCInc" "CN"])
        currname = [dirname filesep dirinfo(i).name];
        currinfo = dir(currname);
        currinfo(1:2)=[];
        flag=1;
%         for j=1:length(currinfo)
%             if currinfo(j).isdir==1 & ismember(currinfo(j).name,["TestingSet" "TrainingSet"])
%                 flag=0;
%                 targetdir=[targetdir,[currname filesep currinfo(j).name]];
%             end
%         end
        if flag==1
            targetdir=[targetdir,[dirname filesep dirinfo(i).name]];
        end
    end 
end
% feature matrix save path
folder_mat = uigetdir(pwd,'Please enter the feature matrix save path');
if ~exist(folder_mat,'dir')
    mkdir(folder_mat);
end

VoxelNum=sum(Mask(:)==1);

% AD CN MCI
GroupNum=length(targetdir);
SubImageList = cell(GroupNum,1);
for G=1:GroupNum
    GroupName=targetdir{G};
    dirsplit = strsplit(GroupName,'\');
    dirnew = dirsplit{end};
%     if ismember(dirnew,["TestingSet" "TrainingSet"])
%         dirnew=[dirsplit{end-1} '_' dirnew];
%     end
    targetdir{G}=[targetdir{G} filesep 'rmwp1'];
    Dir=dir([targetdir{G} filesep  'rmwp1ADNI_*_S_*_I*.nii']);
    SubNum=length(Dir);
    disp([dirnew,'  Subject Number=',num2str(SubNum)]);
    FeatureMatrix=zeros(SubNum,VoxelNum);
%     FeatureLabel=ones(SubNum,1);
%     if ~strcmp(dirnew,'AD')
%         FeatureLabel=-1*FeatureLabel;
%     end
    SubImageList{G}={};
    for i=1:SubNum
        SubName=Dir(i).name;
        FeatureFieldPath=[targetdir{G},filesep,SubName];
        Nii=load_nii(FeatureFieldPath);
        FeatureField=Nii.img;
        SubImageList{G} = [SubImageList{G};FeatureField];
        [ FeatVec ] = ExtractFeatVecFromVolume( FeatureField,Mask );
        FeatureMatrix(i,:)=FeatVec;
        fdim = size(FeatureField);
        
    end
    SavePath=[folder_mat,filesep,dirnew,'.mat'];
    save(SavePath,'FeatureMatrix') 
%     SavePath=[folder_mat,filesep,dirnew,'Label.mat'];
%     save(SavePath,'FeatureLabel')
end
        
    