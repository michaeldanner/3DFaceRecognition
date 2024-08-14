function [y, J] = f_dot(x, nb)
% Dot product between pairs of vectors (and the partial derivatives).
%
% Input arguments:
%  X        NxD matrix of N vectors in D dimensions.
%  NB       Mx2 matrix of pairs of indices into the rows of X.
%
% Output arguments:
%  Y        The dot products between pairs of vectors in X as array of
%           size Mx1. `Y(i)` is the dot prodcut of `X(NB(i,1),:)` with
%           `X(NB(i,2),:)`.
%  J        Optionally the Jacobian is returned. It is a sparse matrix
%           where element (i, j) is the partial derivative of the dot
%           product between vectors `NB(i,1)` and `NB(i,2)` with respect
%           to the j-th element (1 <= j <= N*D) of X.
%
  a = x(nb(:,1),:);
  b = x(nb(:,2),:);
  y = dot(a, b, 2);

  if nargout > 1
    [numx, dimx] = size(x);

    ji = repmat(1:numel(y), [1 2*dimx]);
    jj = bsxfun(@plus, ...
                nb(:,[ones(1,dimx) 2*ones(1,dimx)]), ...
                numx * [1:dimx 1:dimx] - numx);
    jv = [b a];

    J = sparse(ji, jj, jv, numel(y), numel(x));
  end
end
