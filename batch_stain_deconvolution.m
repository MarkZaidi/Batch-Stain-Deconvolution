clear;
%tic;
useGPU=false;
useParallel=true;
%% Stain vectors that work the best:
define_color_vectors
%Calculate vector norm
HDABtoRGB = [He/norm(He) DAB/norm(DAB) Res/norm(Res)]';
RGBtoHDAB = inv(HDABtoRGB);

%% Data loader, create output folder
folderpath='C:\Users\Mark Zaidi\Documents\MATLAB\Stain deconvolution\RGB images\HDAB - H17-178 spheroids - EF5\performace comparison images';
all_target_files=dir([folderpath '\*.tif']);
%sort them from largest file size to smallest, so that if a RAM related
%error occurs, it'll be the first to show
%[~,index] = sortrows([all_target_files.bytes].'); all_target_files = all_target_files(index(end:-1:1)); clear index

deconvoluted_folder=fullfile(folderpath,'\Raw_Data\Zaidi_method');
if ~isdir(deconvoluted_folder)
    mkdir(deconvoluted_folder)
end
%% Begin batch deconvolution 
for z=1%1:length(all_target_files)
    
    inFile = fullfile(folderpath,all_target_files(z).name);
    outFile= fullfile(deconvoluted_folder,all_target_files(z).name);
    
    inFileInfo = imfinfo(inFile);
    inFileInfo=inFileInfo(1);
    %tileSize  = [8192, 8192]; % has to be a multiple of 16.
    tileSize=[8192, 8192];
    
    if useGPU
        fun=@(block_struct) SeparateStains(gpuArray(block_struct.data),RGBtoHDAB);
    else
        fun=@(block_struct) SeparateStains(block_struct.data,RGBtoHDAB);
    end

    
    %As image is being read in, deconvolute on each tile using
    %SeparateStains

    outFileWriter = bigTiffWriter32bit(outFile, inFileInfo(1).Height, inFileInfo(1).Width, tileSize(1), tileSize(2));
    tic;
    blockproc(inFile, tileSize, fun,'Destination',outFileWriter,'UseParallel',useParallel);
    toc;
    clear outFileWriter
    
    
end
%toc;