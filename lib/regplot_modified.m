function regplot_modified(y, lambda, opt, col)
% PURPOSE: Computes and plots the taut string estimator (NOT including the taut string and function
%          tube around the cumulative process)
% --------------------------------------------------------------------------------------------------
% CALL:  regplot_modified(y, lambda, opt, col)
% Input:
%    y ........ DOUBLE(n, 1) data vector of n data values
%    lambda ... DOUBLE(1, 1) function tube radius
%    opt ...... STRING line  (such as -, :, -., --) and symbol (such as ., o, x, +, *, etc.) type
%    col ...... DOUBLE(1, 3) color vector
% Description:
%    Performs the taut string regression and plots the associated taut string estimator.
%    In contrast to regplot.m, the data process, the taut string and the function tube around the
%    cumulative process are NOT displayed.
%
% Copyright: Michael Pokojovy and J. Marcus Jobe (2020)

    N = size(y, 1);
    
    x = linspace(1, N, N)'/N;
    x0 = [0; x];
    
    cy = [0; 1/N*cumsum(y)];
    
    cyl = cy - lambda; 
    cyl(1) = 0; 
    cyl(end) = cy(end);
    
    cyu = cy + lambda; 
    cyu(1) = 0; 
    cyu(end) = cy(end);
    
    [index, cyr] = TautString(x0, cyl, cyu);
    
    yr = zeros(N, 1);
    
    for i = 1:length(index)-1
        I = index(i):min(index(i+1), N);
        yr(I) = (cyr(i+1) - cyr(i))/(x0(index(i+1)) - x0(index(i)));
    end
    
    T = 1;
    YR = yr(1);
    
    for i = 2:N
        T  = [T; i; i];
        YR = [YR; yr(i-1); yr(i)];
    end
    
    T  = [T; N];
    YR = [YR; yr(end)];
    
    plot(T, YR, opt, 'LineWidth', 2, 'Color', col);
end