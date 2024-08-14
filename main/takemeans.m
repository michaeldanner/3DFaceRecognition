function takemeans(annofolders, meanfolder, imagefolder, minversions)
% TAKEMEANS( ANNOFLDS, MEANFLD, IMAGEFLD, MINVERSIONS )
%
% Take the average of multiple identically named .lnd annotation files,
% retaining only points with at least MINVERSIONS different annotations.
%
% ANNOFOLDERS is a cell array of folder names. Each folder contains *.lnd
%             files, which contain points annotated on identically named
%             *.wrl files in IMAGEFOLDER. In other words, where
%             <IMAGEFOLDER>/<NAME>.wrl is a 3D image, then
%             <ANNOFOLDERS_i>/<NAME>.lnd is an annotation for that image.
% MEANFOLDER  is the name of the folder where all averaged annotations will
%             be written to. <MEANFOLDER>/<NAME>.lnd will be an average of
%             annotations for image <IMAGEFOLDER>/<NAME>.wrl. (An average
%             of at least MINVERSIONS annotations that is).
% IMAGEFOLDER is the name of the folder where all 3D images (.wrl) reside.
% MINVERSIONS is a number, specifying the minimum number of different
%             annotations required before taking the mean. Landmarks with
%             fewer annotations are ignored.
%
	if nargin<4 || isempty(minversions), minversions=1; end
  
  % Load all annotation data.
  
  fprintf(' load all files from %d annotation sets.\n', numel(annofolders));
  
	lnddef   = LandmarkDefinition.tena26;
  annosets = cellfun(@(fld)AnnotationSet.load(fullfile(fld,'*.lnd'), lnddef), ...
                      annofolders, 'UniformOutput',0);
  
  % Find all file names with at least `minversions` versions.
  
  allnames        = cellfun(@(as)as.names, annosets, 'UniformOutput',0);
  [allnames,~,ic] = unique(cat(1, allnames{:}));
  cnt             = hist(ic, 1:numel(allnames));
  allnames        = allnames(cnt >= minversions);
  
  % --- some helpful statistics. ---
  cnt = hist(cnt, 1:max(cnt));
  ii  = find(cnt > 0);
  fprintf('  %d images in total.\n', sum(cnt));
  fprintf('  %d annotations in total.\n', numel(ic));
  fprintf('  %5d images annotated %2d times.\n', [cnt(ii); ii]);
  fprintf('  (at least %d versions required for averaging)\n', minversions);
  % --- end statistics ---
  
  % Average all landmark points with at least `minversions` candidates.
  
  fprintf(' average annotations for %d images.\n', numel(allnames));
  
  nsets           = numel(annosets);
  nfiles          = numel(allnames);
  [~,npts,ndim]   = size(annosets{1}.coordinates);
  
  coords          = nan([nfiles npts ndim nsets]);
  
  for i = 1:nsets
    [~,ia,ib]        = intersect(allnames, annosets{i}.names);
    coords(ia,:,:,i) = annosets{i}.coordinates(ib,:,:);
  end
  
  counts          = sum(~isnan(coords(:,:,1,:)), 4);
  invalid         = counts < minversions;
  
  coords          = nanmean(coords, 4);
  coords(invalid) = nan;
  
  averaged        = AnnotationSet.factory(lnddef, 1:npts, coords, allnames);
  
  % Snap annotations to their 3D image surface,
  % and save to file.
  
  fprintf(' snap averaged annotations to image surfaces.\n');
  
  for i = 1:nfiles
    anno = averaged.annotation(i);
    fprintf('%5d. %s\n', i, anno.name);
    
    mesh = Mesh.load(fullfile(imagefolder, [anno.name '.wrl']));
    anno.snaptosurface(mesh);
    anno.saveas(fullfile(meanfolder, [anno.name '.lnd']));
    
    if ~mod(i-1, 100)
      trisurf(mesh);
      view(2);
      title(mesh.name);
      hold on;
      scatter3(anno, 50, anno.indices, 'filled');
      hold off;
      drawnow;
    end
  end
end
