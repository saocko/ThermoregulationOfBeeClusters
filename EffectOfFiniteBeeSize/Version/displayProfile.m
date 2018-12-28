function [] = displayProfile(temperature, density, sysparams, file_name);

%Displays a temperature and density profile, fairly straightforward. 


interior_positions = (1:sysparams.arraysize)/(sysparams.graining);
    [AX, h1, h2] = plotyy(interior_positions, density , interior_positions, temperature);
        set(h1, 'Color', 'black');
        set(h2, 'Color', 'r');
        set(h2, 'LineStyle', ' -- ')
        
        set(AX,{'ycolor'},{'black';'r'})  % Left color red, right color blue...
        %    axis(axis .* [1 0 1 1] + [0 max(interiorpositions) 0 0]);
        title('Temp and Density vs height', 'FontSize', 14);
        xlabel(sprintf('Height'), 'FontSize', 12);
        set(get(AX(1),'Ylabel'),'String','Density', 'FontSize', 12)
        set(get(AX(2),'Ylabel'),'String','Temp', 'FontSize', 12)


if(length(file_name))
    print('-depsc', '-r300',file_name)    
end
