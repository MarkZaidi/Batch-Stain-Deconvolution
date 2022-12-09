    function [ counts ] = getHist( block,ch,binEdges )
    block.data=block.data(:,:,ch);
    %[counts,]=hist(block.data(:), linspace(-50,50,100000));
    counts=histogram(block.data,binEdges).BinCounts;
    %Note on bin edges: Each bin includes the left edge, but does not
    %include the right edge, except for the last bin which includes both
    %edges. For example, if bin edges were -50,-25,25,50, a pixel of -25
    %would fall into the -25,25 bin.
    counts = shiftdim(counts,-1);
    end