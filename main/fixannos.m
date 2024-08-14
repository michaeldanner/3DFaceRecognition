function failed = fixannos(raw, ref, auto_save, skip_if_exists)
% Re-order annotated points to match the reference annotation, and write to
% output files. Output file names are constructed from the .raw input file
% names by replacing their extension with .lnd
%
% RAW             String of file pattern matching the .raw annotation files.
%                 For example: '/path/to/*.raw'
% REF             Annotation object with the reference annotation.
% AUTO_SAVE       Optional boolean specifying whether .lnd files can be
%                 written without user confirmation. Default is false.
% SKIP_IF_EXISTS  Optional boolean specifying if annotation files for which
%                 a .lnd file exists should be skipped. Default is false.
%
% FAILED          cell array of file names for rejected annotations.
%
	if nargin<3 || isempty(auto_save), auto_save=false; end
	if nargin<4 || isempty(skip_if_exists), skip_if_exists=false; end
  
  % Load the reference annotation if passed as file.
  
  if ischar(ref)
    % We don't know the landmark definition, so file must define it.
    ref = Annotation.load(ref);
  end
  
  % Load all available .raw annotation files.
  
  annos = AnnotationSet.load(raw, LandmarkDefinition.universe);
  
  % Construct output file names (.lnd)
  
  fld           = fileparts(raw);
  lnd           = cellfun(@(n)fullfile(fld, [n '.lnd']), annos.names, ...
                          'UniformOutput',0);
  
	% Mark which files can be skipped.
  
	skip          = cellfun(@(f)exist(f, 'file'), lnd);
	skip          = skip & skip_if_exists;
  
	% Keep a log of which files failed.
  
	failed        = cell(annos.numfiles, 1);
  
	% Fix the remaining files.
	
	for i = find(~skip)'
		fprintf('%4d. %s\n', i, annos.names{i});
    
		% Fix order of points.
		
    annoi = annos.annotation(i);
    
    if ~any(numel(annoi.indices) == [14 26])
      fprintf(' -- not 14 or 26 points: skip.\n');
			skip(i) = true;
			continue;
    end
    
    try
      annoi = ref.fixlnddef(annoi);
    catch err
      fprintf(2, ' -- %s - skip.\n', err.message);
      skip(i) = true;
      continue;
    end
    
		% Confirm the found solution.
    
		if ~auto_save
			drawlandmarks(ref, annoi);
      
			if any(strcmpi(input('   OK? (Y/n): ','s'), {'n','no'}))
				disp(' -> failed');
				failed{i} = annos.names{i};
				continue;
			end
		end

		% Save.
    
    filename = fullfile(fld, [annoi.name '.lnd']);
    annoi.saveas(filename);
    
		% Be verbose.
    
		fprintf(' -> %s\n', filename);
	end

	failed = failed(~cellfun(@isempty, failed));
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function drawlandmarks(ref, anno)
% Draw a visual representation of a set of points (for inspection).
%
% REF   Annotation instance to serve as reference.
% ANNO  Annotation instance up for inspection.
%
  assert(ref.lnddef == anno.lnddef, 'Different landmark definitions.');
  
  % Find a few useful points to sketch the face outline.
  ix = LandmarkEncyclopedia.landmarklabel2id({
      'right eye outer corner',     'right eye inner corner';
      'left eye outer corner',      'left eye inner corner';
      'nose left cheek junction',   'nose right cheek junction';
      'nose right cheek junction',  'nose tip';
      'nose tip',                   'nose left cheek junction';
      'mouth left corner',          'upper lip middle top';
      'upper lip middle top',       'mouth right corner';
      'mouth right corner',         'lower lip middle bottom';
      'lower lip middle bottom',    'mouth left corner'});
  
  [~,an] = procrustes(ref, anno, 'Scaling',false, 'Reflection',false);
  
  p = ref.coordinates;
  a = an.coordinates;
  v = a - p;
  lx = a(:,1); lx = lx(ix);
  ly = a(:,2); ly = ly(ix);
  lz = a(:,3); lz = lz(ix);
  
  quiver3(p(:,1), p(:,2), p(:,3), v(:,1), v(:,2), v(:,3), 0, 'k');
  hold on;
  scatter3(ref, 6, 'k', 'filled');
  scatter3(ref, 12, 'g');
  scatter3(an, 24, 'b', 'filled');
  plot3(lx', ly', lz', '-b');
  hold off;
  
  title(anno.name);
  view(2);
  camorbit(-35, -10, 'camera', [0 1 0]);
  grid off;
  axis equal vis3d;
  axis off;
  rotate3d on;
end
