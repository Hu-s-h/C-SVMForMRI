function [ GroupLassoOpt] = Mask_SegToGroupInf(Mask,Seg,XFeature,YLabel,ClassOpt,ROI)

%   This function is used to generate group sparsity related group information for the given mask and seg.

GroupLassoOpt=[];
LinMask=Mask(:);
LinSeg =Seg(:);
SegMask=LinSeg(LinMask==1);
if nargin<6  
    ROI=unique(SegMask);
else
    ROIAll=unique(SegMask);
    ROI=intersect(ROI,ROIAll);
end

VoxelNumList=zeros(length(ROI),1);
% GroupLabel = ROI(:);
GroupIndPosListArray=cell(length(ROI),1);
for i=1:length(ROI)
    VoxelNumList(i)=sum(SegMask==ROI(i));
    GroupIndPosListArray{i}=find(SegMask==ROI(i));
end

MeanVoxelNum=sum(VoxelNumList)/length(ROI);

% GroupLassoOpt.GroupLabel=SegMask;
GroupLassoOpt.GroupLabel=ROI;
GroupLassoOpt.GroupWeight=SetGroupWeight(XFeature,YLabel,ROI,GroupIndPosListArray,ClassOpt);
% GroupLassoOpt.GroupWeight=(VoxelNumList/MeanVoxelNum).^(1/2);
% GroupLassoOpt.GroupWeight=ones(length(ROI),1);
GroupLassoOpt.GroupIndListArray=GroupIndPosListArray;
GroupLassoOpt.VoxelNumList=VoxelNumList;
end