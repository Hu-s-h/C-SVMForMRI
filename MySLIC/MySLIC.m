function [ ClusterMap,nonZeroClusterMap,CenterPos ] = MySLIC( ImageList,Seg,GridNumList,NeighbourList, MaxIter,Option)
    %% ImageList, All subject images
    %% Seg, registered AAL template --> ROISeg.nii.gz from Exctract_Feacture 
    %% GridNumList, Number of grids per dimension [10,10,10]
    %% NeighbourList, Neighborhood length 3
    %% MaxIter, Maximum number of iterations
    %% Option
    
    Image = squeeze(ImageList{1});
    Seg  =squeeze(Seg);

    Dim=size(Image);
    Dim2=size(Seg);
    if ~isequal(Dim,Dim2)
        error('the size of image and segmentation is not equal')
    end
    DimLength=length(Dim);
    ImNum=length(ImageList); %Number of images
    
    if length(GridNumList)==1 
        GridNumList=GridNumList*ones(1,DimLength);
    else
        if length(GridNumList) ~= DimLength
            error('size of GridNumList is not proper');
        end
    end
    % Grid size
    GridSize=ceil(Dim./(GridNumList+1)); % S
    disp(['Number of grids per direction ==>', num2str(GridSize)])
    %% Search 2S ¡Á 2S area
    WithCentrOrNot=1;
    ShiftList1=PositionShift(2*GridSize,WithCentrOrNot );  % have central point
