function R = quat2mat(q)
% Converts a unit quaternion to a rotation matrix.
%
% Input arguments:
%  q        N unit quaternions as 4xN matrix.
%
% Output arguments:
%  R        3x3xN unitary rotation matrices. Its columns form the basis
%           vectors.
%
% Note: There is some issue with instable rotations as the quaternion
%       approaches a scaler. That issue is NOT dealt with in this code.
%
% Todo: Partial derivatives.
%
  n = size(q, 2);

  qr = reshape(q(1,:), [1 1 n]);
  qi = reshape(q(2,:), [1 1 n]);
  qj = reshape(q(3,:), [1 1 n]);
  qk = reshape(q(4,:), [1 1 n]);

  qii2 = 2 * qi .* qi;
  qik2 = 2 * qi .* qk;
  qij2 = 2 * qi .* qj;
  qir2 = 2 * qi .* qr;
  qjj2 = 2 * qj .* qj;
  qjk2 = 2 * qj .* qk;
  qjr2 = 2 * qj .* qr;
  qkk2 = 2 * qk .* qk;
  qkr2 = 2 * qk .* qr;

  R = [ ...
    1 - (qjj2 + qkk2),     (qij2 - qkr2),     (qik2 + qjr2);
        (qij2 + qkr2), 1 - (qii2 + qkk2),     (qjk2 - qir2);
        (qik2 - qjr2),     (qjk2 + qir2), 1 - (qii2 + qjj2);
  ];
end
