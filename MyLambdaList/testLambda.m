%% generate a list of hyperparameters
Lambda1=[0,1]; 
Lambda2=[0.001,0.01,0.2,0.5,1,2,5,10]; 
Lambda3=[0.001,0.01,0.2,0.5,1,2,5,10]; 
ValueArray=cell(3,1);  
ValueArray{1}=Lambda1;ValueArray{2}=Lambda2;ValueArray{3}=Lambda3;
LambdaArray=Mat2RowCell(ParameterArrayGenerator( ValueArray ));