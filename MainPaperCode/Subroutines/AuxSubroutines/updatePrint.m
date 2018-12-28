function [last_length] = updatePrint(string_to_print, lastlength);
%Prints a status update while removing the last status update to prevent the screen from becoming flooded. 
for j = 1:lastlength
   fprintf('\b') 
end
fprintf(string_to_print)

last_length = length(string_to_print);







