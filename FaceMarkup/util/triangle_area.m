function A = triangle_area(faces, vertices)
% Calculate surface areas of all faces.
%
% Input arguments:
%  FACES        An Mx3 matrix of triplets of vertex indices.
%               This function can also be called with a single argument,
%               being a `triangulation` or `Mesh` instance. The faces and
%               vertices are then read from the object.
%  VERTICES     An Nx3 matrix of point coordinates.
%
% Output arguments:
%  A  Mx1 array of triangle areas of each of the M faces.
%
% Considerations:
%  - http://en.wikipedia.org/wiki/Heron%27s_formula
%  - http://http.cs.berkeley.edu/~wkahan/Triangle.pdf
%  - and comment from Andres Toennesmann on:
%    http://www.mathworks.com/matlabcentral/fileexchange/16448
%
  if nargin == 1
    if isa(faces, 'triangulation')
      vertices = faces.Points;
      faces = faces.ConnectivityList;
    elseif isa(faces, 'Mesh')
      vertices = faces.vertices;
      faces = faces.faces;
    else
      error('Invalid input argument.');
    end
  end

  % Compute the edge vectors and their lengths.
  
  f2 = circshift(faces, -1, 2);
  ev = vertices(faces,:) - vertices(f2,:);
  el = sqrt(sum(ev .^ 2, 2));

  % Stabilized Heron's formula to calculate the triangle areas.
  % (Braces matter.)

  el = sort(reshape(el, size(faces)), 2);
  Z = (el(:,3) + (el(:,2) + el(:,1))) .* ...
      (el(:,1) - (el(:,3) - el(:,2))) .* ...
		  (el(:,1) + (el(:,3) - el(:,2))) .* ...
      (el(:,3) + (el(:,2) - el(:,1)));
	A = sqrt(max(0, Z)) / 4;
end
