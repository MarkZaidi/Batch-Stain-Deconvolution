clear;
tic
%% Stain vectors that work the best:
define_color_vectors
%% Calculate normalization parameters based on stain vectors (minmax2)
%Reconstruct color vectors into side-by-side representative image
HeSpot=im2uint8(imresize(cat(3,He(1),He(2),He(3)),10));
DabSpot=im2uint8(imresize(cat(3,DAB(1),DAB(2),DAB(3)),10));
ResSpot=im2uint8(imresize(cat(3,Res(1),Res(2),Res(3)),10));
pure_stains=[HeSpot DabSpot ResSpot];
% combine stain vectors to deconvolution matrix
HDABtoRGB = [He/norm(He) DAB/norm(DAB) Res/norm(Res)]';
RGBtoHDAB = inv(HDABtoRGB);
%Deconvolute pure_stains to get absolute possible min and max values
pure_stains_deconvoluted=SeparateStains(pure_stains,RGBtoHDAB);
HeSpot_deconvoluted=SeparateStains(HeSpot,RGBtoHDAB);
DabSpot_deconvoluted=SeparateStains(DabSpot,RGBtoHDAB);
ResSpot_deconvoluted=SeparateStains(ResSpot,RGBtoHDAB);
%minmax calculated by deconvoluting each spot and getting the minmax
%independently from each stain
 minmax2(1,1)=min(min(min(HeSpot_deconvoluted(:,:,:))));
 minmax2(2,1)=max(max(max(HeSpot_deconvoluted(:,:,:))));
 minmax2(1,2)=min(min(min(DabSpot_deconvoluted(:,:,:))));
 minmax2(2,2)=max(max(max(DabSpot_deconvoluted(:,:,:))));  
 minmax2(1,3)=min(min(min(ResSpot_deconvoluted(:,:,:))));
 minmax2(2,3)=max(max(max(ResSpot_deconvoluted(:,:,:))));  
