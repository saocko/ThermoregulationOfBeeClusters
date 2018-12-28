function [density, temperature, sysparams] = iterativeSolver(guess_density, sysparams);

fprintf('At iterativeSolver! \n');
%This is the iterative solving method described in append. C1

%    fprintf('At integrated solver, guess_density  size is %d, %d \n', size(guess_density, 1), size(guess_density, 2));


eps_tol = .0000000001;
temp_relax_coeff = .2;
dens_relax_coeff = .2;
press_relax_coeff = .01;
height_relax_coeff = .4;




density = guess_density;
press_amb_T = sysparams.ambientT; %The ambient temperature that sets the bee pressure. 

temperature = ones(size(density)) * sysparams.ambientT;
%fprintf('At integrated solver, temp size is %d, %d \n', size(temperature, 1), size(temperature, 2));


start_time = cputime();
relax_coeff = .2;
i = 0;

not_suff_relaxed = true;
bee_number = sysparams.N;


%We iterate 50 times or until it converges, whichever takes longer. 

while(i < 50 || not_suff_relaxed)
    i = i+1;
        
    tic;    
    %Calculates the new density
    [new_density, new_number] = calculateRho(temperature, sysparams, sysparams.ambientT);
    
    
    max_dens_change = max(abs(new_density(:) - density(:)));
    
    %Adjusts bee pressure and system size
    density = (1- dens_relax_coeff) * density + dens_relax_coeff * new_density;
    bee_number = (1-dens_relax_coeff) * bee_number + dens_relax_coeff * new_number;
    
    
    
    %Updates height of the cluster such that bee number is conserved. 
        
    new_height = sysparams.height * (sysparams.N/bee_number)^(1./3.);
    max_height_change = abs(sysparams.height - new_height);
    sysparams.height = new_height;
    bee_number = sysparams.N;
    
    %Updates some helper variables in sysparams which depend on the height
    sysparams.graining = sysparams.array_height/(sysparams.height);
    sysparams.cell_width = 1./sysparams.graining;
    fillIndexArrayAndUpdateGeometry;
    
    %Relaxes temperature
    new_temp = calculateTemp(density, temperature, sysparams);
    max_temp_change = max(abs(temperature(:) - new_temp(:)));
    temperature = (1- temp_relax_coeff) * temperature + temp_relax_coeff * (new_temp);
    
    
    %Checks if it's sufficiently relaxed
    not_suff_relaxed = max_dens_change > eps_tol || max_height_change > eps_tol || max_temp_change > eps_tol;
    
    if(mod(i, sysparams.solving_params.iterations_per_print) ==0)
        %%Display the progress 
        
        if(sysparams.solving_params.print_updates_while_solving)
            %fprintf('\n********************************************\n');
            fprintf('\ni = %d, Maxdenschange is %.02e, Maxtempchange is %.02e ', i, max_dens_change, max_temp_change);
            fprintf('Cluster Radius is %f \n', (sysparams.array_height-2)/(sysparams.array_height) * sysparams.height);
            
            fprintf('Max and min temperature are %.2f, %.2f; ', max(temperature(sysparams.interior)), min(temperature(sysparams.interior)));
            fprintf('Max and min density are %.2f, %.2f \n', max(density(sysparams.interior)), min(density(sysparams.interior)));
        end
    end
    
end

fprintf('Reached end of integrated solver! Took %d iterations and %.03f seconds \n', i, cputime()-start_time);
