function app_subsamples( meta, wrl, addstr )
% Extract all regions from full faces, compute their models, and write model
% plus projected data to file.
%
% @param meta    Optional Nx1 struct with file names etc.
% @param wrl     Optional Nx1 struct with trimeshes
% @param addstr  Optional string to append to filenames (before the extension)
%                useful e.g. when passing selections to meta and wrl (like
%                only male or female data)
%
	global DATA;

%
% Configure parameters here
%
	META_FILE     = [DATA 'metadata-uk.mat'];
	PCASHP_FOLDER = [DATA 'UK-Registered/'];
	REGIONS       = {'Smallface','Eyes','Nose','Mouth','Cheeks'};
	WRLTMP_FOLDER = '/tmp/subs/';

%
% Prepare filesystem
%
	if ~exist(WRLTMP_FOLDER,'dir'), mkdir(WRLTMP_FOLDER); end

%
% Load data
%
	if nargin<1, load(META_FILE); end
	if nargin<2, wrl=triload({meta.wrl}',true); end
	if nargin<3, addstr=''; end
	
	rgb_files = strcat( 'tri', {meta.name}', '.rgb' );
	fprintf( 'Loading %d .rgb files... ', numel(rgb_files) );
	rgb = cell( numel(rgb_files), 1 );
	for j = 1:numel(rgb_files)
		fprintf( '%d,', j );
		if ~mod(j,15), fprintf('...\n'); end
		f      = fopen( [PCASHP_FOLDER rgb_files{j}] );
		lines  = textscan( f, '%s %s %s' );
		fclose( f );
		lines  = strcat( lines{1}, {' '}, lines{2}, {' '}, lines{3} );
		rgb{j} = lines;
	end
	fprintf( 'done.\n' );

%
% Create temporary region wrl files
%
	wrl_files = strcat( WRLTMP_FOLDER, {meta.name}', 'ER.wrl' );
	jpg_files = strcat( 'iso', {meta.name}', '.jpg' );
	for i = 1:numel(REGIONS)
		r = REGIONS{i};
		fprintf( '-----\n' );
		fprintf( 'Processing %s.\n', r );
		try
			fidx = subload( [r 'Tri.bin'] );
		catch ME
			% Smallface is composed of Eyes, Nose, Mouth, and Cheeks
			ri   = i ~= 1:numel(REGIONS);
			reg  = strcat( REGIONS(ri), 'Tri.bin' );
			fidx = subload( reg{:} );
		end
		vidx = unique( wrl(1).faces(fidx,:) );
		
		% .wrl and .jpg
		sub = trisubs( wrl, fidx );
		trisave( sub, wrl_files, jpg_files );
		% .rgb
		for j = 1:numel(rgb_files)
			f = fopen( [WRLTMP_FOLDER rgb_files{j}], 'w' );
			fprintf( f, '%s\n', rgb{j}{vidx} );
			fclose( f );
		end

%
% Wait for user to train model
%
		fprintf( '%s .wrl files created in %s.\n', r, WRLTMP_FOLDER );
		fprintf( ['Now train model on files, generating ShpVtxModelBin.scm,' ...
					' and then press enter.'] );
		input( '', 's' );

%
% Create linear model and projected data
%
		newname = [PCASHP_FOLDER 'ShpVtxModelBin_' r addstr '.scm'];
		movefile( [WRLTMP_FOLDER 'ShpVtxModelBin.scm'], newname );

		pro = pcaload_scm( newname );
		pca = pcaproject( sub, pro );
		save( [PCASHP_FOLDER 'PCAProjected' r addstr '.mat'], 'pca' );
	end

%
% Clean temporary files
%
	rmdir( WRLTMP_FOLDER, 's' );
end

