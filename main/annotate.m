function annotate( wrlfiles, rawfiles, extri, exlm )
% Place landmarks on any 3D surface mesh and save them to file
%
% Left mouse button marks coordinate, press <enter> to put landmark there.
% Right mouse button selects placed landmarks, press <x> (or <del>) to delete.
% Press <s> to save.
% Save and go to previous / next scan with <p> and <n> respectively.
% Save and quit with <q> or close the window to quit without saving.
%
% @param wrlfiles  Nx1 cell array of full-path .wrl files
% @param rawfiles  Nx1 cell array of full-path .raw files
%                  `rawfiles{i}` corresponds to `wrlfiles{i}`
%                  Files referenced in `rawfiles` do not need to exist, but
%                  must be writable.
% @param extri     Optional render an example trimesh, with landmarks `exlm`
% @param exlm      Optional Mx1 array of vertex indices as example landmarks
%
% @modified 23 March, 2011 - Toggle texture map with 'T'
%                            Toggle (intuitive) rotation with 'R'
% @modified 24 March, 2011 - removed 'R', now integral part of mouse interaction
%
%
	addpath ../landmarks;
	
%
% Initialise annotation app window
%
	set( 0, 'Units', 'pixels' );
	scnsize = get( 0, 'ScreenSize' );
	pos     = [5, 5, scnsize(3)*2/3-10, scnsize(4)-10];
	f_main  = figure( 'Position',pos, 'KeyPressFcn',{@f_main_onkeypress} );

%
% Set up example window
%
	if nargin > 2
		pos = [pos(1)+scnsize(3)*2/3, pos(2)+pos(4)/2, scnsize(3)/3-10, pos(4)/2];
		f_ex = figure( 'Position',pos );
		trisurf_( extri );
		view( 2 );
		if nargin > 3
			hold on;
			plot3( extri.vertices(exlm,1), extri.vertices(exlm,2), ...
						extri.vertices(exlm,3), 'g*' );
		end
		rotate3d on;
	else
		f_ex = -1;
	end
	figure( f_main );

%
% If `exlm` is passed, we can use it to verify each annotation
%
	if nargin > 3
		check_landmarks = numel( exlm );
	else
		check_landmarks = 0;
	end

%
% Find last saved scan
%
	wrlidx = 1;
	for i = 1:numel(rawfiles)
		if ~exist( rawfiles{i}, 'file' )
			wrlidx = i;
			break;
		end
	end

%
% The scan loop ================================================================
%
	while wrlidx <= numel(wrlfiles)
%
% Initialize state variable `d`
%
		d = [];
		% reference to main figure
		d.fig    = f_main;
		% mesh wrapped in boundary class for fast intersection
		d.shape  = [];
		% Nx3 matrix of N landmark coordinates
		d.lmxyz  = [];
		% Nx1 array of N point handles
		d.lmhnd  = [];
		% index of currently selected landmark
		d.sel    = 0;
		% handle of marker for selected landmark
		d.selhnd = 0;
		% X Y Z coordinate of last mouse click on surface mesh
		d.mxyz   = [];
		% point handle for last mouse click
		d.mhnd   = -1;
		% pressed key
		d.key    = [];

%
% Load and draw the trimesh
%
		tri     = triload( wrlfiles{wrlidx} );
		tri.vertices = tri.vertices(1:max(tri.faces(:)),:);
		figure( f_main );
		clf( f_main );
		h       = trisurf_( tri, tri.vertexcolor, 'FaceColor','interp', ...
					'ButtonDownFcn',@tri_onclick );
		hl      = light('Position',[20 30 200], 'Style','local', ...
					'Visible','off');
		d.shape = boundary( h );
		set( gca, 'UserData', d );
		title( wrlfiles{wrlidx} );
		zoom( f_main, 1.8 );
		view( 2 );
		hold on;

%
% Install a more intuitive camera control, activated by pressing 'R'
%
		%cameratoolbar( 'SetMode','orbit' );
		cameratoolbar( 'SetCoordSys','y' );
		%cameratoolbar( 'SetMode','nomode' );
		cameratoolbar( 'Show','on' );

