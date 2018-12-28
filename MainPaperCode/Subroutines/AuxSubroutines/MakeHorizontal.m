function [output] = MakeHorizontal(input)
%A Very simple subroutine to take a vector and ensure it's horizontal and not vertical. This is to avoid transpose errors. 


input_size = size(input);

if(input_size(1) == 1)
    
    
    output = input;
    
else
    output = input';
    
end