function asmaux(fldin, fldout, order, smooth, quiet)
% Generate the Active Shape Model auxiliary files (.cur, .tri, and .txt).
%
% Conny's ASM requires those files for both training (TrainingModels) and
% annotating new images (FndLndPV2Final). They are usually created using her own
% code (Curvature) but that is unpleasantly slow. This script was created to
% make our lives pleasant.
%
% Input arguments:
%  FLDIN   String of the folder containing all .wrl files. Optionally, if you
%          need to convert from another file type than .wrl, you can include a
%          pattern for that. For example: 'path/to/here/*.obj'
%  FLDOUT  Optional string specifying the folder to which auxiliary are saved.
%          Default value is taken from `FLDIN`.
%  ORDER   Optional scalar to specify the vertex neighbourhood order when
%          computing the surface curvature.
%          Default value is 10, per Conny's original code.
%  SMOOTH  Optional scalar to smooth the estimated surface curvature.
%          Default value is 0 (no smoothing), per Conny's original code.
%
  if nargin<2 || isempty(fldout), fldout=[]; end
  if nargin<3 || isempty(order), order=10; end
  if nargin<4 || isempty(smooth), smooth=0; end
  if nargin<5 || isempty(quiet), quiet=false; end

  if ischar(order), order=str2double(order); end
  if ischar(smooth), smooth=str2double(smooth); end
  if ischar(quiet), quiet=logical(str2double(quiet)); end

  if quiet
    print = @noop;
  else
    prefix = sprintf('%s: ', mfilename());
    print = @(varargin) fprintf(varargin{:});
  end

  if ~exist(fldout, 'dir')
    print('%sCreate output folder...\n', prefix);
    mkdir(fldout);
  end

  print('%sList files, please wait...\n', prefix);

  % You can pass `fldin = 'path/*.obj'`, and
  % it will load all obj files instead of wrl.
  wrlfiles = listfiles(fldin, '*.wrl');
  nfiles   = numel(wrlfiles);

  if nfiles == 0
    fprintf('%sNo matching files in FLDIN.\n', prefix);
    return;
  end

  % If not set, FLDOUT = FLDIN, and we can
  % take its value from the first file.
  if isempty(fldout)
    fldout = fileparts(wrlfiles{1});
  end

  %----------------------------------------------------------------------------

  print('%sFound %d images.\n', prefix, nfiles);
  print('%sCreate ASM auxiliary files...\n', prefix);

  [~,names,ext] = cellfun(@fileparts, wrlfiles, 'UniformOutput',0);

  parfor i = 1:nfiles
    print('%4d. %s%s', i, names{i}, ext{i});

    outname = fullfile(fldout, names{i});
    curfile = [outname '.cur'];
    trifile = [outname '.tri'];
    txtfile = [outname '.txt'];

    if exist(txtfile,'file') && exist(trifile,'file') && exist(curfile,'file')
      print(' exists. skip.\n');
      continue;
    end

    t0 = tic;

    print(' in:'); % reading file
    tic;

    tri = Mesh.load(wrlfiles{i}, '', 'isdirty',true);
    tri.default_neighbourhood_order = order;

    print('%.1fs', toc);

    % `k1` and `k2` are the principal curvatures.
    % `smoothvtx` are smoothed vertices (using the fitted 2nd order polynomial).

    print(' curv:'); % computing curvature
    tic;

    %coefs = tri.parameters;
    k1 = tri.k1;
    k2 = tri.k2;
    if smooth
      s_fcn = @(d) normpdf(d, 0, 10);
      W = tri.smoothmatrix(smooth, s_fcn);
      k1 = W * k1;
      k2 = W * k2;
      %coefs = W * coefs;
    end
    smoothvtx = tri.vertices;% + ...
                %bsxfun(@times, coefs(:,6), tri.vertexnormals) / 4;

    print('%.1fs', toc);

    % Write to files.

    print(' out:');  % writing files
    tic;

    % - .cur
    dlmwrite(curfile, [k1 k2], 'delimiter',' ', 'precision',8);

    % - .tri
    f = fopen(trifile, 'w');
    print(f, '%d %d\n', size(tri.vertices,1), size(tri.faces,1));
    print(f, '%.6f %.6f %.6f\n', smoothvtx');
    print(f, '3 %d %d %d\n', tri.faces'-1);	% -1 for 0-based indices!!
    fclose(f);

    % - .txt
    f = fopen(txtfile, 'w');
    print(f, '%.6f %.6f %.6f\n', smoothvtx');
    fclose(f);

    print('%.1fs', toc);
    print(' total:%.1fs', toc(t0));
    print('\n');
  end

  print('done.\n');
end
