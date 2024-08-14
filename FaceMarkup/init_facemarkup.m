
% Add all required folders to the path.
% We need absolute paths, so changing directories won't break things.

if ~exist('FLAG_LIBFACEMARKUP', 'var') || ~FLAG_LIBFACEMARKUP
  
  basepath_ = fileparts(mfilename('fullpath'));
  addpath(fullfile(basepath_, 'classes')); % extra CVSSP classes, not public (yet).
  addpath(fullfile(basepath_, 'util')); % shared utility functions.
  addpath(fullfile(basepath_, 'external/low-rank')); % robust pca.
  addpath(fullfile(basepath_, 'mains')); % if you want.
  addpath(fullfile(basepath_, 'mains/Annotate3D'));
  addpath(fullfile(basepath_, 'libFaceMarkup'));
  
  init_lowrank;
  init_libfacemarkup;
  
  % Overwrite aux folder with this one (includes CVSSP private data).
  FLD_LIBFACEMARKUP_AUX = fullfile(basepath_, 'auxi');
  setenv('FLD_LIBFACEMARKUP_AUX', FLD_LIBFACEMARKUP_AUX);
  
  clear basepath;
end
