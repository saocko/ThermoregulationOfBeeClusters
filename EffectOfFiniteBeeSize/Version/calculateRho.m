function [density_profile total_num] = calculateRho(temperature, sysparams, ambientT);
%Calculates density profile for a particular temperature. Also returns the total number of bees, so the size of the cluster can be
%rescaled. 



if(strcmp( sysparams.bulkmodel, 'Changing'))
density_profile = sysparams.base_dens - (sysparams.c0 +sysparams.c1)* temperature - sysparams.c1 *(ambientT - temperature) .* 1./(sysparams.base_bulk + sysparams.bulk_temp_deriv);
else
    density_profile = sysparams.base_dens - (sysparams.c0 +sysparams.c1)* temperature - sysparams.c1 *(ambientT - temperature);

end
density_profile = min(density_profile, sysparams.max_dens);


%This is just to prevent us from going to negative densities to help the iterative solver. 
density_profile = max(density_profile, .001);

total_num = sum(sysparams.volumes(:) .* density_profile(:));



%fprintf('Mean density is %f, radius is %f, total_num is %f \n', mean(density_profile(:)), sysparams.total_radius, total_num);




