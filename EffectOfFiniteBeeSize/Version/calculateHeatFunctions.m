function [f] = calculateHeatFunctions(density, temperature, sysparams);

%Calculates the metabolic rate and the conductivity. 

f.cond = sysparams.cond0* (1.-density)* 1./(density);

if(strcmp(sysparams.metabmodel, 'Changing'))
    
    f.metab = density .* max(1 + 0 *log(2.4)*2 * temperature, 1 - (20./3.) *temperature);
    
else    
    f.metab = density;    
end









