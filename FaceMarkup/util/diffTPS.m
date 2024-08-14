function [y, Jycx, Jycy] = diffTPS(cx, cy, x)
%DIFFTPS Summary of this function goes here
%   Detailed explanation goes here
  [npcx, ndcx] = size(cx);
  [npcy, ndcy] = size(cy);
  [npx, ndx] = size(x);
  assert(npcx == npcy, 'The number of points in CX and CY must match.');
  assert(ndx == ndcx, 'The number of dimensions in CX and X must match.');
  npc = npcx;
  ndx = ndcx;
  ndy = ndcy;


  if nargout == 1 && ~isa(cx, 'sym') && ~isa(cy, 'sym')
    phi = @(r) (r.^2) .* log(r);
    K1 = squareform(phi(pdist(cx)));
    K2 = pdist2(x, cx);
    ix = K2 < eps;
    K2 = phi(K2);
    K2(ix) = 0;
    y = K2 * (K1 \ cy);
    return;
  end

  % Step 1. esimtate `w` -------------------------------------------------

  % I am a bit worried about the transpose in -kron(inv(K1).', inv(K1)),
  % because this is not mentioned in online explanations of the derivative
  % of the inverse, but was needed to get it right.
  % Matlab bug submitted: case number 03354362
  % https://servicerequest.mathworks.com/mysr/cp_case_detail1?cc=us&id=5000Z000018ER4O

  [K1, J1, J2] = kernel(cx, cx);
  Jkcx = J1 + J2;

  w = K1 \ cy;
  Jik = -kron(inv(K1).', inv(K1));
  Jwi = kron(cy.', eye(npc));
  Jwcx = Jwi * Jik * Jkcx;

  % Compute Jycy at once later.
  %Jwcy = kron(eye(ndy), inv(K1));

  % Step 2. project `x` --------------------------------------------------

  [K2, ~, Jkcx] = kernel(x, cx); % (different from `Jkcx` above)
  %Jkcy = 0.

  y = K2 * w;
  Jycx = kron(w.', eye(npx)) * Jkcx ... % product rule.
       + kron(eye(ndy), K2) * Jwcx;
  Jycy = kron(eye(ndy), K2 / K1);
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
  [npx, ndx] = size(x);
  [npy, ndy] = size(y);
  
  assert(ndx == ndy, 'Incompatible dimensions.');
  nd = ndx;

  x = repmat(reshape(x, [npx 1 nd]), [1 npy 1]);
  y = repmat(reshape(y, [1 npy nd]), [npx 1 1]);

  d = (x - y);
  d2 = d .^ 2;
  r = d2(:,:,1);
  for i = 2:nd
    r = r + d2(:,:,i);
  end
  r = sqrt(r);
  z = (r .^ 2) .* log(r);
  if isa(z, 'sym')
    z(isnan(z)) = 0;
  else
    z(r<eps) = 0;
  end

  if nargout > 1
    npxy = npx * npy;

    [i, j] = ndgrid(1:npx, 1:npy);
    i = i(:);
    j = j(:);

    J = d .* repmat(2 * log(r) + 1, [1 1 nd]);
    if ~isa(r, 'sym')
      J(repmat(r<eps, [1 1 nd])) = 0;
    else
      J(isnan(J)) = 0;
    end
    ii = repmat((1:npxy)', [1 nd]);
    jj = repmat(i, [1 nd]) + (1:nd) * npx - npx;
    if isa(x, 'sym')
      Jzx = sym('Jzx', [npxy, npx*nd]);
      Jzx(:) = 0;
      ix = sub2ind([npxy npx*nd], ii(:), jj(:));
      Jzx(ix) = J(:);
    else
      Jzx = sparse(ii, jj, J(:), npxy, npx*nd);
    end

    J = -d .* repmat(2 * log(r) + 1, [1 1 nd]);
    if ~isa(r, 'sym')
      J(repmat(r<eps, [1 1 nd])) = 0;
    else
      J(isnan(J)) = 0;
    end
    ii = repmat((1:npxy)', [1 nd]);
    jj = repmat(j, [1 nd]) + (1:nd) * npy - npy;
    if isa(y, 'sym')
      Jzy = sym('Jzy', [npxy, npy*nd]);
      Jzy(:) = 0;
      ix = sub2ind([npxy npy*nd], ii(:), jj(:));
      Jzy(ix) = J(:);
    else
      Jzy = sparse(ii, jj, J(:), npxy, npy*nd);
    end
  end
end
