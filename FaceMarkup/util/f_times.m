function [c, Jb, Ja] = f_times(a, b)
% Computes C = A .* B, with partial derivatives.
%
% Input arguments:
%  A        Scalar, 1xD row vector, Nx1 column vector or NxD matrix.
%  B        Scalar, 1xD row vector, Nx1 column vector or NxD matrix.
%
% Output arguments:
%  C        The multiplication `A .* B`.
%  JB       Optionally compute and return the Jacobian wrt B. It is a
%           sparse (N*D)xM matrix where M = numel(B).
%  JA       Optionally compute and return the Jacobian wrt A. It is a
%           sparse (N*D)xM matrix where M = numel(A).
%
% Considerations:
%  Currently, the Jacobians only support scalar, vector and matrix inputs.
%  Higher order tensors are not supported.
%
  c = a .* b;

  if nargout > 1
    Jb = dcda(b, a);
  end
  if nargout > 2
    Ja = dcda(a, b);
  end
end

function J = dcda(a, b)
  c = ones(size(a)) .* b;

  [na, da] = size(a);
  [nc, dc] = size(c);

  ii = 1:numel(c);
  jj = 0:numel(c)-1;

  if na < nc
    jj = floor(jj ./ nc);
  end
  if da < dc
    jj = mod(jj, nc);
  end

  J = sparse(ii, jj+1, c, numel(c), numel(a));
end
