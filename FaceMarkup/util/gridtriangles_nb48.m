function T = gridtriangles_nb48(sz)
% Create a 4/8 triangulation for a grid of 2D points.
%
% Input arguments:
%  SZ       Size of the grid as `[H, W]`.
%
% Output arguments:
%  T        Triangulation over a HxW grid of points with 4/8 connectivity.
%
% Considerations:
%  - The grid vertices must be stored row-first (Matlab ordering).
%  - An example of 4/8 connected vertices:
%         *-*-*-*-*
%         |\|/|\|/|
%         *-*-*-*-*
%         |/|\|/|\|
%         *-*-*-*-*
%  - An example of 6 connected vertices:
%         *-*-*-*-*
%         |\|\|\|\|
%         *-*-*-*-*
%         |\|\|\|\|
%         *-*-*-*-*
%
  nrows = sz(1);
  ncols = sz(2);

  evenrows = (2:2:nrows)';
  oddrows = (3:2:nrows)';
  evencols = nrows * (1:2:(ncols-1));
  oddcols = nrows * (2:2:(ncols-1));

  % "A" has \ diagonal,
  % "B" has / diagonal.
  ai1 = bsxfun(@plus, evenrows, evencols);
  ai2 = bsxfun(@plus, oddrows, oddcols);
  ai = [ai1(:); ai2(:)];
  bi1 = bsxfun(@plus, oddrows, evencols);
  bi2 = bsxfun(@plus, evenrows, oddcols);
  bi = [bi1(:); bi2(:)];

  % Above we calculated box offsets.
  % Each box is divided in two triangles.
  % Here we make all the triangles.
  T = [
    bsxfun(@plus, ai, [-nrows-1         0      -1]);  % "\|" triangle shape
    bsxfun(@plus, ai, [-nrows-1    -nrows       0]);  % "|\"
    bsxfun(@plus, bi, [-nrows-1    -nrows      -1]);  % "|/"
    bsxfun(@plus, bi, [-nrows           0      -1]);  % "/|"
  ];
end
