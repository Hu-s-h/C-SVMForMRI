function [PredList] = EvalModel(PredScoreList,PredLabelList,TrueLabelList)
    %% Evaluate the feature set
    ShowFig1=0;
    auc=roc_curve(PredScoreList,TrueLabelList,ShowFig1); 
    EVAL=Evaluate(TrueLabelList,PredLabelList);
    EVAL(8)=auc;   
    % EVAL = [accuracy sensitivity specificity precision recall f_measure gmean auc];
   %% Get various evaluation indicators (for each parameter combination)
    PredList.AccValue = EVAL(1);
    PredList.SenValue = EVAL(2);
    PredList.SpeValue = EVAL(3);
    PredList.precisionValue = EVAL(4);
    PredList.recallValue = EVAL(5);
    PredList.fValue = EVAL(6);
    PredList.gmeanValue = EVAL(7);
    PredList.AUCValue = EVAL(8);
    PredList.PredScoreList = PredScoreList;
    PredList.PredLabelList = PredLabelList;
    PredList.TrueLabelList = TrueLabelList;
end