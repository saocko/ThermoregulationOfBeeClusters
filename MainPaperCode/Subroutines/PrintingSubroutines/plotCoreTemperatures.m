function [] = plotCoreTemperatures(unitless_sizes, ambient_temps, core_temps, sysparams, file_name);
close all;
%Plots coreTemperatures for several unitless sizes and ambient temperatures. Nearly the same as plotClusterRadii
label_font_size = 28;
axis_font_size = 28;
leg_font_size = 16;


for i = 1:length(unitless_sizes)
    for j = 1:length(ambient_temps)
        unpacked_core_temps(i, j) = core_temps{i}(j);        
    end
end
fprintf('Mean of all core temps is %f \n', mean(unpacked_core_temps(:)));


Line_Styles = {'--', ':', '-.'};
Line_Widths = {1.5, 6, 1.5};

plot(ambient_temps, ambient_temps, 'black', 'DisplayName', 'T_{amb}(Ref.)', 'LineWidth', 1);
legend('-DynamicLegend');

hold all;
for i = 1:length(unitless_sizes)
    cur_legend = sprintf('N = %.2f', unitless_sizes(i));
    [AX] = plot(ambient_temps, unpacked_core_temps(i, :), 'red', 'LineStyle', Line_Styles{i}, 'DisplayName', cur_legend, 'LineWidth', Line_Widths{i});
    hold all;
end



axis([min(ambient_temps), max(ambient_temps), min(ambient_temps), max(unpacked_core_temps(:))]);
%title(sysparams.plot_title, 'FontSize', 14);
xlabel(sprintf('Ambient Temperature'), 'FontSize', label_font_size);
ylabel(sprintf('Core Temperature'), 'FontSize', label_font_size);


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
