function [W,LOG] = fitOpt(W0,X,y,ClassOpt)

    StepSize=ClassOpt.StepSize;
    LOG=[];
    
    if ~isfield(ClassOpt,'show')
        ClassOpt.show = 1;
    end
    
    %% initialization
    W=W0;
    W_1=W;
    t_1 = 1;
    loss_array={};
    stepSize_array={};
    initStepSize=StepSize;
    
    [f,df]=lossFun1(X,y,ClassOpt);
    [nl,dnl]=normFun(ClassOpt);
    
    loss=f(W)+ClassOpt.lambda*nl(W);
    loss_array=[loss_array;loss];
    
    for Iter=1:ClassOpt.MaxIter
        grad = df(W);
        DW=W-grad*StepSize;
        Threshold=ClassOpt.lambda*StepSize;
        PW=dnl(DW,Threshold);
        loss_array=[loss_array;f(W)+ClassOpt.lambda*nl(W)];
        
        if ClassOpt.StepSizeType ==1
            Cost1=f(PW)+ClassOpt.lambda*nl(PW);
            Cost2=f(W)+ClassOpt.lambda*nl(PW)+grad'*(PW-W)+(PW-W)'*(PW-W)/(2*StepSize);
            if Cost1<=Cost2
                InOrDeCrease=1;
                ChangeRatio=ClassOpt.StepIncreaseRatio;
            else
                InOrDeCrease=2;
                ChangeRatio=ClassOpt.StepDecreaseRatio;
            end
            PW1=PW;
            StepSize_1=StepSize;
            %% Find the best step size in increasing or decreasing direction
            for L=1:ClassOpt.MaxLineSearchStep
                StepSize=StepSize*ChangeRatio;
                DW=W-grad*StepSize;
                Threshold = ClassOpt.lambda*StepSize;
                PW=dnl(DW,Threshold);

                Cost1=f(PW)+ClassOpt.lambda*nl(PW);
                Cost2=f(W)+ClassOpt.lambda*nl(PW)+grad'*(PW-W)+(PW-W)'*(PW-W)/(2*StepSize);
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
                if StepSize<initStepSize
                    StepSize=StepSize/ChangeRatio;
                    break;
                end
            end
        end
        stepSize_array=[stepSize_array;StepSize];
        if ClassOpt.FistaOrIsta==1
            t=0.5*(1+(1+4*t_1^2)^0.5);
            W=W_1+(PW-W_1)*(t_1-1)/t;
            t_1=t;
        else
            W=PW;
        end
        
        if Iter>ClassOpt.MinIter
            WDiffNorm=norm(W-W_1);
            if WDiffNorm <= ClassOpt.W_ChangeNormLimit
                if ClassOpt.show==1
                    disp(['At Iter ',num2str(Iter,'%06d'),' W change Norm converge, ',num2str(WDiffNorm),'<=',num2str(ClassOpt.W_ChangeNormLimit)] );
                end
                LOG=[];
                LOG.LossArray=loss_array;
                LOG.stepSizeArray=stepSize_array;
                LOG.NonZeroFeature=ComputeNonZeroVoxel(W(1:end-1));
                break;
            end
            WRatio=WDiffNorm/norm(W);
            if WRatio<=ClassOpt.W_ChangeRatioLimit
                if ClassOpt.show==1
                    disp(['At Iter ',num2str(Iter,'%06d'),' W change ratio converge, ',num2str(WRatio),'<=',num2str(ClassOpt.W_ChangeRatioLimit)] );
                end
                LOG=[];
                LOG.LossArray=loss_array;
                LOG.stepSizeArray=stepSize_array;
                LOG.NonZeroFeature=ComputeNonZeroVoxel(W(1:end-1));
                break;
            end
            LossDecreaseRatio = abs((loss_array{Iter-1}-loss_array{Iter})/loss_array{Iter-1});
            if LossDecreaseRatio<=ClassOpt.LossConvRatio
                if ClassOpt.show==1
                    disp(['At Iter ',num2str(Iter,'%06d'),' Loss decrease ratio converge, ',num2str(LossDecreaseRatio),'<=',num2str(ClassOpt.LossConvRatio)] );
                end
                LOG=[];
                LOG.LossArray=loss_array;
                LOG.stepSizeArray=stepSize_array;
                LOG.NonZeroFeature=ComputeNonZeroVoxel(W(1:end-1));
                break;
            end
            if Iter==ClassOpt.MaxIter
                if ClassOpt.show==1
                    disp(['Reach Max Iteration ',num2str(ClassOpt.MaxIter)])
                end
                LOG=[];
                LOG.LossArray=loss_array;
                LOG.stepSizeArray=stepSize_array;
                LOG.NonZeroFeature=ComputeNonZeroVoxel(W(1:end-1));
            end
        end
        W_1 = W;
    end
end

function [N]=ComputeNonZeroVoxel(W)
    N=sum(W~=0);
end

