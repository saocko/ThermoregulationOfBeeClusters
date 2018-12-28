

sysparams.graining =  sysparams.arraysize/sysparams.total_radius;
sysparams.cellwidth = 1./sysparams.graining;




sysparams.radii = ((1:sysparams.arraysize)-.5)' * sysparams.cellwidth;

sysparams.outer_radii = sysparams.radii  + .5 * sysparams.cellwidth;
sysparams.inner_radii = sysparams.radii  - .5 * sysparams.cellwidth;


sysparams.outer_area = 4. * pi() * sysparams.outer_radii.^2;
sysparams.volumes = (4. * pi()/3.) * (sysparams.outer_radii.^3 - sysparams.inner_radii.^3);

