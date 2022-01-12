function [ Xtrain,Xtest,YTrain,YTest,Dividing ] = nFold_DivideData( X,Y,Dividing,SelectInd,FixRandSeed )
% This function is used to divide the data set into training and testing parts after n-fold cross-validation

Num=size(X,1);
%% if not divided (1-fold)
if isscalar(Dividing)
   n=Dividing;
   if nargin<5 
       FixRandSeed=1;
   end
   if FixRandSeed==1
       rng('default');
   end
   NewOrder=randperm(Num); 
   Dividing=cell(n,1);
   StepFloor=floor(Num/n);
   Remind=Num-n*StepFloor;
   End=0;
   Start=0;
   for i=1:n
      if i<=Remind
          Step=StepFloor+1;
      else
          Step=StepFloor;
      end
      Start=End+1;
      End  =Start+Step;
      struct=[];
      TrainIndList=NewOrder;
      TestIndList=NewOrder(Start:End);
      TrainIndList(Start:End)=[];
      TestIndList=sort(TestIndList);
      TrainIndList=sort(TrainIndList);
      struct.TrainInd=TrainIndList;
      struct.TestInd =TestIndList;
      Dividing{i}=struct; 
   end  
end

%% extract training and testing features and labels
n=length(Dividing);
if nargin<4 | isempty(SelectInd)
    Xtrain=cell(n,1); Xtest=cell(n,1);
    YTrain=cell(n,1); YTest=cell(n,1);
    for i=1:n
        SelectInd=i;
        TrainIndList=Dividing{SelectInd}.TrainInd;
        TestIndList =Dividing{SelectInd}.TestInd;
        Xtrain{i}=X(TrainIndList,:);
        Xtest{i} =X(TestIndList ,:);
        YTrain{i}=Y(TrainIndList,:);
        YTest{i} =Y(TestIndList ,:);
    end
    
else
    TrainIndList=Dividing{SelectInd}.TrainInd;
    TestIndList =Dividing{SelectInd}.TestInd;
    Xtrain=X(TrainIndList,:); 
    Xtest =X(TestIndList ,:);
    YTrain=Y(TrainIndList,:);
    YTest =Y(TestIndList ,:);
end

end