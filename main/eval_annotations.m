function [meanerr, evaldata, truthdata] = eval_annotations(...
          fldeval, fldtruth, ldeval, ldtruth, fmteval, fmttruth)
% Evaluate the annotations in FLDEVAL against those in FLDTRUTH.
%
% Input arguments:
%  FLDEVAL   String of a folder containing the annotation files to be evaluated.
%            Optionally, a file name pattern can be added, e.g. to evaluate all
%            .lm3 files you can specify: 'folder/for/evaluation/*.lm3'
%            .mat files are also supported. In that case, set FMTEVAL to the
%            field name that contains the coordinates (default is `'pts'`). The
%            .mat file should also hold a .names property with a cell array of
%            strings, and preferably also a .lnddef property with the landmark
%            definition.
%            Default file type is .lnd.
%  FLDTRUTH  String of a folder containing the ground truth annotation files.
%            Optionally, a file name pattern can be added (see FLDEVAL). Default
%            file type is .lnd.
%  LDEVAL    Optional LandmarkDefinition instance if that cannot be determined
%            from the files in FLDEVAL (see classes/@LandmarkDefinition).
%            Default is 'Tena-26' (LandmarkDefinition.tena26).
%            Note that, IF the landmark definition CAN be read from file, that
%            will always take precedence over this specified value.
%  LDTRUTH   Optional LandmarkDefinition instance if that cannot be determined
%            from the annotation files in FLDTRUTH.
%            Default is 'Tena-26' (LandmarkDefinition.tena26).
%            Note that, IF the landmark definition CAN be read from file, that
%            will always take precedence over this specified value.
%  FMTEVAL   Optional landmark format. If loading data from a .mat file, this
%            specifies the name of the field to read coordinates from (`'pts'`
%            by default). If loading data from multiple annotation files in a
%            folder, this specifies the file format (only needed if this cannot
%            be derived from the file extension automatically).
%  FMTTRUTH  Optional landmark format for the truth data.
%
% Output arguments:
%  MEANERR    Nx1 array with the mean landmark error for each annotation.
%             MEANERR(i) stores the mean landmark error for
%             EVALDATA.annotation(i) compared to TRUTHDATA.annotation(i).
%  EVALDATA   AnnotationSet instance with the evaluated data.
%  TRUTHDATA  AnnotationSet instance with the matching ground truth data.
%
% Considerations:
%  - Note that the returned evaluation data may exclude files in the input data
%    if the file only exists in either FLDEVAL or FLDTRUTH but not in both.
%    Therefore, always inspect the returned `EVALDATA.names`. The returned data
%    is always consistent, meaning that
%    `all(strcmp(EVALDATA.names, TRUTHDATA.names))` and `EVALDATA.lnddef`
%    matches `TRUTHDATA.lnddef`.
%  - Here is some sample code to render a selected image:
%    i = 233; % select your index here.
%    annoeval = evaldata.annotation(i);
%    annotruth = truthdata.annotation(i);
%    m = Mesh.load(['Z:\FRGC\train\beautiful_images\' evaldata.names{i} '.wrl']);
%    figure;
%    trisculpt(m);
%    hold on;
%    scatter3(annoeval,'filled');
%    scatter3(annotruth);
%    hold off;
%    view(2);
%    title(names{i});
%
  if nargin<3 || isempty(ldeval), ldeval=LandmarkDefinition.tena26; end
  if nargin<4 || isempty(ldtruth), ldtruth=LandmarkDefinition.tena26; end
  if nargin<5, fmteval=[]; end
  if nargin<6, fmttruth=[]; end

  % To work from the command line, LDEVAL and
  % LDTRUTH must be definable using strings.

  if ischar(ldeval)
    ldeval = LandmarkDefinition.fromname(ldeval);
  end
  if ischar(ldtruth)
    ldtruth = LandmarkDefinition.fromname(ldtruth);
  end

  fprintf('List files...\n');

  % You can pass `fldeval = 'path/*.raw'`, and
  % it will load all raw files instead of lnd.
  % You can pass `fldtruth = 'path/annotations.mat'`, and
  % it will load the `.pts` from the Matlab file (or `.(fmteval)` if set).

  evaldata = AnnotationSet.load(fldeval, ldeval, fmteval);
  nfiles = evaldata.numfiles;

  if nfiles == 0
    fprintf(2, 'No matching files in FLDEVAL.\n');
    return;
  else
    fprintf('Found %d evaluation files.\n', nfiles);
  end

  % You can pass `fldtruth = 'path/*.raw'`, and
  % it will load all raw files instead of lnd.
  % You can pass `fldtruth = 'path/annotations.mat'`, and
  % it will load the `.pts` from the Matlab file (or `.(fmttruth)` if set).

  truthdata = AnnotationSet.load(fldtruth, ldtruth, fmttruth);

  fprintf('Found %d truth files.\n', truthdata.numfiles);

  % Match the evaluation files to the ground truth files.
  % If one cannot be matched, throw an error.

  [names,ixeval,ixtruth] = intersect(evaldata.names, truthdata.names);
  evaldata.keep(ixeval);
  truthdata.keep(ixtruth);

  if numel(names) ~= nfiles
    %fprintf(2, 'Some files in FLDEVAL could not be matched in FLDTRUTH.\n');
    %return;
    warning('*** testing only. ***')
    nfiles = numel(names);
  end

  % Not only match names, but also match landmark definition.
  evaldata.convertto(truthdata.lnddef);
  nlandmarks = numel(evaldata.indices);

  fprintf('Evaluating %d files.\n', nfiles);
  fprintf('Max %d landmarks (per file) will be evaluated.\n', nlandmarks);

  %----------------------------------------------------------------------------

  fprintf('Evaluate...\n');

  delta = sqrt(sum((evaldata.coordinates - truthdata.coordinates) .^ 2, 3));
  meanerr = nanmean(delta, 2);
%   maxerr  = nanmax(delta, [], 2);

  fprintf('Plot performance...\n');

  figure;
  plotmle(meanerr, 'Names',names);

  fprintf('done.\n');
end
