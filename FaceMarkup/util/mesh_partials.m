function dydm = mesh_partials(m, y)
% Computes first order partial derivatives of Y wrt. the mesh.
%
% Input arguments:
%  M      A mesh. Either a `Mesh` or `triangulation` instance, or a struct
%         with fields `vertices` and `faces`. The vertices have
%         dimensionality K.
%  Y      NxD matrix of values measured at the mesh vertices.
%
% Output arguments:
%  DYDM   NxDxK matrix of partial derivatives of Y wrt. M.
%
% TODO: allow Y from a projective space with its own triangulation.
%
  if isa(m, 'triangulation')
    f = m.ConnectivityList;
    m = m.Points;
  else
    f = m.faces;
    m = m.vertices;
  end

  numf = size(f, 1);        % F
  numm = size(m, 1);
  dimm = size(m, 2);        % K
  szy = size(y);
  numy = szy(1);            % N
  dimy = prod(szy(2:end));  % D

  % Compute differences over edges.
  % Also shift dimensions to make 2xKxF and 2xDxF.

  ab = f(:,1:2);
  bc = f(:,2:3);

  dm = shiftdim(reshape(m(bc,:) - m(ab,:), [numf 2 dimm]), 1);
  dy = shiftdim(reshape(y(bc,:) - y(ab,:), [numf 2 dimy]), 1);
  dy = reshape(dy, [2 dimy numf]);  % Enforce shape when dimy is 1.

  % Compute partial derivatives on the faces.

  dydm_f = zeros(numf, dimm, dimy);
  for i = 1:numf
    dydm_f(i,:,:) = dm(:,:,i) \ dy(:,:,i);
  end

  % Average to the vertices.

  % (a note on the clipping: when triangle area is uniform, all would be
  % exactly 1/numf because the uvspace has area 1. so here we're imposing
  % a lower bound on the accepted triangle at a 1,000-th of that (=shrink
  % factor 30 in both u and v). later we will divide by triangle area, so
  % this is important. furthermore, it is not a problem that we inflate
  % the space a bit, again because we later divide.)

  a_f = triangle_area(f, m);
  a_f = max(sum(a_f) / (1000 * numf), a_f);
  dydm_f = bsxfun(@times, a_f, dydm_f);

  dydm = zeros(numm, dimm, dimy);
  for i = 1:(dimm*dimy)
    dydm(:,i) = accumarray(f(:), repmat(dydm_f(:,i), [3 1]));
    %debug: dyduv(:,i) = accumarray(f(:), repmat(a_f, [3 1]));
  end

  inva = 1 ./ accumarray(f(:), [a_f; a_f; a_f]);
  dydm = bsxfun(@times, dydm, inva);
  dydm = permute(dydm, [1 3 2]);

  if numel(szy) > 2
    dydm = reshape(dydm, [numy szy(2:end) dimm]);
  end
end
