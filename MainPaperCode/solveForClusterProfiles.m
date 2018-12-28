clear all;
close all;

addAllPaths;

%These are the basic parameters of the model
cond0 = .2;
darcy0 = 1.;
sysparams.cond0 = cond0;
sysparams.darcy0 = darcy0;
fprintf('At solveForClusterProfiles! \n');

sysparams.print_plots_to_file  = 1;
sysparams.solving_params.print_updates_while_solving = 1;
sysparams.solving_params.iterations_per_print = max(primes(50)); 
%Update every prime number of iterations so if there's some weird cycle going on I notice. 

%Set the cell size and the list of ambient temperatures to simulate at. 
sysparams.array_height = 32;
step_size = .6;
ambient_temps = -.7:1.5:.8;
ambient_temps = -sort(-ambient_temps);%Sort from highest to lowest, this is just a bit of a convenience thing. 

fprintf('Trying to remove old files... \n');
system('rm -rf ClusterProfileOutput');
fprintf('Removed old files \n');

total_start_time = cputime; %Just to see how much time there's left

%We solve for a bunch of unitless bee numbers, and for a bunch of unitless temperatures.
system('mkdir ClusterProfileOutput');


mode_indices = 2;
for i = mode_indices
    unitless_sizes{i} = [1.5];
end

%Save the list of ambient temperatures, unitless sizes, and modes. 
save ClusterProfileOutput/SavedResults unitless_sizes;
save ClusterProfileOutput/SavedResults ambient_temps;
save ClusterProfileOutput/SavedResults mode_indices;

for mode_index = mode_indices
    %Decide on the params. I have four options, constant/changing metabolism, convection/no convection. 
    if(mode_index ==1)
        fprintf('Doing constant metabolism \n');
        sysparams.c0 = .45;
        sysparams.c1 = .3;
        sysparams.base_dens = .85;
        sysparams.max_dens = .8;
        sysparams.metabmodel = 'Constant';
        sysparams.bulkmodel = 'Constant';
        sysparams.cond0 = cond0;
        sysparams.darcy0 = darcy0;
    elseif(mode_index ==2)
        fprintf('Doing changing metabolism \n');
        sysparams.c0 = .5;
        sysparams.c1 = .25;
        sysparams.max_dens = .8;
        sysparams.base_dens = .85;
        sysparams.metabmodel = 'Changing';
        sysparams.bulkmodel = 'Constant';
        sysparams.cond0 = cond0 * 2;
        sysparams.darcy0 = darcy0 * 2;
    elseif(mode_index == 3)
        fprintf('Doing constant metabolism \n');
        sysparams.c0 = .45;
        sysparams.c1 = .3;
        sysparams.base_dens = .85;
        sysparams.max_dens = .8;
        sysparams.metabmodel = 'Constant';
        sysparams.bulkmodel = 'Constant';
        sysparams.cond0 = cond0;
        sysparams.darcy0 = 0;
    elseif(mode_index ==4)
        fprintf('Doing changing metabolism \n');
        sysparams.c0 = .5;
        sysparams.c1 = .25;
        sysparams.max_dens = .8;
        sysparams.base_dens = .85;
        sysparams.metabmodel = 'Changing';
        sysparams.bulkmodel = 'Constant';
        sysparams.cond0 = cond0 * 2;
        sysparams.darcy0 = 0;
    else
        fprintf('Not a suitable mode number! \n')
        abort
    end
    
    
    %Iterate among different unitless sizes
    for size_index = 1:length(unitless_sizes{mode_index})
        curr_unitless_size = unitless_sizes{mode_index}(size_index);
        
        
        sysparams.unitless_size = curr_unitless_size;
        sysparams.N = curr_unitless_size *  (pi * 4/3); %If unitless size is 1, then fully compressed radius is 1.
        sysparams.height = (1/sysparams.max_dens) * sysparams.N ^(1./3.);
        fillIndexArrayAndUpdateGeometry;%Update the stuff for the graining, etc.
        
        %Start from a uniform density
        density = sysparams.interior * sysparams.N/(sysparams.height .^3 * (.5 * (sysparams.array_height.^2) /sysparams.array_size));
        fprintf('\n ******** Starting to solve for unitless size of %f ******** \n', curr_unitless_size);
        
        for amb_t_index = 1:length(ambient_temps)
            
            sysparams.ambientT = ambient_temps(amb_t_index);
            start_time_for_this_run = cputime;
            
            fprintf('\n *******************\n');
            fprintf('Starting to solve for ambientT of %.3f, unitless size = %.3f, metab is %s \n', sysparams.ambientT, curr_unitless_size, sysparams.metabmodel);
            fprintf('Basedens is %.2f, Maxdens is %.2f, c0 = %.2f, c1 = %.2f, cond0 = %.2f, darcy0 = %.2f \n', sysparams.base_dens, sysparams.max_dens, sysparams.c0, sysparams.c1, sysparams.cond0, sysparams.darcy0);
            [density, temperature, sysparams] = iterativeSolver(density, sysparams);
            
            fprintf('Finishing solving for ambient temperature of %f \n', sysparams.ambientT);
            
            
            MasterObject{mode_index}{size_index}{amb_t_index}.sysparams = sysparams;
            MasterObject{mode_index}{size_index}{amb_t_index}.temperature = temperature;
            MasterObject{mode_index}{size_index}{amb_t_index}.density = density;
            MasterObject{mode_index}{size_index}{amb_t_index}.seconds_took = cputime - start_time_for_this_run;
            save ClusterProfileOutput/SavedResults MasterObject ambient_temps unitless_sizes mode_indices;
            %I save it over every time, just in case something crashes. 
        end
        
    end
end

fprintf('solveForClusterProfiles took %f seconds for %d ambient temps, %d Cluster Sizes \n', cputime - total_start_time, length(ambient_temps)*length(curr_unitless_size), length(unitless_sizes{mode_index}) );

