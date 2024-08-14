function L = app_getvertices(tri, L0)
	f   = figure('KeyPressFcn',@uiresume);
	h   = trisurf_(tri);
	hdt = datacursormode(f);
	set(hdt, 'UpdateFcn', {@dtip_getvertex,tri});
	hold on;
	
	% Install the KeyPress handler that remains even through mode changes!!!
	install_handler(f, 'KeyPressFcn', @evt_keypress);
	
	H = [];	% list of plotted point handles
	L = [];	% list of selected vertices
	
	if nargin > 1 && ~isempty(L0)
		L = L0;
		for i = 1:numel(L)
			H(end+1) = plot3(tri.vertices(L(i),1), tri.vertices(L(i),2),...
						tri.vertices(L(i),3), 'g*');
		end
	end
	
	while true
		% Wait for a key press
		uiwait;
		if ~ishandle(f), break; end
		
		% Read the selected vertex
		try
			data = guidata(h);
			vidx = data.vidx;
		catch
			continue;
		end
		
		l = (L == vidx);
		if any(l)
			% delete if previously marked
			delete(H(l));
			H = H(~l);
			L = L(~l);
		else
			% otherwise, mark now
			vtx      = tri.vertices(vidx,:);
			L(end+1) = vidx;                                %#ok<AGROW>
			H(end+1) = plot3(vtx(1), vtx(2), vtx(3), 'g*'); %#ok<AGROW>
		end
	end
	L = int32(L);
end

function txt = dtip_getvertex(~, evt, tri)
% Add vertex index to the datatip, also store it in the gui data.
%
% @param  ~    not used
% @param  evt  Event object
% @param  tri  Trimesh as struct (contains at least Nx3 matrix .vertices)
% @return txt  String reading the X, Y, and Z coordinates and vertex index of
%              the selected vertex
%
% @note Stores vertex index in guidata under property .vidx
%
	pos    = get(evt, 'Position');
	pospos = repmat(pos, length(tri.vertices), 1);
	vidx   = find(all(pospos == tri.vertices, 2));
	
	data      = guidata(gcbo);
	data.vidx = vidx;
	guidata(gcbo, data);
	
	txt = {['X: ' num2str(pos(1),4)];
		['Y: ' num2str(pos(2),4)];
		['Z: ' num2str(pos(3),4)];
		['Vertex: ' num2str(vidx)]};
end

function [propagate] = evt_keypress(fig, evt)
	uiresume;
	
	propagate = false;
	prop      = {'Exploration.Datacursor', ...
		{'leftarrow','rightarrow','uparrow','downarrow','delete'}, ...
		'Exploration.Rotate3d', ...
		{'uparrow','downarrow','leftarrow','rightarrow','z','y'}, ...
		'Exploration.Zoom', ...
		{'uparrow','downarrow','alt','z','y'}};
	for i = 1:2:numel(prop)
		if isactiveuimode(fig, prop{i}) && any(strcmp(evt.Key, prop{i+1}))
			propagate = true;
			break;
		end
	end
end
