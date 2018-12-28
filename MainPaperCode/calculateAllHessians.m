%Loads the data from ClusterProfileOutput/SavedResults.mat, calculates the linear response matrices, and puts the results into
%CalculatedHessians, as well as saving a few options into StabilityResults

clear all;
close all;

%Sets a few options
stability_params.do_stability = 0;
stability_params.n_kphi_values = 3;
stability_params.plot_eig_vects = 0;
stability_params.update_stab_solv = 1000;
stability_params.temp_dens_deriv_ratios = exp(-10:.1:10);

%Just do this so I don't need to have everything in one folder
addpath('Subroutines');

load ClusterProfileOutput/SavedResults.mat
full_master_object = MasterObject;
full_unitless_sizes = unitless_sizes;

fprintf('\n*************At CalculateAllHessians!************* \n');

system('rm -rf StabilityResults');
system('mkdir StabilityResults');

save StabilityResults/StabilityParams.mat stability_params
total_start_time = cputime;

my_path = 'CalculatedHessians/';
system(sprintf('rm -rf %s', my_path));
system(sprintf('mkdir %s', my_path));


for cur_mode_index = mode_indices
    
    MasterObject = full_master_object{cur_mode_index};
    unitless_sizes = full_unitless_sizes{cur_mode_index};
    
    
    for size_index = 1:length(unitless_sizes)
        curr_unitless_size = unitless_sizes(size_index);
        
        for amb_t_index = 1:length(ambient_temps)
            
            sysparams = MasterObject{size_index}{amb_t_index}.sysparams;
            temperature = MasterObject{size_index}{amb_t_index}.temperature;
            density = MasterObject{size_index}{amb_t_index}.density;
            
            sysparams.stability_params = stability_params;
            fprintf('\nCalculating Hessian where MetabModel is %s, size is %.2f, ambientT is %.2f \n', sysparams.metabmodel, sysparams.unitless_size, sysparams.ambientT);
            
            for kphi_index = 1:stability_params.n_kphi_values
                kphi = kphi_index - 1;
                [density_hessian_matrix, temperature_hessian_matrix] = calculateHessian(density, temperature, sysparams, kphi);
                hessian_file_string = strcat( ...
                    my_path,...
                    sprintf('hessmode%dsize%dambt%dkphi%d.mat', cur_mode_index, size_index, amb_t_index, kphi_index));
                save(hessian_file_string, 'density_hessian_matrix', 'temperature_hessian_matrix');
                
                %Has one file for each mode/size/TAmb/Kphi combination, so it can spit out a lot of files.
            end
            
        end
        
    end
        
end

fprintf('Whole Hessian Calc took %f seconds for %d modes, %d ambient temps, %d Cluster Sizes \n', length(mode_indices),  cputime - total_start_time, length(ambient_temps)*length(curr_unitless_size), length(unitless_sizes) );
