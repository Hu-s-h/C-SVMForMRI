function [ClusterMap]=MergeSmallRegions(ClusterMap,Seg,Option)
    % This function is used to remove fragmented small areas
    if strcmp(Option.SLIC_type,'ac-SLIC')
        Dim=size(ClusterMap);
        LabelList=unique(ClusterMap(:));
        LabelList=sort(LabelList);
        if LabelList(1)==-1
            LabelList(1)=[];
        end
        LabelNum=length(LabelList);
        corrLabel=-1*ones(LabelNum,1);
        for i=1:length(LabelList)
            corrLabel(i)=unique(Seg(ClusterMap==LabelList(i)));
        end
%         RemoveLabel=[];
        for i=1:length(LabelList)
%             if ismember(LabelList(i),RemoveLabel)
%                 continue
%             end
            CurrLabel=[];
            Vnum=sum(ClusterMap(:)==LabelList(i));
            CurrLabel=[CurrLabel;LabelList(i)];
            if Vnum<1000
                CurrLabel=[CurrLabel;LabelList(corrLabel==corrLabel(i))];
                CenterPos=[];
                for j=1:length(CurrLabel)
                    Label=CurrLabel(j);
                    Ind=find(ClusterMap==Label);
                    Sub=IndToSubND(Dim,Ind);
                    MeanSub=[];
                    if size(Sub,1)>1
                        MeanSub=round(mean(Sub));
                    else
                        MeanSub=(Sub);
                    end
                    if ClusterMap(SubToIndND(Dim,MeanSub))==Label
                        CenterPos=[CenterPos;MeanSub];
                    else
                        DistList=sum((Sub-repmat(mean(Sub),[size(Sub,1),1])).^2,2);
                        MinDis=min(DistList);
                        MinDisPos=find(DistList==MinDis);
                        MinDisPos=MinDisPos(1);
                        CenterPos=[CenterPos;Sub(MinDisPos,:)];
                    end
                end
                DistList=zeros(length(CenterPos)-1,1);
                for j=2:length(CenterPos)
                    DistList(j-1)=sum((CenterPos(1,:)-CenterPos(j,:)).^2);
                end
                Label2=CurrLabel(find(DistList==min(DistList),1)+1);
                ClusterMap(ClusterMap==LabelList(i))=Label2;
            end
        end
        
        % Reset label
        LabelList=unique(ClusterMap(:));
        LabelList=sort(LabelList);
        if LabelList(1)==-1
            LabelList(1)=[];
        end
        LabelNum=length(LabelList);
        for i=1:LabelNum
            Label=LabelList(i);
            ClusterMap(ClusterMap==Label)=i;
        end
    else
        
    end
end