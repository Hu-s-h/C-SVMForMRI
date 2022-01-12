function [ClusterMap] =RefineCluster(ClusterMap,Seg,Connectivity, Option)
    Dim=size(ClusterMap);
    DimLength=length(Dim);
%     UseParallel=1;
%     Connectivity = 26;
    ClusterNum=length(unique(ClusterMap)); 
    ClusterLabelList=unique(ClusterMap); 
    IndList1=cell(ClusterNum,1); 
    BW0=ones(Dim);
    numCores=2; % Use 2 cores for parallel operations
    if Option.UseParallel==1 % Parallel operation
        try
            delete(gcp('nocreate'))
            fprintf('Close all open pools\n');
            parpool close; 
        catch
            % ignore any errors
        end
        fprintf('Parallelism turned on, %d cores are being used\n', numCores);
        parpool('local',numCores);
       %%Select the largest part of each cluster
       parfor i=1:ClusterNum
           Label=ClusterLabelList(i); 
           CC=bwconncomp(ClusterMap==Label,Connectivity); 
           CompNum=CC.NumObjects; 
           if CompNum==1 
               IndList1{i}=CC.PixelIdxList{1}; 
           else
               
               PixNumLength=zeros(CompNum,1);
               for j=1:CompNum
                   PixNumLength(j)=length(CC.PixelIdxList{j});
               end
               
               OptPos=find(PixNumLength==max(PixNumLength));
               
               IndList1{i}=CC.PixelIdxList{OptPos(1)};
           end
       end
       IndList2=[];
       for i=1:ClusterNum
           IndList2=[IndList2;IndList1{i}]; 
       end
       BW0(IndList2)=0; 
       CC=bwconncomp(BW0,Connectivity); 
       LeftCompNum=CC.NumObjects; 
       NewClusterPartArray=cell(LeftCompNum,1);
       NewClusterIndArray =cell(LeftCompNum,1); 

       for i=1:LeftCompNum
          Ind=CC.PixelIdxList{i}; 
          Sub=IndToSubND(Dim,Ind);
          if size(Sub,1)==1 
              Min=Sub;   
              Max=Sub;
          else
              Min=min(Sub);
              Max=max(Sub);
          end
          %% Delineate the rectangular range of the connected area
          Min=max([Min-1;ones(1,DimLength)]);
          Max=min([Max+1;Dim]);
          switch DimLength
              case 2
                  ClusterPart=ClusterMap(Min(1):Max(1),Min(2):Max(2));
                  SegPart=Seg(Min(1):Max(1),Min(2):Max(2));
                  UnClearPart=BW0(Min(1):Max(1),Min(2):Max(2));
              case 3
                  SegPart=Seg(Min(1):Max(1),Min(2):Max(2),Min(3):Max(3)); 
                  ClusterPart=ClusterMap(Min(1):Max(1),Min(2):Max(2),Min(3):Max(3));
                  UnClearPart=BW0(Min(1):Max(1),Min(2):Max(2),Min(3):Max(3));
              case 4
                  SegPart=Seg(Min(1):Max(1),Min(2):Max(2),Min(3):Max(3),Min(4):Max(4));
                  ClusterPart=ClusterMap(Min(1):Max(1),Min(2):Max(2),Min(3):Max(3),Min(4):Max(4));
                  UnClearPart=BW0(Min(1):Max(1),Min(2):Max(2),Min(3):Max(3),Min(4):Max(4));
              otherwise 
                  error('Unsupported dimension')
          end
          ClearClusterPart=double(ClusterPart).*double(1-UnClearPart); 
          ClusterPartLin=ClusterPart(:);

          ClearLabelList=unique(ClusterPartLin(logical(1-UnClearPart(:))));
          ClearLabelNum=length(ClearLabelList); 
          UnClearPointNum=sum(UnClearPart(:)); 
          if ClearLabelNum==1 
              NewLabelList=ClearLabelList(1)*ones(UnClearPointNum,1); 
          else
              NewLabelList=-1*ones(UnClearPointNum,1);
              CostList=inf*ones(UnClearPointNum,1);
              for j=1:ClearLabelNum 
                  ClearLabel=ClearLabelList(j);
                  ClearLabelSeg=SegPart(find(ClusterPartLin==ClearLabel,1,'first'));
                  BWPart=ClearClusterPart==ClearLabel; 
                 
                  DistMap=bwdist(BWPart); 
                  DistUnClearPointList=DistMap(logical(UnClearPart(:))); 
                  SegUpClearPointList =SegPart(logical(UnClearPart(:))); 
                  if strcmp(Option.SLIC_type,'ac-SLIC')
                    DistUnClearPointList(SegUpClearPointList ~=ClearLabelSeg )=inf;
                  end
                  NewLabelList(DistUnClearPointList<CostList)=ClearLabel;
                  CostList(DistUnClearPointList<CostList)=DistUnClearPointList(DistUnClearPointList<CostList);
              end
          end
          while sum(NewLabelList==-1)>0
              disp(['Still some point is not proper refined , the number is ',num2str(i),' and points number are ',num2str(sum(NewLabelList==-1))])
              NfpInd1 = find(NewLabelList==-1);
              NfpInd2 = find(UnClearPart==1);
              NfpInd = NfpInd2(NfpInd1);
              Dim1 = size(UnClearPart);
              NfpSub = IndToSubND(Dim1,NfpInd);
              if sum(UnClearPart(NfpInd))~= length(NfpInd)
                  error('error')
              end
              NfpSeg = SegPart(NfpInd);
              NfpShiftList = PositionShift( ones(length(Dim1),1),0 );
              for c=1:size(NfpSub,1)
                  [NNfpInd,NNfpPoint]=NeigbInsidePointIndex(NfpSub(c,:),Dim1,NfpShiftList); 
                  NNfpLabel = ClusterPart(NNfpInd);
                  NNfpSeg = SegPart(NNfpInd);
                  fInd = find(NNfpSeg == NfpSeg(c));
                  if isempty(fInd)
                      USegLabel = unique(NNfpSeg);
                      segcounts = histc(NNfpSeg,USegLabel);
                      NfpSeg(c) = USegLabel(find(max(segcounts),1,'first'));
                      fInd = find(NNfpSeg == NfpSeg(c));
                  end    
                  SaNNfpLabel = NNfpLabel(fInd);
                  USaNNfpLabel = unique(SaNNfpLabel);
                  counts = histc(SaNNfpLabel,USaNNfpLabel);
                  MaxLabel1 = USaNNfpLabel(find(max(counts),1,'first'));
                  SaInd = find(SaNNfpLabel == MaxLabel1,1,'first');
                  if CostList(NfpInd1(c))>sum((NNfpPoint(fInd(SaInd))-NfpSub(c)).^2,2)
                    NewLabelList(NfpInd1(c)) = MaxLabel1;
                    CostList(NfpInd1(c)) = sum((NNfpPoint(fInd(SaInd))-NfpSub(c)).^2,2);
                  end
              end
          end 
          NewClusterPartArray{i}=NewLabelList;
          IndPart=find(UnClearPart==1);
          SubPart=IndToSubND(size(UnClearPart),IndPart);
          SubAll=SubPart+repmat(Min,[size(SubPart,1),1])-1;
          IndAll =SubToIndND(Dim,SubAll);
          NewClusterIndArray{i}=IndAll;
       end
       disp('Complete the Connectivity Zone Assignment section!')
       NewClusterAll=[];
       NewIndAll    =[];
       for i=1:LeftCompNum
           NewClusterAll=[NewClusterAll;NewClusterPartArray{i}];
           NewIndAll    =[NewIndAll;NewClusterIndArray{i}];
       end
       ClusterMap(NewIndAll)=NewClusterAll;

       % close pool
       delete(gcp('nocreate'))

    else
        disp('Only supports parallel operations')    

    end
end