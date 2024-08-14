function [y, J] = f_cotan(x, ix, precision)
% Computes 1/tan for pairs of vectors (and its partial derivatives).
%
% Input arguments:
%  X            Nx3 matrix of N points in Euclidean space.
%  IX           Mx2 matrix indexing pairs of vectors (rows) in X. Where
%               row i is `[a, b]`, the cotangent of the angle is computed
%               between vectors `X(a,:)` and `X(b,:)`.
%  PRECISION    The cotangent is discontinuous when any vector is zero.
%               For values approaching 0 (smaller than PRECISION), we
%               manually set it to 0 (and its gradient, too).
%
% Output arguments:
%  Y            Mx1 array of cotangents.
%  J            Optional Mx(3N) Jacobian matrix (computed only when
%               requested).
%
% Considerations:
%   For a non-right angled triangle with inner angles A, B and C, and
%   opposing edges a, b and c (vectors), tan(A) = || b x c || / (b . c)
%   Note that the cotangent goes to infinity as vectors align, and is 0/0
%   when one (or both) has length 0.
%
  if nargin<3 || isempty(precision), precision = 1e-10; end

  if nargout > 1
    [d, Jd] = f_dot(x, ix);
    [c, Jc] = f_cross(x, ix);
    [l, Jl] = f_vectorlength(c, precision);
    Jl = Jl * Jc;
    % Quotient rule:
    %   f(x) = g(x) / h(x)
    %  f'(x) = (g'(x) h(x) - g(x) h'(x))  /  h(x)^2
    a = bsxfun(@times, Jd, l) - bsxfun(@times, d, Jl);
    llim = l.^2 < precision;
    a(llim,:) = 0;
    l(llim,:) = 1;
    J = bsxfun(@rdivide, a, l.^2);
  else
    d = f_dot(x, ix);
    c = f_cross(x, ix);
    l = f_vector_length(c, precision);
  end

  y = d ./ l;
end
