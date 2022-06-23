%% Before running this script, please run 'exctfeac_from_spm.m' 
%% under folder 'Exctract_Feacture',get characteristic matrix, mask and segment
datapath ='D:\MRI_ToolsAndData\Data\MRI_Alg_hsh\Feature\aalMaskFeac\mwp1\ADNIFeac\ADNI3';
% datapath = 'D:\MRI_ToolsAndData\Data\MRI_Alg_hsh\Feature\CuingnetFeac\rmwp';
dataType = 'ADNI3';
GnameType = 'AD_CN';

ADdata = importdata(fullfile(datapath,'AD.mat'));
CNdata = importdata(fullfile(datapath,'CN.mat'));

XFeature = [ADdata;CNdata];
YLabel = [ones(size(ADdata,1),1);-1*ones(size(CNdata,1),1)];
SubNum=size(XFeature,1);%Number of subjects
D=size(XFeature,2);
%% ClassOpt选项
ClassOpt.isbias = 1; % Is or not have deviation value -- > 1: Yes 0: no
ClassOpt.classifier = 'chinge'; % Loss function type hinge,chinge,least,logreg
ClassOpt.show=1;
ClassOpt.C=1;  % Soft threshold parameter Lossfun+ClassOpt.C*||W||_2
ClassOpt.norm_type='l1';% Norm type
ClassOpt.lambda=0.1; % Norm hyperparameter
ClassOpt.MaxIter=500; % Maximum number of iterations
ClassOpt.MinIter=5; %Minimum number of iterations
ClassOpt.StepSize=1; % Gradient step
ClassOpt.StepSizeType = 1; % Step type 0: fixed step 1: variable step
if ClassOpt.StepSizeType == 1
    ClassOpt.StepIncreaseRatio = 5;  % Step increase rate
    ClassOpt.StepDecreaseRatio = 0.2; % Step descent rate
    ClassOpt.MaxLineSearchStep = 20; % Maximum search times of step change
end
ClassOpt.FistaOrIsta=1; % If 1, use fista; if 0, use ISTA;
ClassOpt.W_ChangeNormLimit=1e-6; % Weight change convergence condition
ClassOpt.W_ChangeRatioLimit=1e-30; % Weight change ratio convergence condition
ClassOpt.LossConvRatio=1e-3; % Cost change convergence condition
%% 
if strcmp( ClassOpt.norm_type,'gl')||strcmp( ClassOpt.norm_type,'gl1/2')||strcmp( ClassOpt.norm_type,'sgl1/2')     
        myPath = uigetdir(pwd,'Please select the folder where Mask and SegROI images are located');
        ClassOpt.templateType='AAL'; % Group template AAL, SLIC-AAL or ac-SLIC-AAL
        GroupLassoOpt=SetGroupLassoOptions(myPath,ClassOpt,XFeature,YLabel);
        GroupLassoOpt.GroupWeight = GroupLassoOpt.GroupWeight';
        GroupLassoOpt.C=1e-3;
        ClassOpt.GroupLassoOpt=GroupLassoOpt;
end

%% Perform n-fold cross validation
CVNum=5; % 10-fold cross validation
RNum=1; % Number of cross validation runs
FixRandSeed=1;  % Fixed random seed
CVZscore=1; % Execute zscore normalization 1: Yes 0: no

% Dividing=CreateRandNfoldDividing(SubNum,CVNum,FixRandSeed ); %Random division
Dividing1=CreateRandNfoldDividingByLabel(YLabel,CVNum,FixRandSeed ); %Random division by Label
[ XTrain,XTest,YTrain,YTest,Dividing1 ]= nFold_DivideData( XFeature,YLabel,Dividing1,1 );
% Perform zscore normalization
if CVZscore==1
    [XTrain,mu,std]=zscore(XTrain);
    XTest=(XTest-repmat(mu,[size(XTest,1),1]))./repmat(std,[size(XTest,1),1]);
    XTest(:,std==0)=0;
end
if ClassOpt.isbias==1
    XTrain(:,size(XTrain,2)+1)=ones(size(XTrain,1),1);
    XTest(:,size(XTest,2)+1)=ones(size(XTest,1),1);
end

% TrainSubNum = length(YTrain);
% Dividing2=CreateRandNfoldDividing(TrainSubNum,CVNum,FixRandSeed ); %Random division
Dividing2=CreateRandNfoldDividingByLabel(YTrain,CVNum,FixRandSeed ); %Random division by Label


