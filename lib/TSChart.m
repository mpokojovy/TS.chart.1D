function first_out_of_control_time_period = TSChart(x, mu, sigma, alpha, all_ok_ARL)
% PURPOSE: Implements the TS chart for a given data stream
% --------------------------------------------------------------------------------------------------
% CALL:  first_out_of_control_time_period = TSChart(x, mu, sigma, alpha, all_ok_ARL)
% Input:
%    x ............ DOUBLE(n, 1) data array of n data values
%    mu ........... DOUBLE(1, 1) all-ok mean
%    sigma ........ DOUBLE(1, 1) all-ok standard deviation
%    alpha ........ DOUBLE(1, 1) TS chart exponent alpha (3/4, 2/3, 5/8 and 3/5)
%    all_ok_ARL ... DOUBLE(1, 1) all-ok ARL
% Output:
%    first_out_of_control_time_period ... DOUBLE(1, 1) detection time (empty if no upset detected)
% Description:
%    For a given data stream, plot the data stream along the taut string estimator computed from the
%    data collected up to detection time (if applicable, otherwise, for the whole data stream),
%    computes and plots the TS signal vs time along with the control limit, displays the earliest 
%    detection time (if applicable)
%
% Copyright: Michael Pokojovy and J. Marcus Jobe (2020)                                                                

    %% Load-up control limit
    cd '../util/';
    CL_TS = get_TS_statistic(alpha, all_ok_ARL, 'ControlLimitConservative');
    cd '../lib/';

    %% Standardize the data stream
    z = (x - mu)/sigma;
    n = length(z);

    %% TS chart
    for m = 1:n
        [TS_SIGNALS(m), ~] = TSChartSingleStep(z(1:m), 0, 1, alpha);
    end

    %%
    set(gcf, 'PaperUnits', 'centimeters');
    xSize = 30; ySize = 14;
    xLeft = (21 - xSize)/2; yTop = (30 - ySize)/2;
    set(gcf,'PaperPosition', [xLeft yTop xSize ySize]);
    set(gcf,'Position', [0 0 xSize*50 ySize*50]);
    
    %%
    subplot_tight(1, 2, 2, [0.08 0.05]);
    hold on;
    p1 = plot(1:n, TS_SIGNALS,       '-',  'Color', [0    0.4470    0.7410]);
    p2 = plot(1:n, ones(n, 1)*CL_TS, '-.', 'Color', [0    0.4470    0.7410]);
    p3 = plot(1:n, TS_SIGNALS,       'o',  'Color', [0    0.4470    0.7410]);

    legend([p3, p2], {'TS signal process', 'Control limit'}, ...
            'Location', 'NorthEast', 'interpreter', 'latex', 'FontSize', 18);

    xlabel('Time period $t_{n}$', 'interpreter', 'latex', 'FontSize', 18);
    ylabel('TS signal $\mathrm{TS}_{n}$', 'interpreter', 'latex', 'FontSize', 18);

    H_MAX = max(max(TS_SIGNALS), CL_TS)*1.25;

    axis([1 n 0 H_MAX]);

    %% TS detection time
    IND = min(find(TS_SIGNALS > CL_TS));
    first_out_of_control_time_period = IND;

    if ~isempty(IND)
        plot([IND IND], [-40 TS_SIGNALS(IND)], 'k--', IND, -40, 'k*');

        if (IND <= n/2)
            text(IND + 0.05*n, CL_TS*1.1, ['Detection time = ', num2str(IND)], 'interpreter', 'latex', 'FontSize', 18);
        else
            text(IND - 0.35*n, CL_TS*1.1, ['Detection time = ', num2str(IND)], 'interpreter', 'latex', 'FontSize', 18);
        end
    end
    
    %%
    if ~isempty(IND)
        %lambda = 1.149*sigma/sqrt(IND);        
        lambda = max(1.149, 0.8*sqrt(2*log(log(max(IND, 3)))))*sigma/sqrt(IND);
        
        TS = TSregression(x(1:IND), lambda);
    else
        %lambda = 1.149*sigma/sqrt(n);
        lambda = max(1.149, 0.8*sqrt(2*log(log(max(n, 3)))))*sigma/sqrt(n);
        TS = TSregression(x, lambda);
    end
        
    H_MIN = (min(x) + max(x))*0.5 - 1.5*(max(x) - min(x))*0.5;
    H_MAX = (min(x) + max(x))*0.5 + 1.5*(max(x) - min(x))*0.5;
    
    subplot_tight(1, 2, 1, [0.08 0.05]);
    hold on;
    
    xlabel('Time period $t_{n}$', 'interpreter', 'latex', 'FontSize', 18);
    ylabel('$x_{t_{n}}$', 'interpreter', 'latex', 'FontSize', 18);
    
    p2 = plot(1:length(TS), TS, '-', 'Color', [0.8500    0.3250    0.0980], 'LineWidth', 2);
    p1 = plot(1:n, x, '-o', 'Color', [0.0000    0.4470    0.7410]);
    
    axis([1 n H_MIN H_MAX]);
    
    if ~isempty(IND)
        legend([p1, p2], {'Data process', 'Taut string estimator for the data up to detection time'}, ...
               'Location', 'Best', 'interpreter', 'latex', 'FontSize', 16);
    else
        legend([p1, p2], {'Data process', 'Taut string estimator for complete data stream'}, ...
               'Location', 'Best', 'interpreter', 'latex', 'FontSize', 18);
    end
end