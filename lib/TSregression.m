function [yr, TV, InitJmp] = TSregression(y, lambda)
% PURPOSE: Computes the taut string estimator, its total variation and the absolute jump at 0
% --------------------------------------------------------------------------------------------------
% CALL:  [yr, TV, InitJmp] = TSregression(y, lambda)
% Input:
%    y ........ DOUBLE(n, 1) data vector of n data values
%    lambda ... DOUBLE(1, 1) function tube radius
% Output:
%    yr ......... DOUBLE(n, 1) taut string estimate
%    TV ......... DOUBLE(1, 1) total variation of the taut string estimate
%    InitJmp .... DOUBLE(1, 1) absolute jump of the taut string estimate at 0
% Description:
%    Performs the taut string regression and computes the total variation and the absolute initial
%    jump of the resulting taut string estimate
%
% Copyright: Michael Pokojovy and J. Marcus Jobe (2020)    

    n = size(y, 1);
    
    x = linspace(1, n, n)'/n;
    x0 = [0; x];
    
    cy = [0; 1/n*cumsum(y)];
    
    cyl = cy - lambda; 
    cyl(1) = 0; 
    cyl(end) = cy(end);
    
    cyu = cy + lambda; 
    cyu(1) = 0; 
    cyu(end) = cy(end);
    
    [index, cyr] = TautString(x0, cyl, cyu);
    
    yr = zeros(n, 1);
    
    for i = 1:length(index)-1
        I = index(i):min(index(i+1), n);
        yr(I) = (cyr(i+1) - cyr(i))/(x0(index(i+1)) - x0(index(i)));
    end
    
    TV      = sum(abs(yr(2:end) - yr(1:end-1)));
    InitJmp = abs(yr(1));
end