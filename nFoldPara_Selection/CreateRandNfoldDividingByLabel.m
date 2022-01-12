function [ Dividing ] = CreateRandNfoldDividingByLabel(Y,n,FixRandSeed )
%UNTITLED6 Summary of this function goes here
%   Detailed explanation goes here
   if nargin<3 
       FixRandSeed=1;
   end
   if FixRandSeed==1
       rng('default');
   end
   uniqueLabel=unique(Y);
   Dividing=cell(n,1);
   TrainIndCell=cell(n,1);
   TestIndCell=cell(n,1);
   for i=1:length(uniqueLabel)
       label_index=find(Y==uniqueLabel(i));
       SubNum=length(label_index);
       NewOrder= randperm(SubNum);
       StepFloor=floor(SubNum/n);
       Remind=SubNum-n*StepFloor;
       End=0;
       Start=0;
       for j=1:n
          if j<=Remind
              Step=StepFloor+1;
          else
              Step=StepFloor;
          end
          Start=End+1;
          End=Start+Step-1;

          TrainInd=label_index(NewOrder);
          TestInd=label_index(NewOrder(Start:End));
          TrainInd(Start:End)=[];
          
          TrainIndCell{j}=[TrainIndCell{j} TrainInd'];
          TestIndCell{j}=[TestIndCell{j} TestInd'];
       end
   end
   for i=1:n
       struct=[];
       TrainIndCell{i}=sort(TrainIndCell{i});
       struct.TrainInd=TrainIndCell{i};
       TestIndCell{i}=sort(TestIndCell{i});
       struct.TestInd =TestIndCell{i};
       Dividing{i}=struct;
   end

end