
function [] = showMaxEigs(total_hessian, sysparams, title_string);


%Shows the largest eigenvectors of a hessian matrix. It will either show all the positive eigenvectors, or will show them in
%descending order until you don't want to see another, depending on sysparams.stability_params.only_show_positive_eigs


fprintf('Starting eig... \n');
[eig_vect, eig_vals] = eig(total_hessian);
fprintf('Finished eig \n');

eig_vals = diag(eig_vals);

[dont_need, eig_indices] = sort(-1 * real(eig_vals));


%fprintf('Kphi is %d,  Max Eig is %f \n', sysparams.kphi, max(real(sorted_eigs)));



if(~sysparams.stability_params.only_show_positive_eigs)
    i = 1;
    do_another = 1;
    while( i < sysparams.array_size && do_another)
        fprintf('\n Eigval number %d is  %f \n', i, eig_vals(eig_indices(i)) );
        eigen_vector = eig_vect(:, eig_indices(i)); %
        figure_title = sprintf('Eigenvector #%d for kphi %d, eigenvalue %.03e',i, sysparams.kphi, real(eig_vals(eig_indices(i)) ));
        
        displayEigvector(eigen_vector, sysparams, '', figure_title);
        
        
        
        do_another_input = input('Do you want to see another? \n');
        do_another = (length(do_another_input)>0) && do_another_input ~=0;
        i = i+1;
        fprintf('\n');
    end
else
    
    n_eigs_to_show = sum(real(eig_vals(:)) >= 0);
    for i = 1:n_eigs_to_show
        fprintf('\n Eigval number %d is  %f \n', i, eig_vals(eig_indices(i)) );
        eigen_vector = eig_vect(:, eig_indices(i)); %
        figure_title = sprintf('Eigenvector #%d for kphi %d, eigenvalue %.03e',i, sysparams.kphi, real(eig_vals(eig_indices(i))));        
        if(~sysparams.stability_params.print_mode)
            title_string = '';            
        end
        displayEigvector(eigen_vector, sysparams, title_string, figure_title);
        
        fprintf('Click to see the next positive eigenvector\n');
        if(~sysparams.stability_params.print_mode)
            pause;
        end
            
    end
    if(n_eigs_to_show ==0)
        fprintf('This matrix is stable! \n');
    end
end

end


