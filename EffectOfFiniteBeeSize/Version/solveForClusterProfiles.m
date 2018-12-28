clear all;
close all;


unitless_sizes = [.5  1  3];

fprintf('At solveForClusterProfiles! \n');
if(1)
    sysparams.arraysize = 150;
    step_size = .05;
    ambient_temps = -.7:step_size:.8;
else
    sysparams.arraysize = 70;
    step_size = .15;
end

%Sysparams is the object that has all the parameters of the system, as well as a few options for plotting, etc. 

sysparams.c0 = .45;
sysparams.c1 = .3;
sysparams.max_dens = .8;
sysparams.bee_length = .14;


sysparams.do_eff_amb_t = 1;
%Says wheether the effective ambient temperature should be the temperature below the surface, or simply the ambient temperature.
%You can toggle this either way

sysparams.base_dens = .85 + .1 * sysparams.do_eff_amb_t;
sysparams.display_params.pause = 0;

sysparams.metabmodel = 'Constant';
%sysparams.metabmodel = 'Changing';
sysparams.bulkmodel = 'Constant';
%sysparams.bulkmodel = 'Changing';

sysparams.cond0 = .2;



sysparams.print_fig = 0;
system('rm -rf Amb*.eps');

total_start_time = cputime;

for unitless_size_ind = 1:length(unitless_sizes)
    sysparams.N = unitless_sizes(unitless_size_ind) * ( (4/3) * pi());
    sysparams.total_radius = 1.2 * sysparams.N ^.33333;
    updatePositionParameters;
    density = ones(sysparams.arraysize, 1) * sysparams.N/(sysparams.total_radius ^3);
    
    for amb_t_index = 1:length(ambient_temps)
        
        sysparams.ambientT = ambient_temps(amb_t_index);
        start_time_for_this_run = cputime;
        fprintf('\n *******************\n ');
        
        fprintf('Starting to solve for ambient temperature of %f \n', sysparams.ambientT);
        [density, temperature, sysparams] = iterativeSolver(density, sysparams);
        fprintf('Finishing solving for ambient temperature of %f \n', sysparams.ambientT);
        
        if(0)
            close all;
            fprintf('Displaying profile! \n');
            fprintf('Took %f seconds for this ambient temperature \n', cputime - start_time_for_this_run);
            fprintf('******************* \n \n \n \n ');
            file_name = sprintf('AmbT%.02f', sysparams.ambientT);
            file_name = strrep(num2str(file_name), '.', 'p');
            displayProfile(temperature, density, sysparams, file_name);
            pause(.2);
        end
        
        seconds_took_list{unitless_size_ind}{amb_t_index} = cputime - start_time_for_this_run;
        density_list{unitless_size_ind}{amb_t_index} = density;
        temperature_list{unitless_size_ind}{amb_t_index} = temperature;
        radius_list{unitless_size_ind}{amb_t_index} = sysparams.total_radius;
        core_temp_list{unitless_size_ind}{amb_t_index} = max(temperature(:));
       
    end
    
end
fprintf('Whole thing took %f seconds for %d ambient temps \n', cputime - total_start_time, length(ambient_temps));

if(sysparams.do_eff_amb_t)
    core_temp_string = 'CoreTempsWithEffect';
    core_and_rad_string = 'ClusterRadiiAndCoreTempsWithEffect';
    cluster_radii_string = 'ClusterRadiiWithEffect';
else
    core_temp_string = 'CoreTempsWithoutEffect';   
    core_and_rad_string = 'ClusterRadiiAndCoreTempsWithoutEffect';  
    cluster_radii_string = 'ClusterRadiiWithoutEffect';    
end
   

%Plot core temps and cluster radii 
plotClusterRadii(unitless_sizes, ambient_temps, radius_list, sysparams, cluster_radii_string);
plotCoreTemperatures(unitless_sizes, ambient_temps, core_temp_list, sysparams, core_temp_string);