%% Data loader, create output folder
folderpath='C:\Users\Mark Zaidi\Documents\MATLAB\Stain deconvolution\RGB images\HDAB - PIMO GBM sections - whole slide images';
all_target_files=dir([folderpath '\*.tif']);
%sort them from largest file size to smallest, so that if a RAM related
%error occurs, it'll be the first to show
%[~,index] = sortrows([all_target_files.bytes].'); all_target_files = all_target_files(index(end:-1:1)); clear index


deconvoluted_folder=fullfile(folderpath,'Deconvoluted_minmax5\');
if ~isdir(deconvoluted_folder)
    mkdir(deconvoluted_folder)
end
minmax5_table=table([0],[0],[0],[0],[0],[0]);
minmax5_table.Properties.VariableNames={'Stain1Min','Stain1Max','Stain2Min','Stain2Max','Stain3Min','Stain3Max'};
%% Begin batch deconvolution only to get minimum and maximum values (minmax4 and minmax5)
fprintf('Calculating global min and max values of the dataset...\n')
for z=1:length(all_target_files)
  
    inFile = fullfile(folderpath,all_target_files(z).name);
    outFile= fullfile(deconvoluted_folder,all_target_files(z).name);
    
    inFileInfo = imfinfo(inFile);
    inFileInfo=inFileInfo(1);
    %tileSize  = [8192, 8192]; % has to be a multiple of 16.
    tileSize=[2048, 2048];
    
    fun=@(block_struct) SeparateStains(block_struct.data,RGBtoHDAB);
    clear temp
    %As image is being read in, deconvolute on each tile using
    %SeparateStains
    temp=blockproc(inFile, tileSize, fun);
    %we ran the deconvolution on the original image, loaded straight from the
    %network drive.
    %minmax calculated on a per-image basis, as it has been before
    for p=1:3
        minmax(1,p)=min(min(temp(:,:,p)));
        minmax(2,p)=max(max(temp(:,:,p)));
        %Obtain histogram for each channel of the image, using fixed bins
        hstogrm=histogram(temp(:,:,p),linspace(-50,50,100000));
        if p==1
            BinCounts_ch1(z,:)=[0 hstogrm.BinCounts];
        elseif p==2
            BinCounts_ch2(z,:)=[0 hstogrm.BinCounts];
        elseif p==3
            
            BinCounts_ch3(z,:)=[0 hstogrm.BinCounts];
        end

        clear hstogrm
        
        
    end
    minmax5_table(z,:)=array2table(reshape(minmax,[1 6]));
end
%% Identify the bins containing the specified percentiles to perform linear equalization
%After iterating over each image in the dataset and collecting the
%histograms, each bin for each channel is pooled. From this, a CDF is
%calculated, to identify the percentile thresholds specified as
%contrast_adjustment_factor_lower and contrast_adjustment_factor_upper.
%Essentially, this performs a constant linear equalization across the
%entire dataset. If the upper limit is 0 and the lower limit is 1, this is
%effectively just normalization across the entire dataset
binEdges=linspace(-50,50,100000); %figured this would be a broad enough range
BinCounts_ch1=sum(BinCounts_ch1,1);
BinCounts_ch2=sum(BinCounts_ch2,1);
BinCounts_ch3=sum(BinCounts_ch3,1);
contrast_adjustment_factor_lower_ch1=0.98; %lower values shift histogram to the left, increases lower saturation
contrast_adjustment_factor_upper_ch1=0.001; %greater values spread the histogram to the right, increases upper saturation
contrast_adjustment_factor_lower_ch2=0.99; %lower values shift histogram to the left, increases lower saturation
contrast_adjustment_factor_upper_ch2=0.001; %greater values spread the histogram to the right, increases upper saturation
contrast_adjustment_factor_lower_ch3=0.99; %lower values shift histogram to the left, increases lower saturation
contrast_adjustment_factor_upper_ch3=0.001; %greater values spread the histogram to the right, increases upper saturation

%modified version of stretchlim function to get percentiles
cdf_ch1 = cumsum(BinCounts_ch1)/sum(BinCounts_ch1); %cumulative distribution function
ilow_ch1 = find(cdf_ch1 > contrast_adjustment_factor_upper_ch1, 1, 'first');
ihigh_ch1 = find(cdf_ch1 >= contrast_adjustment_factor_lower_ch1, 1, 'first');
cdf_ch2 = cumsum(BinCounts_ch2)/sum(BinCounts_ch2); %cumulative distribution function
ilow_ch2 = find(cdf_ch2 > contrast_adjustment_factor_upper_ch2, 1, 'first');
ihigh_ch2 = find(cdf_ch2 >= contrast_adjustment_factor_lower_ch2, 1, 'first');
cdf_ch3 = cumsum(BinCounts_ch3)/sum(BinCounts_ch3); %cumulative distribution function
ilow_ch3 = find(cdf_ch3 > contrast_adjustment_factor_upper_ch3, 1, 'first');
ihigh_ch3 = find(cdf_ch3 >= contrast_adjustment_factor_lower_ch3, 1, 'first');
minmax6=[binEdges(ilow_ch1),binEdges(ilow_ch2),binEdges(ilow_ch3);binEdges(ihigh_ch1),binEdges(ihigh_ch2),binEdges(ihigh_ch3)];

writetable(minmax5_table,'normalization bounds.xlsx')
minmax5=[min(minmax5_table.Stain1Min),min(minmax5_table.Stain2Min),min(minmax5_table.Stain3Min);max(minmax5_table.Stain1Max),max(minmax5_table.Stain2Max),max(minmax5_table.Stain3Max)];

fprintf('Begin batch deconvolution\n')
%% Begin batch deconvolution
for r=1:length(all_target_files)

    
    %% BigTiff read and deconvolution
    inFile = fullfile(folderpath,all_target_files(r).name);
    outFile= fullfile(deconvoluted_folder,all_target_files(r).name);
    
    inFileInfo = imfinfo(inFile);
    inFileInfo=inFileInfo(1);
    %tileSize  = [8192, 8192]; % has to be a multiple of 16.
    tileSize=[2048, 2048];
    
    fun=@(block_struct) SeparateStains(block_struct.data,RGBtoHDAB);
    clear temp
    %As image is being read in, deconvolute on each tile using
    %SeparateStains
    temp=blockproc(inFile, tileSize, fun);
    %we ran the deconvolution on the original image, loaded straight from the
    %network drive.
    %minmax calculated on a per-image basis, as it has been before
    for p=1:3
        minmax(1,p)=min(min(temp(:,:,p)));
        minmax(2,p)=max(max(temp(:,:,p)));
    end
    %minmax5_table(r,:)=array2table(reshape(minmax,[1 6]));
    for p=1:3
        minmax3(1,p)=min(min(pure_stains_deconvoluted(:,:,p)));
        minmax3(2,p)=max(max(pure_stains_deconvoluted(:,:,p)));
    end
    %% MODIFICATION - ADDED IMCOMPLEMENT
    %minmax calculated from deconvoluting image with every possible RGB
    %value:
    minmax4=[-58.717167,-15.071361,-70.365967;58.697033,15.070252,59.575241];
    
    if inFileInfo.BitsPerSample(1)==8
        %If the input image is 8 bit, convert the single-precision temp image
        %to uint8 AFTER performing the normalization
       %change minmax below to match whatever normalization method you want
       %to test
        fun_normalize=@(block_struct) im2uint8(imcomplement(imnormalize(block_struct.data,minmax6)));
        %use the bigTiffWriter adapter with metadata specs for 8 bit RGB image
        %when writing
        outFileWriter = bigTiffWriter8bit(outFile, inFileInfo(1).Height, inFileInfo(1).Width, tileSize(1), tileSize(2));
    elseif inFileInfo.BitsPerSample(1)==16
        %no need to convert single to 16 bit if the original image was 16 bit, bigTiffWriter seems to handle it
        %just fine
        fun_normalize=@(block_struct) imcomplement(imnormalize(block_struct.data,minmax));
        outFileWriter = bigTiffWriter(outFile, inFileInfo(1).Height, inFileInfo(1).Width, tileSize(1), tileSize(2));
    else
        error('Image BitsPerSample is not 8 or 16')
    end
    blockproc(temp, tileSize, fun_normalize, 'Destination', outFileWriter);
    outFileWriter.close();
    fprintf(['Finished ' all_target_files(r).name '\n'])
end
%% Show the images after applying a linear equalization with the same range to all
%  im1=imread(fullfile(deconvoluted_folder,'H17-178 549 CTRL L2 EF5 - no hypoxia.tif'));
%  im2=imread(fullfile(deconvoluted_folder,'H17-178 CA DUAL #26 L1 EF5 - very low artifactual DAB.tif'));
%  im3=imread(fullfile(deconvoluted_folder,'H17-178 CA 9 #2 L2 EF5.tif'));
%  im4=imread(fullfile(deconvoluted_folder,'H17-178 CAL2 #29 L1 EF5 - high hypoxia.tif'));
%  view_ch=1;
%  figure('Name',['Contrast Adjustment Factor: ' num2str(contrast_adjustment_factor_lower_ch1) '_' num2str(contrast_adjustment_factor_upper_ch1)])
%  set(gcf, 'WindowState', 'maximized');
%  subplot(2,4,1)
% imshow(imoverlay(imoverlay(im1(:,:,view_ch),im1(:,:,view_ch)==0,'blue'),im1(:,:,view_ch)==255,'red'))
% subplot(2,4,2)
% imshow(imoverlay(imoverlay(im2(:,:,view_ch),im2(:,:,view_ch)==0,'blue'),im2(:,:,view_ch)==255,'red'))
% subplot(2,4,3)
% imshow(imoverlay(imoverlay(im3(:,:,view_ch),im3(:,:,view_ch)==0,'blue'),im3(:,:,view_ch)==255,'red'))
% subplot(2,4,4)
% imshow(imoverlay(imoverlay(im4(:,:,view_ch),im4(:,:,view_ch)==0,'blue'),im4(:,:,view_ch)==255,'red'))
% subplot(2,4,5)
% imhist(im1(:,:,view_ch))
% title(['LowSat:' num2str(sum(im1(:,:,view_ch)==0,'all')/numel(im1(:,:,view_ch))*100) '%' ' | UpperSat:' num2str(sum(im1(:,:,view_ch)==255,'all')/numel(im1(:,:,view_ch))*100) '%'])
% subplot(2,4,6)
% imhist(im2(:,:,view_ch))
% title(['LowSat:' num2str(sum(im2(:,:,view_ch)==0,'all')/numel(im2(:,:,view_ch))*100) '%' ' | UpperSat:' num2str(sum(im2(:,:,view_ch)==255,'all')/numel(im2(:,:,view_ch))*100) '%'])
% subplot(2,4,7)
% imhist(im3(:,:,view_ch))
% title(['LowSat:' num2str(sum(im3(:,:,view_ch)==0,'all')/numel(im3(:,:,view_ch))*100) '%' ' | UpperSat:' num2str(sum(im3(:,:,view_ch)==255,'all')/numel(im3(:,:,view_ch))*100) '%'])
% subplot(2,4,8)
% imhist(im4(:,:,view_ch))
% title(['LowSat:' num2str(sum(im4(:,:,view_ch)==0,'all')/numel(im4(:,:,view_ch))*100) '%' ' | UpperSat:' num2str(sum(im4(:,:,view_ch)==255,'all')/numel(im4(:,:,view_ch))*100) '%'])

%% Summary of different minmax ranges:
%minmax: calculated on a per image basis, as it was done before (bad)
%minmax2: took the color vectors, turned them to pure color spots. Got
%the minmax by deconvoluting each spot independently and getting the minmax from all channels
%for a given spot
%minmax3: took the color vectors, turned them to pure color spots.
%Concatenated each spot horizontally into it's own image, deconvoluted.
%minmax(1:2,1) comes from the H stain, 2=Dab,3=Res
%minmax4: deconvoluted EVERY FUCKING GODDAMN POSSIBLE COLOR IN EXISTENCE
%from an 8 bit image. Got the minmax from that image. To do after
%Wednesday: see how minmax4 looks. Compare to all
%minmax5: iterate over each image, get minmax, record it in a table.
%After iterating through all images, get global min and max, and normalize
%to that
%minmax6: same as minmax5, however this method allows for linear
%equalization
toc;

