function [density_profile, total_num] = calculateRho(temperature, sysparams, ambientT);

%Straightforward helper function, calcualtes the density at fixed fixed temeprature. Also calculates the total bee number, so the
%cluster can be scaled to correct for this. 


if(strcmp( sysparams.bulkmodel, 'Changing'))
density_profile = sysparams.base_dens - (sysparams.c0 +sysparams.c1)* temperature - sysparams.c1 *(ambientT - temperature) .* 1./(sysparams.base_bulk + sysparams.bulk_temp_deriv);
else
    density_profile = sysparams.base_dens - (sysparams.c0 +sysparams.c1)* temperature - sysparams.c1 *(ambientT - temperature);
    %Is the same as -c0*temp -c1 * ambientT
end

density_profile = min(density_profile, sysparams.max_dens);
density_profile = max(density_profile, .01);
%This is simply to make the iterative solving easier, as this prevents us from going to negative densities which break the solver.

density_profile(sysparams.exterior) = 0;
%Truncates and gets rid of the outside


%Sum of density * vol/phi * 2pi
total_num = 2 *  pi() * sum(sum(density_profile .*sysparams.cell_volume));









