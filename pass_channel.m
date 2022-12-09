function OutCh = pass_channel(inRGB, ch)
%Simple function that allows only 1 channel from an RGB image to be
%outputted
OutCh=inRGB(:,:,ch);