function norm_img = imnormalize(input_img,minmax)
        for i=1:size(input_img,3)
            norm_img(:,:,i) = (input_img(:,:,i)-minmax(2,i))/(minmax(1,i)-minmax(2,i));
            %Error handling for NaN or Inf that arise from log
            %transformation artifacts, such as in the case of deconvolution
            %methods using sparse non-negative matrix factorization. Method
            %fails if #Nan or #inf is equal to modal value of image
            if sum(isnan(norm_img(:,:,i)),'all')>0 | sum(isinf(norm_img(:,:,i)))
                warning('NaN or Inf values detected')
                mask=isnan(norm_img(:,:,i))|isinf(norm_img(:,:,i));
                corr=norm_img(:,:,i);
                corr(mask)=mode(corr,'all');
                norm_img(:,:,i)=corr;
                clear core mask
            end
        end
        
end