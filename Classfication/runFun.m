%% Before running this script, please run 'exctfeac_from_spm.m' under folder 'Exctract_Feacture',get characteristic matrix, mask and segment

% datapath ='D:\Data\MRI_Alg_hsh\Feature\ADNIFeac';
datapath = uigetdir(pwd,'Please select data matrix path');
ADdata = importdata(fullfile(datapath,'AD_TrainingSet.mat'));
CNdata = importdata(fullfile(datapath,'CN_TrainingSet.mat'));
XFeature = [ADdata;CNdata];
YLabel = [ones(size(ADdata,1),1);-1*ones(size(CNdata,1),1)];
SubNum=size(XFeature,1); %Number of subjects
D=size(XFeature,2);
%% classification related parameters
ClassOpt.isbias = 1; % Is or not have deviation value -- > 1: Yes 0: no
ClassOpt.classifier = 'chinge'; % Loss function type

% ClassOpt.C=1; % Soft threshold parameter Lossfun+ClassOpt.C*||W||_2
ClassOpt.norm_type='0'; % Norm type
% ClassOpt.lambda=0; % Norm hyperparameter
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
ClassOpt.LossConvRatio=1e-3;  % Cost change convergence condition
%% 
if strcmp( ClassOpt.norm_type,'gl')||strcmp( ClassOpt.norm_type,'gl1/2')||strcmp( ClassOpt.norm_type,'sgl1/2')     
        myPath = uigetdir(pwd,'Please select the folder where Mask and SegROI images are located');
        ClassOpt.templateType='AAL'; %Grouping template,AAL and ac-SLIC-AAL can be Selected.
        
        GroupLassoOpt=SetGroupLassoOptions(myPath,ClassOpt);
        GroupLassoOpt.GroupWeight = GroupLassoOpt.GroupWeight';
        GroupLassoOpt.C=1e-3; % C is the smoothing threshold of sgl1/2 norm
        ClassOpt.GroupLassoOpt=GroupLassoOpt;
end
%% 
Lambda1=[0.01,0.1,0.2,0.5,1,2,5,10]; 
Lambda2=[0.01,0.1,0.2,0.5,1,2,5,10];
ValueArray=cell(2,1);  
ValueArray{1}=Lambda1;
ValueArray{2}=Lambda2;
LambdaArray=Mat2RowCell(ParameterArrayGenerator( ValueArray ));
N = length(LambdaArray);

TrainAccList=zeros(N,1);
TrainAUCList=zeros(N,1);
TrainSenList=zeros(N,1);
TrainSpeList=zeros(N,1);
TrainrecallList=zeros(N,1);
TraingmeanList=zeros(N,1);
TrainfList=zeros(N,1);
TrainprecisionList=zeros(N,1);

N_TrainPredScoreArray=cell(N,1);
N_TrainPredLabelArray=cell(N,1);
N_TrainTrueLabelArray=cell(N,1);

TestAccList=zeros(N,1);
TestAUCList=zeros(N,1);
TestSenList=zeros(N,1);
TestSpeList=zeros(N,1);
TestrecallList=zeros(N,1);
TestgmeanList=zeros(N,1);
TestfList=zeros(N,1);
TestprecisionList=zeros(N,1);

N_TestPredScoreArray=cell(N,1);
N_TestPredLabelArray=cell(N,1);
N_TestTrueLabelArray=cell(N,1);

LogArray=cell(N,1);
WArray=cell(N,1);
AveWArray=cell(N,1);
%% Perform n-fold cross validation
CVNum=10; % 10-fold cross validation
RNum=1; % Number of cross validation runs
FixRandSeed=1;  % Fixed random seed
Dividing=CreateRandNfoldDividing(SubNum,CVNum,FixRandSeed ); 
CVZscore=1; % Execute zscore normalization 1: Yes 0: no
tic;

BestOptArray = {};

