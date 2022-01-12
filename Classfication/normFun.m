function [nl,dnl] = normFun(ClassOpt)
    nl=@(w) norm_loss(w,ClassOpt);
    dnl=@(w,thre) grad_norm_loss(w,thre,ClassOpt);
end

function nl=norm_loss(w,ClassOpt)
    if ClassOpt.isbias==1
        w1=w(1:end-1);
    else
        w1=w;
    end

    if strcmp(ClassOpt.norm_type,'l1')
        nl=sum(abs(w1));
    elseif strcmp(ClassOpt.norm_type,'l2')
        nl=norm(w1)^2/2;
    elseif strcmp(ClassOpt.norm_type,'l1/2')
        nl=sum(sqrt(abs(w1)));
    elseif strcmp(ClassOpt.norm_type,'gl')
        GroupLassoOpt=ClassOpt.GroupLassoOpt;
        GroupIndListArray=GroupLassoOpt.GroupIndListArray;
        GroupWeightList = GroupLassoOpt.GroupWeight;
%         NormList=cellfun(@(GroupIndList) norm(w1(GroupIndList))^2/2,GroupIndListArray);
        NormList=cellfun(@(GroupIndList) norm(w1(GroupIndList),2),GroupIndListArray);
        nl=GroupWeightList*NormList;
    elseif strcmp(ClassOpt.norm_type,'gl1/2')
        GroupLassoOpt=ClassOpt.GroupLassoOpt;
        GroupIndListArray=GroupLassoOpt.GroupIndListArray;
        GroupWeightList = GroupLassoOpt.GroupWeight;
        NormList = cellfun(@(GroupIndList) sqrt(sum(abs(w1(GroupIndList)))),GroupIndListArray);
        nl=GroupWeightList*NormList;
    elseif strcmp(ClassOpt.norm_type,'sgl1/2')
        GroupLassoOpt=ClassOpt.GroupLassoOpt;
        GroupIndListArray=GroupLassoOpt.GroupIndListArray;
        GroupWeightList = GroupLassoOpt.GroupWeight;
        f1 = @(x) -1/(8*GroupLassoOpt.C^3)*x.^4+3/(4*GroupLassoOpt.C)*x.^2+3*GroupLassoOpt.C/8;
        f2 = @(x) abs(x);
        nl=0;
        for g1=1:length(GroupIndListArray)
            GroupIndList=GroupIndListArray{g1};
            GroupIndList1=GroupIndList(abs(w1(GroupIndList))<GroupLassoOpt.C);
            GroupIndList2=GroupIndList(abs(w1(GroupIndList))>=GroupLassoOpt.C);
            feat1=w1(GroupIndList1);
            feat2=w1(GroupIndList2);
            n11=sum(f1(feat1));
            n12=sum(f2(feat2));
            nl=nl+GroupWeightList(g1)*sqrt(n11+n12);
        end
%         NormList = cellfun(@(GroupIndList) sqrt(sum([f1(w1(GroupIndList(abs(w1(GroupIndList))<GroupLassoOpt.C)));f2(w1(GroupIndList(abs(w1(GroupIndList))>=GroupLassoOpt.C)))])),GroupIndListArray);
%         nl=GroupWeightList*NormList;
    else  
        nl=0;
    end
end

function dnl=grad_norm_loss(w,thre,ClassOpt)
    if ClassOpt.isbias==1
        w1=w(1:end-1);
    else
        w1=w;
    end
    if strcmp(ClassOpt.norm_type,'l1')
        dnl=max(abs(w1)-thre,0).*sign(w1);
    elseif strcmp(ClassOpt.norm_type,'l2')
        dnl=w1./(1+thre);
    elseif strcmp(ClassOpt.norm_type,'l1/2')
        dnl=zeros(size(w1));
        ind = (abs(w1)>(.75*thre^(2/3))) ; 
        dnl(ind) = 2/3*w1(ind).*(1+cos(2*pi/3-2/3*acos(thre/8*(abs(w1(ind))/3).^(-3/2))));
    elseif strcmp(ClassOpt.norm_type,'gl')
        GroupLassoOpt=ClassOpt.GroupLassoOpt;
        GroupIndListArray=GroupLassoOpt.GroupIndListArray;
        GroupWeightList = GroupLassoOpt.GroupWeight;
        dnl=zeros(size(w1));
        for g1=1:length(GroupIndListArray)
            GroupIndList=GroupIndListArray{g1};
            feat=w1(GroupIndList);
            n2=norm(feat,2);
%             dnl(GroupIndList)=w1(GroupIndList)*max(norm(w1(GroupIndList))^2/2-GroupWeightList(g1)*thre,0)/(norm(w1(GroupIndList))^2/2);
            dnl(GroupIndList)=feat*max(n2-GroupWeightList(g1)*thre,0)/n2;
        end
        
    elseif strcmp(ClassOpt.norm_type,'gl1/2')
        GroupLassoOpt=ClassOpt.GroupLassoOpt;
        GroupIndListArray=GroupLassoOpt.GroupIndListArray;
        GroupWeightList = GroupLassoOpt.GroupWeight;
        dnl=zeros(size(w1));
        for g1=1:length(GroupIndListArray)
            GroupIndList=GroupIndListArray{g1};
            feat=w1(GroupIndList);
            n1=sum(abs(feat));
            dnl(GroupIndList)=sign(feat).*max(abs(feat)-thre,0)*max(sqrt(n1)-GroupWeightList(g1)*thre,0)/sqrt(n1);
        end
