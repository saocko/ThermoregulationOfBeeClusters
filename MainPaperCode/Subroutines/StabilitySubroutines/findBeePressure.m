function [beePressure] = findBeePressure(density, temp, sysparams)

%Calculates the bee pressure at a given density and temperature profile. We ignore the maximum density, because we'll take care of
%that later. 

thermotax = sysparams.c1; %Positive convection
rhoprime = sysparams.c0  + sysparams.c1;%Positive convention

base_rho = sysparams.base_dens - rhoprime * (temp);
beePressure = (density - base_rho) - thermotax * temp;




