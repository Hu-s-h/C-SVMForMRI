%% Before running this script, please run 'exctfeac_from_spm.m' 
%% under folder 'Exctract_Feacture',get characteristic matrix, mask and segment
datapath ='D:\MRI_ToolsAndData\Data\MRI_Alg_hsh\Feature\ADNIFeac';
% datapath = 'D:\MRI_ToolsAndData\Data\MRI_Alg_hsh\Feature\CuingnetFeac\rmwp';
ADdata = importdata(fullfile(datapath,'AD.mat'));
CNdata = importdata(fullfile(datapath,'CN.mat'));

XFeature = [ADdata;CNdata];
YLabel = [ones(size(ADdata,1),1);-1*ones(size(CNdata,1),1)];
SubNum=size(XFeature,1);%Number of subjects


%% classification related parameters
ClassOpt.isbias = 1; % Is or not have deviation value -- > 1: Yes 0: no
ClassOpt.classifier = 'chinge'; % Loss function type

ClassOpt.C=1; % Soft threshold parameter Lossfun+ClassOpt.C*||W||_2
ClassOpt.norm_type='0'; % Norm type
ClassOpt.lambda=0; % Norm hyperparameter
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
ClassOpt.LossConvRatio=1e-4;  % Cost change convergence condition

%% Select grouping method
ClassOpt.templateType='AAL'; % Group template AAL or ac-SLIC-AAL
myPath = uigetdir(pwd,'Please select the folder where Mask and SegROI images are located');
GroupLassoOpt=SetGroupLassoOptions(myPath,ClassOpt,XFeature,YLabel);
gNum=length(GroupLassoOpt.GroupLabel);

%% Perform n-fold cross validation
CVNum=10; % 10-fold cross validation
RNum=1; % Number of cross validation runs
FixRandSeed=1;  % Fixed random seed
Dividing=CreateRandNfoldDividing(SubNum,CVNum,FixRandSeed ); 
% Dividing=CreateRandNfoldDividingByLabel(YLabel,CVNum,FixRandSeed );
CVZscore=1; % Execute zscore normalization 1: Yes 0: no

TestAccList=zeros(gNum,1);
TestAUCList=zeros(gNum,1);
TestSenList=zeros(gNum,1);
TestSpeList=zeros(gNum,1);
TestrecallList=zeros(gNum,1);
TestgmeanList=zeros(gNum,1);
TestfList=zeros(gNum,1);
TestprecisionList=zeros(gNum,1);

GroupTestPredLabelArray=cell(gNum,1);
GroupTestTrueLabelArray=cell(gNum,1);
GroupTestPredScoreArray=cell(gNum,1);
for i=1:gNum
    X = XFeature(:,GroupLassoOpt.GroupIndListArray{i});
    D=size(X,2);
    TestPredScoreArray = [];
    TestPredLabelArray = [];
    TestTrueLabelArray = [];
    for r=1:RNum
        TrainPredScore = [];
        TrainPredLabel = [];
        TrainTrueLabel = [];
        TestPredScore = [];
        TestPredLabel = [];
        TestTrueLabel = [];
        for j=1:CVNum
            [ TrainFeature,TestFeature,TrainYList,TestYList,Dividing1 ]= nFold_DivideData( X,YLabel,Dividing,j );
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
            W0=zeros(D+ClassOpt.isbias,1); %Set initial weight
            [W,LOG] = fitOpt(W0,TrainFeature,TrainYList,ClassOpt);
            
            % Calculate training set
            [PredScore1,PredLabel1,TrueLabel1] = Predict_Model(TrainFeature,TrainYList,W,ClassOpt);
            TrainPredScore = [TrainPredScore;PredScore1];
            TrainPredLabel = [TrainPredLabel;PredLabel1];
            TrainTrueLabel = [TrainTrueLabel;TrueLabel1];
            % Calculate test set
            [PredScore2,PredLabel2,TrueLabel2] = Predict_Model(TestFeature,TestYList,W,ClassOpt);
            TestPredScore = [TestPredScore;PredScore2];
            TestPredLabel = [TestPredLabel;PredLabel2];
            TestTrueLabel = [TestTrueLabel;TrueLabel2];
        end
        currAcc1=sum(TrainPredLabel==TrainTrueLabel)/size(TrainPredLabel,1);
        disp(['Group:' num2str(GroupLassoOpt.GroupLabel(i)) ',The average train accuracy is:' num2str(currAcc1)])
        currAcc2=sum(TestPredLabel==TestTrueLabel)/size(TestPredLabel,1);
        disp(['Group:' num2str(GroupLassoOpt.GroupLabel(i)) 'The ' num2str(r) '-th' num2str(CVNum) '-fold cross validation is completed.The average accuracy is:' num2str(currAcc2)])
        
        TestPredScoreArray = [TestPredScoreArray;TestPredScore];
        TestPredLabelArray = [TestPredLabelArray;TestPredLabel];
        TestTrueLabelArray = [TestTrueLabelArray;TestTrueLabel];
    end
    %% Define the structure of all combined evaluation indicators
    [TestPredList] = EvalModel(TestPredScoreArray,TestPredLabelArray,TestTrueLabelArray); 
    TestAccList(i)=TestPredList.AccValue;
    TestAUCList(i)=TestPredList.AUCValue;
    TestSenList(i)=TestPredList.SenValue;
    TestSpeList(i)=TestPredList.SpeValue;
    TestrecallList(i)=TestPredList.recallValue;
    TestgmeanList(i)=TestPredList.gmeanValue;
    TestfList(i)=TestPredList.fValue;
    TestprecisionList(i)=TestPredList.precisionValue;
    
    GroupTestPredLabelArray{i}=TestPredList.PredLabelList;
    GroupTestTrueLabelArray{i}=TestPredList.TrueLabelList;
    GroupTestPredScoreArray{i}=TestPredList.PredScoreList;
    
    TestResult=[];
    TestResult.AccList=TestAccList;
    TestResult.AUCList=TestAUCList;
    TestResult.SenList=TestSenList;
    TestResult.SpeList=TestSpeList;
    TestResult.precisionList=TestprecisionList;
    TestResult.recallList=TestrecallList;
    TestResult.gmeanList=TestgmeanList;
    TestResult.fList=TestfList;
    TestResult.PredLabel=GroupTestPredLabelArray;
    TestResult.TrueLabel=GroupTestTrueLabelArray;
    TestResult.PredScore=GroupTestPredScoreArray;
    TestResultName = 'GroupEvalResult.mat';
    TestResultPath = ['D:\MRI_ToolsAndData\Data\MRI_Alg_hsh\Result', filesep, TestResultName];
    save(TestResultPath, 'TestResult');
end


