%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                  TS CHART APPLICATION EXAMPLES                                   %
%                                                                                                  %
% The program gives four application examples of the TS chart.                                     %
%                                                                                                  %
% Copyright: Michael Pokojovy and J. Marcus Jobe (2020)                                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

cd 'lib/';

% Select the example index between 1 and 8
example_ind = 1;

switch (example_ind)
    case 1
    %% Example 1: Lucas & Crosier (1982) - IC case
    run('../examples/example1_lucas_crosier.m');
    
    case 2
    %% Example 2: Lucas & Crosier (1982) - OC case
    run('../examples/example2_lucas_crosier.m');
    
    case 3
    %% Example 3: Montgomery (2009) - TS plots
    run('../examples/example1_montgomery.m');
    
    case 4
    %% Example 4: Montgomery (2009) - Signal processes
    run('../examples/example2_montgomery.m');
    
    case 5
    %% Example 1: All-okay situation
    n = 100;
    x = randn(n, 1);
    mu = 0;
    sigma = 1;
    alpha = 0.6;
    all_ok_ARL = 750;
    
    TSChart(x, mu, sigma, alpha, all_ok_ARL);
    
    case 6
    %% Example 2: Sustained shift: initial state
    delta = 1.5;
    
    n = 100;
    x = randn(n, 1) + delta;
    mu = 0;
    sigma = 1;
    alpha = 0.6;
    all_ok_ARL = 750;
    
    TSChart(x, mu, sigma, alpha, all_ok_ARL);
    
    case 7
    %% Example 3: Sustained shift: steady state
    delta             = 1.5;
    steady_state_size = 10;
    
    n = 100;
    x = randn(n, 1) + delta*((1:n)' > steady_state_size);
    mu = 0;
    sigma = 1;
    alpha = 0.6;
    all_ok_ARL = 750;
    
    TSChart(x, mu, sigma, alpha, all_ok_ARL);
    
    case 8
    %% Example 4: Lake Erie dataset
    cd '../examples/datasets/';
    dataset_lake_erie;
    cd '../../lib';
    
    x = x;
    n = size(x, 1);
    mu = mean(x);
    sigma = 1.48/sqrt(2)*median(abs(x(2:end) - x(1:end-1)));

    alpha = 0.6;
    all_ok_ARL = 750;
    
    TSChart(x, mu, sigma, alpha, all_ok_ARL);
end
    
cd '../';