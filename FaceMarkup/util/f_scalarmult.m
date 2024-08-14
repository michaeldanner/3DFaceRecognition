function [y, J] = f_scalarmult(x, w)
% Scalar multiplication (or elementwise) and the partial derivatives.
%
% Input arguments:
%  X        N points in D dimensions as NxD matrix.
%  W        Scalar or matrix of size NxD.
%
% Output arguments:
%  Y        The multiplication `W .* X`.
%  J        Optionally compute and return the Jacobian, a sparse
%           (N*D)x(N*D) matrix. Here N*D the number of variables in X.
%           Variable indices are read from X and Y in row-first order, per
%           Matlab standard.
%
  warning('Please use f_times.');

  y = w .* x;

  if nargout > 1
    nx = numel(x);
    if numel(w) == 1
      w = w * ones(nx, 1);
    end
    J = spdiags(w, 0, nx, nx);
  end
end
