function [] = juxtaposeProfiles(temperature_list, density_list, sysparams_list, file_name);
%Juxtapose the temperature and density profiles of a cluster at hot and cold ambient temperature. 


im_size = 800;
fprintf('At Juxtapose Profiles! \n');

fprintf('Mean of temperature list is %f, %f \n', mean(temperature_list{1}(:)), mean(temperature_list{2}(:)));
fprintf('Mean of density list is %f, %f \n', mean(density_list{1}(:)), mean(density_list{2}(:)));




%function[contour_iamge] =  generateContourImage(color_bar, step_array, values, x_mesh, y_mesh);
density_color_map = flipud(colormap('bone'));
%density_color_map = 'bone';
temperature_color_map = colormap('jet');
map_range  = round(size(temperature_color_map, 1)/2.8):round(size(temperature_color_map, 1));
temperature_color_map = temperature_color_map(map_range, :);
temperature_color_map = imresize(temperature_color_map, [64, 3]);
temperature_color_map = max(temperature_color_map, 0);
temperature_color_map = min(temperature_color_map, 1);

max_display_temp = max(max(temperature_list{1}(:)), max(temperature_list{2}(:)));
min_display_temp = min(min(temperature_list{1}(:)), min(temperature_list{2}(:)));


cold_aspect_ratio_pad = .3;

regular_juxtapose = 1;


%Generates the contour images which we then glue together and display as images. 
for i = 1:2
    if(regular_juxtapose)
        aspect_ratio_pad = 1 + (i-1) * cold_aspect_ratio_pad;
    else
        aspect_ratio_pad = 1;
    end
    
    
    
    trunc_density = density_list{i}(density_list{i} > 0);
    dens_step_size = .1 * range(trunc_density(:));
    dens_step_array = [0 (min(trunc_density(:))-.000001):dens_step_size:(max(trunc_density)) 1];
    temp_step_size = .1 * (range(temperature_list{i}));
    temp_step_array = [min_display_temp   sysparams_list{i}.ambientT:temp_step_size:max_display_temp];
    
    
    pad_helper = zeros(sysparams_list{i}.array_height+2, sysparams_list{i}.array_width+1);
    pad_helper((1 + (1:sysparams_list{i}.array_height)), 1:sysparams_list{i}.array_width) = true;
    
    padded_temp = sysparams_list{i}.ambientT* ones(size(pad_helper));
    padded_temp(pad_helper==1) = temperature_list{i};
    padded_dens = zeros(size(pad_helper));
    padded_dens(pad_helper==1) = density_list{i};
    
    density_list{i} = padded_dens;
    temperature_list{i} = padded_temp;
    
    %A few helper variables for plotting
    
    
    x_values = (sysparams_list{i}.height/sysparams_list{i}.array_height) * (-.5 + (1:sysparams_list{i}.array_width ));
    x_values(sysparams_list{i}.array_width +1) = sysparams_list{i}.xpad*aspect_ratio_pad;
    y_values = (sysparams_list{i}.height/sysparams_list{i}.array_height) * ( -.5 - sysparams_list{i}.array_height/2 + (1:sysparams_list{i}.array_height));
    y_values = [-sysparams_list{i}.ypad y_values sysparams_list{i}.ypad];
    
    
    [x_mesh, y_mesh] = meshgrid(x_values, y_values);
    density_image{i} = imresize(generateContourImage(density_color_map, dens_step_array, density_list{i}, x_mesh, y_mesh), [im_size, im_size/2 * aspect_ratio_pad]);
    temperature_image{i}= imresize(generateContourImage(temperature_color_map, temp_step_array, temperature_list{i}, x_mesh, y_mesh), [im_size, im_size/2 * aspect_ratio_pad] );
end



%Adds lines in the middle to differentiate between the right and left contours
mid_black_line = zeros(size(density_image{1}, 1), 3, 3);
mid_white_line =  ones(size(density_image{1}, 1), 5, 3) * 255;
mid_line = [mid_black_line, mid_white_line, mid_black_line];


if(regular_juxtapose)
    
    combined_dens_image = [flipdim(density_image{1}, 2) mid_line density_image{2}];
    combined_temp_image = [flipdim(temperature_image{1}, 2) mid_line temperature_image{2}];
else
    combined_dens_image = [flipdim(density_image{1}, 2) mid_line temperature_image{1}];
    combined_temp_image = [flipdim(density_image{2}, 2) mid_line temperature_image{2}];

end
%imwrite(combined_dens_image, 'DensTotal.bmp');
%imwrite(combined_temp_image, 'TempTotal.bmp');

%%%%%%%%%%%%%%%%%%%%%%Now The Actual Displaying of the Images %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close all;
figure(1);
unfreezeColors;
clf(1);

%A few hardcoded parameters determining the plot size
subfig_width = 800;
subfig_height = 400;

bot_margin = 40;
left_margin = 50;
mid_margin = 50;
top_margin = 0;
%top_margin = 40;
right_margin = 50;

fig_width  = (2* subfig_width) + left_margin + mid_margin + right_margin;
fig_height = subfig_height + bot_margin + top_margin;

plot_scaling = 1./[fig_width fig_height fig_width fig_height];

