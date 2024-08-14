function app_subcreate( tri, sub, h )
% Mark triangles in the face to define a subregion
%
% Click and drag the mouse to mark triangles.
% Start on a marked triangle to trigger 'erase mode'.
% When finished enter the filename and press <enter>.
%
% You can first draw the shape yourself (and add other stuff to the axes)
% before calling this app. For example to mark other regions. In that case pass
% the trimesh's handle as second argument.
%
% @param tri  Trimesh from which triangles are to be marked
% @param sub  Nx1 array of face indices for initialisation
% @param h    Optional, if the trimesh was already drawn, pass its handle here
%
	if nargin<3, h=trisurf_(tri); end

%
% Axes, Figure, and Boundary
%	
	a      = get( h, 'Parent' );
	f      = get( a, 'Parent' );
	b      = boundary( h );

%
% Once drawn, Matlab provides convenient access to the X, Y and Z data
%
	tx     = get( h, 'XData' );
	ty     = get( h, 'YData' );
	tz     = get( h, 'ZData' );
	
	tmin   = [min(tx);min(ty);min(tz)]' - eps;
	tmax   = [max(tx);max(ty);max(tz)]' + eps;
	clear tx ty tz

%
% Drawmode and handles to marking patches
%
	m      = NaN( length(get(h,'Faces')), 1 );
	mode   = 'draw';

%
% Start listening for mouse actions
%
	set( h, 'ButtonDownFcn',@evt_mousedown );

%
% Initialise subregion
%
	if nargin > 1
		for i = 1:numel(sub)
			mark_face( sub(i) );
		end
	end

%
% App ends when user enters filename
%
	fprintf( 'To mark faces click and drag the mouse over the surface.\n' );
	fprintf( 'Erase by clicking and dragging over previously marked faces.\n' );
	filename = input( 'When done enter filename to save: ', 's' );
	fidx     = find( ~isnan( m ) );
	subsave( fidx, filename );



% ==============================================================================
% Nested functions for user interaction
%                                       (share variables.)
% ==============================================================================

%
% Event handlers
%
	function evt_mousedown( src, evt )
		% Event handler catches mouse clicks on 3D shape and selects faces
		pt  = get( a, 'CurrentPoint' );
		xyz = intersect( b, pt );
		fi  = find_face( xyz );
		if ishandle(m(fi)), mode='erase'; else, mode='draw'; end
		mark_face( fi );
		set( f, 'WindowButtonMotionFcn',@evt_mousemove, ...
					'WindowButtonUpFcn',@evt_mouseup );
	end
	function evt_mousemove( src, evt )
		% Find mouse position on surface mesh and mark hovered face
		pt  = get( a, 'CurrentPoint' );
		xyz = intersect( b, pt );
		fi  = find_face( xyz );
		mark_face( fi );
	end
	function evt_mouseup( src, evt )
		% Release mouse handlers when releasing the mouse button
		set( f, 'WindowButtonMotionFcn','', 'WindowButtonUpFcn','' );
	end

%
% Drawing
%
	function mark_face( fi )
		% Mark / unmark a face by drawing / erasing a blue triangle over it
		if strcmp(mode,'draw') && ~ishandle( m(fi) )
			m(fi) = patch( 'Faces',[1 2 3], ...
						'Vertices',tri.vertices(tri.faces(fi,:)',:), ...
						'FaceVertexCData',[0 1 1], 'FaceColor','flat', ...
						'EdgeColor','none', 'HitTest','off' );
		elseif strcmp(mode,'erase') && ishandle( m(fi) )
			delete( m(fi) );
			m(fi) = NaN;
		end
	end

%
% Lookup
%
	function fi = find_face( xyz )
		% Given a point in 3D lying on some face, determine the face's index
		% find approximately which triangle was clicked
		XYZ = repmat( xyz, size(tri.faces,1), 1 );
		fi  = all( XYZ > tmin, 2 ) & all( XYZ < tmax, 2 );
		fi  = find( fi );
		clear XYZ
		% find exactly which triangle was clicked
		if numel(fi) > 1
			for i = 1:numel(fi)
				% http://www.blackpawn.com/texts/pointinpoly/
				vi       = tri.faces(fi(i),:);
				v0       = tri.vertices(vi(3),:) - tri.vertices(vi(1),:);
				v1       = tri.vertices(vi(2),:) - tri.vertices(vi(1),:);
				v2       = xyz - tri.vertices(vi(1),:);
				d00      = dot( v0, v0 );
				d01      = dot( v0, v1 );
				d02      = dot( v0, v2 );
				d11      = dot( v1, v1 );
				d12      = dot( v1, v2 );
				invdenom = 1 / (d00 * d11 - d01 * d01);
				u        = (d11 * d02 - d01 * d12) * invdenom;
				v        = (d00 * d12 - d01 * d02) * invdenom;
				if (u > 0) && (v > 0) && (u + v < 1)
					fi = fi(i);
					break;
				end
			end
			if numel(fi) > 1
				error( 'Could not determine the triangle.' );
			end
		end
	end
end


