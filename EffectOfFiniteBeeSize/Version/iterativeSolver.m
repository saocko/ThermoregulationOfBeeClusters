function [density, temperature, sysparams] = iterativeSolver(old_density, sysparams);

fprintf('At iterativeSolver! \n');



eps_tol = .0000001;
if(1)
    temp_relax_coeff = .1;
    dens_relax_coeff = .1;
    press_relax_coeff = .01;
    %height_relax_coeff = .000002;
    height_relax_coeff = .01;
else
    temp_relax_coeff = .1;
    dens_relax_coeff = .1;
    press_relax_coeff = .1;
    %height_relax_coeff = .000002;
    height_relax_coeff = .002;
end

tic

density = old_density;
temperature = calculateTemp(density, sysparams.ambientT * ones(size(density)), sysparams);


relax_coeff = .2;
i = 0;

not_suff_relaxed = true;


%Iterates 50 steps or until we get within some tolerance, whichever takes longer. 
while(i < 50 || not_suff_relaxed)
    i = i+1;
    
    
    tic;
    
    %size(temperature)
    %size(density)
    
    
    
    %Calculates the new density
    if(sysparams.do_eff_amb_t)
        eff_amb_t = calculateEffectiveAmbientT(temperature, sysparams);
    else
        eff_amb_t = sysparams.ambientT;
    end
    [new_density beenumber] = calculateRho(temperature, sysparams, eff_amb_t);
    
    
    
    
    
    max_dens_change = max(abs(new_density - density));
    %Adjusts bee pressure and system size
    density = (1- dens_relax_coeff) * density + dens_relax_coeff * new_density;
    
    
    volume_change = sysparams.N/beenumber;
    
    sysparams.total_radius = sysparams.total_radius * (volume_change)^(1./3.);
    
    updatePositionParameters;
    
    %    fprintf('New height is %f \n', sysparams.total_radius)
    sysparams.graining = sysparams.arraysize/(sysparams.total_radius);
    
    new_temp = calculateTemp(density, temperature, sysparams);
    max_temp_change = max(abs(temperature - new_temp));
    temperature = (1- temp_relax_coeff) * temperature + temp_relax_coeff * (new_temp);
    
    %    fprintf('Volume change is %f \n', volume_change);
    not_suff_relaxed = max_dens_change > eps_tol || max_temp_change > eps_tol;
    
    
    if(mod(i, 103) ==0)
        %displayProfile(temperature, density, sysparams, '');
        %   fprintf('Press ambient T is %f, total bee number is %f \n maxdenschange is %f, maxtempchange is %f \n Height is %f \n', press_amb_T, beenumber, max_dens_change, max_temp_change, sysparams.total_radius);
        % pause;
    end
    
end

%toc
%plot(temperature)

