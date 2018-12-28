function [temperature] = calculateTemp(density, old_temp, sysparams)

%Calculates temperature profile at fixed density profile and metabolic rate. 
%fprintf('At calculateTemp \n');

f = calculateHeatFunctions(density, old_temp, sysparams);
heat_transfer_matrix = zeros(sysparams.arraysize);


f.cond;
f.metab;


%Constructs a heat transfer matrix to be put in a linear solver

for i = 1:(sysparams.arraysize - 1)
   mean_cond = .5 * (f.cond(i) + f.cond(i+1));
   mat_elem = mean_cond * sysparams.graining * sysparams.outer_area(i);
    
   heat_transfer_matrix(i, i)       =   heat_transfer_matrix(i, i)      - mat_elem;
   heat_transfer_matrix(i, i+1)     =   heat_transfer_matrix(i, i+1)    + mat_elem;
   heat_transfer_matrix(i+1, i)     =   heat_transfer_matrix(i+1, i)    + mat_elem;
   heat_transfer_matrix(i+1, i+1)   =   heat_transfer_matrix(i+1, i+1)  - mat_elem;       
end




edges = [sysparams.arraysize];
for i = edges
    cond = f.cond(i);
    heat_transfer_matrix(i, i) =heat_transfer_matrix(i, i) -cond * sysparams.graining * sysparams.outer_area(i);
end



%Sets up the right side of the linear equation, whose terms come from metabolic heat production and the ambient tempeature. 

target_vector = f.metab .* sysparams.volumes;

for i = edges
    cond = f.cond(i);
    target_vector(i) = target_vector(i) + cond * sysparams.graining * sysparams.ambientT * sysparams.outer_area(i);        
end




temperature = heat_transfer_matrix \ -target_vector;


%fprintf('Finished calculateTemp \n');





