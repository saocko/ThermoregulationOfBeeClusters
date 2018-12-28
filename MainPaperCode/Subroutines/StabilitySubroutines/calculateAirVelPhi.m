function [heat_transf_matrix, base_heat_transf_vec, phi_divergence_vec] = calculateAirVelPhi(density, temperature, delta_density, delta_temperature, base_pressure, sysparams, kphi)

%fprintf('At calculateAirVelPhi \n');

%Calculates the air velocity under a certain density, temperature, and periodic perturbations to each. This is Appendix F.1.b.
if(sysparams.darcy0 ==0)
    heat_transf_matrix = sparse([], [], [], sysparams.array_size, sysparams.array_size);
    base_heat_transf_vec = zeros(sysparams.array_size, 1);
    pressure_vector = zeros(sysparams.array_size, 1);
    %fprintf('Darcy0 is 0, returning \n');
else
    %fprintf('Darcy0 is not 0, calculating\n');
    
    %Does this for convenience
    temperature = temperature+ delta_temperature;
    density = density + delta_density;
    
    f_unpert = calculateHeatFunctions(density, temperature, sysparams);
    f_pert = calculateHeatFunctions(density+delta_density, temperature+ delta_temperature, sysparams);
    pressure_matrix =  sparse([], [], [], sysparams.array_size, sysparams.array_size);
    
    %pressure_matrix = zeros(sysparams.array_size); %For Right velocity, up velocity, and pressure
    in_plane_base_div = zeros(sysparams.array_size, 1); %The base divergence if pressure were zero everywhere
    out_of_plane_base_div = zeros(sysparams.array_size, 1);
    
    
    out_of_plane_air_transfer_coeffs = (kphi.^2 * 1./sysparams.cyl_radius) .* (sysparams.cell_width.^2) .*f_unpert.darcy;
    %This is per unit phi, which is different than per unit distance.The 1/cyl_rad is for the gradient of pressure which is
    %proportional to flow. The cell_width^2 is the cross-sectional area of a ring.
    %Flow rate is distance * darcy * pressure. This makes sense units wise. Then the divergence will be w^2/r * 1/(w^2 * r) = 1/(r^2)
    
    %The base divergence is (pressure(phi = 0) - base_pressure) * (vol/phi)*(kphi/cyl_rad)^2
    
    for iX = 1:(sysparams.array_width-1)
        for iY = 1:(sysparams.array_height-1)
            %Calculates the base divergences, if pressure(phi = 0) were zero everywhere
            
            cur_index = sysparams.index_array(iY, iX);
            
            upper_neighbor_index = sysparams.index_array(iY+1, iX);
            %The conductance is the permeability times the area divided by the distance
            air_tranfer_coeff = harmmean([f_pert.darcy(iY, iX)  f_pert.darcy(iY+1, iX)]) * sysparams.upper_area(iY, iX)/sysparams.cell_width;
            %The buoyant force is equal to the change in temperature times the height of a cell
            upper_buoyant_force = (sysparams.cell_width)*( mean([temperature(iY, iX), temperature(iY+1, iX)]) - sysparams.ambientT);
            
            %If the pressure in each was the same, the transfer would be the product of the two.
            base_air_transf = air_tranfer_coeff * upper_buoyant_force;
            
            if(cur_index ~= -1)
                in_plane_base_div(cur_index) = in_plane_base_div(cur_index) + base_air_transf;
                %What the divergence would be if the average pressure was
                %the base pressure, and the local pressure was zero, and on
                %the other side it was twice the base pressure.
                out_of_plane_base_div(cur_index) = out_of_plane_base_div(cur_index) - out_of_plane_air_transfer_coeffs(iY, iX) * base_pressure(cur_index);
            end
            %The upper part gets more divergence, the lower part gets less divergence
            if(upper_neighbor_index ~= -1)
                in_plane_base_div(upper_neighbor_index) = in_plane_base_div(upper_neighbor_index) - base_air_transf;
            end
            
            
        end
    end
    
    
    for iX = 1:(sysparams.array_width-1)
        for iY = 1:(sysparams.array_height-1)
            cur_index = sysparams.index_array(iY, iX);
            
            %Adds a component for the out of plane divergence due to different pressures in different places
            if(cur_index ~= -1)
                pressure_matrix(cur_index, cur_index)  =    pressure_matrix(cur_index, cur_index) + out_of_plane_air_transfer_coeffs(iY, iX);
            end
            
            %Calculates the pressure matrix, which will be put into a linear solver to find pressure everywhere
            %Upper neighbor
            neighbor_index(1) = sysparams.index_array(iY +1, iX);
            air_tranfer_coeff(1)=  harmmean([f_pert.darcy(iY, iX)  f_pert.darcy(iY+1, iX)])  * sysparams.upper_area(iY, iX)/sysparams.cell_width;
            
            %Right neighbor
            neighbor_index(2) = sysparams.index_array(iY   , iX +1);
            air_tranfer_coeff(2) =  harmmean([f_pert.darcy(iY, iX)  f_pert.darcy(iY, iX+1)]) * sysparams.right_area(iY, iX)/sysparams.cell_width;
            
            
            for k = 1:2
                
                if(cur_index ~= -1)
                    pressure_matrix(cur_index, cur_index) = pressure_matrix(cur_index, cur_index) + air_tranfer_coeff(k); %More pressure means more diverengence
                end
                
                if(neighbor_index(k) ~=-1)
                    pressure_matrix(neighbor_index(k), neighbor_index(k)) = pressure_matrix(neighbor_index(k), neighbor_index(k)) + air_tranfer_coeff(k);%More pressure means more divergence
                end
                
                if((neighbor_index(k)~=-1) && (cur_index ~=-1))
                    pressure_matrix(cur_index, neighbor_index(k)) = pressure_matrix(cur_index, neighbor_index(k))  - air_tranfer_coeff(k); %Higher pressure means negative divergence
                    pressure_matrix(neighbor_index(k), cur_index) = pressure_matrix(neighbor_index(k), cur_index)  - air_tranfer_coeff(k);
                end
                %The neighbor part gets more divergence, the lower part gets less
            end
            
            %End of positional loop
        end
    end
    
    
    
    pressure_vector = pressure_matrix \ -(in_plane_base_div + out_of_plane_base_div);
    %The pressure must cancel out what the base divergence would be
    
    base_heat_transf_vec = zeros(size(pressure_vector));
    heat_transf_matrix = sparse([], [], [], sysparams.array_size, sysparams.array_size);
    
    is_vert_help = [1 0];%Just a little helper array
    
    
    %Calculates the heat flow from each cell to each other cell. This gives us
    %the heat transfer matrix and the heat transfer vector for convection
    
    
    total_in_plane_divergence = zeros(sysparams.array_size, 1);
    for iX = 1:(sysparams.array_width-1)
        for iY = 1:(sysparams.array_height-1)
            
            %Makes the convective heat transfer matrix
            
            cur_index = sysparams.index_array(iY, iX);
            cur_temp = temperature(iY, iX);
            
            
            
            %Figure out the pressure in our cell
            if(cur_index ==-1)
                cur_press = 0;
            else
                cur_press = pressure_vector(cur_index);
            end
            
            
            %Upper neighbor
            neighbor_index(1) = sysparams.index_array(iY +1, iX);
            air_tranfer_coeff(1)=  harmmean([f_pert.darcy(iY, iX)  f_pert.darcy(iY+1, iX)]) * sysparams.upper_area(iY, iX)/sysparams.cell_width;
            neighbor_temp(1) = temperature(iY+1, iX);
            
            
            neighbor_index(2) = sysparams.index_array(iY   , iX +1);
            air_tranfer_coeff(2) =  harmmean([f_pert.darcy(iY, iX)  f_pert.darcy(iY, iX+1)]) * sysparams.right_area(iY, iX)/sysparams.cell_width;
            neighbor_temp(2) = temperature(iY, iX+1);
            
            %Calculate pressure in neighbor cells
            for k = 1:2
                if(neighbor_index(k) == -1)
                    neighbor_press(k) = 0;
                else
                    neighbor_press(k) = pressure_vector(neighbor_index(k));
                end
            end
            
            
            
            air_transf_rate = air_tranfer_coeff .* ...
                ((cur_press - neighbor_press) + is_vert_help .* (.5/sysparams.graining) .*(neighbor_temp + cur_temp - 2*sysparams.ambientT));
            
            
            
            %from_index is the index of the cell where the air flow came from, to_index is the index of the cell where the air
            %flow is going to.
            for k = 1:2
                if(air_transf_rate(k) >0)
                    from_index = cur_index;
                    to_index = neighbor_index(k);
                    %Air going from cur to neighbor
                else
                    from_index = neighbor_index(k);
                    to_index = cur_index;
                    %Vice versa
                end
                
                
                if(from_index ~= -1)
                    heat_transf_matrix(from_index, from_index) = heat_transf_matrix(from_index, from_index) - abs(air_transf_rate(k));
                    
                    if(to_index ~= -1)
                        heat_transf_matrix(to_index, from_index) = heat_transf_matrix(to_index, from_index)  + abs(air_transf_rate(k));
                    end
                else
                    if(to_index ~= -1)
                        base_heat_transf_vec(to_index) = base_heat_transf_vec(to_index) + abs(air_transf_rate(k)) * sysparams.ambientT;
                    end
                    
                end
                
                %End of positional loop
                
                %Does a check
                if(from_index ~= -1)
                    total_in_plane_divergence(from_index) = total_in_plane_divergence(from_index) +abs(air_transf_rate(k));
                end
                if(to_index ~=-1)
                    total_in_plane_divergence(to_index) = total_in_plane_divergence(to_index) -abs(air_transf_rate(k));
                end
            end
        end
    end
    
    
    for i = 1:sysparams.array_size
        heat_transf_matrix(i, i) = heat_transf_matrix(i, i) + total_in_plane_divergence(i);
    end
    %Positive in plane divergence leads to negative out of plane divergence, which draws air in, giving a positive component to the
    %heat transfer matrix
    
    %max_abs_tot_div = max(abs(total_in_plane_divergence))
end







