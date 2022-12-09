inpath='C:\Users\Mark Zaidi\Documents\MATLAB\Stain deconvolution\RGB images\HDAB - H17-178 spheroids - EF5\Raw_Data\deconvoluted_histomicstk_macenkoPCA\H17-178 CAL2 #29 L1 EF5 - high hypoxia.tif';
outpath=strrep(inpath,'.tif','_rearranged.tif');
outpath=inpath;

img=imread(inpath);
inFileInfo=imfinfo(inpath);
tileSize=[2048, 2048];
%replace array below with order of rearranged channels relative to
%original. For example, to swap the 1st and 2nd channels, use [2 1 3]
fun = @(block_struct) block_struct.data(:,:,[2 1 3]);
outFileWriter = bigTiffWriter32bit(outpath, inFileInfo(1).Height, inFileInfo(1).Width, tileSize(1), tileSize(2));
blockproc(img, tileSize, fun, 'Destination', outFileWriter);
outFileWriter.close();