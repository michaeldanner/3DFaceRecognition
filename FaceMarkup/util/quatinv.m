function qi = quatinv(q)
% Returns the inverse quaternion.
%
% Input arguments:
%  Q          A quaternion as 4x1 column vector, or N quaternions as 4xN
%             matrix.
%
% Output arguments:
%  QI         The quaternion inverse(s), same size as Q.
%
  qi = cdiv2norm([q(1,:); -q(2:end,:)]);  % libFaceMarkup
end
