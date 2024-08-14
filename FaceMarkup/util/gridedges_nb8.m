function nb = gridedges_nb8(sz)
% 8-neighbourhood grid cell connectivity.
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
  [tli, tlj] = ndgrid(1:sz(1)-1, 1:sz(2)-1);
  [bri, brj] = ndgrid(2:sz(1),   2:sz(2));
  [bli, blj] = ndgrid(2:sz(1),   1:sz(2)-1);
  [tri, trj] = ndgrid(1:sz(1)-1, 2:sz(2));

  nb = sub2ind(sz, [tli(:) bri(:);        % top-left    -> bottom-right
                    bli(:) tri(:)], ...   % bottom-left -> top-right
                   [tlj(:) brj(:);
                    blj(:) trj(:)]);
  nb = [gridedges_nb4(sz); nb];%; nb(:,[2 1])];
end
