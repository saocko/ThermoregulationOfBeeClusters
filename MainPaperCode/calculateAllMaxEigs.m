%Loads the data from ClusterProfileOutput/SavedResults.mat, CalculatedHessians, as well as StabilityParams, and calculates the
%maximum real part of the eigenvalues to see if there is a linear instability. Currently only outputs things to the command line. 


clear all;
close all;
%Just do this so I don't need to have everything in one folder
addAllPaths

load ClusterProfileOutput/SavedResults.mat
full_master_object = MasterObject;
full_unitless_sizes = unitless_sizes;

fprintf('***************At calculateAllMaxEigs!***************\n');

load('StabilityResults/StabilityParams.mat');
stability_params.temp_dens_deriv_ratios =exp([ -10:-5 -4:.1:4 5:10]);

total_start_time = cputime;
my_path = 'CalculatedHessians/';

num_eigs_geq_zero = nan(max(mode_indices),length(unitless_sizes{1}), length(ambient_temps), stability_params.n_kphi_values, length(stability_params.temp_dens_deriv_ratios));
all_max_eigs = nan(max(mode_indices),length(unitless_sizes{1}), length(ambient_temps), stability_params.n_kphi_values, length(stability_params.temp_dens_deriv_ratios)); 
for cur_mode_index = mode_indices
    fprintf('\nDoing mode %d ... \n \n', cur_mode_index);
    
    MasterObject = full_master_object{cur_mode_index};
    unitless_sizes = full_unitless_sizes{cur_mode_index};
        
    for size_index = 1:length(unitless_sizes)
        curr_unitless_size = unitless_sizes(size_index);
        
        for amb_t_index = 1:length(ambient_temps)
            
            sysparams = MasterObject{size_index}{amb_t_index}.sysparams;
            temperature = MasterObject{size_index}{amb_t_index}.temperature;
            density = MasterObject{size_index}{amb_t_index}.density;
            
            sysparams.stability_params = stability_params;
            fprintf('Loading Hessians where MetabModel is %s, size is %.2f, ambientT is %.2f \n', sysparams.metabmodel, sysparams.unitless_size, sysparams.ambientT);
            
            for kphi_index = 1:stability_params.n_kphi_values     
                kphi = kphi_index - 1;
                fprintf('At kphi = %d \n', kphi);
                hessian_file_string = strcat( ...
                    my_path,...
                    sprintf('hessmode%dsize%dambt%dkphi%d.mat', cur_mode_index, size_index, amb_t_index, kphi_index));
                load(hessian_file_string);
                
                last_length = 0;
                for ratio_index = 1:length(stability_params.temp_dens_deriv_ratios)
                   cur_ratio = stability_params.temp_dens_deriv_ratios(ratio_index); 
                   total_hessian = sqrt(cur_ratio) * temperature_hessian_matrix + (1/sqrt(cur_ratio)) * density_hessian_matrix;
                   [max_eig, n_geq_zero] = findMaxEig(total_hessian);
                   
                   all_max_eigs(cur_mode_index, size_index, amb_t_index, kphi_index, ratio_index) = max_eig;
                   num_eigs_geq_zero(cur_mode_index, size_index, amb_t_index, kphi_index, ratio_index) = n_geq_zero;                   
                   
                   if(mod(ratio_index, 10) == 0)
                       last_length = updatePrint(sprintf('Doing ratio index %d out of %d', ratio_index, length(stability_params.temp_dens_deriv_ratios)), last_length);
                   end
                end
                updatePrint('', last_length);
                
                
                %temp_hessian_index_string = sprintf('temphessmode%dsize%dambt%dkphi%d', cur_mode_index, size_index, amb_t_index, kphi_index);
                %dens_hessian_index_string = sprintf('denshessmode%dsize%dambt%dkphi%d', cur_mode_index, size_index, amb_t_index, kphi_index);
                
%                my_eval_sp

                clear density_hessian_matrix;
                clear tempeature_hessian_matrix;
            end
        end
        
    end
    
    fprintf('\n');
    
end
    fprintf('calculateAllMaxEigs took %f seconds for %d modes,  %d ambient temps, %d Cluster Sizes \n', length(mode_indices), cputime - total_start_time, length(ambient_temps)*length(curr_unitless_size), length(unitless_sizes) );


kphi_summed_instable_eigs = sum(num_eigs_geq_zero, 4);
%k_phi_not_zero_instable_eigs = num_eigs_geq_zero(:, :, :, 2:3, :);
max_eigs_at_ratio = sum(max(mode_indices), length(stability_params.temp_dens_deriv_ratios));



%Print the maximum eigenvalues for each mode, and the number of eigenvalues greater than 0. We then see if there is ANY
%temperature/density derivative ratio where all cluster sizes and all ambient temperatures are stable.
fprintf('\n \n');
for cur_mode_index = mode_indices
    max_eigs_for_mode_index = all_max_eigs(cur_mode_index, :, :, :, :);
    n_geq_zero_for_mode_index = kphi_summed_instable_eigs(cur_mode_index, :, :, :, :);
    fprintf('At mode index %d max real part of eig is %.6e \n', cur_mode_index, max(real(max_eigs_for_mode_index(:))));        
    fprintf('Number of eigs with real>0 is %d, real=0: %d \n', max(real(max_eigs_for_mode_index(:)))>0, max(real(max_eigs_for_mode_index(:)))==0 );
    fprintf('Max Number greater than zero is %d \n', max(kphi_summed_instable_eigs(:)));
    for deriv_ratio_index = 1:length(stability_params.temp_dens_deriv_ratios)
    
        max_eigs_for_ratio_index = all_max_eigs(cur_mode_index, :, :, :, deriv_ratio_index);
        max_eigs_at_ratio(cur_mode_index, deriv_ratio_index) = max(real(max_eigs_for_ratio_index(:)));
    end
    
    [max_picked_eig, max_picked_index] = min(real(max_eigs_at_ratio(cur_mode_index, :)));
    fprintf('Among all derivative ratios the maximum eigenvalue is %.6e at ratio %.6e \n',  max_picked_eig, stability_params.temp_dens_deriv_ratios(max_picked_index));        
    
end










