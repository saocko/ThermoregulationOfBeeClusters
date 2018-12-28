
function [] = displayProfile(temperature, density, sysparams, file_name);
%Displays a temperature and density profile of a cluster. Nothing too complicated, but a lot of the lines of code
%is related to formatting and color bars. 


figure(1);
unfreezeColors;
clf(1);
title_font_size = 26;

reg_ax_font_size = 18;


%A few hardcoded parameters determining the plot size
subfig_width = 650;
subfig_height = 550;

bot_margin = 50;
left_margin = 100;
mid_margin = 180;
top_margin = 100;
right_margin = 100;

fig_width  = (2* subfig_width) + left_margin + mid_margin + right_margin;
fig_height = subfig_height + bot_margin + top_margin;

plot_scaling = 1./[fig_width fig_height fig_width fig_height];

first_box = [left_margin bot_margin   subfig_width   subfig_height];
second_box = [(left_margin + subfig_width + mid_margin) bot_margin subfig_width subfig_height];


%Sets up profile size
set(1, 'Resize', 'off');
set(1,'PaperSize',[fig_width fig_height])

if(sysparams.display_params.pad_array)
    
    pad_helper = zeros(sysparams.array_height+2, sysparams.array_width+1);
    pad_helper((1 + (1:sysparams.array_height)), 1:sysparams.array_width) = true;
    
    padded_temp = sysparams.ambientT* ones(size(pad_helper));
    padded_temp(pad_helper==1) = temperature;
    padded_dens = zeros(size(pad_helper));
    padded_dens(pad_helper==1) = density;
    
    density = padded_dens;
    temperature = padded_temp;
    
    %A few helper variables for plotting
    
    
    x_values = (sysparams.height/sysparams.array_height) * (-.5 + (1:sysparams.array_width ));
    x_values(sysparams.array_width +1) = sysparams.display_params.xpad;
    y_values = (sysparams.height/sysparams.array_height) * ( -.5 - sysparams.array_height/2 + (1:sysparams.array_height));
    y_values = [-sysparams.display_params.ypad y_values sysparams.display_params.ypad];
    
    
else
    x_values = (sysparams.height/sysparams.array_height) * (-.5 + (1:sysparams.array_width ));
    y_values = (sysparams.height/sysparams.array_height) * ( -.5 - sysparams.array_height/2 + (1:sysparams.array_height));
end
[x_mesh, y_mesh] = meshgrid(x_values, y_values);




if(1)
    temperature_box = first_box;
    density_box = second_box;
    y_axis_location = 'left';
    color_bar_loc = 'EastOutside';
end
if(sysparams.display_params.flipped)
    %    temperature_box = second_box;
    %    density_box = first_box;
    x_mesh = -fliplr(x_mesh);
    temperature = fliplr(temperature);
    density = fliplr(density);
    %    y_axis_location = 'right';
    color_bar_loc = 'WestOutside';
end



%Does temperature
if(1)
    
    
    temperature_color_map = colormap('jet');
    map_range  = round(size(temperature_color_map, 1)/2.8):round(size(temperature_color_map, 1));
    temperature_color_map = temperature_color_map(map_range, :);
    temperature_color_map = imresize(temperature_color_map, [64, 3]);
    temperature_color_map = max(temperature_color_map, 0);
    temperature_color_map = min(temperature_color_map, 1);
    
    %subplot(1, 2, 1);
    temp_step_size = min(.1, .1*range(temperature(:)));
    
    colormap(temperature_color_map);
    axes1 = axes('Parent',1,...
        'Position', temperature_box .*plot_scaling,...
        'Layer','top');
    box(axes1,'on');
    hold(axes1,'all');
    
    [C, handle] = contourf(x_mesh, y_mesh, temperature, sysparams.display_params.min_ambT:temp_step_size:sysparams.display_params.max_display_temp);
    
    title('Temperature', 'FontSize', title_font_size);
    set(gca, 'YAxisLocation', y_axis_location);
    

    colormap(temperature_color_map);
    temp_cbarax_1 = colorbar(color_bar_loc);
    caxis([sysparams.display_params.min_ambT sysparams.display_params.max_display_temp])
    
    set(gca, 'FontSize', reg_ax_font_size);
    set(temp_cbarax_1, 'FontSize', 16);
    cbfreeze(temp_cbarax_1)
    if(sysparams.display_params.show_circle)
        circle_radius = max(max(sysparams.interior.*sysparams.cyl_radius));
        thetas = 0:.01:3.14;
        x_line = sin(thetas)* circle_radius;
        z_line = cos(thetas) * circle_radius;
        
        line(x_line, z_line, 'Color', 'k');
    end
end


%This I need to get the color bars working. I don't know why
freezeColors;



%%%%%%%%%%%%%%%Does Density
if(1)
    non_zero_densities = density(density>0);
    min_nonzero_density = min(non_zero_densities(:));
    max_nonzero_density = max(non_zero_densities(:));
    
    dens_range = range(non_zero_densities);
    dens_step_size = min(.1, .2*(max_nonzero_density-min_nonzero_density));
    dens_step_size = max(dens_step_size, .01);
    
    dens_step_array = [0 (min_nonzero_density-.000001):dens_step_size:max_nonzero_density];
    
    my_color_map = colormap('bone');
    my_color_map = flipud(my_color_map);
    colormap(my_color_map);
    axes2 = axes('Parent',1,...
        'Position', density_box .* plot_scaling,...
        'Layer','top');
    box(axes2,'on');
    hold(axes2,'all');
    
    [C, handle] = contourf(x_mesh, y_mesh, density, dens_step_array, 'CDataMapping','direct');
    dens_cbarax_2 = colorbar(color_bar_loc);
    caxis([0 1])
    title('Bee Density', 'FontSize', title_font_size);
    
    set(gca, 'FontSize', reg_ax_font_size);    
    set(dens_cbarax_2, 'FontSize', 16);
    
    set(gca, 'YAxisLocation', y_axis_location);
    
    if(sysparams.display_params.show_circle)
        circle_radius = max(max(sysparams.interior.*sysparams.cyl_radius));
        thetas = 0:.01:3.14;
        x_line = sin(thetas)* circle_radius;
        z_line = cos(thetas) * circle_radius;
        
        line(x_line, z_line, 'Color', 'k');
    end
end

title_bounds = [(0.02 * fig_width)/fig_width (fig_height - .7 * top_margin)/fig_height (.98 * fig_width)/fig_width  (.65 * top_margin)/fig_height];
figure_title = sprintf('Temp and density profiles for cluster of size %.2f, ambient T = %.1f   ', sysparams.unitless_size, sysparams.ambientT);
annotation(1,'textbox', title_bounds, ...
    'String',{figure_title},'FitBoxToText','off','LineStyle','none', 'FontSize', 14);

if(length(file_name))
    pause(.2)
    print('-depsc', '-r300',file_name)
    pause(.2)
    saveas(1, file_name);
end

%set(1, 'Units', 'default');

