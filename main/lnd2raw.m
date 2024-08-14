function lnd2raw(fldin, fldout, ldin, ldout)
% Convert .lnd annotation files to the .raw format used in ASM.
%
% Input arguments:
%  FLDIN   String of the folder containing all .lnd files. Optionally, if you
%          need to convert from another file type than .lnd, you can include a
%          pattern for that. For example: 'path/to/here/*.lm3'
%  FLDOUT  Optional string of the folder to write out .raw files. If a file type
%          is required different from .raw (default), then you can add it to the
%          path. For example: 'output/folder/*.bst' will write out .bst files.
%          Default value is taken from `FLDIN`.
%  LDIN    Optional LandmarkDefinition instance providing a reference definition
%          of the landmarks in all .lnd files. See: classes/@LandmarkDefinition.
%          Can also be passed as string: 'Tena-26', 'Perakis-8', or 'Ruiz-14'.
%          Default is `LandmarkDefinition.tena26`.
%  LDOUT   Optional LandmarkDefinition instance providing a definition of the
%          landmarks to be written out to file.
%          Can also be passed as string: 'Tena-26', 'Perakis-8', or 'Ruiz-14'.
%          Unless you are 110% sure what you are doing, do not set this value.
%          Default is `LandmarkDefinition.ruiz14`.
%
% Considerations:
%  - The necessary FaceMarkup folders must be on your Matlab path. This can be
%    accomplished by running the FaceMarkup/init_facemarkup.m script.
%
  if nargin<2 || isempty(fldout), fldout=[]; end
  if nargin<3 || isempty(ldin), ldin=LandmarkDefinition.tena26; end
  if nargin<4 || isempty(ldout), ldout=LandmarkDefinition.ruiz14; end
  
  % You can pass `fldin = 'path/*.raw'`, and
  % it will load all raw files instead of lnd.
  lndfiles  = listfiles(fldin, '*.lnd');
  nfiles    = numel(lndfiles);
  
  if nfiles == 0
    fprintf('No matching files in FLDIN.\n');
    return;
  end
  
  % If not set, FLDOUT = FLDIN, and we can
  % take its value from the first file.
  extout = '.raw';
  if isempty(fldout)
    fldout = fileparts(lndfiles{1});
  else
    [fld,~,ext] = fileparts(fldout);
    if ~isempty(ext)
      fldout = fld;
      extout = ext;
    end
  end

  if ~exist(fldout, 'dir')
    mkdir(fldout);
  end
  
  % To work from the command line, LDIN and
  % LDOUT must be definable using strings.
  if ischar(ldin)
    ldin = LandmarkDefinition.fromname(ldin);
  end
  if ischar(ldout)
    ldout = LandmarkDefinition.fromname(ldout);
  end
  
  %----------------------------------------------------------------------------
  
  [~,names,ext] = cellfun(@fileparts, lndfiles, 'UniformOutput',0);
  
  fprintf('Converting %d files from %s to %s...\n', nfiles, ext{1}, extout);
  
  for i = 1:nfiles
    fprintf('%4d. %s%s\n', i, names{i}, ext{i});
    
    anno = Annotation.load(lndfiles{i}, ldin);
    anno.convertto(ldout);
    
    rawfile = fullfile(fldout, [names{i} extout]);
    anno.saveas(rawfile);
  end
  
  fprintf('done.\n');
end
