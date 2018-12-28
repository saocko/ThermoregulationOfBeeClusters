function[contour_image] =  generateContourImage(color_bar, step_array, values, x_mesh, y_mesh);
%Generates a contour image, prints it to file, loads the file, and then crops the image. It's a pretty roundabout way to do this,
%but I don't know any better way to do it.

close all;
pause(.2);


[AX, handle] = contourf(x_mesh, y_mesh, values, step_array, 'CDataMapping','direct');
colormap(color_bar)
set(gca, 'XTickLabelMode', 'Manual')
set(gca, 'XTick', [])
set(gca, 'YTickLabelMode', 'Manual')
set(gca, 'YTick', [])
set(gca, 'CLim', [0 1]);




pause(.2)



print('-dbmp', '-r300', 'TemporaryContourImage')


loaded_image = imread('TemporaryContourImage.bmp');
system('rm TemporaryContourImage.bmp');


%Crops the image
not_white = rgb2gray(loaded_image) ~= 255;
[im_x_mesh, im_y_mesh] = meshgrid(1:size(not_white, 2), 1:size(not_white, 1));

min_x = min(min(im_x_mesh(not_white)));
max_x = max(max(im_x_mesh(not_white)));

min_y = min(min(im_y_mesh(not_white)));
max_y = max(max(im_y_mesh(not_white)));

cropped_image = loaded_image(min_y:max_y, min_x:max_x, :);

contour_image = cropped_image;

close all;