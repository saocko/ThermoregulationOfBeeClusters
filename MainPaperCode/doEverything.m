%I have set the program up to be modular, so different parts can be commented out. Each part sets up files that the other parts
%will read. 

addAllPaths; %Add the file paths of every program in subfolders. 

solveForClusterProfiles; %Solves for the temperature and density profiles of various dimensionless bee numbers, ambient temperatures, 
%and modes, and puts the results into ClusterProfileOutput/SavedResults.mat
displayResults %Loads the data from ClusterProfileOutput/SavedResults.mat and plots cluster profiles, etc. in the DisplayedResults folder

calculateAllHessians 
%Loads the data from ClusterProfileOutput/SavedResults.mat, calculates the linear response matrices, and puts the results into
%CalculatedHessians, as well as saving a few options into StabilityResults

calculateAllMaxEigs
%Loads the data from ClusterProfileOutput/SavedResults.mat, CalculatedHessians, as well as StabilityParams, and calculates the
%maximum real part of the eigenvalues to see if there is a linear instability. 

showSomeEigenvectors %Puts you into a menu where you can choose a mode and cluster size, and shows eigenvectors for that mode.  
