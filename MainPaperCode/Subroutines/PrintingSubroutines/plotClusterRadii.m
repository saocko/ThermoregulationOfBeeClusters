function [] = plotClusterRadii(unitless_sizes, ambient_temps, cluster_radii, sysparams, file_name);

%Plots clusterRadii for several unitless sizes and ambient temperatures. Nearly the same as plotCoreTemperatures

close all;
fprintf('At plotClusterRadii \n');
label_font_size = 28;
axis_font_size = 28;



%This is pretty straightforward. I Just plot the cluster_radii, cluster_radii against the ambient temperature

for i = 1:length(unitless_sizes)
    for j = 1:length(ambient_temps)
        unpacked_cluster_radii(i, j) = cluster_radii{i}(j);        
    end
end


fprintf('Mean of all radii is %f \n', mean(unpacked_cluster_radii(:)));

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


if(sysparams.display_params.pause_before_plot)
    pause;
end

if(length(file_name))
    pause(.2)
    print('-depsc', '-r300',file_name)
    pause(.2)
    saveas(1, file_name);
end
