% Process all annotation files by putting the landmarks in fixed order
% Then average each set of annotations for a scan
%

  if exist('FLD_FACECAP', 'var')
    FLD_BASE = FLD_FACECAP; % Set in startup.m
  else
    FLD_BASE = '/vol/vssp/facecap/';
  end
  
	DATASET  = 'twins';

	% Minimum number of annotation versions in order to average them.
	MINVERSIONS   = 3;

	% Reference annotation to fix order of landmark points
  relpath       = fileparts(mfilename('fullpath'));
	ANNO_REF      = Annotation.load(fullfile(relpath, 'suppl/reference.lnd'), ...
                                  LandmarkDefinition.tena26);
  ANNO_REF.convertto(LandmarkDefinition.ruiz14);
  ANNO_REF.convertto(LandmarkDefinition.tena26);
	% Flag to not ask for confirmation before creating .lnd file
	ANNO_AUTO     = true;
	% ... or, if a .lnd file already exists, assume it is already fixed.
	ANNO_SKIP_LND = true;

  FLD_WRL  = fullfile(FLD_BASE, DATASET, 'faces/images');
  FLD_REG  = fullfile(FLD_BASE, DATASET, 'faces/registered/manual');
  FLD_ANNO = fullfile(FLD_BASE, DATASET, 'faces/annotation');
  FLD_MEAN = fullfile(FLD_ANNO, 'manual');

  whatever = exist('', 'var');  % (mute Matlab's annoying warnings)
  if whatever || strcmp(DATASET, 'pobi')
		annotators = {
        'abdel';
        'antonio';
        'bruce';
        'dan';
        'dev';
        'ho';
        'kasia';
        'paul'};
  elseif whatever || strcmp(DATASET, 'twins')
    annotators = {
        'abdel';
        'bruce';
        'dan';
        'dev';
        'kasia';
        'paul';
        'doubles'};
	else
		throw('Unknown data set.');
  end

  FLDS_RAW   = cellfun(@(n) fullfile(FLD_ANNO, ['manual-' n]), annotators, 'UniformOutput',0);

% Fix annotations -- creates .lnd files for .raw files
%
	if ~any(strcmpi(input('Fix annotations? (Y/n): ','s'), {'N','n'}))
		failed = cellfun(@(fld) ...
					fixannos(fullfile(fld, '*.raw'), ANNO_REF, ANNO_AUTO, ANNO_SKIP_LND), ...
					FLDS_RAW, 'UniformOutput',0);
		failed = cat(1, failed{:});

		if numel(failed) > 0
			fprintf('The following files failed:\n');
			fprintf('%s\n', failed{:});
		end
	end

% Extract means
%
	fprintf('Computing annotation averages...\n');
	takemeans(FLDS_RAW, FLD_MEAN, FLD_WRL, MINVERSIONS);
	fprintf('done.\n');

% Switch to Python for registration
%
	fprintf('\nBefore app_exportdata(), please run the following from this directory:\n');
	fprintf('     registerall.py %s %s %s\n\n', ...
				FLD_WRL, FLD_MEAN, FLD_REG);
