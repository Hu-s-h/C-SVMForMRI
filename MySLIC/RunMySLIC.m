Option.Type = 1;
Option.Connectivity = 26; % connect neighborhood
Option.m = 1;
Option.SLIC_type='ac-SLIC'; % SLIC or ac-SLIC
MaxIter = 15; %The maximum number of iterations
NeighbourList = 3; %Neighborhood length
GridNumList = 10; % Number of grids per dimension   i.e. k cluster centers
%% select path
dirname=uigetdir;% set open path
dirinfo=dir(dirname);
dirinfo(1:2)=[];
[filepath1,flodpath1]= uigetfile({'*.nii';'*.nii.gz';'*.*'},'Please select a template path'); %ROISeg
SegPath=[flodpath1 filepath1];

%% image path
ImageListpath ={};
for i=1:length(dirinfo)
    if dirinfo(i).isdir ~=1
        ImageListpath = [ImageListpath;[dirname filesep dirinfo(i).name]];
    end
end
ImageList ={};
for i=1:length(ImageListpath)
    Nii=load_nii(ImageListpath{i});
    ImageNii=Nii.img;
    ImageList = [ImageList;ImageNii];
end
Nii=load_nii(SegPath);
Seg=Nii.img;

[ClusterMap,nonZeroClusterMap,CenterPos] = MySLIC( ImageList,Seg,GridNumList,NeighbourList, MaxIter,Option);