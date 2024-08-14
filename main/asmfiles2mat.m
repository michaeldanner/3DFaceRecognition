function asmfiles2mat(flddata, allnames, lnddef)
% Read all annotations from an ASM output folder and save data in a .mat file.
%
% Input arguments:
%  FLDDATA   ASM output folder. Contains all *.raw, *.bst and *.log files.
%  ALLNAMES  Nx1 cell array of strings with the base names (no folder, no file
%            extension) of all files in the data set. The files in FLDDATA may
%            be a smaller subset of the ones listed in ALLNAMES, e.g. when an
%            experiment was run on a particular selection.
%            Alternatively, ALLNAMES may be a struct with field `.names` or a
%            string specifying the `manual.mat` file that stores this
%            information. The last option (path to the `manual.mat` file) is
%            probably preferred, because it ensures the `names` fields match.
%            Default is to match all *.raw files found in FLDDATA.
%  LNDDEF    LandmarkDefinition instance, or name, to specify the landmark
%            definition to which the annotations are converted before writing
%            to ASMMAT.
%            Default value is `LandmarkDefinition.tena26`.
%
% Considerations:
%  - Output will be written to the file annotations.mat in FLDDATA.
%
  if nargin<3 || isempty(lnddef), lnddef=LandmarkDefinition.tena26; end

  % Read the exhaustive list of file names.

  if nargin<2 || isempty(allnames)
    files = listfiles(flddata, '*.raw');
    [~,names] = cellfun(@fileparts, files, 'UniformOutput',0);
  elseif ischar(allnames) && exist(allnames, 'file')
    manual = load(allnames);
    names = manual.names;
  elseif isstruct(allnames)
    names = allnames.names;
  elseif iscellstr(allnames)
    names = allnames;
  else
    error('Invalid value for ALLNAMES argument.');
  end

  % Set up the variables that will be saved to file.
  
  if ischar(lnddef)
    lnddef = LandmarkDefinition.fromname(lnddef);
  end

  nfiles = numel(names);
  npts = size(lnddef.lxmap, 1);

  bst = nan(nfiles, npts, 3);
  pts = nan(nfiles, npts, 3);
  log = nan(nfiles, 17);

  % Read the ASM output files one by one.
  % Convert annotations to the output LandmarkDefinition.

  parfor i = 1:nfiles
    fprintf('%5d. %s\n', i, names{i});

    rawfile = fullfile(flddata, [names{i} '.raw']);
    bstfile = fullfile(flddata, [names{i} '.bst']);
    logfile = fullfile(flddata, [names{i} '.log']);

%     fprintf('%5d. %s\n', i, rawfile);

    % Skip missing files.
    % The coordinates will be saved as `nan`.
    if ~exist(rawfile, 'file')
      fprintf('   skip.\n');
      continue;
    end

    anno_raw = Annotation.load(rawfile, LandmarkDefinition.ruiz14);
    anno_raw.convertto(lnddef);
    pts(i,:,:) = anno_raw.coordinates;

    anno_bst = Annotation.load(bstfile, LandmarkDefinition.ruiz14);
    anno_bst.convertto(lnddef);
    bst(i,:,:) = anno_bst.coordinates;

    data_log = dlmread(logfile);
    log(i,:) = data_log;
  end

  % Save all data to .mat file.

  asm.names = names;
  asm.lnddef = lnddef;
  asm.pts = pts;
  asm.bst = bst;
  asm.log = log; %#ok<STRNU>

  asmmatfile = fullfile(flddata, 'annotations.mat');

  disp('Save to file...');
  save(asmmatfile, '-struct','asm');
  disp('done.');
end
