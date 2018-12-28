function [f] = calculateHeatFunctions(density, temperature, sysparams);

%Calculates the permeability(darcy), the conductivity, and the metabolic rate. 

f.darcy = sysparams.darcy0 * ((1-density).^3) .* 1./(density.^2);
f.cond = sysparams.cond0* (1.-density)* 1./(density);

if(strcmp(sysparams.metabmodel, 'Changing'))
%    fprintf('Changing metabmodel \n');
    f.metab = density .* max(1 + 2 * temperature, 1 - (20./3.)*temperature);    
elseif(strcmp(sysparams.metabmodel, 'Constant'))
%    fprintf('Constant metabmodel \n');
    f.metab = density;
else
    fprintf('Bad formatting for metabmodel \n');    
end









