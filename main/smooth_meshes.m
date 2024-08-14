function smooth_meshes(fldin, fldout, corder, sorder, ssigma)
% Convert ugly noisy meshes to beautiful smooth surfaces.
%
% Input arguments:
%  FLDIN   String specifying the folder from which to load meshes. You can
%          include a file pattern if the input meshes are not .wrl. For
%          example: `'path/to/*.obj'`.
%  FLDOUT  String specifying the folder to write beautiful meshes to. All files
%          are written in the .wrl format.
%  CORDER  Optional scalar specifying the neighbourhood order when computing
%          the curvature.
%          Default is 10.
%  SORDER  Optional scalar specifying the neighbourhood order when smoothing
%          the vertex normals.
%          Default is 10.
%  SSIGMA  Optional scalar specifying the width (sigma) of the smoothing kernel
%          which is `@(x)normpdf(x,0,SSIGMA)`.
%          Default is 5.
%
% Considerations:
%  - To appreciate the beauty of the shape, we strip texture from the meshes.
%  - From all combinations of 5s and 10s we found the default values to produce
%    the visually most pleasing results. No numerical evaluation.
%
  if nargin<3 || isempty(corder), corder=10; end
  if nargin<4 || isempty(sorder), sorder=10; end
  if nargin<5 || isempty(ssigma), ssigma=5; end
  
  wrlfiles = listfiles(fldin, '*.wrl');
  numfiles = numel(wrlfiles);
  
  [~,names] = cellfun(@fileparts, wrlfiles, 'UniformOutput',0);

  fprintf('Smooth %d images.\n', numfiles);
  
  %for i = 1:numfiles
  parfor i = 1:numfiles
    fprintf('%5d. %s\n', i, names{i});
    
    % Load the mesh and do some basic cleaning.
    % Mostly we don't like needle-shaped triangles.
    m = Mesh.load(wrlfiles{i});
    m.clean();
    
    % Mask excludes some vertices from processing. (or "does not include").
    %mi = MeshICS(m, params);
    %mask = mi.mask;
    mask = [];
    
    % Some settings. You can configure them if you like.
    curvorder = corder;
    smoothorder = sorder;
    smoothsigma = ssigma;
    smoothfcn = @(d)normpdf(d,0,smoothsigma);
    
    % Adjust vertex positions.
    W = m.smoothmatrix(smoothorder, smoothfcn, mask);
    m.vertexnormals = W * m.vertexnormals;
    C = m.parameterization(curvorder);
    m.vertices = m.vertices + bsxfun(@times, C(:,6), m.vertexnormals);

    % XXX: we could recompute normals and partly undo changes for points whose
    %      normals were affected "too much". Because smoothing should not
    %      change the already smooth normals.

%     %%% DEBUG
%     figure;
%     subplot(1, 2, 1);
%     trisurf(m, K);
%     view(2);
%     subplot(1, 2, 2);
%     trisurf(m, W*K);
%     view(2);
%     figure;
%     trisculpt(m);
%     view(2);
%     title(sprintf('%s: corder:%d, sorder:%d, ssigma:%d', ...
%             names{i}, corder, sorder, ssigma));
%     %%% DEBUG END
    
    % Strip all texture information. It's a waste.
    m.texturecoords = [];
    m.textureindices = [];
    m.vertexcolor = [];
    m.facecolor = [];
    m.texturefile = '';
    
    % Done. Save the smooth surface.
    m.saveas(fullfile(fldout, [names{i} '.wrl']));
  end

  disp('Done.');
end
