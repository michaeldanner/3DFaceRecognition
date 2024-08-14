function [y, J] = f_distance(x, a, precision)
% Pairwise distance between two sets of points.
%
% Input arguments:
%  X            NxD matrix of N points in D dimensions.
%  A            Either NxD matrix of N points, in which case each point
%               `i` in X is measued against the same indexed point `i` in
%               A. Alternatively A is 1xD in which case the distance of
%               every point to A is computed.
%  PRECISION    The gradient of the vector length is discontinuous at 0.
%               For values approaching 0 (smaller than PRECISION), we
%               manually set the gradient to 0. This optional variable
%               gives you control. The default value is 1e-10.
%
% Output arguments:
%  Y            Nx1 array of distances.
%  J            Optional Nx(numel(A)) Jacobian matrix (computed only when
%               requested).
%
  if nargin<3 || isempty(precision), precision = 1e-10; end

  if nargout > 1
    [x, Jd] = f_minus(x, a);
    [y, Jl] = f_vectorlength(x, precision);
    J = Jl * Jd;
  else
    y = f_vectorlength(f_minus(x, a), precision);
  end
end
