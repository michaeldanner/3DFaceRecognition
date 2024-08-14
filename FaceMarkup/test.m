d = uigetdir(pwd, 'C:\\Data\\bosphorus\\source\\BosphorusDB\\bs000\\');
files = dir(fullfile(d, '*.bnt'));
% Display the names
for k = 1:length(files)
  baseFileName = files(k).name;
  fullFileName = fullfile(d, baseFileName);
  myMesh = Mesh.load(fullFileName);
  newFileName = strrep(fullFileName, '.bnt', '.wrl');
  saveas(myMesh, newFileName, 'wrl');
end

