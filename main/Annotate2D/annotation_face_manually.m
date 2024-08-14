%   Description:
%       landmark = annotation_face_manually(img, num_landmarks)
%       To manually annotate a face image
%   Parameters:
%       img - a color or grey-level 2D image
%       num_landmarks - the number of landmarks to be annotated
%   Output:
%       landmark - a N*2 matrix with each row of the corresponging
%       coordinates [x_n, y_n] of the n-th landmark
%   Copyrights:
%       Zhenhua FENG,2015
%       Centre for Vision, Speech and Signal Processing, Unviersity of Surrey, UK
%       Email: fengzhenhua2010@gmail.com


function landmark = annotation_face_manually(img, num_landmarks)
switch nargin
    case 1
        num_landmarks = 3;
        disp('Warning: please ensure that the number of landmarks has been defined. Using default setting for 3 landmarks.')
    case 2
    otherwise
        disp('Error: Please call the function using: annotation_face_manually(path_to_the_image, number_of_landmarks)');
end

imshow(img);
hold on;

landmark = zeros(num_landmarks,2);
for i = 1:num_landmarks
    tmp_landmark = ginput(1);                    %get the coordinates of the current landmark
    plot(tmp_landmark(1),tmp_landmark(2),'r.');
    landmark(i,:) = tmp_landmark;
end
hold off;
end