function [density_hessian_matrix, temperature_hessian_matrix] = calculateHessian(density, temperature, sysparams, kphi);

%Calculates the hessian matrices for a given temperature and density profile. Perturbs temperature and density in every possible
%way, and constructs a matrix from the linear response. 

start_time = cputime();
delta = .0005;%The amount to perturb by. 

couple_dens_and_temp = 1;
[dont_need_heat_transf_matrix, dont_need_base_heat_transf_vec, base_pressure] = calculateAirVel(density, temperature, sysparams);

base_temp_deriv = findTempDerivatives(density, temperature, 0*density, 0*temperature, base_pressure, sysparams, kphi);
base_dens_deriv = findDensityDerivatives(density, temperature, 0*density, 0*temperature, sysparams, kphi);
fprintf('Starting to calculate Hessian, kphi = %d, max unpert deriv is %.02e ...\n',kphi, max(max(abs(base_temp_deriv)), max(abs(base_dens_deriv))));
%Make sure that the time derivatives are very close to zero. 


%I have two matrices to make it more convenient to vary the time scales between the two
density_hessian_matrix = zeros(2*sysparams.array_size, 2*sysparams.array_size);
temperature_hessian_matrix = zeros(2* sysparams.array_size, 2*sysparams.array_size);

last_length = 0;
accum = 0;
tic;
for i = 1:(2*sysparams.array_size)
    accum = accum + 1;
    if(sysparams.stability_params.update_stab_solv &&   accum > (2*sysparams.array_size)/sysparams.stability_params.update_stab_solv)        
        last_length =  updatePrint(sprintf('Progress: %.3f', i/(2*sysparams.array_size)), last_length);
        accum = 0;
    end
    
    %    fprintf('Doing hessian for index %d out of %d \n',  i, sysparams.array_size * 2);
    is_dens_index = i<=sysparams.array_size; %Determine whether temperature or density is perturbed
    array_index = i - sysparams.array_size *(1- is_dens_index); %Figures out the index, whether it's to the temperature or density perturbation
    
    %Creates the perturbation
    delta_density = (sysparams.index_array == array_index) * delta * is_dens_index; %Density perturbation
    delta_temperature = (sysparams.index_array == array_index) * delta * (1- is_dens_index); %Temperature perturbation
    
    %Helper arrays for indexing
    density_indices = (1:sysparams.array_size)';
    temperature_indices = density_indices + sysparams.array_size;
    
    %Fills the density hessian matrix
    density_hessian_matrix(density_indices, i) = ...
        (MakeHorizontal(findDensityDerivatives(density, temperature, delta_density, delta_temperature * couple_dens_and_temp, sysparams, kphi)) - ...
        MakeHorizontal(findDensityDerivatives(density, temperature, -delta_density, -delta_temperature * couple_dens_and_temp, sysparams, kphi)))';
    %Fills the temperature hessian matrix
    temperature_hessian_matrix(temperature_indices, i) =...
        (MakeHorizontal(findTempDerivatives(density, temperature, delta_density*couple_dens_and_temp, delta_temperature, base_pressure, sysparams, kphi )) - ...
        MakeHorizontal(findTempDerivatives(density, temperature, -delta_density*couple_dens_and_temp, -delta_temperature, base_pressure, sysparams, kphi)) )';
end
updatePrint('', last_length);

%Locks and decouples modes with saturated densities
density_vector = density(sysparams.index_to_array_helper);
for i = 1:(2*sysparams.array_size)
    is_dens_index = i<=sysparams.array_size; %Determine whether this corresponds to temperature of density
    array_index = i - sysparams.array_size *(1- is_dens_index); %Figures out the index
    if(is_dens_index && (density_vector(array_index)>(sysparams.max_dens - .001)))
        density_hessian_matrix(i, :) = 0; %Decouple
        density_hessian_matrix(:, i) = 0; %Decouple
        density_hessian_matrix(i, i) = -10000000; %Lock
        
        temperature_hessian_matrix(i, :) = 0;
        temperature_hessian_matrix(:, i) = 0;
       % fprintf(' Maxed out point \n');         
    end
end

density_hessian_matrix = density_hessian_matrix/(2 * delta);
temperature_hessian_matrix = temperature_hessian_matrix/(2*delta);

fprintf('Finished calculating hessian, ', kphi);
toc;

