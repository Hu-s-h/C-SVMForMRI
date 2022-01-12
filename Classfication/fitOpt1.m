function [W,LOG] = fitOpt1(W0,X,y,ClassOpt)
    MaxIter = ClassOpt.MaxIter;
    MinIter = ClassOpt.MinIter;
    FISTAOrISTA = ClassOpt.FistaOrIsta;
    Lambda = ClassOpt.lambda;
    StepSize = ClassOpt.StepSize;
    StepSizeType = ClassOpt.StepSizeType; 
    StepIncreaseRatio=ClassOpt.StepIncreaseRatio;
    StepDecreaseRatio = ClassOpt.StepDecreaseRatio;
    MaxLineSearchStep=ClassOpt.MaxLineSearchStep;
    W_ChangeNormLimit=ClassOpt.W_ChangeNormLimit;
    W_ChangeRatioLimit=ClassOpt.W_ChangeRatioLimit;
    CostConvRatio=ClassOpt.LossConvRatio;
    [f,df] = lossFun1(X,y,ClassOpt);
    [nl,dnl]=normFun(ClassOpt);
    %% initialization
    W = W0;
    W_1 = W;
    t_1 = 1;
    grad=df(W);
    CostList=[];
    StepSizeList=[StepSize];
    for Iter=1:MaxIter
        grad=df(W);
        CostList=[CostList;f(W)+Lambda*nl(W)];
        DW = W-grad*StepSize;
        Threshold = Lambda*StepSize;
        PW=dnl(DW,Threshold);
        if StepSizeType ==1
            Cost1=f(PW)+Lambda*nl(PW);
            Cost2=f(W)+Lambda*nl(PW)+grad'*(PW-W)+(PW-W)'*(PW-W)/(2*StepSize);
            if Cost1<=Cost2
                InOrDeCrease=1;
                ChangeRatio=StepIncreaseRatio;
            else
                InOrDeCrease=2;
                ChangeRatio=StepDecreaseRatio;
            end
            PW1=PW;
            StepSize_1=StepSize;
            %% Find the best step size in increasing or decreasing direction
            for L=1:MaxLineSearchStep
                StepSize=StepSize*ChangeRatio;
                DW=W-grad*StepSize;
                Threshold = Lambda*StepSize;
                PW=dnl(DW,Threshold);
%                 PW=DW;
%                 PW(1:end-1)=max(abs(DW(1:end-1))-Threshold,0).*sign(DW(1:end-1));
                Cost1=f(PW)+Lambda*nl(PW);
                Cost2=f(W)+Lambda*nl(PW)+grad'*(PW-W)+(PW-W)'*(PW-W)/(2*StepSize);
                if Cost1<=Cost2
                    if InOrDeCrease==1 
                        StepSize=StepSize*ChangeRatio;
                        PW1=PW;
                        StepSize_1=StepSize;
                    else
                        break;
                    end
                else
                    if InOrDeCrease==1
                        PW=PW1;
                        StepSize=StepSize_1;
                        break;
                    else
                        StepSize=StepSize*ChangeRatio;
                    end
                end
                if StepSize<ClassOpt.StepSize
                    StepSize=StepSize/ChangeRatio;
                    break;
                end
            end
        end
        StepSizeList=[StepSizeList;StepSize];
        if FISTAOrISTA==1
            t=0.5*(1+(1+4*t_1^2)^0.5);
            W=W_1+(PW-W_1)*(t_1-1)/t;
            t_1=t;
        else
            W=PW;
        end
        if Iter>MinIter
            WDiffNorm=norm(W-W_1);
            if WDiffNorm <= W_ChangeNormLimit
                disp(['At Iter ',num2str(Iter,'%06d'),' W change Norm converge, ',num2str(WDiffNorm),'<',num2str(W_ChangeNormLimit)] );
                LOG=[];
                LOG.CostList = CostList;
                LOG.StepSizeList = StepSizeList;
                LOG.NonZeroFeature=ComputeNonZeroVoxel(W(1:end-1));
                break;
            end
            WRatio=WDiffNorm/norm(W);
            if WRatio<=W_ChangeRatioLimit
                disp(['At Iter ',num2str(Iter,'%06d'),' W change ratio converge, ',num2str(WRatio),'<',num2str(W_ChangeRatioLimit)] );
                LOG=[];
                LOG.CostList = CostList;
                LOG.StepSizeList = StepSizeList;
                LOG.NonZeroFeature=ComputeNonZeroVoxel(W(1:end-1));
                break;
            end
            CostDecreaseRatio = abs(CostList(Iter-1,end)-CostList(Iter,end))/CostList(Iter-1,end);
            if CostDecreaseRatio<=CostConvRatio
                disp(['At Iter ',num2str(Iter,'%06d'),' Cost decrease ratio converge, ',num2str(CostDecreaseRatio),'<',num2str(CostConvRatio)] );
                LOG=[];
                LOG.CostList = CostList;
                LOG.StepSizeList = StepSizeList;
                LOG.NonZeroFeature=ComputeNonZeroVoxel(W(1:end-1));
                break;
            end
            if Iter==MaxIter
                disp(['Reach Max Iteration ',num2str(MaxIter)])
                LOG=[];
                LOG.CostList = CostList;
                LOG.StepSizeList = StepSizeList;
                LOG.NonZeroFeature=ComputeNonZeroVoxel(W(1:end-1));
            end
        end
        W_1 = W;
    end
end
function [N]=ComputeNonZeroVoxel(W)
    N=sum(W~=0);
end

