function as3d = anno2Dto3D(as2da, as2db, fld)
% Convert 2D texture annotations to 3D shape annotations.
%
% Input arguments:
%  AS2DA  AnnotationSet instance with N annotations in 2D. 
%  AS2DB  AnnotationSet instance with N annotations in 2D.
%  FLD    Folder name where 3D images are found. Images should be named as
%         follows: '<FLD>/<AS2D_*.names{i}>.wrl'
%
% Output arguments:
%  AS3D   AnnotationSet instance with N annotations in 3D.
%
% Considerations:
%  Since the texture images for the .wrl files consist of two photos, AS2DA
%  provides annotation on one of the two photos, while AS2DB provides annotation
%  for the other. It is not known, however, which of the two matches which
%  physical side of the 3D shape (left or right).
%
  p = inputParser();
  p.FunctionName = 'anno2Dto3D';
  p.addRequired('as2d_left', @(x)ischar(x)||isa(x,'AnnotationSet'));
  p.addRequired('as2d_right', @(x)ischar(x)||isa(x,'AnnotationSet'));
  p.addRequired('fld', @(x)exist(x,'dir'));
  p.parse(as2da, as2db, fld);
  
  as2da  = p.Results.as2d_left;
  as2db  = p.Results.as2d_right;
  fld    = p.Results.fld;
  
  if ischar(as2da), as2da=AnnotationSet.load(as2da); end
  if ischar(as2db), as2db=AnnotationSet.load(as2db); end
  
  assert(all(strcmp(as2da.names, as2db.names)));
  
  names  = as2da.names;
  lnddef = as2da.lnddef;
  N      = as2da.numfiles;
  M      = as2da.maxindex;
  
  as2db.convertto(lnddef);
  
  as3d   = AnnotationSet(lnddef, nan(N,M,3), names);
  coords = as3d.coordinates;
  
  parfor i = 1:N
    fprintf('%5d %s\n', i, names{i});
    
    m           = Mesh.load(fullfile(fld, [names{i} '.wrl']));
    mt          = Mesh(m.texturecoords, m.textureindices, '', [], [], true);
    img         = imread(m.texturefile);
    [h,w,~]     = size(img);
    mt.vertices = mt.vertices * [w 0; 0 h];
    
    % Transfer annotations from 2D texture to 3D shape.
    % When
    %  * da == db == 0 -> continue to average,
    %  * otherwise     -> remove landmark with largest distance to triangle.
    
    extrapolate = true;
    
    aa          = as2da.annotation(i); %#ok<PFBNS>
    [aa,~,da]   = aa.transfer(mt, m, extrapolate);
    ab          = as2db.annotation(i); %#ok<PFBNS>
    [ab,~,db]   = ab.transfer(mt, m, extrapolate);
    
    aa.coordinates(da>db,:) = nan;
    ab.coordinates(db>da,:) = nan;
    
    % Average annotations, then snap to the 3D surface.
    
    pts  = nanmean(cat(3, aa.coordinates, ab.coordinates), 3);
    anno = Annotation(1:M, pts, lnddef);
    anno.snaptosurface(m);
    
    coords(i,:,:) = anno.coordinates;
    
    % Check for missing coordinates.
    
    if ~anno.iscomplete
      warning('anno2Dto3D:incompleteAnnotation', ...
              'Annotation for %s is incomplete (has %d of %d landmarks).', ...
              names{i}, numel(anno.indices), M);
    end
  end
  
  as3d.coordinates = coords;
end
