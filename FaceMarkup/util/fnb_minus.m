function [y, J] = fnb_minus(x, nb)
% Computes `X(NB(:,1),:) - X(NB(:,2),:)` and its partial derivatives.
%
% Input arguments:
%  X        N points in D dimensions as NxD matrix.
%  NB       Pairs of points (indices into the rows of X) as Mx2 matrix.
%
% Output arguments:
%  Y        The difference `NB(:,1) - NB(:,2)` as MxD matrix.
%  J        Optionally compute and return the Jacobian, a sparse
%           (M*D)x(N*D) matrix. Here M*D is the number of variables in Y
%           and N*D the number of variables in X. Variable indices are
%           read from X and Y in row-first order, per Matlab standard.
%
  y = x(nb(:,1),:) - x(nb(:,2),:);

  if nargout > 1
    szy = size(y);
    [numx, dimx] = size(x);

    ji = repmat(1:numel(y), [1 2]);
    jj = bsxfun(@plus, ...
                nb(:,[ones(1,dimx) 2*ones(1,dimx)]), ...
                numx * [1:dimx 1:dimx] - numx);

    J = sparse(ji, jj, [ones(szy), -ones(szy)], ...
               numel(y), numel(x));
  end
end
