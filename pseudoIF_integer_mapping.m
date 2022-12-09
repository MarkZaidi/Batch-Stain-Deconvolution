%pseudoIF_integer_mapping.m essentially converts 32-bit IEEEFP .tifs
%generated from batch_stain_normalization to 8 or 16-bit unsigned integer
%values. Any value less than 0 will be mapped as 0, any value greater than
%1 will be mapped to 255 if uint8 or 65535. Thus, only images that have
%been normalized such that the majority of values lie between 0-1 should be
%used as inputs, such as those from batch_stain_normalizaiton.m

clear;
tic;
useGPU=false;
useParallel=true;
output_bit_depth=16;

%% Data loader, create output folder
folderpath='C:\Users\Mark Zaidi\Documents\MATLAB\Stain deconvolution\RGB images\HDAB - H17-178 spheroids - EF5\Raw_Data\Zaidi_method\Batch_Normalized';
all_target_files=dir([folderpath '\*.tif']);
%sort them from largest file size to smallest, so that if a RAM related
%error occurs, it'll be the first to show
%[~,index] = sortrows([all_target_files.bytes].'); all_target_files = all_target_files(index(end:-1:1)); clear index
if output_bit_depth==8
    deconvoluted_folder=fullfile(folderpath,'\mapped_to_uint8');
    if ~isdir(deconvoluted_folder)
        mkdir(deconvoluted_folder)
    end
elseif output_bit_depth==16
    deconvoluted_folder=fullfile(folderpath,'\mapped_to_uint16');
    if ~isdir(deconvoluted_folder)
        mkdir(deconvoluted_folder)
    end
else
    error('output_bit_depth has to be 8 or 16')
end
%% Begin batch deconvolution only to get minimum and maximum values (minmax4 and minmax5)
for z=1:length(all_target_files)
    
    inFile = fullfile(folderpath,all_target_files(z).name);
    outFile= fullfile(deconvoluted_folder,all_target_files(z).name);
    
    inFileInfo = imfinfo(inFile);
    inFileInfo=inFileInfo(1);
    tileSize=[2048, 2048]; % has to be a multiple of 16.
    if output_bit_depth==8
        if useGPU
            fun=@(block_struct) im2uint8(gpuArray(block_struct.data));
        else
            fun=@(block_struct) im2uint8(block_struct.data);
        end
        outFileWriter = bigTiffWriter8bit(outFile, inFileInfo(1).Height, inFileInfo(1).Width, tileSize(1), tileSize(2));
    elseif output_bit_depth==16
        if useGPU
            fun=@(block_struct) im2uint16(gpuArray(block_struct.data));
        else
            fun=@(block_struct) im2uint16(block_struct.data);
        end
        outFileWriter = bigTiffWriter16bit(outFile, inFileInfo(1).Height, inFileInfo(1).Width, tileSize(1), tileSize(2));
    else
        error('output_bit_depth has to be 8 or 16')
    end
    
    
    %As image is being read in, deconvolute on each tile using
    %SeparateStains
    
    blockproc(inFile, tileSize, fun,'Destination',outFileWriter,'UseParallel',useParallel);
    clear outFileWriter
    
    
end
toc;