tstart=tic;
BestOpt.maxAcc=0;
BestOpt.bestWList=[];
BestOpt.rNum=0;

TrainPredScoreArray = {};
TrainPredLabelArray = {};
TrainTrueLabelArray = {};
VaildPredScoreArray = {};
VaildPredLabelArray = {};
VaildTrueLabelArray = {};
TestPredScoreArray = {};
TestPredLabelArray = {};
TestTrueLabelArray = {};
TestPred3Array={};
VaildPred2Array={};
TrainPred1Array={};
for r=1:RNum
    if r==1
        W0=zeros(D+ClassOpt.isbias,1);
    else
        W0=2*(rand(D+ClassOpt.isbias,1)-0.5)*1;
    end
    WList = []; 
    LOGCVList=[];
    TrainPredScoreList = [];
    TrainPredLabelList = [];
    TrainTrueLabelList = [];
    VaildPredScoreList = [];
    VaildPredLabelList = [];
    VaildTrueLabelList = [];
    TestPredScoreList = [];
    TestPredLabelList = [];
    TestTrueLabelList = [];
    TestPred3List = {};
    VaildPred2List = {};
    TrainPred1List = {};
    for j=1:CVNum
        [ TrainFeature,ValidFeature,TrainYList,VaildYList,Dividing3 ]= nFold_DivideData( XTrain,YTrain,Dividing2,j ); 
        % Perform zscore normalization
%         if CVZscore==1
%             [TrainFeature,mu,std]=zscore(TrainFeature);
%             ValidFeature=(ValidFeature-repmat(mu,[size(ValidFeature,1),1]))./repmat(std,[size(ValidFeature,1),1]);
%             ValidFeature(:,std==0)=0;
%         end
%         if ClassOpt.isbias==1
%             TrainFeature(:,size(TrainFeature,2)+1)=ones(size(TrainFeature,1),1);
%             ValidFeature(:,size(ValidFeature,2)+1)=ones(size(ValidFeature,1),1);
%         end
        [W,LOG] = fitOpt(W0,TrainFeature,TrainYList,ClassOpt);
        WList=[WList W];
        LOGCVList=[LOGCVList;LOG];
        % Calculate training set
        [PredScore1,PredLabel1,TrueLabel1] = Predict_Model(TrainFeature,TrainYList,W,ClassOpt);
        [TrainPred1] = EvalModel(PredScore1,PredLabel1,TrueLabel1);
        TrainPredScoreList = [TrainPredScoreList;PredScore1];
        TrainPredLabelList = [TrainPredLabelList;PredLabel1];
        TrainTrueLabelList = [TrainTrueLabelList;TrueLabel1];
        % Calculate vaild set
        [PredScore2,PredLabel2,TrueLabel2] = Predict_Model(ValidFeature,VaildYList,W,ClassOpt);
        [VaildPred2] = EvalModel(PredScore2,PredLabel2,TrueLabel2);
        VaildPredScoreList = [VaildPredScoreList;PredScore2];
        VaildPredLabelList = [VaildPredLabelList;PredLabel2];
        VaildTrueLabelList = [VaildTrueLabelList;TrueLabel2];
        % Calculate test set
        [PredScore3,PredLabel3,TrueLabel3] = Predict_Model(XTest,YTest,W,ClassOpt);
        [TestPred3] = EvalModel(PredScore3,PredLabel3,TrueLabel3);
        TestPredScoreList = [TestPredScoreList;PredScore3];
        TestPredLabelList = [TestPredLabelList;PredLabel3];
        TestTrueLabelList = [TestTrueLabelList;TrueLabel3];
        
        TrainPred1List = [TrainPred1List;TrainPred1];
        VaildPred2List = [VaildPred2List;VaildPred2];
        TestPred3List = [TestPred3List;TestPred3];
        
        nfoldAcc1=sum(PredLabel1==TrueLabel1)/size(PredLabel1,1);
        nfoldAcc2=sum(PredLabel2==TrueLabel2)/size(PredLabel2,1);
        nfoldAcc3=sum(PredLabel3==TrueLabel3)/size(PredLabel3,1);
        disp(['currunt cross:' num2str(r) ',fold:' num2str(j) ',cross validation is completed. The accuracy of the training set is:' num2str(nfoldAcc1) ',and the accuracy of the vaild set is:' num2str(nfoldAcc2) ',and the accuracy of the test set is:' num2str(nfoldAcc3)]);
