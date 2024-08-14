function [y, Jq, Jx] = f_qrot(x, q)
% Rotate data using a unit quaternion.
%
% Input arguments:
%  X        Nx3 matrix of position vectors in Euclidean space.
%  Q        Unit quaternion as 4x1 vector or N quaternions as 4xN matrix.
%
% Output arguments:
%  Y        Nx3 matrix of rotated position vectors.
%  JQ       Optionally computes and returns the gradient wrt Q.
%  JX       Optionally computes and returns the gradient wrt X.
%
  nq = size(q, 2);

  q = cdiv2norm(q); % libFaceMarkup

  % Rotation with a matrix is more efficient, and the cost of creating the
  % matrix is offset with only a handful of rotations. Generally N is
  % bigger than that.
  % Also, when Jx is requested, we need R anyway.
  R = quat2mat(q);

  if nq == 1
    y = x * R;
  else
    x = repmat(permute(x, [2 3 1]), [1 3 1]);
    y = permute(dot(x, R, 1), [3 2 1]);
  end

  if nargout > 1
    % Here goes:
    %
    % x = sym('x', [1 3]);
    % q = sym('q', [4 1]);
    % Jr = jacobian(f_qrot(x, q), q);
    %
    % But there is a constraint that |q| == 1, so we need to postmultiply
    % with the Jacobian of the vector normalisation (which is 4x4 btw).
    %
    % Jn = jacobian(q ./ norm(q), q);
    % J = Jr * Jn;
    %
    v11 = 2 * q(1,:) .* x(:,1);
    v12 = 2 * q(1,:) .* x(:,2);
    v13 = 2 * q(1,:) .* x(:,3);
    v21 = 2 * q(2,:) .* x(:,1);
    v22 = 2 * q(2,:) .* x(:,2);
    v23 = 2 * q(2,:) .* x(:,3);
    v31 = 2 * q(3,:) .* x(:,1);
    v32 = 2 * q(3,:) .* x(:,2);
    v33 = 2 * q(3,:) .* x(:,3);
    v41 = 2 * q(4,:) .* x(:,1);
    v42 = 2 * q(4,:) .* x(:,2);
    v43 = 2 * q(4,:) .* x(:,3);

    Jq = [ v42-v33,       v43+v32, -2*v31+v22-v13, -2*v41+v23+v12;
          -v41+v23, v31-2*v22+v13,        v43+v21, -2*v42+v33-v11;
           v31-v22, v41-2*v23-v12,  v42-2*v33+v11,        v32+v21];

    if nq == 1
      v = null(q.');
      Jn = v * v.';
    else
      % This is effectively the same as above, but written out. It applies
      % the same operation for all quaternions in parallel.
      n2 = ones(1, 4) * (q .^ 2);
      n = sqrt(n2);
      qt = -q ./ (n .* n2);
      Jn = bsxfun(@times, reshape(q, [4 1 nq]), reshape(qt, [1 4 nq])) ...
         + eye(4) ./ reshape(n, [1 1 nq]);
      nq4 = nq * 4;
      ii = [1:4 1:4 1:4 1:4].' * ones(1, nq) + (0:4:(nq4 - 1));
      jj = ones(4, 1) * (1:nq4);
      Jn = sparse(ii, jj, Jn(:), nq4, nq4);
    end

    Jq = Jq * Jn;
  end

  if nargout > 2
    nx = size(x, 1);

    if nq == 1
      Jx = kron(R.', speye(nx));
    elseif nx == nq
      R = shiftdim(R, 2); % = permute(R, [3 1 2])
      ii = (1:nx).' + kron(0:2, nx * ones(1, 3));
      jj = (1:numel(x)).' * ones(1, 3);
      Jx = sparse(ii, jj, R(:), numel(x), numel(x));
    else
      error('Array expansion on X not supported yet.');
    end
  end
end

% function y = qh(q1, q2)
% % Hamilton product.
%   a1 = q1(1);
%   b1 = q1(2);
%   c1 = q1(3);
%   d1 = q1(4);
% 
%   a2 = q2(1);
%   b2 = q2(2);
%   c2 = q2(3);
%   d2 = q2(4);
% 
%   y = [ ...
%     a1 * a2 - b1 * b2 - c1 * c2 - d1 * d2;
%     a1 * b2 + b1 * a2 + c1 * d2 - d1 * c2;
%     a1 * c2 - b1 * d2 + c1 * a2 + d1 * b2;
%     a1 * d2 + b1 * c2 - c1 * b2 + d1 * a2;
%   ];
% end
% 
% function y = qi(q)
% % Quaternion inverse.
%   y = [q(1); -q(2:end)];
% end
