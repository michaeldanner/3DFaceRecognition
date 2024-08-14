function [c, Jb, Ja] = f_mtimes(a, b)
% Computes the matrix multiplication C = A * B, with partial derivatives.
%
% Input arguments:
%  A          NxM matrix.
%  B          MxK matrix.
%
% Output arguments:
%  C          NxK matrix. Element C(i,j) = A(i,:) * B(:,j).
%  JB         Optionally computes the Jacobian matrix of C with respect to
%             the elements of B. That is, element JB(i,j) stores the
%             partial derivative dC(i)/dB(j) where i and j are linear
%             indices. JB is of size (NK)x(MK).
%  JA         Optionally computes the Jacobian matrix of C with respect to
%             the elements of A. JA has size (NK)x(NM).
%
  c = a * b;

  if nargout > 1
    k = size(b, 2);
    Jb = kron(speye(k), a);
  end

  if nargout > 2
    n = size(a, 1);
    Ja = kron(b.', speye(n));
  end
end