%         for g1=1:length(GroupIndListArray)
%             GroupIndList=GroupIndListArray{g1};
%             wg=w1(GroupIndList);
%             wg_norm=sum(abs(wg));
%             if wg_norm>(.75*(GroupWeightList(g1)*thre)^(2/3))
%                 dnl(GroupIndList)=2/3*wg_norm*(1+cos(2*pi/3-2/3*acos((GroupWeightList(g1)*thre)/8*(wg_norm/3)^(-3/2))))*max(abs(wg)-thre,0).*sign(wg);
%             end
%         end
%         for g1=1:length(GroupIndListArray)
%             GroupIndList=GroupIndListArray{g1};
%             ind = (sum(abs(w1(GroupIndList)))>(.75*(GroupWeightList(g1)*thre)^(2/3))) ; 
%             dnl(GroupIndList)=sign(w1(GroupIndList))*
%             dnl(GroupIndList)=sign(w1(GroupIndList))*max(2*sqrt(sum(abs(w1(GroupIndList))))-GroupWeightList(g1)*thre,0)/(2*sqrt(sum(abs(w1(GroupIndList)))));
%         end
    elseif strcmp(ClassOpt.norm_type,'sgl1/2')
        GroupLassoOpt=ClassOpt.GroupLassoOpt;
        GroupIndListArray=GroupLassoOpt.GroupIndListArray;
        GroupWeightList = GroupLassoOpt.GroupWeight;
        f1 = @(x) -1/(8*GroupLassoOpt.C^3)*x.^4+3/(4*GroupLassoOpt.C)*x.^2+3*GroupLassoOpt.C/8;
        f2 = @(x) abs(x);
        df1 = @(x) -1/(2*GroupLassoOpt.C^3)*x.^3+3/(2*GroupLassoOpt.C)*x;
        df2 = @(x) sign(x);
        dnl=zeros(size(w1));
%         for g1=1:length(GroupIndListArray)
%             GroupIndList=GroupIndListArray{g1};
%             GroupIndList1=GroupIndList(abs(w1(GroupIndList))<GroupLassoOpt.C);
%             GroupIndList2=GroupIndList(abs(w1(GroupIndList))>=GroupLassoOpt.C);
%             dnl(GroupIndList1)=df1(w1(GroupIndList1))*max(2*sqrt(sum(f1(w1(GroupIndList1))))-GroupWeightList(g1)*thre,0)/(2*sqrt(sum(f1(w1(GroupIndList1)))));
%             dnl(GroupIndList2)=df2(w1(GroupIndList2))*max(2*sqrt(sum(f2(w1(GroupIndList2))))-GroupWeightList(g1)*thre,0)/(2*sqrt(sum(f2(w1(GroupIndList2)))));
%         end
        for g1=1:length(GroupIndListArray)
            GroupIndList=GroupIndListArray{g1};
            GroupIndList1=GroupIndList(abs(w1(GroupIndList))<GroupLassoOpt.C);
            GroupIndList2=GroupIndList(abs(w1(GroupIndList))>=GroupLassoOpt.C);
            feat1=w1(GroupIndList1);
            feat2=w1(GroupIndList2);
            n11=sum(f1(feat1));
            n12=sum(f2(feat2));
            dnl(GroupIndList1)=df1(feat1).*max(f1(feat1)-thre,0)*max(sqrt(n11)-GroupWeightList(g1)*thre,0)/sqrt(n11);
            dnl(GroupIndList2)=df2(feat2).*max(f2(feat2)-thre,0)*max(sqrt(n12)-GroupWeightList(g1)*thre,0)/sqrt(n12);
        end
%         for g1=1:length(GroupIndListArray)
%             GroupIndList=GroupIndListArray{g1};
%             GroupIndList1=GroupIndList(abs(w1(GroupIndList))<GroupLassoOpt.C);
%             GroupIndList2=GroupIndList(abs(w1(GroupIndList))>=GroupLassoOpt.C);
%             wg1=w1(GroupIndList1);
%             wg2=w1(GroupIndList2);
%             wg_norm1=sum(f1(wg1));
%             wg_norm2=sum(f2(wg2));
%             if wg_norm1>(.75*(GroupWeightList(g1)*thre)^(2/3))
%                 dnl(GroupIndList1)=2/3*wg_norm1*(1+cos(2*pi/3-2/3*acos((GroupWeightList(g1)*thre)/8*(wg_norm1/3)^(-3/2))))*max(abs(wg1)-thre,0).*sign(wg1);
%             end
%             if wg_norm2>(.75*(GroupWeightList(g1)*thre)^(2/3))
%                 dnl(GroupIndList2)=2/3*wg_norm2*(1+cos(2*pi/3-2/3*acos((GroupWeightList(g1)*thre)/8*(wg_norm2/3)^(-3/2))))*max(abs(wg2)-thre,0).*sign(wg2);
%             end
%         end
    else  
        dnl=w1;
    end
    dnl(end+1)=w(end);
    dnl=dnl(:);
end


