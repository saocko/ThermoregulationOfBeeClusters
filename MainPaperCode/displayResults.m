clear all;
close all;


addAllPaths;


load ClusterProfileOutput/SavedResults.mat
full_master_object = MasterObject;
full_unitless_sizes = unitless_sizes;


fprintf('At displayResults! \n');

system('rm -rf DisplayedResults');
system('mkdir DisplayedResults');
total_start_time = cputime;



%Chooses a few options of what things to plot.
display_params.min_ambT = min(ambient_temps);
display_params.pad_array = 0;
display_params.juxtapose = 1;
display_params.show_profiles = 1;
display_params.show_radius_and_core_temp = 0;
display_params.show_circle = 1;
display_params.pause_before_plot = 0;



%We iterate over mode indices, cluster sizes, and ambient temperatures. If display_params.juxtapose is set to 1, then we also
%compare the profiles at the highest and lowest ambient temperature.


for index_to_use = mode_indices;
    
    MasterObject = full_master_object{index_to_use};
    unitless_sizes = full_unitless_sizes{index_to_use};
    sys_params_with_type = MasterObject{1}{1}.sysparams;
    fprintf('index_to_use is %d, mode is %s \n', index_to_use, sys_params_with_type.metabmodel);
    mkdir_sys_command = sprintf('mkdir DisplayedResults/Metab%s', sys_params_with_type.metabmodel);
    mkdir_sys_command =  strrep(num2str(mkdir_sys_command), '.', 'p');
    system(mkdir_sys_command);
    
    for size_index = 1:length(unitless_sizes)
        curr_unitless_size = unitless_sizes(size_index);
        mkdir_sys_command = sprintf('mkdir DisplayedResults/Metab%s/Size%.02f', sys_params_with_type.metabmodel, curr_unitless_size);
        mkdir_sys_command =  strrep(num2str(mkdir_sys_command), '.', 'p');
        system(mkdir_sys_command);
        
        
        max_height = 0;
        max_temp = min(ambient_temps(:));
        for amb_t_index = 1:length(ambient_temps)
            sysparams = MasterObject{size_index}{amb_t_index}.sysparams;
            max_height = max(max_height, sysparams.height * 1.05);
            max_temp = max(max_temp, max(MasterObject{size_index}{amb_t_index}.temperature(:)));
        end
        
        for amb_t_index = 1:length(ambient_temps)
            sysparams = MasterObject{size_index}{amb_t_index}.sysparams;
            sysparams.display_params = display_params;
            temperature = MasterObject{size_index}{amb_t_index}.temperature;
            density = MasterObject{size_index}{amb_t_index}.density;
            sysparams.display_params.xpad = max_height/2;
            sysparams.display_params.ypad = max_height/2;
            sysparams.display_params.max_display_temp = max_temp;
            
            fillIndexArrayAndUpdateGeometry;
            if(sysparams.display_params.show_profiles)
                %Decides whether to actually display the profile
                if(amb_t_index ==1)
                    sysparams.display_params.xpad = sysparams.height/2;
                    sysparams.display_params.xpad = sysparams.height/2;
                end
                                
                fprintf('Displaying profile for ambient temperature of %.1f, size %.1f! \n', sysparams.ambientT, sysparams.unitless_size);
                file_name = sprintf('DisplayedResults/Metab%s/Size%.02f/AmbT%.02f', sys_params_with_type.metabmodel, curr_unitless_size, sysparams.ambientT);
                file_name = strrep(num2str(file_name), '.', 'p');
                sysparams.display_params.flipped = 0;
                displayProfile(temperature, density, sysparams, file_name);
                close all;
                sysparams.display_params.flipped = 1;
                displayProfile(temperature, density, sysparams, strcat(file_name, 'Flipped'));
                %Does both flipped and not flipped. Purely a cosmetic difference. 
                
                close all;
                fprintf('Done displaying profile\n');
                %        pause;
            end
        end
        
        %Unpacks data into a form where it can get plotted
        for amb_t_index = 1:length(ambient_temps)
            sysparams = MasterObject{size_index}{amb_t_index}.sysparams;
            temperature = MasterObject{size_index}{amb_t_index}.temperature;
            density = MasterObject{size_index}{amb_t_index}.density;
            
            core_temps{size_index}(amb_t_index) = max(temperature(:));
            cluster_radii{size_index}(amb_t_index) = sysparams.height/2;
        end
        
    end
    
    if(display_params.show_radius_and_core_temp)
        sysparams.display_params = display_params;
        sysparams.plot_title = 'Unitless Core Temperatures For Different Sizes';
        file_name = sprintf('DisplayedResults/Metab%s/CoreTemps', sys_params_with_type.metabmodel);
        plotCoreTemperatures(unitless_sizes, ambient_temps, core_temps, sysparams, file_name);
        sysparams.plot_title = 'Cluster Radii for Different Sizes';
        fprintf('Trying to do clusterradii');
        plotClusterRadii(unitless_sizes, ambient_temps, cluster_radii, sysparams, sprintf('DisplayedResults/Metab%s/Radii', sys_params_with_type.metabmodel));
    end
    
    
    fprintf('Whole displaying took %f seconds for %d ambient temps, %d Cluster Sizes \n', cputime - total_start_time, length(ambient_temps)*length(curr_unitless_size), length(unitless_sizes) );
    
    if(display_params.juxtapose)
        %Juxtapose profiles, like what was done in the main body of the paper. 
        fprintf('Starting to juxtapose profiles... \n');
        for size_index = 1:length(unitless_sizes)
            upper_index = length(ambient_temps);
            
            temperature_list{1} = MasterObject{size_index}{1}.temperature;
            temperature_list{2} = MasterObject{size_index}{upper_index}.temperature;
            
            
            density_list{1} = MasterObject{size_index}{1}.density;
            density_list{2} = MasterObject{size_index}{upper_index}.density;
            
            sysparams_list{1} = MasterObject{size_index}{1}.sysparams;
            sysparams_list{2} = MasterObject{size_index}{upper_index}.sysparams;
            
            max_height = max(sysparams_list{1}.height, sysparams_list{2}.height);
            
            sysparams_list{1}.xpad = .55 * max_height;
            sysparams_list{1}.ypad = .55 * max_height;
            sysparams_list{2}.xpad = .55 * max_height;
            sysparams_list{2}.ypad = .55 * max_height;
            file_name = sprintf('DisplayedResults/Metab%s/Size%.02f/Juxtaposed',sys_params_with_type.metabmodel, unitless_sizes(size_index));
            file_name = strrep(num2str(file_name), '.', 'p');
            fprintf('Sizes of each are %f, %f \n', sysparams_list{1}.N, sysparams_list{2}.N);
            
            juxtaposeProfiles(temperature_list, density_list, sysparams_list, file_name);
        end
    end
    
end

close all;