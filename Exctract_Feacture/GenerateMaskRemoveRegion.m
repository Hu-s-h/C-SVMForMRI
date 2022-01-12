function [ Mask, Seg, ROISeg ] = GenerateMaskRemoveRegion( Segmentation,ROIList,removeROIList )

% Segmentation=squeeze(Segmentation);
Mask=zeros(size(Segmentation));
ROISeg=zeros(size(Segmentation));
Seg=Segmentation;
if isempty(ROIList) 
    if isempty(removeROIList)
        Mask=double(Segmentation ~=0);
        ROISeg=Segmentation;
    else
        Mask=double(Segmentation ~=0);
        for i=1:length(removeROIList)
            Mask(Segmentation==removeROIList(i))=0;
        end
        ROISeg=Mask.*Segmentation;
    end
else 
    if isempty(removeROIList)
        for i=1:length(ROIList)
            Mask=Mask+double(Segmentation==ROIList(i));
        end
        ROISeg=Mask.*Segmentation;
    else
       
        ROIList=setdiff(ROIList,removeROIList );
        for i=1:length(ROIList)
            Mask=Mask+double(Segmentation==ROIList(i));
        end
        ROISeg=Mask.*Segmentation;
    end
end

end