%         W0=W;
        W0=zeros(D+ClassOpt.isbias,1);
%         W0=2*(rand(D+ClassOpt.isbias,1)-0.5)*1;

    end
    currAcc=sum(TestPredLabelList==TestTrueLabelList)/size(TestPredLabelList,1);
    disp(['The ' num2str(r) '-th' num2str(CVNum) '-foldcross validation is completed.The average accuracy is:' num2str(currAcc)]);
    TrainPredScoreArray = [TrainPredScoreArray;TrainPredScoreList];
    TrainPredLabelArray = [TrainPredLabelArray;TrainPredLabelList];
    TrainTrueLabelArray = [TrainTrueLabelArray;TrainTrueLabelList];
    VaildPredScoreArray = [VaildPredScoreArray;VaildPredScoreList];
    VaildPredLabelArray = [VaildPredLabelArray;VaildPredLabelList];
    VaildTrueLabelArray = [VaildTrueLabelArray;VaildTrueLabelList];
    TestPredScoreArray = [TestPredScoreArray;TestPredScoreList];
    TestPredLabelArray = [TestPredLabelArray;TestPredLabelList];
    TestTrueLabelArray = [TestTrueLabelArray;TestTrueLabelList];
    
    TrainPred1Array = [TrainPred1Array;TrainPred1List];
    VaildPred2Array = [VaildPred2Array;VaildPred2List];
    TestPred3Array = [TestPred3Array;TestPred3List];
    
    
    if currAcc>BestOpt.maxAcc
        BestOpt.maxAcc=currAcc;
        BestOpt.bestWList=WList;
        BestOpt.bestLogList=LOGCVList;
        BestOpt.rNum=r;
        BestOpt.nFoldTestPred=TestPred3Array;
    end
end

AveW=mean(BestOpt.bestWList,2);
[TrainPredList] = EvalModel(TrainPredScoreArray{BestOpt.rNum},TrainPredLabelArray{BestOpt.rNum},TrainTrueLabelArray{BestOpt.rNum});
[VaildPredList] = EvalModel(VaildPredScoreArray{BestOpt.rNum},VaildPredLabelArray{BestOpt.rNum},VaildTrueLabelArray{BestOpt.rNum});
[TestPredList] = EvalModel(TestPredScoreArray{BestOpt.rNum},TestPredLabelArray{BestOpt.rNum},TestTrueLabelArray{BestOpt.rNum});
tend=toc(tstart);
%% Define the structure of all combined evaluation indicators
EvalResult=[];
EvalResult.TrainPredList=TrainPredList;
EvalResult.VaildPredList=VaildPredList;
EvalResult.TestPredList=TestPredList;
EvalResult.W=AveW;
if strcmp( ClassOpt.norm_type,'gl')||strcmp( ClassOpt.norm_type,'gl1/2')||strcmp( ClassOpt.norm_type,'sgl1/2')
    EvalResult.GroupLassoOpt=GroupLassoOpt;
end
EvalResult.LOGList=BestOpt.bestLogList;
EvalResult.nFoldTestPred=BestOpt.nFoldTestPred;
EvalResult.normLamda = ClassOpt.lambda;
EvalResult.normType = ClassOpt.norm_type;
EvalResult.solverTime = tend;
norm_type = strrep(ClassOpt.norm_type,'/','_');
if strcmp( ClassOpt.norm_type,'gl')||strcmp( ClassOpt.norm_type,'gl1/2')||strcmp( ClassOpt.norm_type,'sgl1/2')
    EvalResultName = [dataType '_' GnameType '_' ClassOpt.templateType '_' ClassOpt.classifier '_C' num2str(ClassOpt.C), '_', norm_type '_' num2str(ClassOpt.lambda) '_' num2str(tend) '.mat'];
else
    EvalResultName = [dataType '_' GnameType '_' ClassOpt.classifier '_C' num2str(ClassOpt.C), '_', norm_type '_' num2str(ClassOpt.lambda) '_' num2str(tend) '.mat'];
end


EvalResultPath = ['D:\MRI_ToolsAndData\Data\MRI_Alg_hsh\Result', filesep, EvalResultName];
save(EvalResultPath, 'EvalResult');
