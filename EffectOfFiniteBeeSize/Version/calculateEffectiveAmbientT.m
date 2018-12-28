function [ambient_t_eff] = calculateEffectiveAmbientT(temperature, sysparams);
%Calculates the "Effective ambient temperature", which is the temperature a certain distance from the surface that sets the
%behavioral pressure. 


goal_radius = sysparams.total_radius - sysparams.bee_length;
number_below = sum(sysparams.radii < goal_radius);
lower_radius = sysparams.radii(number_below);
interp_factor = (goal_radius - sysparams.radii(number_below))/sysparams.cellwidth;

ambient_t_eff = temperature(number_below) * (1-interp_factor) + temperature(number_below + 1) * interp_factor;






