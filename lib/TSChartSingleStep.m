function [TSsignal, TV] = TSChartSingleStep(y, mu, sigma, alpha)
% PURPOSE: Computes the TS signal at a single time period along with the total variation of the 
%          respective taut string estimate
% --------------------------------------------------------------------------------------------------
% CALL:  [TSsignal, TV] = TSChartSingleStep(y, mu, sigma, alpha)
% Input:
%    y ....... DOUBLE(n, 1) data array of n data values
%    mu ...... DOUBLE(1, 1) all-ok mean
%    sigma ... DOUBLE(1, 1) all-ok standard deviation
%    alpha ... DOUBLE(1, 1) TS chart exponent alpha (3/4, 2/3, 5/8, 3/5 and 1)
% Output:
%    TSsignal ... DOUBLE(1, 1) TS signal
%    TV ......... DOUBLE(1, 1) total variation of the taut string estimator computed from the data
% Description:
%    Computes the TS signal at time t_n (based on n data values) and the total variation of the
%    respective taut string estimate
%
% Copyright: Michael Pokojovy and J. Marcus Jobe (2020)

    n = length(y);
    
    c = max(1.149, 0.8*sqrt(2*log(log(max(n, 3))))); % LiL scaling: 04/23/2020

    lambda_mu = c*sigma/sqrt(n);
    
    [~, TV, InitJmp] = TSregression(y - mu, lambda_mu);
    
    TSsignal = (TV + InitJmp)*n^alpha;
end
