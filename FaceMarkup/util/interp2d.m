function rgb = interp2d(img, qs, qt, method, extrapval)
%INTERP2D 2D interpolation over multiple layers, e.g. R G and B.
%
% Input arguments:
%  IMG        HxWxD image to be interpolated.
%  QS         Horizontal positions of the query points. Must be 1- or 2D.
%             Higher dimensionality is not supported.
%  QT         Vertical positions of the query points, same size as QS.
%  METHOD     Sampling method. 'nearest', 'linear' or 'bicubic'. When
%             sampling points are equally spaced and monotonic, use
%             `['*' METHOD]` for speed.
%  EXTRAPVAL  A scalar value that is assigned to all queries that lie
%             outside the domain of the sample points.
%
% Output arguments:
%  RGB     Matrix of interpolated data. Where QS is size MxN, RGB is size
%          MxNxD.
%
% See also: interp2d_grid, interp2.
%
  args = {};
  if nargin>3, args{1} = method; end
  if nargin>4, args{2} = extrapval; end

  szi = size(img);
  d = prod(szi(3:end));
  if numel(szi) > 3
    img = img(:,:,:);
  end

  szq = size(qs);
  rgb = zeros([szq d]);

  for i = 1:d
    rgb(:,:,i) = interp2(img(:,:,i), qs, qt, args{:});
  end

  if numel(szi) > 3
    rgb = reshape(rgb, [szq szi(3:end)]);
  end
  rgb = squeeze(rgb);
end