%     ShiftList2=PositionShift(2*GridSize,0 );               % no central point
    
    if length(NeighbourList)==1
        NeighbourList=NeighbourList*ones(1,DimLength);
    else
        if length(NeighbourList) ~= DimLength
            error('size of NeighbourList is not proper');
        end
    end
    % Get initial center point location
    Grid1DArray=cell(DimLength,1); 
    for i=1:DimLength
        Grid1DArray{i}=round(GridSize(i)*((1:GridNumList(i))'));
    end
    % Initialize cluster center
    PosList=zeros(prod(GridNumList),DimLength);
    for i=1:DimLength
        Before=prod(GridNumList(1:i-1));
        After =prod(GridNumList(i+1:end));
        Part1=repmat(reshape(Grid1DArray{i},[1,length(Grid1DArray{i})]),[After,1]);
        PosList(:,i)=repmat(Part1(:),[Before,1]);
    end
    %% Calculate gradient amplitude
    % Move the center to the seed position corresponding to the lowest gradient position in the neighborhood
    GradAmp=GradientAmp(Image);
    WithCentrOrNot=1;
%     ShiftList0 = PositionShift( NeighbourList,WithCentrOrNot );
    ShiftList0 = PositionShift( ones(1,DimLength),WithCentrOrNot );
    for i=1:size(PosList,1)
        GridPoint=PosList(i,:);
        [NInd,NPoint]=NeigbInsidePointIndex(GridPoint,Dim,ShiftList0); 
        MinGradAmp=min(GradAmp(NInd)); 
        ListInd=find(GradAmp(NInd)==MinGradAmp); 
        if length(ListInd)==1 
            PosList(i,:)=NPoint(ListInd,:); 
        else
            SpatialDistList=sum((NPoint(ListInd,:)-repmat(PosList(i,:),[length(ListInd),1])).^2,2);
            OptInd=ListInd(find(SpatialDistList==min(SpatialDistList),1,'first'));
            PosList(i,:)=NPoint(OptInd,:);
        end
    end
    %% Check whether some ROIs in the segment do not have an initial cluster center. 
    %% If not, add a center for this ROI
    [ CenterInd ] = SubToIndND( Dim,PosList ); 
    AllSegLabel=unique(Seg(:));
    AllCenterLabel=unique(Seg(CenterInd));
    NoCenterROI=setdiff(AllSegLabel,AllCenterLabel) ;
    
    for i=1:length(NoCenterROI)
        Label=NoCenterROI(i);
        Ind=find(Seg==Label);
        Points=IndToSubND(Dim,Ind);
        MeanPoint=round(mean(Points));
        if Seg(MeanPoint)==Label
            PosList=[PosList;MeanPoint];
        else
            DistList=sum((Points-repmat(MeanPoint,[size(Points,1),1])).^2,2);
            MinDist=min(DistList);
            OptPos=find(DistList==MinDist);
            PosList=[PosList;Points(OptPos(1),:)];
        end
    end
    disp(['Initialize', num2str(size(PosList,1)) ,' cluster centers'])
    CenterList=PosList;
    ClusterLabelList=[1:size(PosList,1)]';
    CenterIndList=SubToIndND(Dim,CenterList);
    CenterLabelList=Seg(CenterIndList);
    
    CenterIntenseList=zeros(size(PosList,1),ImNum);
    for i=1:ImNum
        CenterIntenseList(:,i)=ImageList{i}(CenterIndList);
    end
    ClusterMap=-1*ones(Dim);
    DistMap=inf*ones(Dim);
    KeepIter=1; 
    Iter=0; 
    PreClusterMap=ClusterMap; 
    DirectNormVector=reshape(1./(GridSize.^2),[DimLength,1]);
    % Start iteration (generally 10 times)
    while KeepIter
        Iter=Iter+1;
        t=clock;
        disp(['==>Number of iterations:',num2str(Iter), '  ,Start time:',datestr(t)]);
        for C=1:size(CenterList,1)
            Center=CenterList(C,:);
            [NInd,NPoint]=NeigbInsidePointIndex(Center,Dim,ShiftList1);
            SpatialDistList=((NPoint-repmat(Center,[length(NInd),1])).^2)*DirectNormVector;
            IntenseDistList=zeros(length(NInd),1);
            for i=1:ImNum
                IntenseDistList=IntenseDistList+sum((ImageList{i}(NInd)-CenterIntenseList(C,i)).^2,2);
            end
            IntenseDistList=IntenseDistList/ImNum;
           
            LabelDistList=zeros(length(NInd),1);
            % Do not cross anatomical boundaries
            if strcmp(Option.SLIC_type,'ac-SLIC')
                LabelDistList(Seg(NInd)~=CenterLabelList(C))=inf;
            end
            % Option.Type is used to judge whether there are significant differences between clusters
            % Determining the maximum grayscale intensity distance IntMax is not that simple, as the grayscale intensity distance can vary significantly from cluster to cluster and from image to image
            % If Option.Type==1, it means that the gray intensity distance can be calculated
            SpaMax=max(SpatialDistList);
            IntMax=max(IntenseDistList);
            if IntMax==0
                Option.Type=0;
            else
                Option.Type=1;
            end
            if Option.Type==1 % adaptive 
                DistList=LabelDistList+SpatialDistList/SpaMax+IntenseDistList/IntMax;
            else   % people set a 'm'
                DistList=IntenseDistList+SpatialDistList*(Option.m^2)+LabelDistList;
            end
            NCostList=DistMap(NInd);
            DistMap(NInd(NCostList>DistList))=DistList(NCostList>DistList); 
            ClusterMap(NInd(NCostList>DistList))=ClusterLabelList(C); 
        end
        Num_ClusterLabel = unique(ClusterMap(:));
        NoClusterROI=setdiff(ClusterLabelList,Num_ClusterLabel) ;
        disp(['The labels that are not assigned to the zone are:',num2str(NoClusterROI')])
        if ~isempty(find(Num_ClusterLabel==-1, 1))
            disp([num2str(size(CenterList,1) - length(Num_ClusterLabel) + 1),'cluster centers are removed, and the remaining ',num2str(length(Num_ClusterLabel)-1),' cluster centers'])
        else
            disp([num2str(size(CenterList,1) - length(Num_ClusterLabel)),' cluster centers are removed, and the remaining ',num2str(length(Num_ClusterLabel)),' cluster centers'])
        end
        
        if Iter>=MaxIter
            KeepIter=0;
            disp('Maximum number of iterations reached')
        end
        DifSum=sum(ClusterMap(:)~=PreClusterMap(:));
        if sum(DifSum)==0 % & sum(ClusterMap(:)==-1)==0
            KeepIter=0;
            disp('Clustering has converged.')
        else
            disp(['The voxels whose labels have changed are:',num2str(DifSum)]) % Output the number of voxels that do not have cluster centers assigned
        end
        [CenterList,CenterIndList,CenterIntenseList,ClusterMap,ClusterLabelList]=CluterToUpdateCenter(ClusterMap,ImageList);
        PreClusterMap=ClusterMap;
        % Check for unlabeled voxels
        BW=(ClusterMap==-1);
        disp(['Number of unlabeled voxels: ', num2str(sum(BW(:)==1)),' Current number of clusters: ',num2str(size(CenterList,1))])
        % assign new cluster centers to remaining voxels
        AddCenters=[];
        if sum(BW(:))>0
            CC=bwconncomp(BW); 
            
            for j=1:CC.NumObjects 
                ComponentSub=FromInd2Sub(CC.PixelIdxList{j},Dim); 
                Mean=round(mean(ComponentSub));
                Dist=sum((ComponentSub-repmat(Mean,[size(ComponentSub,1),1])).^2,2);
                if min(Dist)==0
                    NewCenter=Mean;
                    AddCenters=[AddCenters;NewCenter];
                else
                    OptInd=find(Dist==min(Dist));
                    NewCenter=ComponentSub(OptInd,:);
                    AddCenters=[AddCenters;NewCenter];
                end
            end          
        end
        % Add a new cluster center to an existing cluster center
        if ~isempty(AddCenters)
            CenterList=[CenterList;AddCenters];
            CurrentMaxClusteLabel=max(ClusterLabelList);
            ClusterLabelList=[ClusterLabelList; [CurrentMaxClusteLabel+1:CurrentMaxClusteLabel+size(AddCenters)]'];
            AddCenterIndList=SubToIndND(Dim,AddCenters);
            CenterLabelList=[CenterLabelList;Seg(AddCenterIndList)];
            AddCenterIntensityList=zeros(length(AddCenterIndList),ImNum);
            for i=1:ImNum
                AddCenterIntensityList(:,i)=ImageList{i}(AddCenterIndList);
            end
            CenterIntenseList=[CenterIntenseList;AddCenterIntensityList];
            disp(['Add ',num2str(size(AddCenters,1)),' cluster centers, the current number of clusters: ',num2str(size(CenterList,1))])
        end
    end
    %% Refinement clustering
    if ~isfield(Option,'Refine') 
        Option.Refine=1;
    end
    if ~isfield(Option,'Merge_Regions') 
        Option.Merge_Regions=1;
    end

    if Option.Refine==1
        Connectivity=Option.Connectivity; 
        Option.UseParallel=1; 
        [ClusterMap] =RefineCluster(ClusterMap,Seg,Connectivity, Option);
        if Option.Merge_Regions==1
            [ClusterMap]=MergeSmallRegions(ClusterMap,Seg,Option);
        end
        nonZeroClusterMap = ClusterMap;
        zeroLabelList = unique(nonZeroClusterMap(Seg==0));
        nonZeroClusterMap(Seg==0) = 0;
        newLabelList = unique(nonZeroClusterMap);
        newLabelList=sort(newLabelList);
        if newLabelList(1) == 0
            newLabelList(1)=[];
        end
        for m=1:length(newLabelList)
            nonZeroClusterMap(nonZeroClusterMap==newLabelList(m)) = m;
        end  
        %% save SLIC map
        SLICNii=make_nii(ClusterMap,[]);
        nonZeroSLICNii=make_nii(nonZeroClusterMap,[]);
        
        SLICdirname=uigetdir(pwd,'Please select the path to store the SLIC map');
        save_nii(SLICNii,[SLICdirname filesep 'ClusterMap.nii.gz'])
        save_nii(nonZeroSLICNii,[SLICdirname filesep 'nonZeroClusterMap.nii.gz'])
        
        ShortImageList=cell(1,1);
        ShortImageList{1}=ImageList{1};
        %% update cluster center
        [CenterList,CenterIndList,CenterIntenseList]=CluterToUpdateCenter(ClusterMap,ShortImageList);
    end
    CenterPos=CenterList;
end