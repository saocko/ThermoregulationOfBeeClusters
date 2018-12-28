function [] = displayEigenvector(eigenvector, sysparams, file_name, figure_title);

%Displays an eigenvector. Pretty much the same as displayProfile, except now we're displaying an eigenvector of the linear
%response matrix. 

%To flip the phase for displaying
eigenvector = 1 * eigenvector;
%Renormalize so the max amplitude is 1.

eigenvector = eigenvector * 1./max(abs(eigenvector(:)));

figure(1);
unfreezeColors;
clf(1)

title_font_size = 26;

reg_ax_font_size = 18;


%Unpacks temperature and density
density = zeros(size(sysparams.index_array));
density_indices = 1:sysparams.array_size;
temperature = zeros(size(sysparams.index_array));
temperature_indices = density_indices + sysparams.array_size;

temperature(sysparams.index_to_array_helper) = eigenvector(temperature_indices);
density(sysparams.index_to_array_helper) = eigenvector(density_indices);

if(sum(temperature(:))<0)
    %Sets net change in temperature to be positive
   temperature = -1 * temperature;
   density = -1 * density;
end


%A few hand-coded parameters
subfig_width = 600;
subfig_height = 500;

bot_margin = 50;
left_margin = 100;
mid_margin = 140;
top_margin = 100;
right_margin = 50;

fig_width  = (2* subfig_width) + left_margin + mid_margin + right_margin;
fig_height = subfig_height + bot_margin + top_margin;


plot_scaling = 1./[fig_width fig_height fig_width fig_height];
first_box = [left_margin bot_margin   subfig_width   subfig_height];
second_box = [(left_margin + subfig_width + mid_margin) bot_margin subfig_width subfig_height];


%Sets size, does some thing with the color bars
set(1, 'Resize', 'off');
set(1,'PaperSize',[fig_width fig_height])
title_bounds = [(0.1 * fig_width)/fig_width (fig_height - .7 * top_margin)/fig_height (.8 * fig_width)/fig_width  (.65 * top_margin)/fig_height];
annotation(1,'textbox', title_bounds, ...
    'String',{figure_title},'FitBoxToText','off','LineStyle','none', 'FontSize', 15);



%A few things to make the plotting nicer
x_values = (sysparams.height/sysparams.array_height) * (-.5 + (1:sysparams.array_width ));
y_values = (sysparams.height/sysparams.array_height) * ( -.5 - sysparams.array_height/2 + (1:sysparams.array_height));
[x_mesh, y_mesh] = meshgrid(x_values, y_values);


temperature_color_map = colormap('jet');
map_range  = round(size(temperature_color_map, 1)/2.8):round(size(temperature_color_map, 1));
temperature_color_map = temperature_color_map(map_range, :);

%Does temperature
if(1)
    colormap(temperature_color_map);
    axes1 = axes('Parent',1,...
        'Position', first_box .*plot_scaling,...
        'Layer','top');
    box(axes1,'on');
    hold(axes1,'all');
    
    max_temperature_range = max(abs(temperature(:)));
    temperature_bars = (-max_temperature_range):(.1 * max_temperature_range):max_temperature_range;
    
    if(max_temperature_range>0)
        [C, handle] = contourf(x_mesh, y_mesh, temperature, temperature_bars);
        caxis([-max_temperature_range max_temperature_range]);
    else
        [C, handle] = contourf(x_mesh, y_mesh, temperature);
    end
        
    title('Temperature', 'FontSize', title_font_size);
    
    colormap(temperature_color_map);
    temp_cbarax_1 = colorbar('EastOutside');
    set(gca, 'FontSize', reg_ax_font_size);    
    
    cbfreeze(temp_cbarax_1)
    
    
    if(sysparams.stability_params.show_circle)
        hold(axes1,'all');

        circle_radius = max(max(sysparams.interior.*sysparams.cyl_radius));
        thetas = 0:.01:3.14;
        x_line = sin(thetas)* circle_radius;
        z_line = cos(thetas) * circle_radius;

        line(x_line, z_line, 'Color', 'k');
    end

end

freezeColors;




%%%%%%%%%%%%%%%Does Density
if(1)
    my_color_map = colormap('bone');
    my_color_map = flipud(my_color_map);
    colormap(my_color_map);
    axes2 = axes('Parent',1,...
        'Position', second_box .* plot_scaling,...
        'Layer','top');
    box(axes2,'on');
    hold(axes2,'all');
    
    max_density_range = max(abs(density(:)));
    density_bars = (-max_density_range):(.1 * max_density_range):max_density_range;
    
    
    if(max_density_range>0)
        [C, handle] = contourf(x_mesh, y_mesh, density, density_bars);
        caxis([-max_density_range max_density_range])
    else
        [C, handle] = contourf(x_mesh, y_mesh, density);
    end
    dens_cbarax_2 = colorbar('EastOutside');
    
    title('Bee Density', 'FontSize', title_font_size);

    
    if(sysparams.stability_params.show_circle)
        hold(axes2,'all');

        circle_radius = max(max(sysparams.interior.*sysparams.cyl_radius));
        thetas = 0:.01:3.14;
        x_line = sin(thetas)* circle_radius;
        z_line = cos(thetas) * circle_radius;

        line(x_line, z_line, 'Color', 'k');
    end
    set(gca, 'FontSize', reg_ax_font_size);    
    set(dens_cbarax_2, 'FontSize', reg_ax_font_size);
end


if(length(file_name))
    pause(.1)

    print('-depsc', '-r300',file_name)
    pause(.2)
    saveas(1, file_name);
end
