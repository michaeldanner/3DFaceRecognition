function [R, Q] = rq(A)
% RQ decomposition.
%
% Returns a factorisation of A such that `A = R * Q`.
%
% Input arguments:
%  A          An MxN matrix, with M <= N.
%
% Output arguments:
%  R          An MxN upper triangular matrix.
%  Q          An NxN unitary matrix, i.e., `Q' * Q = I`.
%
% Author: Bruno Luong
% Last Update: 04/Oct/2008
% Source: comp.soft-sys.matlab
%
  [m, n] = size(A);

  if m > n
    error('RQ: Number of rows must be smaller than columns.');
  end

  [Q, R] = qr(flipud(A).');
  sgn = sign(diag(R));
  Q = Q .* sgn.';
  R = R .* sgn;

  R = flipud(R.');
  R(:,1:m) = R(:,m:-1:1);
  Q = Q.';
  Q(1:m,:) = Q(m:-1:1,:);
end
