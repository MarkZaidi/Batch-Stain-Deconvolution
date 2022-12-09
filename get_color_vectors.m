%% ONLY WORKS ON R2018B OR LATER
%Input an RGB image to the script (either HE or HDAB). Run the script once
%per color vector you want to get. For example, in the first run, you might
%want to get the hematoxylin vector of an image. Zoom into a nucleus, draw
%a square around it. Repeat for 4-5 nuclei to get an accurate average. Once
%satisfied, close the window, and it'll give you the vectors to paste into
%define_color_vectors.m
clear
impath = 'C:\Users\Mark Zaidi\Documents\MATLAB\Stain deconvolution\RGB images\HDAB - H17-178 spheroids - EF5\H17-178 CA 9 #2 L2 EF5.tif';
img = im2double(imread(impath));
i=1;
h=imshow(img);
while ishghandle(h)
ROI=drawrectangle;
if ~ishghandle(h)
    break;
end
rect_pos=uint32(ROI.Position);
%imshow(img(rect_pos(2):rect_pos(2)+rect_pos(4),rect_pos(1):rect_pos(1)+rect_pos(3),1:3))


colorvectors(i,1:3)=reshape(mean(img(rect_pos(2):rect_pos(2)+rect_pos(4),rect_pos(1):rect_pos(1)+rect_pos(3),1:3),[1 2]),1,3);
i=i+1;
end
avg_ROI_vectors=mean(colorvectors,1);
pause(1)
imshow(imresize(cat(3,avg_ROI_vectors(1),avg_ROI_vectors(2),avg_ROI_vectors(3)),50))
output_to_paste=strrep(mat2str(avg_ROI_vectors),' ',';')
