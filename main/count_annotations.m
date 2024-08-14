function s = count_annotations(filepat, varargin)
% List for each file name who has annotated it, and how many points.
%
% Input arguments:
%  FILEPAT     String with the file pattern to match files in each folder.
%              If left empty, it will default to '*.lnd'.
%  FOLDERS...  One or more strings of folders holding annotation files.
%              Can be passed as multiple arguments or as cell array of strings.
%  NAMES       Optional cell array of strings with the exact names to look for
%              in each folder. This acts as a filter on the files found in each
%              folder, and only those files whose base name (without
%              extension) occurs in NAMES are returned.
%              By default NAMES is built up from all discovered annotation files
%              in all folders.
%
% Output arguments:
%  COUNTS      Struct with the following fields:
%              .folders  Mx1 cell array of strings with the folder names
%                        (without path component).
%              .names    Nx1 cell array of strings. It is a copy of NAMES input
%                        argument, or its value as it is constructed.
%              .counts   NxM matrix where element `(i,j)` gives the number of
%                        landmarks annotated for image `names{i}` in folder
%                        `folders{j}`.
%
% Considerations:
%  Also writes the file "annotation_counts_<date>.csv" to the current directory.
%
  if isempty(filepat)
    filepat = '*.lnd';
  end
  
  if nargin > 2
    folders = varargin;
  else
    folders = varargin{1};
  end
  
  if ischar(folders)
    folders = {folders};
  end

  if iscellstr(folders{end})
    names   = folders{end};
    folders = folders(1:end-1);
  else
    names   = [];
  end
  
  if numel(folders) == 1 && ~iscellstr(folders)
    folders = folders{1};
  end
  
  % Find the folder base names.
  %   - also works if folder names end in "/".
  
  [parent,fldnames]   = cellfun(@fileparts, folders, 'UniformOutput',0);
  retry               = isempty(fldnames);
  [~,fldnames(retry)] = cellfun(@fileparts, parent(retry), 'UniformOutput',0);
  
  % List all files in all folders.
  %   - assign base name index and folder index.
  %   - filter out files not in `names`.
  
  disp('List files.');
  
  files   = cellfun(@(fld) arrayfun(@(f) ...
              fullfile(fld,f.name), dir(fullfile(fld,filepat)), ...
              'UniformOutput',0), folders, 'UniformOutput',0);
  ixfld   = arrayfun(@(i) i * ones(size(files{i})), (1:numel(files))', ...
              'UniformOutput',0);
  files   = cat(1, files{:});
  ixfld   = cat(1, ixfld{:});
  
  [~,nm]  = cellfun(@fileparts, files, 'UniformOutput',0);
  
  if isempty(names)
    [names,~,ixname] = unique(nm);
  else
    [~,ixname] = ismember(nm, names);
    keep       = ixname > 0;
    files      = files(keep);
    ixfld      = ixfld(keep);
    ixname     = ixname(keep);
  end
  
  % Read every file to count the number of annotated points.
  
  disp('Count annotation points in each file.');
  
  counts = zeros(size(files));
  
  parfor i = 1:numel(files)
    anno      = Annotation.load(files{i}, LandmarkDefinition.universe);
    counts(i) = numel(anno.indices);
  end
  
  counts = full(sparse(ixname, ixfld, counts, numel(names), numel(folders)));
  
  % Write results to file.
  
  filename = sprintf('annotation_counts_%s.csv', datestr(now, 'yyyymmdd'));
  
  fprintf('Write to %s.\n', filename);
  
  pat1 = [repmat(',%s', 1, numel(fldnames)) '\n'];
  pat2 = ['%s' repmat(',%d', 1, numel(fldnames)) '\n'];
  
  data1 = fldnames;
  data2 = [names num2cell(counts)]';
  
  fid = fopen(filename, 'w');
  fprintf(fid, pat1, data1{:});
  fprintf(fid, pat2, data2{:});
  fclose(fid);
  
  % Return as structure.
  
  s.folders    = fldnames;
  s.names      = names;
  s.counts     = counts;
end
