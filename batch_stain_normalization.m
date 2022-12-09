clear
%% Data loader, create output folder
folderpath='C:\Users\Mark Zaidi\Documents\MATLAB\Stain deconvolution\RGB images\HDAB - H17-178 spheroids - EF5\Raw_Data\histomicstk_div2000';
all_target_files=dir([folderpath '\*.tif']);
%sort them from largest file size to smallest, so that if a RAM related
%error occurs, it'll be the first to show
%[~,index] = sortrows([all_target_files.bytes].'); all_target_files = all_target_files(index(end:-1:1)); clear index
Processing_Xu_or_Macenko_methods=0

deconvoluted_folder=fullfile(folderpath,'Batch_Normalized\');

if ~isdir(deconvoluted_folder)
    mkdir(deconvoluted_folder)
end
%% Initializing constants
%minmax5_table will contain per-image upper and lower limit equalization
%bounds, as determined by the percentiles defined by the
%contrast_adjustment_factors below. Currently, this is NOT USED for
%equalization, since a global histogram is computed across all images in
%the folder, and equalization limits are computed from those, which are
%then applied consistently across all images in the dataset. The function
%of this table is to compare batch normalization with per-image
%normalization, and the artifacts that can arise from it
minmax5_table=table(zeros(length(all_target_files),1),zeros(length(all_target_files),1),zeros(length(all_target_files),1),zeros(length(all_target_files),1),zeros(length(all_target_files),1),zeros(length(all_target_files),1));
minmax5_table.Properties.VariableNames={'Stain1Min','Stain1Max','Stain2Min','Stain2Max','Stain3Min','Stain3Max'};
binEdges=linspace(-50,50,100000); %figured this would be a broad enough range with enough increments. May have to modify when I learn more about the maximum and minimum limits

%Mark to note: deconvoluted images are not inverted, as would expect from
%the previous version of this code. As such, upper and lower limit values
%below may have to be adjusted, as well as their descriptions. Also, might
%be good to find a way to automatically generate these values.
contrast_adjustment_factor_lower_ch1=0.01; %greater values shift histogram to the left, increases lower saturation
contrast_adjustment_factor_upper_ch1=0.99;%lower values spread the histogram to the right, increases upper saturation
contrast_adjustment_factor_lower_ch2=0.01;%greater values shift histogram to the left, increases lower saturation
contrast_adjustment_factor_upper_ch2=0.99;%lower values spread the histogram to the right, increases upper saturation
contrast_adjustment_factor_lower_ch3=0.01;%greater values shift histogram to the left, increases lower saturation
contrast_adjustment_factor_upper_ch3=0.99;%lower values spread the histogram to the right, increases upper saturation

%% TEMPORARY OVERRIDE FOR DEALING WITH MACENKO AND XU DECONVOLVED. DELETE IMMDEDIATELY AFTER AS WELL AS THE 1- ON fun_normalize=@(block_struct) 1-imnormalize(block_struct.data,minmax6);
if Processing_Xu_or_Macenko_methods
    %If dealing with the outputs of the Macenko or Xu methods, the nuclear
    %channel appears to be channel 2 and the DAB is channel 1. Furthermore, the
    %outputs of the histomicstk deconvolution for those two methods are
    %inverted and have to be re-inverted during the normalization process
    
    contrast_adjustment_factor_upper_ch1=1-0.01;%1-0.1; %greater values shift histogram to the left, increases lower saturation
    contrast_adjustment_factor_lower_ch1=1-0.99;%1-0.995;%lower values spread the histogram to the right, increases upper saturation
    contrast_adjustment_factor_upper_ch2=1-0.01;%1-0.01;%greater values shift histogram to the left, increases lower saturation
    contrast_adjustment_factor_lower_ch2=1-0.99;%1-0.999;%lower values spread the histogram to the right, increases upper saturation
    contrast_adjustment_factor_upper_ch3=1-0.01;%greater values shift histogram to the left, increases lower saturation
    contrast_adjustment_factor_lower_ch3=1-0.99;%lower values spread the histogram to the right, increases upper saturation
end
%% Calculate normalization bounds
fprintf('Calculating global min and max values of the dataset...\n')
for z=1:length(all_target_files)
    %Specify input and output file properties
    inFile = fullfile(folderpath,all_target_files(z).name);
    
    inFileInfo = imfinfo(inFile);
    inFileInfo=inFileInfo(1);
    tileSize=[2048, 2048]; % has to be a multiple of 16.
    %compute histograms for each of the channels (will only do first 3)
    for p=1:inFileInfo.SamplesPerPixel
        
        hstogrm = permute(sum(sum(blockproc(inFile, tileSize, @(block_struct) getHist(block_struct,p,binEdges)),1),2),[3 2 1])';
        %Yeah, it looks ugly, but it works. Good luck finding a way to
        %compute an image histogram without loading the entire image into
        %memory
        %For each channel(p), compute histogram, calculate cumulative distribution,
        %and record in table for later use of per-mage equalization (inferior
        %method)
        if p==1
            BinCounts_ch1(z,:)=[0 hstogrm];
            %modified version of stretchlim function to get percentiles
            cdf_ch1 = cumsum(BinCounts_ch1(z,:))/sum(BinCounts_ch1(z,:)); %cumulative distribution function
            ilow_ch1 = find(cdf_ch1 >= contrast_adjustment_factor_upper_ch1, 1, 'first');
            ihigh_ch1 = find(cdf_ch1 > contrast_adjustment_factor_lower_ch1, 1, 'first');
            minmax5_table.Stain1Max(z)=binEdges(ilow_ch1);
            minmax5_table.Stain1Min(z)=binEdges(ihigh_ch1);
            
        elseif p==2
            BinCounts_ch2(z,:)=[0 hstogrm];
            %modified version of stretchlim function to get percentiles
            cdf_ch2 = cumsum(BinCounts_ch2(z,:))/sum(BinCounts_ch2(z,:)); %cumulative distribution function
            ilow_ch2 = find(cdf_ch2 >= contrast_adjustment_factor_upper_ch2, 1, 'first');
            ihigh_ch2 = find(cdf_ch2 > contrast_adjustment_factor_lower_ch2, 1, 'first');
            minmax5_table.Stain2Max(z)=binEdges(ilow_ch2);
            minmax5_table.Stain2Min(z)=binEdges(ihigh_ch2);
        elseif p==3
            
            BinCounts_ch3(z,:)=[0 hstogrm];
            %modified version of stretchlim function to get percentiles
            cdf_ch3 = cumsum(BinCounts_ch3(z,:))/sum(BinCounts_ch3(z,:)); %cumulative distribution function
            ilow_ch3 = find(cdf_ch3 >= contrast_adjustment_factor_upper_ch3, 1, 'first');
            ihigh_ch3 = find(cdf_ch3 > contrast_adjustment_factor_lower_ch3, 1, 'first');
            minmax5_table.Stain3Max(z)=binEdges(ilow_ch3);
            minmax5_table.Stain3Min(z)=binEdges(ihigh_ch3);
        end
        
        clear hstogrm
        
        
    end
    minmax5_table.imagepath(z)={inFile};
end
writetable(minmax5_table,'normalization bounds with equalization.xlsx')

%% Identify the bins containing the specified percentiles to perform linear equalization
%After iterating over each image in the dataset and collecting the
%histograms, each bin for each channel is pooled. From this, a CDF is
%calculated, to identify the percentile thresholds specified as
%contrast_adjustment_factor_lower and contrast_adjustment_factor_upper.
%Essentially, this performs a constant linear equalization across the
%entire dataset. If the upper limit is 0 and the lower limit is 1, this is
%effectively just normalization across the entire dataset
BinCounts_ch1=sum(BinCounts_ch1,1);
BinCounts_ch2=sum(BinCounts_ch2,1);
BinCounts_ch3=sum(BinCounts_ch3,1);

clear cdf_ch1 cdf_ch2 cdf_ch3 ilow_ch1 ilow_ch2 ilow_ch3 ihigh_ch1 ihigh_ch2 ihigh_ch3
%modified version of stretchlim function to get percentiles
cdf_ch1 = cumsum(BinCounts_ch1)/sum(BinCounts_ch1); %cumulative distribution function
ilow_ch1 = find(cdf_ch1 >= contrast_adjustment_factor_upper_ch1, 1, 'first');%Find first case in CDF graph where the total count becomes greather than or equal to contrast_adjustment_factor_upper_ch1
ihigh_ch1 = find(cdf_ch1 > contrast_adjustment_factor_lower_ch1, 1, 'first');
cdf_ch2 = cumsum(BinCounts_ch2)/sum(BinCounts_ch2); %cumulative distribution function
ilow_ch2 = find(cdf_ch2 >= contrast_adjustment_factor_upper_ch2, 1, 'first');
ihigh_ch2 = find(cdf_ch2 > contrast_adjustment_factor_lower_ch2, 1, 'first');
cdf_ch3 = cumsum(BinCounts_ch3)/sum(BinCounts_ch3); %cumulative distribution function
ilow_ch3 = find(cdf_ch3 >= contrast_adjustment_factor_upper_ch3, 1, 'first');
ihigh_ch3 = find(cdf_ch3 > contrast_adjustment_factor_lower_ch3, 1, 'first');
%minmax6 - global minimum and maximum limits to perform equalization to.
minmax6=[binEdges(ilow_ch1),binEdges(ilow_ch2),binEdges(ilow_ch3);binEdges(ihigh_ch1),binEdges(ihigh_ch2),binEdges(ihigh_ch3)];

%minmax5=[min(minmax5_table.Stain1Min),min(minmax5_table.Stain2Min),min(minmax5_table.Stain3Min);max(minmax5_table.Stain1Max),max(minmax5_table.Stain2Max),max(minmax5_table.Stain3Max)];
%% Apply normalization bounds
%Since data is lost by converting from 32 to 8 bit precision, images will
%be normalized from 0 to 1 in 32-bit single precision. A separate program
%will be built to invert and write out as 8 bit .tiffs to mimic fluorescent
%microscopy single-channel images
fprintf('Begin batch normalization\n')
for r=1:length(all_target_files)
    minmax5=[minmax5_table.Stain1Max(r) minmax5_table.Stain2Max(r) minmax5_table.Stain3Max(r);minmax5_table.Stain1Min(r) minmax5_table.Stain2Min(r) minmax5_table.Stain3Min(r)];
    inFile = fullfile(folderpath,all_target_files(r).name);
    outFile= fullfile(deconvoluted_folder,all_target_files(r).name);
    
    inFileInfo = imfinfo(inFile);
    inFileInfo=inFileInfo(1);
    fun_normalize=@(block_struct) imnormalize(block_struct.data,minmax6);
    if Processing_Xu_or_Macenko_methods
        fun_normalize=@(block_struct) 1-imnormalize(block_struct.data,minmax6);
    end
    
    %use the bigTiffWriter adapter with metadata specs for 32 bit RGB image
    %when writing
    fprintf(['Writing: ',all_target_files(r).name,'\n'])
    outFileWriter = bigTiffWriter32bit(outFile, inFileInfo(1).Height, inFileInfo(1).Width, tileSize(1), tileSize(2));
    % temp=blockproc(inFile, tileSize, fun_normalize);
    % subplot(1,3,1)
    % imshow(temp(:,:,1))
    % subplot(1,3,2)
    % imshow(imcomplement(temp(:,:,1)))
    % subplot(1,3,3)
    % histogram(temp(:,:,1))
    
    blockproc(inFile, tileSize, fun_normalize, 'Destination', outFileWriter);
    outFileWriter.close();
    fprintf(['Finished ' all_target_files(r).name '\n'])
end
%% Show the images after applying a linear equalization with the same range to all

preview_normalization(deconvoluted_folder,'H17-178 549 CTRL L2 EF5 - no hypoxia.tif','H17-178 CA DUAL #26 L1 EF5 - very low artifactual DAB.tif','H17-178 CA 9 #2 L2 EF5.tif','H17-178 CAL2 #29 L1 EF5 - high hypoxia.tif',1)
