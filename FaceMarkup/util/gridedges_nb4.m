function nb = gridedges_nb4(sz)
% 4-neighbourhood grid cell connectivity.
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
  [ti, tj] = ndgrid(1:sz(1)-1, 1:sz(2));
  [bi, bj] = ndgrid(2:sz(1),   1:sz(2));
  [li, lj] = ndgrid(1:sz(1),   1:sz(2)-1);
  [ri, rj] = ndgrid(1:sz(1),   2:sz(2));

  nb = sub2ind(sz, [ ti(:)  bi(:);        % top         -> bottom
                     li(:)  ri(:)], ...   % left        -> right
                   [ tj(:)  bj(:);
                     lj(:)  rj(:)]);
  %nb = [nb; nb(:,[2 1])];
end
