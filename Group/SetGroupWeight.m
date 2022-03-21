function [GroupWeight] = SetGroupWeight(XFeature,YLabel,GroupLabel,GroupIndListArray,Opt)
    GroupWeightPath=['D:\MRI_ToolsAndData\Data\MRI_Alg_hsh\Result\' Opt.templateType '_GroupWeight.mat'];
    if exist(GroupWeightPath,'file')
        Mat=load(GroupWeightPath);
        GroupWeight = Mat.GroupWeight;
    else
        gNum=length(GroupLabel);
        Opt.norm_type='0'; 
        Opt.lambda=0;
        Opt.LossConvRatio=1e-4;
        Opt.show=0;
        %% Perform n-fold cross validation
        CVNum=10; % 10-fold cross validation
        RNum=1; % Number of cross validation runs
        SubNum=size(XFeature,1);%Number of subjects
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
            X = XFeature(:,GroupIndListArray{i});
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
                    if Opt.isbias==1
                        TrainFeature(:,size(TrainFeature,2)+1)=ones(size(TrainFeature,1),1);
                        TestFeature(:,size(TestFeature,2)+1)=ones(size(TestFeature,1),1);
                    end
                    W0=zeros(D+Opt.isbias,1); %Set initial weight
                    [W,LOG] = fitOpt(W0,TrainFeature,TrainYList,Opt);

                    % Calculate training set
                    [PredScore1,PredLabel1,TrueLabel1] = Predict_Model(TrainFeature,TrainYList,W,Opt);
                    TrainPredScore = [TrainPredScore;PredScore1];
                    TrainPredLabel = [TrainPredLabel;PredLabel1];
                    TrainTrueLabel = [TrainTrueLabel;TrueLabel1];
                    % Calculate test set
                    [PredScore2,PredLabel2,TrueLabel2] = Predict_Model(TestFeature,TestYList,W,Opt);
                    TestPredScore = [TestPredScore;PredScore2];
                    TestPredLabel = [TestPredLabel;PredLabel2];
                    TestTrueLabel = [TestTrueLabel;TrueLabel2];
                end
                currAcc1=sum(TrainPredLabel==TrainTrueLabel)/size(TrainPredLabel,1);
                disp(['Group:' num2str(GroupLabel(i)) ',The average train accuracy is:' num2str(currAcc1)])
                currAcc2=sum(TestPredLabel==TestTrueLabel)/size(TestPredLabel,1);
                disp(['Group:' num2str(GroupLabel(i)) 'The ' num2str(r) '-th' num2str(CVNum) '-fold cross validation is completed.The average accuracy is:' num2str(currAcc2)])

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
        end 
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
        TestResultName = [Opt.templateType '_GroupEvalResult_' datestr(now,30) '.mat'];
        TestResultPath = ['D:\MRI_ToolsAndData\Data\MRI_Alg_hsh\Result', filesep, TestResultName];
        save(TestResultPath, 'TestResult');

        GroupWeight=1./TestAccList;
        GroupWeight=mapminmax(GroupWeight',0,1)';
        GroupWeightPath=['D:\MRI_ToolsAndData\Data\MRI_Alg_hsh\Result\' Opt.templateType '_GroupWeight.mat'];
        save(GroupWeightPath, 'GroupWeight');
    end
end

