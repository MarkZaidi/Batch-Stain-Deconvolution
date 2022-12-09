%% Convert vectors listed in define_color_vectors.m to QuPath format
% Since there is no easy way of converting the vectors in QuPath, the best
% alternative is to copy and paste the outputs from this script into the
% respective fields for setColorDeconvolutionStains
clear
define_color_vectors;
He=1-He'
DAB=1-DAB'
Res=round(Res*255)'