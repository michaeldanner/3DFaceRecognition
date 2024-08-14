function [y, J] = fnb_distance(x, nb, precision)
% Euclidean distance between pairs of neighbouring points.
%
% Input arguments:
%  X           NxD matrix of N points in D dimensions.
%  NB          Mx2 adjacency matrix. For each row with values `i, j` the
%              distance is computed between points `X(i,:)` and `X(j,:)`.
%  PRECISION   The gradient of the vector length is discontinuous at 0. For
%              values approaching 0 (smaller than PRECISION), we manually
%              set the gradient to 0. This optional variable gives you
%              control. The default value is 1e-10.
%
% Output arguments:
%  Y       Mx1 array of distances.
%  J       Optional Mx(N*D) Jacobian matrix (computed only when requested).
%
  if nargin<3 || isempty(precision), precision = 1e-10; end

  if nargout > 1
    [x, Jd] = fnb_minus(x, nb);
    [y, Jl] = f_vectorlength(x, precision);
    J = Jl * Jd;
  else
    y = f_vectorlength(fnb_minus(x, nb), precision);
  end
end
