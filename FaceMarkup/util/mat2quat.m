function q = mat2quat(R)
% Converts a rotation matrix to a unit quaternion.
%
% Input arguments:
%  R        N unitary rotation matrices. Columns form the basis vectors.
%           R is of size 3x3xN.
%
% Output arguments:
%  q        N unit quaternion as 4xN matrix. (N can be 1 of course.)
%
  n = size(R, 3);

  m11 = reshape(R(1,1,:), [1 n]);
  m12 = reshape(R(1,2,:), [1 n]);
  m13 = reshape(R(1,3,:), [1 n]);
  m21 = reshape(R(2,1,:), [1 n]);
  m22 = reshape(R(2,2,:), [1 n]);
  m23 = reshape(R(2,3,:), [1 n]);
  m31 = reshape(R(3,1,:), [1 n]);
  m32 = reshape(R(3,2,:), [1 n]);
  m33 = reshape(R(3,3,:), [1 n]);
  
  i1 = (m11 + m22 + m33 > 0);
  i2 = ~i1 & (m11 > m22 & m11 > m33);
  i3 = ~i1 & ~i2 & (m22 > m33);
  i4 = ~i1 & ~i2 & ~i3;

  qr = zeros(1, n);
  qi = zeros(1, n);
  qj = zeros(1, n);
  qk = zeros(1, n);

  if any(i1)
    qr(i1) = sqrt(1 + m11(i1) + m22(i1) + m33(i1)) / 2;
    invdenom = 1 ./ (qr(i1) * 4);
    qi(i1) = (m32(i1) - m23(i1)) .* invdenom;
    qj(i1) = (m13(i1) - m31(i1)) .* invdenom;
    qk(i1) = (m21(i1) - m12(i1)) .* invdenom;
  end

  if any(i2)
    qi(i2) = sqrt(1 + m11(i2) - m22(i2) - m33(i2)) / 2;
    invdenom = 1 ./ (qi(i2) * 4);
    qr = (m32(i2) - m23(i2)) .* invdenom;
    qj = (m12(i2) + m21(i2)) .* invdenom;
    qk = (m13(i2) + m31(i2)) .* invdenom;
  end

  if any(i3)
    qj(i3) = sqrt(1 + m22(i3) - m11(i3) - m33(i3)) / 2;
    invdenom = 1./ (qj(i3) * 4);
    qr = (m13(i3) - m31(i3)) .* invdenom;
    qi = (m12(i3) + m21(i3)) .* invdenom;
    qk = (m23(i3) + m32(i3)) .* invdenom;
  end
  
  if any(i4)
    qk(i4) = sqrt(1.0 + m33(i4) - m11(i4) - m22(i4)) / 2;
    invdenom = 1./ (qk(i4) * 4);
    qr(i4) = (m21(i4) - m12(i4)) .* invdenom;
    qi(i4) = (m13(i4) + m31(i4)) .* invdenom;
    qj(i4) = (m23(i4) + m32(i4)) .* invdenom;
  end
  
  q = [qr; qi; qj; qk];
  q = cdiv2norm(q); % libFaceMarkup
end
