% [filepath1,flodpath1]= uigetfile({'*.nii';'*.nii.gz';'*.*'},'Please select a template path'); %ROISeg
% SegPath=[flodpath1 filepath1];
% Nii=load_nii(SegPath);
% Seg=Nii.img;
% [filepath2,flodpath2] = uigetfile({'*.nii';'*.nii.gz';'*.*'},'Please select a template path');
% Path=[flodpath2 filepath2];
% Nii = load_nii(Path);
% nonZeroClusterMap = Nii.img;
% labels=unique(nonZeroClusterMap);
% if labels(1)==0
%     labels(1)=[];
% end
% a={};
% lindlist=[];
% for i=1:length(labels)
%     seg_label = unique(Seg(nonZeroClusterMap==labels(i)));
%     if length(seg_label)>1
%         lindlist=[lindlist;find(nonZeroClusterMap==labels(i))];
%         nonZeroClusterMap(nonZeroClusterMap==labels(i))=0;
%     end
% %     result_SLIC=[result_SLIC;{labels(i) seg_label}];
% end
% newlabels=unique(nonZeroClusterMap);
% % newlabels=sort(newlabels);
% if newlabels(1)==0
%     newlabels(1)=[];
% end
% for i=1:length(newlabels)
%     nonZeroClusterMap(nonZeroClusterMap==newlabels(i))=i;
% end
labels=unique(nonZeroClusterMap);
result_SLIC={};
for i=1:length(labels)
    l1 = length(find(nonZeroClusterMap==labels(i)));
    seg_label = unique(Seg(nonZeroClusterMap==labels(i)));
    result_SLIC=[result_SLIC;{labels(i) seg_label l1}];
end