% color deconvolution project by Jakob Nikolas Kather, 2015
% contact: www.kather.me

function imageOut = SeparateStains(imageRGB, Matrix)

    % convert input image to double precision float
    % add 2 to avoid artifacts of log transformation
    
    imageRGB = single(imageRGB)+2;
    %blockproc method below
%      fun=@(block_struct) double(block_struct.data)+2;
%      imageRGB=blockproc(imageRGB,[64 64],fun);

    % perform color deconvolution
    %Mark note: switch to -log if you want to have an inverted image where
    %increasing darkness corresponds to increasing signal
    imageOut = reshape(log(imageRGB),[],3) * Matrix;
    imageOut = reshape(imageOut, size(imageRGB));
    %temporary fix: convert image to uint8 so that it can be exported. What
    %you need to figure out is how to find what the min and max values are
    %of each layer... perhaps read in the whole image to get those values,
    %then use them as the normalization (and equalization values from
    %stretchlim), and pass those on to this function.
    
     %imageOut=im2uint16(imageOut);

    % post-processing
    %imageOut = normalizeImage(imageOut,'stretch');
%     if exist('doNormalize')
%         for i=1:size(imageOut,3)
%             imageOut(:,:,i) = (imageOut(:,:,i)-minmax(1,i))/(minmax(2,i)-minmax(1,i));
%         end
%         imageOut=im2uint16(imageOut);
%         
%     end

end
