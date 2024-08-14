function nb = gridedges_nb16(sz)
% 16-neighbourhood grid cell connectivity.
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
  nb4 = gridedges_nb4(sz);
  nb8 = gridedges_nb8(sz);
  nb4 = sparse(nb4, nb4(:,[2 1]), 1);
  nb8 = sparse(nb8, nb8(:,[2 1]), 1);

  [i, j] = find(nb4 * nb8);
  m = i ~= j;
  i = i(m);
  j = j(m);
  nb = unique([min(i, j) max(i, j)], 'rows');
end