first_box = [left_margin bot_margin   subfig_width   subfig_height];
second_box = [(left_margin + subfig_width + mid_margin) bot_margin subfig_width subfig_height];

cbar_ax_scaling = .7;%Not sure but this is somehow entangled with repeating axis labels
cbar_font_scaling = 1.5;
cbar_ax_skew = -3;


%Sets up profile size
set(1, 'Resize', 'off');
set(1,'PaperSize',[fig_width fig_height])


if(1)
    temperature_box = first_box;
    density_box = second_box;
    y_axis_location = 'left';
    color_bar_loc = 'East';
end



%Does temperature
if(1)
    y_tick_max = round(max(temp_step_array * 10))/10;
    y_tick_min = round(min(temp_step_array * 10))/10;
    
    
    
    %Matlab likes there to be 7 ticks for some reason
    y_ticks = y_tick_min+ (y_tick_max - y_tick_min) * (1./3.) * (0:3);
    y_ticks = round(10*y_ticks)/10;
    
    scaled_y_ticks = 1.01 + (size(temperature_color_map,1) - 1.1) *  (y_ticks - min(y_ticks))/range(y_ticks);
    
    colormap(temperature_color_map);
    axes2 = axes('Parent',1,...
        'Position', temperature_box .* plot_scaling,...
        'Layer','top');
    [handle] = imshow(combined_temp_image);
    
    box(axes2,'on');
    hold(axes2,'all');
    
    
    colormap(temperature_color_map);
    
    
    temp_cbarax_1 = colorbar('YLim',[1 size(temperature_color_map, 1)],...                        &# The axis limits
        'YTick', scaled_y_ticks,...                    %# The tick locations
        'YTickLabel', y_ticks, 'YColor', 'black');
    cytick = get(temp_cbarax_1,'YTick');
    
    
    initpos = get(temp_cbarax_1,'Position');
    initfontsize = get(temp_cbarax_1,'FontSize');
    
    if(1)
        set(temp_cbarax_1, ...
            'Position',[initpos(1)+initpos(3)*(1-cbar_ax_scaling)*cbar_ax_skew initpos(2)+initpos(4)*(1- cbar_ax_scaling)/2 ...
            initpos(3)*cbar_ax_scaling initpos(4)*cbar_ax_scaling], ...
            'FontSize',initfontsize*cbar_font_scaling, 'YColor', 'black')
        set(temp_cbarax_1, 'YTick', cytick);
    end
    
    caxis([min(temp_step_array(:)) max(temp_step_array(:))])
    set(temp_cbarax_1, 'FontSize', 18);
    cbfreeze(temp_cbarax_1);
end


%This I need to get the color bars working. I don't know why
freezeColors;



%%%%%%%%%%%%%%%Does Density
if(1)
    
    
    
    colormap(density_color_map);
    axes2 = axes('Parent',1,...
        'Position', density_box .* plot_scaling,...
        'Layer','top');
    [handle] = imshow(combined_dens_image);
    
    box(axes2,'on');
    hold(axes2,'all');
    
    
    colormap(density_color_map);
    
    
    
    dens_cbarax_2 = colorbar('YLim',[1 size(density_color_map, 1)],...                        &# The axis limits
        'YTick', 1.01 + (size(density_color_map, 1) - 1.1) * (0:.2:1),...                    %# The tick locations
        'YTickLabel', 0:.2:1);
    %              {'0','.2','.4', '.6', '.8', '1'}
    cytick = get(dens_cbarax_2,'YTick');
    
    initpos = get(dens_cbarax_2,'Position');
    initfontsize = get(dens_cbarax_2,'FontSize');
    if(1)
        set(dens_cbarax_2, ...
            'Position',[initpos(1)+initpos(3)*(1-cbar_ax_scaling)*cbar_ax_skew initpos(2)+initpos(4)*(1-cbar_ax_scaling)/2 ...
            initpos(3)*cbar_ax_scaling initpos(4)*cbar_ax_scaling], ...
            'FontSize',initfontsize*cbar_font_scaling)
        set(dens_cbarax_2, 'YTick', cytick);
    end
    
    set(dens_cbarax_2, 'FontSize', 18);
    
end


%Does title

title_down_shift = 37;
title_bounds = [(0 * fig_width)/fig_width (fig_height - .7 * top_margin - title_down_shift)/fig_height (1. * fig_width)/fig_width  (.65 * top_margin)/fig_height];
figure_title = sprintf('Comparison of Temperature and Density profiles of cluster size %.2f for ambient temperatures of %.1f(left), %.1f(right)', sysparams_list{1}.unitless_size, sysparams_list{1}.ambientT, sysparams_list{2}.ambientT);
%figure_title = sprintf('Comparison of Temperature and Density profiles at different Ambient Temperatures \n Cluster Size = %.1f, T_{a} of %.1f(left), %.1f(right)', sysparams_list{1}.unitless_size, sysparams_list{1}.ambientT, sysparams_list{2}.ambientT);

annotation(1,'textbox', title_bounds, ...
    'String',{figure_title},'FitBoxToText','off','LineStyle','none', 'FontSize', 16, 'HorizontalAlignment', 'center');


if(length(file_name))
    fprintf('Printing Juxtapose To File \n');
    pause(.2)
    print('-depsc', '-r300',file_name)
    pause(.2)
    saveas(1, file_name);
end

