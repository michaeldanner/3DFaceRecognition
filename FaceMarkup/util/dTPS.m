function [y, Jycy, Jycx, Jyx] = dTPS(x, cx, cy)
% A thin plate spline, differentiable wrt the control points, CX and CY.
%
% Input arguments:
%  X        NxD matrix of the N points in source space.
%  CX       KxD matrix of K control points in the source space.
%  CY       KxE matrix of the same control points in the target space.
%
% Output arguments:
%  Y        NxE matrix of the source points warped to target space.
%  JYCY     Jacobian matrix of Y wrt CY.
%  JYCX     Jacobian matrix of Y wrt CX.
%  JYX      Jacobian matrix of Y wrt X.
%
  if nargout == 1
    K1 = kernel(cx);
    K2 = kernel(x, cx);
    y = K2 * (K1 \ cy);
  else
    npc = size(cx, 1);
    npx = size(x, 1);
    ndy = size(cy, 2);

    [K1, Jk1cx1, Jk1cx2] = kernel(cx);
    [K2,      ~, Jk2cx ] = kernel(x, cx);

    w = K1 \ cy;
    y = K2 * w;

    Jycy = kron(eye(ndy), K2 / K1);

    if nargout > 2
      Jwcx = kron(cy.', eye(npc)) ...         %   J w/inv ...
           * -kron(inv(K1).', inv(K1)) ...    % * J inv/K1 ...
           * (Jk1cx1 + Jk1cx2);               % * J K1/cx

      Jycx = kron(w.', eye(npx)) * Jk2cx ...  % product rule.
           + kron(eye(ndy), K2) * Jwcx;
    end

    if nargout > 3
      Jyx = 0;
      error('TODO: implement Jyx.');
    end
  end
end

function [z, Jzx, Jzy] = kernel(x, y)
% Computes `z = phi(pdist2(x, y));` and its derivatives wrt x and y.
% Where phi(r) = r.^2 .* log(r).
%
% Input arguments:
%  X    NxD matrix of N points in D dimensions.
%  Y    MxD matrix of M points in D dimensions.
%
% Output arguments:
%  Z    NxM matrix. `Z(i,j) == phi(norm(x(i,:) - y(j,:)))`.
%  JZX  Jacobian of Z wrt X.
%  JZY  Jacobian of Z wrt Y.
%
  if nargout == 1
    if nargin == 1
      z = squareform(phi(pdist(x)));
    else
      z = phi(pdist2(x, y));
    end
  else
    if nargin == 1, y = x; end

    [npx, ndx] = size(x);
    [npy, ndy] = size(y);
    npxy = npx * npy;
    nd = ndx;

    assert(ndx == ndy, 'X and Y must have the same number of columns.');

    d = bsxfun(@minus, reshape(x, [npx 1 nd]), reshape(y, [1 npy nd]));
    r = sqrt(sum(d .^ 2, 3));
    z = phi(r);

    % Stabilise for r -> 0, force J = 0 (which is correct).
    r(r < eps) = exp(-0.5);
    J = d .* (2 * log(r) + 1);

    [i, j] = ndgrid(1:npx, 1:npy);
    i = i(:);
    j = j(:);

    ii = repmat((1:npxy)', [1 nd]);
    jj = repmat(i, [1 nd]) + (0:(nd-1)) * npx;
    Jzx = sparse(ii, jj, J(:), npxy, npx*nd);

    %ii = repmat((1:npxy)', [1 nd]);
    jj = repmat(j, [1 nd]) + (0:(nd-1)) * npy;
    Jzy = sparse(ii, jj, -J(:), npxy, npy*nd);
  end

  function z = phi(r)
  % Thin plate spline non-linearity.
  %
  % Input arguments:
  %  R          Non-negative scalar, vector, matrix, ... In principle, R
  %             measures a distance between two points.
  %
  % Output arguments:
  %  Z          `(R.^2) .* log(R)` properly evaluated at R = 0.
  %
    z = (r .^ 2) .* log(r);
    z(r < eps) = 0;
  end
end
