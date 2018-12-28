function [temperature] = calculateTemp(density, guess_temp, sysparams)


%We first calculate metabolic rate and airvelocity based on the density and the current temperature. We then solve for temperature
%while keeping these things fixed. 


%Calculates the right and left components of the linear equation due to convection at the current temperature and density
[conv_heat_transf_matrix, base_conv_heat_transf] = calculateAirVel(density, guess_temp, sysparams);

%Finds the metabolism and conductivity we will be using
f = calculateHeatFunctions(density, guess_temp, sysparams);


cond_heat_transf_matrix = sparse([], [], [], sysparams.array_size, sysparams.array_size);
base_cond_heat_transf = zeros(sysparams.array_size, 1);
unpacked_metab_vector = zeros(sysparams.array_size, 1);


metab_times_volume = f.metab .* sysparams.cell_volume;

unpacked_metab_vector = metab_times_volume(sysparams.index_to_array_helper);


%We need to fill the conductivity matrix
for iX = 1:(sysparams.array_width-1)
    for iY = 1:(sysparams.array_height-1)
               
        cur_index = sysparams.index_array(iY, iX);
        cur_temp = guess_temp(iY, iX);
                
        %Upper neighbor
        neighbor_index(1) = sysparams.index_array(iY +1, iX   );
        heat_transfer_coeff(1)=  harmmean([f.cond(iY, iX)  f.cond(iY+1, iX)])  * (sysparams.upper_area(iY, iX)/sysparams.cell_width);
        neighbor_temp(1) = guess_temp(iY+1, iX);
        
        %Right neighbor
        neighbor_index(2) = sysparams.index_array(iY   , iX +1);
        heat_transfer_coeff(2) =  harmmean([f.cond(iY, iX)  f.cond(iY, iX+1)]) * (sysparams.right_area(iY, iX)/sysparams.cell_width);
        neighbor_temp(2) = guess_temp(iY, iX+1);
                
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



%Our total incoming heat is equal to the metabolism times heat takes from the outside both conductively and convectively
total_target_vector=  unpacked_metab_vector +  base_cond_heat_transf + base_conv_heat_transf;



%Heat created by metabolism/moved from outside is equal to the NEGATIVE of heat taken to a certain area.
temperature_vector = (cond_heat_transf_matrix + conv_heat_transf_matrix) \ -(total_target_vector);
%Actually does the linear solving;

temperature = sysparams.ambientT *  ones(size(guess_temp));


temperature(sysparams.index_to_array_helper) = temperature_vector;

%   fprintf('At end of calculateTemp, guess_temp size is %d, %d \n', size(guess_temp, 1), size(guess_temp, 2));