%
% Load and draw any existing landmarks
%
		if exist( rawfiles{wrlidx}, 'file' )
			fprintf( 'Loading %s... ', rawfiles{wrlidx} );
			d.lmxyz    = dlmread( rawfiles{wrlidx} );
			nlandmarks = size( d.lmxyz, 1 );
			fprintf( 'loaded %d landmarks.\n', nlandmarks );
			d.lmhnd    = zeros( nlandmarks, 1 );
			d.sel      = nlandmarks;
			for i = 1:nlandmarks
				d.lmhnd(i) = plot3(d.lmxyz(i,1),d.lmxyz(i,2),d.lmxyz(i,3),'g*');
			end
			if nlandmarks > 0
				d.selhnd = plot3( d.lmxyz(end,1),d.lmxyz(end,2),d.lmxyz(end,3),...
							'mo', 'LineWidth',2, 'MarkerSize',10 );
			else
				d.selhnd = -1;
			end
		else
			d.lmxyz  = [];
			d.lmhnd  = [];
			d.sel    = 0;
			d.selhnd = -1;
		end

%
% The edit loop ----------------------------------------------------------------
%
		changed_landmarks = false;
		
		while true
%
% Wait for a key to be pressed
%
			d.key = [];
			uiwait;
			if ~ishandle(f_main)	% user closed the main window
				if ishandle(f_ex), close(f_ex); end
				return;
			end
			ch = d.key;

%
% Handle the pressed key
%
			% <enter> : add point to landmarks
			if any( strcmpi( ch, {' ','space','','return'} ) )
				if numel(d.mxyz)~=3 || ~ishandle(d.mhnd), continue; end
				delete( d.mhnd );
				d.lmxyz(end+1,:)  = d.mxyz;
				d.lmhnd(end+1)    = plot3( d.mxyz(1), d.mxyz(2), d.mxyz(3), ...
							'g*', 'HitTest','off' );
				d.mxyz            = [];		% prevent double <enter>
				changed_landmarks = true;
				select_landmark( numel(d.lmhnd) );
			
			%  `x`    : delete selected landmark
			elseif any( strcmpi( ch, {'x','delete','backspace'} ) )
				if ~d.sel, continue; end
				delete( d.selhnd );
				delete( d.lmhnd(d.sel) );
				d.lmhnd(d.sel)    = [];
				d.lmxyz(d.sel,:)  = [];
				changed_landmarks = true;
				select_landmark( min( d.sel, numel(d.lmhnd) ) );
			
			%  `>`    : goto next landmark
			elseif any( strcmpi( ch, {'rightarrow','downarrow','period'} ) )
				idx = mod( d.sel, numel(d.lmhnd) ) + 1;
				idx = min( idx,   numel(d.lmhnd) );
				select_landmark( idx );
			
			%  `<`    : goto previous landmark
			elseif any( strcmpi( ch, {'leftarrow','uparrow','comma'} ) )
				idx = d.sel - 1;
				if idx < 1
					idx = numel( d.lmhnd );
				end
				select_landmark( idx );
			
			%  `s`    : save, but stay in this figure
			elseif any( strcmpi( ch, {'s'} ) )
				save_landmarks( d.lmxyz, rawfiles{wrlidx} );
				changed_landmarks = false;
			
			%  `g`    : goto specific scan number
			elseif any( strcmpi( ch, {'g'} ) )
				if ~confirm_landmarks(), continue; end
				n = str2double( input( 'Goto scan number: ', 's' ) );
				if isnan( n ) || n < 1 || n > numel( wrlfiles )
					n = min( numel( wrlfiles ), max( 1, n ) );
					fprintf( 'Invalid file index. Going to %d instead.\n', n );
				end
				wrlidx = n;
				break;
			
			%  `t`    : switch texture on/off
			elseif any( strcmpi( ch, {'t'} ) )
				if ~isempty( get(h, 'FaceVertexCData') )
					% texture off, only shape
					set(h, 'FaceVertexCData',[], 'FaceColor',[.9 .9 .9], ...
								'AmbientStrength',.2, 'DiffuseStrength',.8, ...
								'SpecularStrength',.05);
					set(hl, 'Visible','on');
				else
					% texture on (lighting off)
					set(h, 'FaceVertexCData',tri.vertexcolor, ...
								'FaceColor','interp');
					set(hl, 'Visible','off');
				end
			
			% all other characters break the landmark loop
			elseif any( strcmpi( ch, {'n','p','q'} ) )
				if ~confirm_landmarks(), continue; end
				break;
			end
		end % ------------------------------------------------------------------

%
% Done editing, save and jump to next file
%
		if changed_landmarks
			save_landmarks( d.lmxyz, rawfiles{wrlidx} );
		end
		
		%  `n`: next,    `p`: previous,    `q`: quit
		if     any(strcmpi(ch,{'n'})), wrlidx=wrlidx+1;
		elseif any(strcmpi(ch,{'p'})), wrlidx=max(1,wrlidx-1);
		elseif any(strcmpi(ch,{'q'})), break;
		end
	end % ======================================================================

