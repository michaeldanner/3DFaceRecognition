function anno = annotate_ics(fldwrl, fldlnd, varargin)
% Annotate a folder of 3D face images using their intrinsic coordinate system.
%
% Input arguments:
%  FLDWRL        String specifying the source folder containing .wrl files, or
%                a pattern that matches 3D images (e.g. '/some/path/*.obj'), or
%                a cell array of file names.
%  FLDLND        String specifying the output folder to write .lnd files. The
%                annotations will also be stored in a Matlab file named
%                annotations.mat.
%  REFANNO       Filename of the .lnd file that provides a reference annotation
%                (on the reference mesh), or an Annotation instance.
%                Default value is `FLD_FACEMARKUP_AUX/SymRef.lnd` where
%                FLD_FACEMARKUP_AUX is read from the environment variable.
%  REFMESH       Filename of the reference mesh or a struct of the reference
%                mesh.
%                Default value is `FLD_FACEMARKUP_AUX/SymRef.wrl` where
%                FLD_FACEMARKUP_AUX is read from the environment variable.
%  REFCONFIRMED  Optional logical scalar to indicate that the ICS estimate of
%                REFMESH will be OK and manual inspection is not needed.
%  EVALMODEL     Object with a `predict` method that evaluates the delta
%                between the reference annotation and the points snapped onto
%                the facial surface. Good form should return a low value.
%
% Output arguments:
%  ANNO  Struct with fields:
%        .names    - Nx1 cell array of file base names (no folder or ext),
%        .coordsys - Nx1 array of CoordinateSystem instances,
%        .lnddef   - LandmarkDefinition instance for the pts indices (1:M)
%                    (this is REFANNO.lnddef),
%        .pts      - NxMx3 array of annotations clipped to the mesh surfaces.
%        .pts0     - NxMx3 array of annotations without clipping, just rigidly
%                    transformed.
%        .reject   - Nx1 logical array. Where true, the coordinate system of
%                    the face could not be estimated (and thus the image was
%                    not annotation, hence .pts will be all nan).
%        .params   - Struct with the parameters passed to MeshICS.
%        This data is also saved in "FLDLND/annotations.mat".
%  
%
% Issues:
%  - Throws error is zero files need to be annotated.
%    (`annos(nfiles,1) = Annotation` fails)
%  - TODO: add ICS parameters to command line options
%
  warning('TODO: insist on specifying refmesh and refanno.');

  FLD_FACEMARKUP_AUX = getenv('FLD_FACEMARKUP_AUX');

  default_anno = fullfile(FLD_FACEMARKUP_AUX, 'SymRef.lnd');
  default_mesh = fullfile(FLD_FACEMARKUP_AUX, 'SymRef.wrl');

  p = inputParser;
  p.FunctionName = 'annotate_ics';
  p.addRequired('FldWrl',                 @(x)ischar(x) || iscellstr(x));
  p.addRequired('FldLnd',                 @(x)ischar(x));
  p.addParameter('RefAnno', default_anno, @(x)ischar(x) || isa(x,'Annotation'));
  p.addParameter('RefMesh', default_mesh, @(x)ischar(x) || isa(x,'Mesh'));
  p.addParameter('RefConfirmed',   false, @isscalar)
  p.addParameter('EvalModel',         []); % filename or object with `predict()`.
  p.parse(fldwrl, fldlnd, varargin{:});

  fldwrl       = p.Results.FldWrl;
  fldlnd       = p.Results.FldLnd;
  refmesh      = p.Results.RefMesh;
  refanno      = p.Results.RefAnno;
  refconfirmed = p.Results.RefConfirmed;
  evalmodel    = p.Results.EvalModel;

  if isempty(gcp('nocreate'))
    parpool(feature('numcores'));
  end
  if ~exist(fldlnd, 'dir')
    mkdir(fldlnd);
  end

  % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ICS Parameters.

  % FRGC:
  % - Mask 0.9
  % - CurvatureOrder 10
  % - SmoothingOrder 5
  % - SmoothingFunction @(d)normpdf(d,0,10)
  % - PeaksMinDist 20
  % - PeaksMaxNum 30
  % - PosAngle 3 * pi/180
  % - NegAngle 9 * pi/180
  % - BinCentres 2 * pi/180
% % % % %   % - PlaneCapsNum 3
% % % % %   % - PlaneSortNum 5
  % - PosLinesMinNum 5
  % - Version 3
  % - Verbose false
%   s_fcn = @(d) normpdf(d, 0, 10);

  % TwinsUK, 2015-10-26
  s_fcn = @(d) normpdf(d, 0, 5);
  params = struct(...%'Mask', 0.9, ...                % Focus on central 90% of data.
    'CurvatureOrder', 10, ...       % 10-neighbourhood for Gaussian curvature.
    'SmoothingOrder', 10, ...       % 10-neighbourhood smoothing matrix.
    'SmoothingFunction', s_fcn, ... % Normal pdf with sigma=5.
    'PeaksMinDist', 10, ...         % 10 mm between peaks.
    'PeaksMaxNum', 30, ...          % 30 peaks max. (x3 for cups, caps, saddles).
    'PosAngle', 3 * pi/180, ...     % Less than 3 degrees (rad) is aligned.
    'NegAngle', 9 * pi/180, ...     % Consider 9 degrees for neg. line segments.
    'BinCentres', 2 * pi/180, ...   % Bins spaced roughly 2 degrees apart.
    'TipMaxOffset', 7, ...          % Nose tip 7 mm from plane of symmetry.
    'PlaneMaxVar', 3, ...           % Max 3 mm var. in line segment midpoints.
    'PosLinesMinNum', 5, ...        % Require at least 4 pos lines to accept.
    'Verbose', false, ...           % Don't print timings or draw figures.
    'Version', 4 ...
  );

  % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Parse & Validate Input Arguments.

  % ----- Mesh files.

  disp('List input files...');

  % You can pass `fldwrl = 'path/*.obj'`, and
  % it will load all obj files instead of wrl.
  wrlfiles = listfiles(fldwrl, '*.wrl');

  [~,names] = cellfun(@fileparts, wrlfiles, 'UniformOutput',0);
