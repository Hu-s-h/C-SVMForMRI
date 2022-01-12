function [PredScoreList,PredLabelList,TrueLabelList] = Predict_Model(X,Y,W,ClassOpt)

    %% make predictions
    if strcmp(ClassOpt.classifier,'logreg')
        PredScore=1./(1+exp(-(X*W)));
        PredLabel = 2*(PredScore>=0.5)-1;
%         Y(Y==0)=-1;
    else
        PredScore=X*W;
        PredLabel=2*(PredScore>=0)-1;
    end
    %% feature set prediction result
    TrueLabelList=reshape(Y,[length(Y),1]);
    PredLabelList=reshape(PredLabel,[length(PredLabel),1]);
    PredScoreList=reshape(PredScore,[length(PredScore),1]);
    
    
end

