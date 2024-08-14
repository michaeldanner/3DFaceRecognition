function [y, J] = f_minus(x, a)
% Computes `bsxfun(@minus, X, A)` and its partial derivatives wrt A.
%
% Input arguments:
%  X        N points in D dimensions as NxD matrix.
%  A        A scalar, 1xD row vector, Nx1 column vector or NxD matrix.
%
% Output arguments:
%  Y        The difference `X - A` as MxD matrix.
%  J        Optionally compute and return the Jacobian, a sparse
%           (N*D)x(numel(A)) matrix. Here M*D is the number of variables
%           in Y and numel(A) the number of variables in A. Variable
%           indices are read from X and Y in Matlab order.
%
  y = bsxfun(@minus, x, a);

  if nargout > 1
    szy = size(y);
    sza = size(a);
    
    if prod(sza) == 1
      % A is scalar.
      J = -ones(numel(y), 1);
    elseif sza(1) == 1
      % A is row vector.
      one = -ones(szy(1), 1);
      zero = zeros(szy);
      J = reshape([repmat([one zero], 1, szy(2)-1) one], numel(y), sza(2));
    elseif sza(2) == 1
      % A is column vector.
      n = szy(1); % == sza(1)
      J = repmat(spdiags(-ones(n, 1), 0, n, n), [szy(2) 1]);
    else
      % A is NxD, the same size as X and Y.
      n = numel(y); % == numel(a)
      J = spdiags(-ones(n, 1), 0, n, n);
    end
  end
end
