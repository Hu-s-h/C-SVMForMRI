function [ FeatureMatrix ] = ExtractFeatureMatrix( Root,Pat )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
%
%   Root--root directory, Pat--image file directory name
%   i.e.Root='D:\MRI_ToolsAndData\Data\newdata' Pat='AD'

CurrentSystem=computer;
if ~contains( CurrentSystem,'WIN')
    separation='/';
else
    separation='\';
end

Dir=dir([Root,separation,Pat]);
FeatureNum=length(Dir);
Feature1=importdata([Root,separation,Dir(1).name]);
Feature1=Feature1(:);
FeatureMatrix=zeros(FeatureNum,length(Feature1));
for i=1:FeatureNum
    Feature1=importdata([Root,separation,Dir(i).name]);
    Feature1=Feature1(:);
    FeatureMatrix(i,:)=Feature1;
end




end

