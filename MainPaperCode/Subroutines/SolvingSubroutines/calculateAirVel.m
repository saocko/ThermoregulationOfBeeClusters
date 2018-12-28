function [heat_transf_matrix, base_heat_transf_vec, pressure_vector] = calculateAirVel(density, guess_temp, sysparams)
%Sets up a linear equation to determine the air velocity at fixed temperature and bee density. 


if(sysparams.darcy0 ==0)
    heat_transf_matrix = sparse([], [], [], sysparams.array_size, sysparams.array_size);
    base_heat_transf_vec = zeros(sysparams.array_size, 1);
    pressure_vector = zeros(sysparams.array_size, 1);
    %Checks special case of no convection. 
    %fprintf('Darcy0 is 0, returning \n');
else
    %fprintf('Darcy0 is not 0, calculating\n');
    
    f = calculateHeatFunctions(density, guess_temp, sysparams);
    
    pressure_matrix =  sparse([], [], [], sysparams.array_size, sysparams.array_size);
    
    %pressure_matrix = zeros(sysparams.array_size); %Pressure is the independent variable we solve for, such that the net outwards
    %flow(divergence) of each cell is 0. 
    
    %The base divergence if pressure were zero everywhere(Changes in temperature and airflow would give us divergence)
    base_divergence = zeros(sysparams.array_size, 1);
    
        
    for iX = 1:(sysparams.array_width-1)
        for iY = 1:(sysparams.array_height-1)
            %Calculates the base divergences, if pressure were zero everywhere
            cur_index = sysparams.index_array(iY, iX);
            
            upper_neighbor_index = sysparams.index_array(iY+1, iX);
            %The air transfer coefficient (air conductance) is the permeability times the area divided by the distance
            air_tranfer_coeff = harmmean([f.darcy(iY, iX)  f.darcy(iY+1, iX)]) * sysparams.upper_area(iY, iX)/sysparams.cell_width;
            %The buoyant force is equal to the change in temperature times the height of a cell
            upper_buoyant_force = (1./sysparams.graining)*( mean([guess_temp(iY, iX), guess_temp(iY+1, iX)]) - sysparams.ambientT);
            
            %If the pressure in each was the same, the transfer would be the buoyancy times the air transfer coefficient
            base_air_transf = air_tranfer_coeff * upper_buoyant_force;
            
            %The upper part gets negative divergence, the lower part gets positive divergence
            if(cur_index ~= -1)
                base_divergence(cur_index) = base_divergence(cur_index) + base_air_transf;
            end
            
            if(upper_neighbor_index ~= -1)
                base_divergence(upper_neighbor_index) = base_divergence(upper_neighbor_index) - base_air_transf;
            end
            
        end
    end
    
    
    for iX = 1:(sysparams.array_width-1)
        for iY = 1:(sysparams.array_height-1)
            %Calculates the pressure matrix, which will be put into a linear solver to find pressure everywhere
            
            cur_index = sysparams.index_array(iY, iX);
            %Upper neighbor
            neighbor_index(1) = sysparams.index_array(iY +1, iX   );
            air_tranfer_coeff(1)=  harmmean([f.darcy(iY, iX)  f.darcy(iY+1, iX)])  * sysparams.upper_area(iY, iX)/sysparams.cell_width;
            
            %Right(outer) neighbor
            neighbor_index(2) = sysparams.index_array(iY   , iX +1);
            air_tranfer_coeff(2) =  harmmean([f.darcy(iY, iX)  f.darcy(iY, iX+1)]) * sysparams.right_area(iY, iX)/sysparams.cell_width;
            
            %iterates over upper and right neighbors
            for k = 1:2
                
                if(cur_index ~= -1)
                    pressure_matrix(cur_index, cur_index) = pressure_matrix(cur_index, cur_index) + air_tranfer_coeff(k);
                    %Flow out of the current index in the direction of the neighbor index. More pressure means more diverengence
                end
                
                if(neighbor_index(k) ~=-1)
                    %Flow from the neighbor index in the direction of the current index
                    pressure_matrix(neighbor_index(k), neighbor_index(k)) = pressure_matrix(neighbor_index(k), neighbor_index(k)) + air_tranfer_coeff(k);%More pressure means more divergence
                end
                
                if((neighbor_index(k)~=-1) && (cur_index ~=-1))
                    %Transfer between neighbor_index and current index
                    pressure_matrix(cur_index, neighbor_index(k)) = pressure_matrix(cur_index, neighbor_index(k))  - air_tranfer_coeff(k);
                    pressure_matrix(neighbor_index(k), cur_index) = pressure_matrix(neighbor_index(k), cur_index)  - air_tranfer_coeff(k);
                end
                
                
            end
            
            %End of positional loop
        end
    end
    
    
    
    pressure_vector = pressure_matrix \ -base_divergence;
    %Actually solves for it
    %The pressure must cancel out what the base divergence would be, s.t. the actual divergence is 0. 
    
        
    base_heat_transf_vec = zeros(size(pressure_vector));
    heat_transf_matrix = sparse([], [], [], sysparams.array_size, sysparams.array_size);
    
    is_vert_help = [1 0]; %Just a little helper array to use for piecewise multiplication
        
    %Calculates the heat flow from each cell to each other cell. This gives us
    %the heat transfer matrix and the heat transfer vector for convection. This uses an upstreaming scheme, where the heat
    %transfer between two cells depends on the temperature of the cell that the air is leaving. 
    
    %A check that the total divergence is zero. If it's not, then we have set up the linear problem incorrectly
    total_divergence = zeros(sysparams.array_size, 1);
    
    for iX = 1:(sysparams.array_width-1)
        for iY = 1:(sysparams.array_height-1)
            
            %Makes the convective heat transfer matrix
            cur_index = sysparams.index_array(iY, iX);
            cur_temp = guess_temp(iY, iX);
            
            
            %Figure out the pressure in our cell
            if(cur_index ==-1)
                cur_press = 0; %Pressure outside of the cluster is zero
            else
                cur_press = pressure_vector(cur_index);
            end
            
            
            %Upper neighbor
            neighbor_index(1) = sysparams.index_array(iY +1, iX);
            air_tranfer_coeff(1)=  harmmean([f.darcy(iY, iX)  f.darcy(iY+1, iX)]) * sysparams.upper_area(iY, iX)/sysparams.cell_width;
            neighbor_temp(1) = guess_temp(iY+1, iX);
            
            %Right(outer) neighbor
            neighbor_index(2) = sysparams.index_array(iY   , iX +1);
            air_tranfer_coeff(2) =  harmmean([f.darcy(iY, iX)  f.darcy(iY, iX+1)]) * sysparams.right_area(iY, iX)/sysparams.cell_width;
            neighbor_temp(2) = guess_temp(iY, iX+1);
            
            %Calculate pressure in neighbor cells
            for k = 1:2
                if(neighbor_index(k) == -1)
                    neighbor_press(k) = 0;
                else
                    neighbor_press(k) = pressure_vector(neighbor_index(k));
                end
            end
            
            
            %Air transfer due to buoyancy and pressure differences
            air_transf_rate = air_tranfer_coeff .* ...
                ((cur_press - neighbor_press) + is_vert_help .* (.5/sysparams.graining) .*(neighbor_temp + cur_temp - 2*sysparams.ambientT));
            
            
            
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
                    %Heat transferred away from from_index
                    heat_transf_matrix(from_index, from_index) = heat_transf_matrix(from_index, from_index) - abs(air_transf_rate(k));
                    if(to_index ~= -1)
                        %Transfer from from_index to to_index
                        heat_transf_matrix(to_index, from_index) = heat_transf_matrix(to_index, from_index)  + abs(air_transf_rate(k));
                    end
                else
                    if(to_index ~= -1)
                        %Heat transfer from the outside to to_index
                        base_heat_transf_vec(to_index) = base_heat_transf_vec(to_index) + abs(air_transf_rate(k)) * sysparams.ambientT;
                    end
                end
                %End of positional loop
                
                %Does some summing to check that the actual divergence of each cell is actually zero(Air flow conserved)
                if(from_index ~= -1)
                    total_divergence(from_index) = total_divergence(from_index) +abs(air_transf_rate(k));
                end
                if(to_index ~=-1)
                    total_divergence(to_index) = total_divergence(to_index) -abs(air_transf_rate(k));
                end
            end
        end
        
    end
    
    %Makes sure that divergence is very small
    if(max(abs(total_divergence))> .000001)
        fprintf('Max divergence is %f, aborting \n', max(abs(total_divergence(:))));
        abort;
    end
end