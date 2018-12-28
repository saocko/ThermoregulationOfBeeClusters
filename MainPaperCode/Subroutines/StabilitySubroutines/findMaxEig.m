function [max_eig, num_geq_zero] = findMaxEig(total_hessian);
%Short helper method that finds the maximum eigenvalue of a matrix, as well as the number of eigenvalues with real part greater than zero.  
[eig_vect, eig_vals] = eig(total_hessian);
eig_vals = diag(eig_vals);


[max_real_eig, max_real_index] = max(real(eig_vals));
max_eig = eig_vals(max_real_index);
num_geq_zero = sum(real(eig_vals(:)) >=0);





