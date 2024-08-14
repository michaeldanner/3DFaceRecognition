function nb = gridedges_fc(sz)
% A fully connected grid.
%
% Input arguments:
%  SZ       Size of the grid as `[H, W]`.
%
% Output arguments:
%  NB       Kx2 matrix of pairs of grid cell indices (by index, not
%           subscripts). Every row describes an edge as the link between
%           the two indexed grid cells.
%
% Considerations:
%  Grid edges are undirected. If A,B is in NB, then B,A is not.
%
  nb = nchoosek(1:prod(sz), 2);
  %nb = [nb; nb(:,[2 1])];
end
