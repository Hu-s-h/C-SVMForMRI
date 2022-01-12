%% test n-fold cross validation
CVNum=5; 
FixRandSeed=1;  
SubjNum = 100; 
Dividing=CreateRandNfoldDividing(SubjNum,CVNum,FixRandSeed ); 
CVZscore=1;
AllTrainFea={};
AllTrainLab={};
AllTestFea={};
AllTestLab={};
for j=1:CVNum
    
    [ TrainFeature,TestFeature,TrainYList,TestYList,Dividing1 ]= nFold_DivideData( FeaArray,LabelArray,Dividing,j ); 
    
    if CVZscore==1
        [TrainFeature,mu,std]=zscore(TrainFeature);
        TestFeature=(TestFeature-repmat(mu,[size(TestFeature,1),1]))./repmat(std,[size(TestFeature,1),1]);
        TestFeature(:,std==0)=0;
        TrainFeature(:,end)=1;
        TestFeature(:,end)=1;
    end
    AllTrainFea = [AllTrainFea;TrainFeature];
    AllTrainLab=[AllTrainLab;TrainYList];
    AllTestFea=[AllTestFea;TestFeature];
    AllTestLab=[AllTestLab;TestYList];
end