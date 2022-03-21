%% Before running this script, please run 'exctfeac_from_spm.m' 
%% under folder 'Exctract_Feacture',get characteristic matrix, mask and segment
datapath ='D:\MRI_ToolsAndData\Data\MRI_Alg_hsh\Feature\ADNIFeac';
% datapath = 'D:\MRI_ToolsAndData\Data\MRI_Alg_hsh\Feature\CuingnetFeac\rmwp';
dataType = 'ADNI';
GnameType = 'AD_CN';

ADdata = importdata(fullfile(datapath,'AD.mat'));
CNdata = importdata(fullfile(datapath,'CN.mat'));

XFeature = [ADdata;CNdata];
YLabel = [ones(size(ADdata,1),1);-1*ones(size(CNdata,1),1)];
SubNum=size(XFeature,1);%Number of subjects
D=size(XFeature,2);
%% ClassOptÑ¡Ïî
ClassOpt.isbias = 1; % Is or not have deviation value -- > 1: Yes 0: no
ClassOpt.classifier = 'chinge'; % Loss function type hinge,chinge,least,logreg
ClassOpt.show=1;
ClassOpt.C=1;  % Soft threshold parameter Lossfun+ClassOpt.C*||W||_2
ClassOpt.norm_type='sgl1/2';% Norm type
ClassOpt.lambda=0.01; % Norm hyperparameter
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
CVNum=10; % 10-fold cross validation
RNum=1; % Number of cross validation runs
FixRandSeed=1;  % Fixed random seed
Dividing=CreateRandNfoldDividing(SubNum,CVNum,FixRandSeed );
% Dividing=CreateRandNfoldDividingByLabel(YLabel,CVNum,FixRandSeed ); 
CVZscore=1; % Execute zscore normalization 1: Yes 0: no
tstart=tic;
BestOpt.maxAcc=0;
BestOpt.bestWList=[];
BestOpt.rNum=0;

TrainPredScoreArray = {};
TrainPredLabelArray = {};
TrainTrueLabelArray = {};
TestPredScoreArray = {};
TestPredLabelArray = {};
TestTrueLabelArray = {};
TestPred2Array={};
TrainPred1Array={};
for r=1:RNum
    W0=zeros(D+ClassOpt.isbias,1);
    WList = []; 
    LOGCVList=[];
    TrainPredScoreList = [];
    TrainPredLabelList = [];
    TrainTrueLabelList = [];
    TestPredScoreList = [];
    TestPredLabelList = [];
    TestTrueLabelList = [];
    TestPred2List = {};
    TrainPred1List = {};
    for j=1:CVNum
        [ TrainFeature,TestFeature,TrainYList,TestYList,Dividing1 ]= nFold_DivideData( XFeature,YLabel,Dividing,j ); 
        % Perform zscore normalization
        if CVZscore==1
            [TrainFeature,mu,std]=zscore(TrainFeature);
            TestFeature=(TestFeature-repmat(mu,[size(TestFeature,1),1]))./repmat(std,[size(TestFeature,1),1]);
            TestFeature(:,std==0)=0;
        end
        if ClassOpt.isbias==1
            TrainFeature(:,size(TrainFeature,2)+1)=ones(size(TrainFeature,1),1);
            TestFeature(:,size(TestFeature,2)+1)=ones(size(TestFeature,1),1);
        end
        [W,LOG] = fitOpt(W0,TrainFeature,TrainYList,ClassOpt);
        WList=[WList W];
        LOGCVList=[LOGCVList;LOG];
        % Calculate training set
        [PredScore1,PredLabel1,TrueLabel1] = Predict_Model(TrainFeature,TrainYList,W,ClassOpt);
        [TrainPred1] = EvalModel(PredScore1,PredLabel1,TrueLabel1);
        TrainPredScoreList = [TrainPredScoreList;PredScore1];
        TrainPredLabelList = [TrainPredLabelList;PredLabel1];
        TrainTrueLabelList = [TrainTrueLabelList;TrueLabel1];
        % Calculate test set
        [PredScore2,PredLabel2,TrueLabel2] = Predict_Model(TestFeature,TestYList,W,ClassOpt);
        [TestPred2] = EvalModel(PredScore2,PredLabel2,TrueLabel2);
        TestPredScoreList = [TestPredScoreList;PredScore2];
        TestPredLabelList = [TestPredLabelList;PredLabel2];
        TestTrueLabelList = [TestTrueLabelList;TrueLabel2];
        TestPred2List = [TestPred2List;TestPred2];
        TrainPred1List = [TrainPred1List;TrainPred1];
        W0=zeros(D+ClassOpt.isbias,1);
    end
    TrainPredScoreArray = [TrainPredScoreArray;TrainPredScoreList];
    TrainPredLabelArray = [TrainPredLabelArray;TrainPredLabelList];
    TrainTrueLabelArray = [TrainTrueLabelArray;TrainTrueLabelList];
    TestPredScoreArray = [TestPredScoreArray;TestPredScoreList];
    TestPredLabelArray = [TestPredLabelArray;TestPredLabelList];
    TestTrueLabelArray = [TestTrueLabelArray;TestTrueLabelList];
    TestPred2Array = [TestPred2Array;TestPred2List];
    TrainPred1Array = [TrainPred1Array;TrainPred1List];
    
    if currAcc>BestOpt.maxAcc
        BestOpt.maxAcc=currAcc;
        BestOpt.bestWList=WList;
        BestOpt.bestLogList=LOGCVList;
        BestOpt.rNum=r;
        BestOpt.nFoldTestPred=TestPred2Array;
    end
end

AveW=mean(BestOpt.bestWList,2);
[TrainPredList] = EvalModel(TrainPredScoreArray{BestOpt.rNum},TrainPredLabelArray{BestOpt.rNum},TrainTrueLabelArray{BestOpt.rNum});
[TestPredList] = EvalModel(TestPredScoreArray{BestOpt.rNum},TestPredLabelArray{BestOpt.rNum},TestTrueLabelArray{BestOpt.rNum});
tend=toc(tstart);
%% Define the structure of all combined evaluation indicators
EvalResult=[];
EvalResult.TrainPredList=TrainPredList;
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