% %%% DEBUG
%   flds = strcat(...
%     '/vol/vssp/datasets/still02/frgc/FRGC-2.0-dist/nd1/', ...
%     {'Fall2003range/'; 'Spring2003range/'; 'Spring2004range/'});
%   wrlfiles = cellfun(@(fld)strcat(fld,names','.abs.gz'), flds, 'UniformOutput',0);
%   wrlfiles = cat(1, wrlfiles{:});
%   mask = cellfun(@exist, wrlfiles) > 0;
%   assert(all(sum(mask,1)==1));
%   wrlfiles = wrlfiles(mask);
% %%% END DEBUG
  numfiles = numel(names);

  if numfiles == 0
    fprintf(2, 'Found no 3D images.\n');
    return;
  else
    fprintf('Found %d 3D images.\n', numfiles);
  end

  % ----- Landmark files.

  disp('List output files...');

  lndfiles = cellfun(@(n) fullfile(fldlnd, [n '.lnd']), names, ...
              'UniformOutput',0);  
  matfile = fullfile(fldlnd, 'annotations.mat');

  % ----- Reference files.

  disp('Load reference files...');

  if ischar(refmesh)
    refmesh = Mesh.load(refmesh);
  end
  if ischar(refanno)
    refanno = Annotation.load(refanno);
  end

  % ----- Evaluation model.
  %       Used to predict if an ICS annotation is good.

  if ischar(evalmodel)
    evalmodel = load(evalmodel, 'model');
  end

  % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Calibrate ICS on RefMesh.

  disp('Calibrate...');

  refics = MeshICS(refmesh, params);
  refcosy = refics.coordsys;

  % Only proceed if the calibration went well.

  if ~refconfirmed && feature('ShowFigureWindows') %&& false
    figure;
    trisculpt(refmesh);
    hold on;
    plot3(refcosy, 100, 'LineWidth',3);
    hold off;
    title('Inspect annotation, then close figure.');
    disp('Inspect annotation, then close figure.');
    uiwait;
    question = 'Did the coordinate system look right?';
    answer = questdlg(question, 'ICS', 'Yes', 'No', 'Yes');
    if ~strcmp(answer, 'Yes')
      fprintf(2, 'Aborted.\n');
      return;
    end
  elseif ~refconfirmed
    warning(['Cannot show figures in this terminal. ' ...
          'Going to assume calibration was OK.']);
  end

  % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Annotate All Images.

  disp('Annotate all images...');

  annos0(numfiles,1) = Annotation;
  annos(numfiles,1) = Annotation;
  coordsys(numfiles,1) = CoordinateSystem;
  rejected = false(numfiles, 1);
  pred = nan(numfiles, 1);

%   i0 = find(strcmp(names, 'bs050_YR_L90_0'));
%   for i = i0:numfiles
%   for i = [238 272]
%     fprintf('%5d. %s\n', i, names{i});
%     keyboard;
  parfor i = 1:numfiles
    fprintf('.');if~mod(i,50),fprintf('\n');end

    mesh = Mesh.load(wrlfiles{i});
%     mesh.clean(); % takes a second, but helps a lot.

    ics = MeshICS(mesh, params);

    try
      [annos(i),annos0(i),pred(i)] = ics.annotate(refanno, refcosy, evalmodel);
    catch err
      if strcmpi(err.identifier, 'MeshICS:Failed')
        fprintf(2, '%s rejected.\n', names{i});
        rejected(i) = true;
        ics.default();
        [annos(i),annos0(i),pred(i)] = ics.annotate(refanno, refcosy);
      else
        rethrow(err);
      end
    end
    coordsys(i) = ics.coordsys;

    % ----- Save to file on the fly.
    annos(i).saveas(lndfiles{i});

% %%% DEBUG
%     figure;
%     trisurf(mesh, ics.K);
%     hold on;
%     plot3(coordsys(i), 100);
%     scatter3(annos(i), 'filled');
%     hold off;
%     view(2);
%     title(names{i});
%     %uiwait;
%     drawnow;
%     %keyboard;
% %%% DEBUG END
  end

  % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Save Results.

  disp('Save results...');

  anno = [];
  anno.names      = names;
  anno.coordsys   = coordsys;
  anno.lnddef     = refanno.lnddef;
  anno.pts        = permute(cat(3,annos.coordinates), [3 1 2]);
  anno.pts0       = permute(cat(3,annos0.coordinates), [3 1 2]);
  anno.reject     = rejected;
  anno.prediction = pred;
  anno.params     = params;

  save(matfile, '-struct', 'anno');
end
