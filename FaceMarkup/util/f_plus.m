function [c, Jb, Ja] = f_plus(a, b)
% Computes `A + B` and its partial derivatives.
%
% Input arguments:
%  A        A scalar, 1xD row vector, Nx1 column vector or NxD matrix.
%  B        A scalar, 1xD row vector, Nx1 column vector or NxD matrix.
%
% Output arguments:
%  C        The sum `A + B` as NxD matrix.
%  JB       Optionally computes and returns the Jacobian wrt B, a sparse
%           (N*D)xM matrix, where M is numel(C).
%  JA       Optionally computes and returns the Jacobian wrt A.
%
% Considerations:
%  Currently, the Jacobians only support scalar, vector and matrix inputs.
%  Higher order tensors are not supported.
%
  c = a + b;

  if nargout > 1
    sza = size(a);
    szb = size(b);
    szc = max(sza, szb);

    Jb = jac(szc, szb);
    if nargout > 2
      Ja = jac(szc, sza);
    end
  end
end

function J = jac(szc, sza)
  na = prod(sza);
  nc = prod(szc);

  ii = 1:nc;
  jj = 0:nc-1;

  if sza(1) < szc(1)
    jj = floor(jj ./ szc(1));
  end
  if sza(2) < szc(2)
    jj = mod(jj, szc(1));
  end

  J = sparse(ii, jj+1, ones(szc), nc, na);
end
