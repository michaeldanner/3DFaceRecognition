function ix = subgrid_indices(sz_full, sz_sub, spacing)
% Linear indices for vertices forming a subgrid.
%
% Input arguments:
%  SZ_FULL          Size `[Hf, Wf]` of the full grid.
%  SZ_SUB           Size `[Hs, Ws]` of the sub grid.
%  SPACING          Integer to specify the spacing of the subgrid within
%                   the full grid. Mode
%                   1 or 'full' leaves no space around the subgrid,
%                   2 or 'medium' leaves half the space around the subgrid
%                     compared to full space within the subgrid,
%                   3 or 'small' leaves equal space around and within the
%                     subgrid.
%                   (All spacing of course up to rounding.)
%
% Output arguments:
%  IX               Index array of length `Hs * Ws` providing the (linear)
%                   cell indices of the subgrid vertices inside the full
%                   grid.
%
% Examples:
%  * `SUBGRID_INDICES([5 6], [3 2], 1) == [1 3 5 26 28 30]'`
%       o  .  .  .  .  o
%       .  .  .  .  .  .
%       o  .  .  .  .  o
%       .  .  .  .  .  .
%       o  .  .  .  .  o
%  * `SUBGRID_INDICES([5 6], [2 2], 2) == [7 9 22 24]'`
%       .  .  .  .  .  .
%       .  o  .  .  o  .
%       .  .  .  .  .  .
%       .  o  .  .  o  .
%       .  .  .  .  .  .
%  * `SUBGRID_INDICES([5 8], [2 2], 3) == [12 14 27 29]'`
%       .  .  .  .  .  .  .  .
%       .  .  o  .  .  o  .  .
%       .  .  .  .  .  .  .  .
%       .  .  o  .  .  o  .  .
%       .  .  .  .  .  .  .  .
%
  switch spacing
    case {1, 'full'}
      %step = (sz_full - 1) ./ (sz_sub - 1);
      start = [1 1];
    case {2, 'medium'}
      step = sz_full ./ sz_sub;
      start = (step - 1) ./ 2 + 1;
    case {3, 'small'}
      step = (sz_full + 1) ./ (sz_sub + 1);
      start = step;
  end

  stop = sz_full + 1 - start;
  [r, c] = ndgrid(round(linspace(start(1), stop(1), sz_sub(1))), ...
                  round(linspace(start(2), stop(2), sz_sub(2))));
  ix = sub2ind(sz_full, r(:), c(:));
end
