function norm_img = preview_normalization(deconvoluted_folder,im1_name,im2_name,im3_name,im4_name,view_ch)

im1=imread(fullfile(deconvoluted_folder,im1_name));
 im2=imread(fullfile(deconvoluted_folder,im2_name));
 im3=imread(fullfile(deconvoluted_folder,im3_name));
 im4=imread(fullfile(deconvoluted_folder,im4_name));
 if isa(im1,'single')
     class_max=1;
     class_min=0;
 elseif isa(im1,'uint8')
     class_max=255;
     class_min=0;
 elseif isa(im1,'uint16')
     class_max=65535;
     class_min=0;
 else
     error('unknown image type; unable to determine minimum and maximum values');
 end
 
    figure;
 set(gcf, 'WindowState', 'maximized');
 subplot(2,4,1)
imshow(imoverlay(imoverlay(im1(:,:,view_ch),im1(:,:,view_ch)<class_min,'blue'),im1(:,:,view_ch)>class_max,'red')) %Red is cyan when inverted, blue is yellow when inverted
subplot(2,4,2)
imshow(imoverlay(imoverlay(im2(:,:,view_ch),im2(:,:,view_ch)<class_min,'blue'),im2(:,:,view_ch)>class_max,'red'))
subplot(2,4,3)
imshow(imoverlay(imoverlay(im3(:,:,view_ch),im3(:,:,view_ch)<class_min,'blue'),im3(:,:,view_ch)>class_max,'red'))
subplot(2,4,4)
imshow(imoverlay(imoverlay(im4(:,:,view_ch),im4(:,:,view_ch)<class_min,'blue'),im4(:,:,view_ch)>class_max,'red'))
subplot(2,4,5)
imhist(im1(:,:,view_ch))
title(['LowSat:' num2str(sum(im1(:,:,view_ch)<class_min,'all')/numel(im1(:,:,view_ch))*100) '%' ' | UpperSat:' num2str(sum(im1(:,:,view_ch)>class_max,'all')/numel(im1(:,:,view_ch))*100) '%'])
subplot(2,4,6)
imhist(im2(:,:,view_ch))
title(['LowSat:' num2str(sum(im2(:,:,view_ch)<class_min,'all')/numel(im2(:,:,view_ch))*100) '%' ' | UpperSat:' num2str(sum(im2(:,:,view_ch)>class_max,'all')/numel(im2(:,:,view_ch))*100) '%'])
subplot(2,4,7)
imhist(im3(:,:,view_ch))
title(['LowSat:' num2str(sum(im3(:,:,view_ch)<class_min,'all')/numel(im3(:,:,view_ch))*100) '%' ' | UpperSat:' num2str(sum(im3(:,:,view_ch)>class_max,'all')/numel(im3(:,:,view_ch))*100) '%'])
subplot(2,4,8)
imhist(im4(:,:,view_ch))
title(['LowSat:' num2str(sum(im4(:,:,view_ch)<class_min,'all')/numel(im4(:,:,view_ch))*100) '%' ' | UpperSat:' num2str(sum(im4(:,:,view_ch)>class_max,'all')/numel(im4(:,:,view_ch))*100) '%'])
end
