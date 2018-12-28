%Puts you into a menu where you can choose a mode and cluster size, and it will display all instable eigenvectors.
addAllPaths

load ClusterProfileOutput/SavedResults.mat
full_master_object = MasterObject;
full_unitless_sizes = unitless_sizes;
fprintf('\n ********At showSomeEigenvectors!********* \n');


load('StabilityResults/StabilityParams.mat');


total_start_time = cputime;
my_path = 'CalculatedHessians/';


all_max_eigs = nan(max(mode_indices),length(unitless_sizes{1}), length(ambient_temps), stability_params.n_kphi_values, length(stability_params.temp_dens_deriv_ratios));


%A few options for how to display the information.
stability_params.print_mode = 1;
stability_params.only_show_positive_eigs = 1;
stability_params.show_circle = 1;

show_another = 1;
while(show_another)
    cur_mode_index = input('Which mode?(Choose 0 to end) \n');
    show_another = cur_mode_index> 0;
    if(show_another)
        fprintf('Sizes : \n');
        my_array(1, 1:length(full_unitless_sizes{cur_mode_index})) = 1:length(full_unitless_sizes{cur_mode_index});
        my_array(2, 1:length(full_unitless_sizes{cur_mode_index}))  = full_unitless_sizes{cur_mode_index};
        disp(my_array);
        size_index = input('Which size?\n');
        cur_ratio = input('Which temperature/density derivative ratio? \n');
        
        %Iterates over all ambient temperatures and wave numbers.
        for amb_t_index = 1:length(ambient_temps)
            sysparams = full_master_object{cur_mode_index}{size_index}{amb_t_index}.sysparams;
            sysparams.stability_params = stability_params;
            fprintf('\nDoing ambientT of %.2f \n', sysparams.ambientT);
            
            %Iterates over all wave numbers
            for kphi_index = 1:stability_params.n_kphi_values
                kphi = kphi_index - 1;
                fprintf('At kphi = %d \n', kphi);
                
                hessian_file_string = strcat( ...
                    my_path,...
                    sprintf('hessmode%dsize%dambt%dkphi%d.mat', cur_mode_index, size_index, amb_t_index, kphi_index));
                load(hessian_file_string);
                
                total_hessian = sqrt(cur_ratio) * temperature_hessian_matrix + (1/sqrt(cur_ratio)) * density_hessian_matrix;
                showMaxEigs(total_hessian, sysparams, 'StabilityResults/InstabilityOutput');
                
                
                clear density_hessian_matrix;
                clear tempeature_hessian_matrix;
            end
        end
    end
    
    fprintf('Reached end of this mode!\n');
end

