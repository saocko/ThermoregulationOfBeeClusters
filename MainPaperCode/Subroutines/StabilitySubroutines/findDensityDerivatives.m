function [density_deriv_vector] = findDensityDerivatives(density, temp, delta_density, delta_temp, sysparams, kphi)

%fprintf('At findDensityDerivatives \n');

%We calculate the bee pressure and then using a simple "bee pressure taxis" model,

%Spots which are saturated will have no bees enter or exit, to within limits of the linear approximation.
saturated_spots = abs(sysparams.max_dens - density)<.001;


base_bee_pressure = findBeePressure(density, temp, sysparams);
changed_bee_pressure = findBeePressure(density+ delta_density, temp + delta_temp, sysparams);

delta_bee_pressure = changed_bee_pressure - base_bee_pressure;
bee_number_deriv = zeros(size(density));

%First does movements of bees within the plane

for iX = 1:(sysparams.array_width-1)
    for iY = 1:(sysparams.array_height-1)
        
        cur_index = sysparams.index_array(iY, iX);
        cur_bee_pressure = changed_bee_pressure(iY, iX);
        cur_array_index = sub2ind(size(density), iY, iX);
        cur_saturated = saturated_spots(iY, iX);
        
        %Upper neighbor
        neighbor_index(1) = sysparams.index_array(iY +1, iX   );
        bee_transfer_coeff(1)=  mean([density(iY, iX)  density(iY+1, iX)])  * (sysparams.upper_area(iY, iX)/sysparams.cell_width);
        neighbor_bee_pressure(1) = changed_bee_pressure(iY+1, iX);
        neighbor_array_index{1} = sub2ind(size(density), iY+1, iX);
        neighbor_saturated(1) = saturated_spots(iY+1, iX);
        
        
        neighbor_index(2) = sysparams.index_array(iY   , iX +1);
        bee_transfer_coeff(2) =  mean([density(iY, iX)  density(iY, iX+1)]) * (sysparams.right_area(iY, iX)/sysparams.cell_width);
        neighbor_bee_pressure(2) = changed_bee_pressure(iY, iX+1);
        neighbor_array_index{2} = sub2ind(size(density), iY , iX + 1);
        neighbor_saturated(2) = saturated_spots(iY, iX+1);
        
        %Current is equal to the gradient in pressure times density times area
        
        %Iterate over upper and top neighbors
        
        
        for k = 1:2
            neither_saturated = (~cur_saturated) && (~neighbor_saturated(k));
            %Makes sure that both indices are interior and unsaturated
            if(cur_index > -1 && neighbor_index(k) > (-1) && neither_saturated)
                bee_transfer_rate = bee_transfer_coeff(k) * (cur_bee_pressure-neighbor_bee_pressure(k));
                
                %foobar = bee_number_deriv(neighbor_array_index{k})
                bee_number_deriv(neighbor_array_index{k}) = bee_number_deriv(neighbor_array_index{k})  + bee_transfer_rate;
                bee_number_deriv(cur_array_index) = bee_number_deriv(cur_array_index)  - bee_transfer_rate;
            end
        end
        
        %Now does bee movement in the phi direction.
        bee_number_deriv(cur_array_index) = bee_number_deriv(cur_array_index) - ...
            delta_bee_pressure(cur_array_index) * density(cur_array_index) * sysparams.cell_width^2 *...
            (kphi^2 * 1./sysparams.cyl_radius(cur_array_index));
        %Bee Movement in the phi direction.
        %BeePressure * Width * density ~Temperature * Width * cond -> Flow rate
        %Density deriv = Pressure * w^2/r * (1/(w^2 * r)) = 1/r^2 which works with the laplacian picture
    end
end

density_deriv = bee_number_deriv.* 1./sysparams.cell_volume;
density_deriv_vector = density_deriv(sysparams.index_to_array_helper);

%Add in a trick to lower the eigenvalue of the uniform density eigen vector
if(kphi == 0)
    total_change_in_bee_number = sum(sum(delta_density.*sysparams.cell_volume));
    density_deriv_vector = density_deriv_vector -.001 * total_change_in_bee_number/ sum(sum(sysparams.interior .* sysparams.cell_volume));
end



