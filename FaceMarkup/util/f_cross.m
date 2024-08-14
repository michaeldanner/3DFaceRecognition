function [y, J] = f_cross(x, ix)
% Cross product between pairs of vectors (and the partial derivatives).
%
% Input arguments:
%  X        Nx3 matrix of N vectors in Euclidean space.
%  IX       Mx2 matrix of pairs of indices into the rows of X.
%
% Output arguments:
%  Y        The cross products between pairs of vectors in X as array of
%           size Mx1. `Y(i)` is the cross prodcut of `X(IX(i,1),:)` with
%           `X(IX(i,2),:)` (in that order).
%  J        Optionally the Jacobian is returned. It is a sparse matrix
%           where element (i, j) is the partial derivative of the cross
%           product between vectors `IX(i,1)` and `IX(i,2)` with respect
%           to the j-th element (1 <= j <= 3N) of X.
%
  a = x(ix(:,1),:);
  b = x(ix(:,2),:);
  y = cross(a, b, 2);

  if nargout > 1
    numx = size(x, 1);  % size(x, 2) == 3.

    ji = repmat(1:numel(y), [1 4]);
    jj = bsxfun(@plus, ...
                ix(:,[ones(1,6) 2*ones(1,6)]), ...  % 6 = 2 * 3
                numx * [1 2 0   2 0 1   2 0 1   1 2 0]);
    jv = [b(:,[3 1 2]) ...
         -b(:,[2 3 1]) ...
          a(:,[2 3 1]) ...
         -a(:,[3 1 2])];

    J = sparse(ji, jj, jv, numel(y), numel(x));
  end
end
