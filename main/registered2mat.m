function registered2mat(fldreg, names)
% Read all registered meshes and save data in a .mat file.
%
% Input arguments:
%  FLDREG   Folder containing *ER.wrl files.
%  NAMES    Optional Nx1 cell array of strings with the base names (no folder,
%           and stripped from "ER.wrl" suffix) of all files to be included.
%           The file "<FLDREG>/<NAMES{i}>ER.wrl" does not have to exist. Only if
%           it exists will the vertex data be inserted in the vertex data
%           matrix. Otherwise, the data matrix will consist of `nan`s for that
%           entry.
%           Default is to match all *ER.wrl files in FLDREG.
%
% Considerations:
%  - Output will be written to the file "registered.mat" in FLDREG.
%
  if nargin<2 || isempty(names)
    files = dir(fullfile(fldreg, '*ER.wrl'));
    names = arrayfun(@(f)f.name(1:end-6), files, 'UniformOutput',0);
  end
  
  fprintf('Discover files.\n');
  
  numnames  = numel(names);
  
  filenames = cellfun(@(n)fullfile(fldreg, [n 'ER.wrl']), names, ...
                      'UniformOutput',0);
  available = cellfun(@(f)exist(f,'file'), filenames);
  
  % Allocate memory for all files.
  % (examine the first mesh for measurements)
  
  fprintf('Read sample file.\n');
  
  j = find(available, 1);
  m = Mesh.load(filenames{j});
  
  faces    = m.faces;
  vertices = nan(numnames, m.numvertices, m.vertexdim);
  
  % Read vertex data from all files.
  
  fprintf('---\n');
  fprintf('%5d names.\n', numnames);
  fprintf('%5d match files in FLDREG.\n', nnz(available));
  fprintf('Each file is registered to:\n');
  fprintf('  %6d faces\n', m.numfaces);
  fprintf('  %6d vertices\n', m.numvertices);
  fprintf('---\n');
  fprintf('Read vertex data from %d files.\n', nnz(available));
  
  vertices(j,:,:) = m.vertices;
  
  parfor i = (j+1):numnames
    if ~mod(i,40)
      fprintf('.\n');
    else
      fprintf('.');
    end
    
    if available(i)
      m = Mesh.load(filenames{i});
      vertices(i,:,:) = m.vertices;
    end
  end
  
  % Save data to .mat file.
  
  fprintf('Save to "registered.mat"...');
  
  filename = fullfile(fldreg, 'registered.mat');
  
  s.names  = names;
  s.tri    = faces;
  s.vtx    = vertices; %#ok<STRNU>
  
  save(filename, '-struct','s');
  
  fprintf(' done.\n');
end
