function [] = plotClusterRadii(unitless_sizes, ambient_temps, cluster_radii, sysparams, file_name);
close all;
fprintf('At plotClusterRadii \n');
label_font_size = 28;
axis_font_size = 28;


%This is pretty straightforward. I Just plot the cluster_radii for different bee numbers against the ambient temperature
%Basically the same as plotCoreTemperatures


%Just unpacks the data into a different format. 
unpacked_cluster_radii = zeros(length(unitless_sizes), length(ambient_temps));
for i = 1:length(unitless_sizes)
    for j = 1:length(ambient_temps)
        unpacked_cluster_radii(i, j) = cluster_radii{i}{j};        
    end
end



Line_Styles = {'--', ':', '-.'};
Line_Widths = {1.5, 6, 1.5};

for i = 1:length(unitless_sizes)
    cur_legend = sprintf('N = %.2f', unitless_sizes(i));
    [AX] = plot(ambient_temps, unpacked_cluster_radii(i, :), 'black', 'LineStyle', Line_Styles{i}, 'DisplayName', cur_legend, 'LineWidth', Line_Widths{i});
    legend('-DynamicLegend');
    hold all;
end


axis([min(ambient_temps), max(ambient_temps), 0,  max(unpacked_cluster_radii(:))]);
%title(sysparams.plot_title, 'FontSize', 14);
xlabel(sprintf('Ambient Temperature'), 'FontSize', label_font_size);
ylabel(sprintf('Cluster Radius'), 'FontSize', label_font_size);

set(gca, 'FontSize', axis_font_size);
if(sysparams.display_params.pause)
    pause;
end


if(length(file_name))
    pause(.2)
    print('-depsc', '-r300',file_name)
    pause(.2)
    saveas(1, file_name);
end
