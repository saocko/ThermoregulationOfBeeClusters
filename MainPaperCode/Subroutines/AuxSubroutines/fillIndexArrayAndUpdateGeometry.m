%This subroutine(Not quite a subroutine), takes a sysparams object, makes an index array, and also makes a bunch of helper objets
%to deal with the heat transfer and indexing. It's called somewhat redundantly, in that when it's called during iterativeSolver,
%only a fraction of what it does is required, but it's not worth the added complexity to change.
sysparams.graining = (sysparams.array_height -2)/sysparams.height;
sysparams.cell_width = 1./sysparams.graining;
sysparams.array_width = sysparams.array_height/2;
x_values = (sysparams.height/(sysparams.array_height-2)) * (-.5 + (1:sysparams.array_width ));
y_values = (sysparams.height/(sysparams.array_height-2)) * ( -.5 - sysparams.array_height/2 + (1:sysparams.array_height));


radius = sysparams.height/2;

[x_mesh, y_mesh] = meshgrid(x_values, y_values);
sysparams.index_array =  - ((x_mesh.^2 + y_mesh.^2) >= (radius).^2);

sysparams.cyl_radius = x_mesh;

%Fills up the index array and the index array helper
cur_index = 1;
for iX = 1:size(sysparams.index_array, 2)
    for iY = 1:size(sysparams.index_array, 1)
        if(sysparams.index_array(iY, iX)~=-1)
            sysparams.index_to_array_helper(cur_index) = sub2ind(size(sysparams.index_array), iY, iX);
            sysparams.index_array(iY, iX) = cur_index;
            cur_index = cur_index +1;
        end
    end
end

sysparams.index_to_array_helper = MakeHorizontal(sysparams.index_to_array_helper)';
%Just does a bit of a fix on the size

sysparams.interior = sysparams.index_array > -1;
sysparams.exterior = sysparams.index_array == -1;

%fprintf('Doing area and volume stuff \n');
sysparams.right_area  = (x_mesh + (.5 * sysparams.cell_width))* sysparams.cell_width; %The radius times the height(Area)
sysparams.upper_area  =.5 *( (x_mesh + (.5 * sysparams.cell_width)).^2 - (x_mesh - (.5 * sysparams.cell_width)).^2);
%The area of a pizza slice is .5 * r^2 * phi. Therefore, we take the outer area minus the inner area
sysparams.cell_volume = sysparams.upper_area * sysparams.cell_width;
%The volume is the upper area times the height


%Just to possibly cause us less headaches later on
sysparams.kphi = 0;

sysparams.array_size = sum(sysparams.index_array(:) > -1);
