function [ FeatVec ] = ExtractFeatVecFromVolume( FeatureField,Mask )
% This function is used to extract the feature vector under the mask
FeatureField=squeeze(FeatureField);
Mask=squeeze(Mask);
if ~isequal(size(FeatureField),size(Mask)) 
    error('Two input should be equal size');
else
    F_Line=FeatureField(:);
    M_Line=Mask(:);
    FeatVec=F_Line(M_Line==1);
end
end