%
% Done all scans, close the windows
%
	if ishandle(f_main), close(f_main); end
	if ishandle(f_ex), close(f_ex); end
	fprintf( 'Totally done. ;)\n' );

%
% Nested functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%                  (share variables.)
%

%
% Event handlers
%
	function f_main_onkeypress( ~, evt )
		% Key press event handler captures key to derive next action
		d.key = char( evt.Key );
		uiresume;
	end

	function tri_onclick( varargin )
		% Mouse click event handler captures point on trimesh surface
		% - left mouse button marks point to place new landmark
		% - right mouse button selects nearest landmark
		st  = get( d.fig, 'SelectionType' );
		if strcmp( st, 'alt' )
			ax      = get( d.fig, 'CurrentAxes' );
			pt      = get( ax,    'CurrentPoint' );
			xyz     = intersect( d.shape, pt );
			dst     = repmat( xyz, size(d.lmxyz,1), 1 ) - d.lmxyz;
			[~,idx] = min( dot(dst,dst,2) );
			select_landmark( idx );
		else
			%set_mousepoint( xyz );
			set( f_main, 'WindowButtonMotionFcn', @tri_ondrag );
			set( f_main, 'WindowButtonUpFcn', {@tri_onrelease, false} );
		end
	end
	function tri_ondrag( varargin )
		set( f_main, 'WindowButtonMotionFcn', [] );
		cameratoolbar( 'SetMode','orbit' );
		cameratoolbar( f_main, 'down' );
		set( f_main, 'WindowButtonUpFcn', {@tri_onrelease, true} );
	end
	function tri_onrelease( varargin )
		dragged = varargin{end};
		if ~dragged			% after mouse click (point selection)
			set( f_main, 'WindowButtonMotionFcn', [] );
			set( f_main, 'WindowButtonUpFcn', [] );
			ax  = get( d.fig, 'CurrentAxes' );
			pt  = get( ax,    'CurrentPoint' );
			xyz = intersect( d.shape, pt );
			if ~isempty(xyz), set_mousepoint( xyz ); end
		else				% after mouse drag (object rotation)
			%wbuf( varargin{1:end-1} );
			cameratoolbar( 'up' );
			cameratoolbar( 'SetMode','nomode' );
			set( h, 'ButtonDownFcn',@tri_onclick );
		end
	end

%
% Mouse pointing
%
	function set_mousepoint( xyz )
		% Mark the point of the mouse
		% @param xyz  [x y z] matrix of the 3D mouse coordinate
		unset_mousepoint();
		d.mxyz = xyz;
		d.mhnd = plot3( xyz(1), xyz(2), xyz(3), 'b*', 'HitTest','off' );
	end
	function unset_mousepoint()
		% Unset any mouse position
		if ishandle(d.mhnd), delete(d.mhnd); end
		d.mxyz = [];
	end

%
% Landmark selection
%
	function select_landmark( idx )
		% Set active selection to landmark `idx`
		% @param idx  Index of the landmark to be set active, 0 to deactivate
		deselect_landmark();
		d.sel = idx;
		if ~idx, return; end
		xyz      = d.lmxyz(idx,:);
		d.selhnd = plot3( xyz(1), xyz(2), xyz(3), 'mo', ...
					'LineWidth',2, 'MarkerSize',10, 'HitTest','off' );
	end
	function deselect_landmark()
		% Unset any landmark selection
		if ishandle(d.selhnd), delete(d.selhnd); end
		d.sel = 0;
	end

%
% Confirm the number of landmarks before skipping to another file
%
	function confirmed = confirm_landmarks()
		% When >0 landmarks are expected, and >0 landmarks have been placed,
		% but they are different numbers, then raise the question if they really
		% want to save this configuration.
		nlm = size( d.lmxyz, 1 );
		if check_landmarks && nlm && (nlm ~= check_landmarks)
			question  = sprintf( ['You have annotated %d landmarks, but %d' ...
						' are expected. Do you still want to continue?'], ...
						nlm, check_landmarks );
			answer    = questdlg( question, 'Warning', 'Yes', 'No', 'Yes' );
			confirmed = strcmp( answer, 'Yes' );
		else
			confirmed = true;
		end
	end
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
end




%
% External functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%
function save_landmarks( landmarks, rawfilename )
% Write all placed landmarks to file
%
% @param landmarks    Nx3 matrix of N landmarks
% @param rawfilename  Full filename with writable permission
%
	if isempty(landmarks), fprintf('No data to save.\n'); return; end
	dlmwrite( rawfilename, landmarks, 'delimiter',' ', 'precision','%4.06f' );
	fprintf( 'Saved %d landmarks.\n', size(landmarks,1) );
end
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