for i=1:N   
    LambdaList = LambdaArray{i};
    ClassOpt.C=LambdaList(1); % Soft threshold parameter Lossfun+ClassOpt.C*||W||_2
    ClassOpt.lambda=LambdaList(2); % Norm hyperparameter
    BestOpt.maxAcc=0;
    BestOpt.bestWList=[];
    BestOpt.rNum=0;
    
    TrainPredScoreArray = {};
    TrainPredLabelArray = {};
    TrainTrueLabelArray = {};
    TestPredScoreArray = {};
    TestPredLabelArray = {};
    TestTrueLabelArray = {};
    for r=1:RNum
        W0=zeros(D+ClassOpt.isbias,1); %Set initial weight
        WList = []; 
        LOGCVList=[];
        TrainPredScoreList = [];
        TrainPredLabelList = [];
        TrainTrueLabelList = [];
        TestPredScoreList = [];
        TestPredLabelList = [];
        TestTrueLabelList = [];
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
            %% Calculate training set
            [PredScore1,PredLabel1,TrueLabel1] = Predict_Model(TrainFeature,TrainYList,W,ClassOpt);
            TrainPredScoreList = [TrainPredScoreList;PredScore1];
            TrainPredLabelList = [TrainPredLabelList;PredLabel1];
            TrainTrueLabelList = [TrainTrueLabelList;TrueLabel1];
            %% Calculate test set
            [PredScore2,PredLabel2,TrueLabel2] = Predict_Model(TestFeature,TestYList,W,ClassOpt);
            TestPredScoreList = [TestPredScoreList;PredScore2];
            TestPredLabelList = [TestPredLabelList;PredLabel2];
            TestTrueLabelList = [TestTrueLabelList;TrueLabel2];
            nfoldAcc1=sum(PredLabel1==TrueLabel1)/size(PredLabel1,1);
            nfoldAcc2=sum(PredLabel2==TrueLabel2)/size(PredLabel2,1);
            disp(['currunt cross:' num2str(r) ',fold:' num2str(j) 'cross validation is completed. The accuracy of the training set is:' num2str(nfoldAcc1) ',and the accuracy of the test set is:' num2str(nfoldAcc2)])
            W0=zeros(D+ClassOpt.isbias,1); %Set initial weight
        end
        currAcc=sum(TestPredLabelList==TestTrueLabelList)/size(TestPredLabelList,1);
        disp(['The ' num2str(r) '-th' num2str(CVNum) '-foldcross validation is completed.The average accuracy is:' num2str(currAcc)])
        TrainPredScoreArray = [TrainPredScoreArray;TrainPredScoreList];
        TrainPredLabelArray = [TrainPredLabelArray;TrainPredLabelList];
        TrainTrueLabelArray = [TrainTrueLabelArray;TrainTrueLabelList];
        TestPredScoreArray = [TestPredScoreArray;TestPredScoreList];
        TestPredLabelArray = [TestPredLabelArray;TestPredLabelList];
        TestTrueLabelArray = [TestTrueLabelArray;TestTrueLabelList];
        if currAcc>BestOpt.maxAcc
            BestOpt.maxAcc=currAcc;
            BestOpt.bestWList=WList;
            BestOpt.bestLogList=LOGCVList;
            BestOpt.rNum=r;
        end  
    end
    BestOptArray=[BestOptArray;BestOpt];
    AveW=mean(BestOpt.bestWList,2);%Average by row
    AveWArray{i}=AveW;
    WArray{i}=BestOpt.bestWList;
    LogArray{i}=BestOpt.bestLogList;
    
    [TrainPredList] = EvalModel(TrainPredScoreArray{BestOpt.rNum},TrainPredLabelArray{BestOpt.rNum},TrainTrueLabelArray{BestOpt.rNum});
    TrainAccList(i)=TrainPredList.AccValue;
    TrainAUCList(i)=TrainPredList.AUCValue;
    TrainSenList(i)=TrainPredList.SenValue;
    TrainSpeList(i)=TrainPredList.SpeValue;
    TrainrecallList(i)=TrainPredList.recallValue;
    TraingmeanList(i)=TrainPredList.gmeanValue;
    TrainfList(i)=TrainPredList.fValue;
    TrainprecisionList(i)=TrainPredList.precisionValue;
    
    N_TrainPredLabelArray{i}=TrainPredList.PredLabelList;
    N_TrainTrueLabelArray{i}=TrainPredList.TrueLabelList;
    N_TrainPredScoreArray{i}=TrainPredList.PredScoreList;
    
    [TestPredList] = EvalModel(TestPredScoreArray{BestOpt.rNum},TestPredLabelArray{BestOpt.rNum},TestTrueLabelArray{BestOpt.rNum});
    
    TestAccList(i)=TestPredList.AccValue;
    TestAUCList(i)=TestPredList.AUCValue;
    TestSenList(i)=TestPredList.SenValue;
    TestSpeList(i)=TestPredList.SpeValue;
    TestrecallList(i)=TestPredList.recallValue;
    TestgmeanList(i)=TestPredList.gmeanValue;
    TestfList(i)=TestPredList.fValue;
    TestprecisionList(i)=TestPredList.precisionValue;
    N_TestPredLabelArray{i}=TestPredList.PredLabelList;
    N_TestTrueLabelArray{i}=TestPredList.TrueLabelList;
    N_TestPredScoreArray{i}=TestPredList.PredScoreList;  
end
toc;
%% Define the structure of all combined evaluation indicators
EvalResult=[];
EvalResult.LambdaArray=LambdaArray;
EvalResult.WList= WArray;
EvalResult.AveW=AveWArray;

TrainResult.AccList=TrainAccList;
TrainResult.AUCList=TrainAUCList;
TrainResult.SenList=TrainSenList;
TrainResult.SpeList=TrainSpeList;
TrainResult.precisionList=TrainprecisionList;
TrainResult.recallList=TrainrecallList;
TrainResult.gmeanList=TraingmeanList;
TrainResult.fList=TrainfList;
TrainResult.PredLabel=N_TrainPredLabelArray;
TrainResult.TrueLabel=N_TrainTrueLabelArray;
TrainResult.PredScore=N_TrainPredScoreArray;

EvalResult.Train = TrainResult;

TestResult.AccList=TestAccList;
TestResult.AUCList=TestAUCList;
TestResult.SenList=TestSenList;
TestResult.SpeList=TestSpeList;
TestResult.precisionList=TestprecisionList;
TestResult.recallList=TestrecallList;
TestResult.gmeanList=TestgmeanList;
TestResult.fList=TestfList;
TestResult.PredLabel=N_TestPredLabelArray;
TestResult.TrueLabel=N_TestTrueLabelArray;
TestResult.PredScore=N_TestPredScoreArray;

EvalResult.Test = TestResult;

EvalResultPath=uigetdir(pwd,'ÇëÉèÖÃÆÀ¹À½á¹û´æ´¢Â·¾¶');%ÉèÖÃÆÀ¹À½á¹ûÂ·¾¶
save(EvalResultPath, 'EvalResult');
