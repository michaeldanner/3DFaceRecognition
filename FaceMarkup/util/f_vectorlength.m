function [y, J] = f_vectorlength(x, precision)
% Computes the length of vectors (and its partial derivatives).
%
% Input arguments:
%  X           N points in D dimensions as NxD matrix.
%  PRECISION   The gradient of the vector length is discontinuous at 0. For
%              values approaching 0 (smaller than PRECISION), we manually
%              set the gradient to 0.
%
% Output arguments:
%  Y       Nx1 array of vector lengths.
%  J       Optional Nx(N*D) Jacobian matrix (computed only when requested).
%
  y = sqrt(sum(x .^ 2, 2));

  if nargout > 1
    % y = sqrt(  x1^2   +   y1^2   +   z1^2  )
    %
    % f(x) = sqrt(x)         f'(x) = 1 / (2*sqrt(x))
    % g(x) = x^2 + C         g'(x) = 2x
    % (f(g(x)))' = f'(g(x)) * g'(x)
    %            = 1 / (2 * sqrt(g(x))) * g'(x)
    %            = 2x / (2 * sqrt(x^2 + C))
    %            = x / sqrt(x^2 + C)
    %            = x / f(g(x))
    %            = x / y

    [numx, dimx] = size(x);

    % lim_{x->0} x / ||x||_2 = 0      (the plot is beautiful.)
    yl = y < precision;
    x(yl,:) = 0;
    y(yl) = 1;

    ji = repmat(1:numx, [1 dimx]);
    jj = 1:numel(x);
    jv = bsxfun(@rdivide, x, y);

    J = sparse(ji, jj, jv(:)', numel(y), numel(x));
  end
end
