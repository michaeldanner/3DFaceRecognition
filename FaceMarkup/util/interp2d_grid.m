function rgb = interp2d_grid(img, qs, qt, method, extrapval)
%INTERP2D_GRID Wrapper for `interp2d` whith sampling points from `ndgrid`.
%
% Input arguments:
%  IMG        HxWxD image to be interpolated.
%  QS         Horizontal positions of the query points. It is a vector of
%             equally spaced and monotonic X values (conditions are forced
%             to use fast interpolation), e.g. from `linspace` or `:`
%             notation.
%  QT         Vertical positions of the query points, same size as QS and
%             with the same conditions.
%  METHOD     Sampling method. 'nearest', 'linear' or 'bicubic'. Do not use
%             *METHOD notation: if METHOD is specified, the asterisk is
%             added automatically.
%  EXTRAPVAL  A scalar value that is assigned to all queries that lie
%             outside the domain of the sample points.
%
% Output arguments:
%  RGB     Matrix of interpolated data. Where QS is size MxN, RGB is size
%          MxNxD.
%
% See also: interp2d, interp2.
%
  args = {};
  if nargin>3, args{1} = ['*' method]; end
  if nargin>4, args{2} = extrapval; end

  [qt, qs] = ndgrid(qt, qs);
  rgb = interp2d(img, qs, qt, args{:});
end
