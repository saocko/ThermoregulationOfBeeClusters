function [temperature_derivative_vector] = findTempDerivatives(density, temperature, delta_density, delta_temp, base_pressure, sysparams, kphi)

%fprintf('At findTempDerivatives \n');


[conv_heat_transf_matrix, base_conv_heat_transf] = calculateAirVelPhi(density, temperature, delta_density, delta_temp, base_pressure, sysparams, kphi);
f_unpert = calculateHeatFunctions(density, temperature, sysparams);
f_pert = calculateHeatFunctions(density + delta_density, temperature + delta_temp, sysparams);

%
cond_heat_transf_matrix = zeros(sysparams.array_size);
base_cond_heat_transf = zeros(sysparams.array_size, 1);
unpacked_metab_vector = zeros(sysparams.array_size, 1);

metab_times_volume = f_pert.metab .* sysparams.cell_volume;
unpacked_metab_vector = metab_times_volume(sysparams.index_to_array_helper);

%We need to fill the conductivity matrix
for iX = 1:(sysparams.array_width-1)
    for iY = 1:(sysparams.array_height-1)
               
        cur_index = sysparams.index_array(iY, iX);
        cur_temp = temperature(iY, iX);
                
        %Upper neighbor
        neighbor_index(1) = sysparams.index_array(iY +1, iX   );
        heat_transfer_coeff(1)=  harmmean([f_pert.cond(iY, iX)  f_pert.cond(iY+1, iX)])  * (sysparams.upper_area(iY, iX)/sysparams.cell_width);
        neighbor_temp(1) = temperature(iY+1, iX);
        
        %Right neighbor
        neighbor_index(2) = sysparams.index_array(iY   , iX +1);
        heat_transfer_coeff(2) =  harmmean([f_pert.cond(iY, iX)  f_pert.cond(iY, iX+1)]) * (sysparams.right_area(iY, iX)/sysparams.cell_width);
        neighbor_temp(2) = temperature(iY, iX+1);
                
        %Iterate over the upper and right neighbors
        for k = 1:2
            %Big and small indices are a convenience to make the cases easier. If only one index corresponds to the inside of the
            %cluster, it's the big_index
            big_index = max(cur_index, neighbor_index(k));
            small_index = min(cur_index, neighbor_index(k));
            
            if(big_index ~= -1)
                %Heat transfer away from big_index 
                cond_heat_transf_matrix(big_index, big_index) =  cond_heat_transf_matrix(big_index, big_index) -heat_transfer_coeff(k);
                if(small_index ~= -1)
                    %Heat transfer between big_index and small_index
                    cond_heat_transf_matrix(small_index, small_index) =  cond_heat_transf_matrix(small_index, small_index) -heat_transfer_coeff(k);                    
                    %
                    cond_heat_transf_matrix(small_index, big_index) =  cond_heat_transf_matrix(small_index, big_index) +heat_transfer_coeff(k);
                    cond_heat_transf_matrix(big_index, small_index) =  cond_heat_transf_matrix(big_index, small_index) +heat_transfer_coeff(k);
                else
                    %Heat transfer from outside to big_index
                    base_cond_heat_transf(big_index) = base_cond_heat_transf(big_index) + heat_transfer_coeff(k) * sysparams.ambientT;
                end
            end            
        end
        %Done iterating over right and left
        
    end
end


%delta_temp_size = size(delta_temp)
temperature_vector = temperature(sysparams.index_to_array_helper) + delta_temp(sysparams.index_to_array_helper);

heat_gain_vector = ((cond_heat_transf_matrix + conv_heat_transf_matrix) * temperature_vector) + (unpacked_metab_vector + base_cond_heat_transf + base_conv_heat_transf);


%Adds the out-of-plane conductivity in the phi direction
heat_gain_vector = heat_gain_vector - ...
    (kphi^2 * 1./sysparams.cyl_radius(sysparams.index_to_array_helper)) * (sysparams.cell_width^2) ...
.* delta_temp(sysparams.index_to_array_helper) .*  f_unpert.cond(sysparams.index_to_array_helper);
%Cond * distance * temperature = power
%temp deriv = w^2/(r) * 1/(w^2 * r) = 1/(r^2) which makes sense laplacian-wise


%Temperature derivative is the heat gain divided by the density

temperature_derivative_vector  = heat_gain_vector .* 1./density(sysparams.index_to_array_helper) .* 1./sysparams.cell_volume(sysparams.index_to_array_helper); 


