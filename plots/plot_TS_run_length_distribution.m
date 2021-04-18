%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%              Plot PDF and CDF of the empirical TS chart all-ok run length distribution           %
%                                                                                                  %
% PURPOSE: Based on precomputed all-ok run length quantiles, plots the empirical CDF and a         %
% kernel-based empirical PDF estimates for the TS chart all-ok run length distributions for given  %
% alpha and all_ok_ARL(s)                                                                          %
%                                                                                                  %
% Copyright: Michael Pokojovy and J. Marcus Jobe (2020)                                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Select alpha from 3/4, 2/3, 5/8, 3/5 and 1
alpha = 0.6;

% Select all-ok ARL (or ARLs)
all_ok_ARL = [100 370 750];

% % Select p-values defining respective all-ok run length quantiles for the steady-steady case
% selected_p_values = [0.35 0.10 0.05];

%% Plot the CDFs/PDFs
for i = 1:length(all_ok_ARL)
        cd '../util/';
        all_ok_stdRL = get_TS_statistic(alpha, all_ok_ARL(i), 'stdRL');
        cd '../plots/';
    
        INPUT_PATH = ['../output/quantiles/RL.quantiles.alpha=', num2str(alpha, '%6.4f'), '.all-ok.ARL=', num2str(all_ok_ARL(i)), '.mat'];
        
        ERROR_MESSAGE = ['The file output/quantiles/RL.quantiles.alpha=', num2str(alpha, '%6.4f'), '.all-ok.ARL=', num2str(all_ok_ARL(i)), '.mat', ...
                         ' does not exist. Please run ../util/compute_TS_statistics.m first.'];
        
        if ~exist(INPUT_PATH)
            error(ERROR_MESSAGE);
        end
        
        load(INPUT_PATH);

        RUN_LENGTH_QUANTILES_GRID_SIZE = length(RUN_LENGTH_QUANTILES);
        
        p_grid       = linspace(0, 1, RUN_LENGTH_QUANTILES_GRID_SIZE)';
        RL_quantiles = RUN_LENGTH_QUANTILES;
    
        %%
        figure(i);
        
        set(gcf, 'PaperUnits', 'centimeters');
        %xSize = 30; ySize = 10;
        xSize = 26; ySize = 12;
        xLeft = (21 - xSize)/2; yTop = (30 - ySize)/2;
        set(gcf, 'PaperPosition', [xLeft yTop xSize ySize]);
        set(gcf, 'Position',[0 0 xSize*50 ySize*50]);
        
        %%
        cd '../lib/';
        subplot_tight(1, 2, 1, [0.1 0.05]);
        cd '../plots/';
        
        xlabel('Run length $l$', 'interpreter', 'latex', 'FontSize', 17);
        ylabel('Empirical cdf $\hat{F}_{N}(l)$', 'interpreter', 'latex', 'FontSize', 17);
        title(['TS chart run length cdf for IC ARL ', num2str(all_ok_ARL(i))], 'interpreter', 'latex', 'FontSize', 17);
        
        hold on;
        grid on;
        
        plot(RL_quantiles, p_grid, 'LineWidth', 2, 'Color', [0    0.4470    0.7410]);
        
        set(gca, 'XTick', sort([0 all_ok_ARL(i) 500:500:3000], 'ascend'));
        
        axis([0 2500 0 1]);
 
        %RL = interp1(p_grid, RL_quantiles, selected_p_values(i), 'linear');
        
        RL  = all_ok_ARL(i);
        
        [uRL iuRL] = unique(RL_quantiles, 'last');
        puRL = p_grid(iuRL);
        
        pRL = interp1(uRL, puRL, RL, 'linear');
        
        plot([RL RL], [0   pRL], 'k--');
        plot( RL, 0, 'ko');
        plot([RL RL], [pRL pRL], 'ko');
        text(RL + 15, 0.03, ['$\mathrm{P}(\mathrm{RL} \leq ', num2str(RL) ') = ', num2str(pRL, '%6.2f'), '$'], 'interpreter', 'latex', 'FontSize', 17);
        
        %plot([RL RL], [0 selected_p_values(i)], 'k--');
        %plot(RL, 0, 'ko');
        %plot(RL, selected_p_values(i), 'ko');
        %text(RL + 5, 0.025, [num2str(selected_p_values(i), '%6.2f'), '\textsuperscript{th} quantile = ', num2str(RL)], 'interpreter', 'latex', 'FontSize', 17);
        
        %%
        cd '../lib/';
        subplot_tight(1, 2, 2, [0.1 0.05]);
        cd '../plots/';
        
        xlabel('Run length $l$', 'interpreter', 'latex', 'FontSize', 17);
        ylabel('Kernel pdf estimate $\hat{f}_{h}(l)$ with $h \sim N^{-1/5}$', 'interpreter', 'latex', 'FontSize', 17);
        title(['TS chart run length pdf for IC ARL ', num2str(all_ok_ARL(i))], 'interpreter', 'latex', 'FontSize', 17);
        
        hold on;
        grid on;
        
        h = (4/(1 + 2))^(1/(1 + 4))*(2*RUN_LENGTH_QUANTILES_GRID_SIZE)^(-1/(1 + 4))*all_ok_stdRL;
        
        x = linspace(1, 2500, 1000);
        
        PDF = 0;
        
        for j = 1:RUN_LENGTH_QUANTILES_GRID_SIZE
            PDF = PDF + normpdf((x - RUN_LENGTH_QUANTILES(j))/h)/(h*2*RUN_LENGTH_QUANTILES_GRID_SIZE);
            PDF = PDF + normpdf((x - (1 - RUN_LENGTH_QUANTILES(j)))/h)/(h*2*RUN_LENGTH_QUANTILES_GRID_SIZE);
        end
        
        plot(x, PDF, 'LineWidth', 2, 'Color', [0    0.4470    0.7410]);
        plot([all_ok_ARL(i) all_ok_ARL(i)], [0 interp1(x, PDF, all_ok_ARL(i), 'linear')], 'k--');
        plot([all_ok_ARL(i) all_ok_ARL(i)], [0 interp1(x, PDF, all_ok_ARL(i), 'linear')], 'ko');
        
        set(gca, 'XTick', sort([0 all_ok_ARL(i) 500:500:3000], 'ascend'));
        
        axis([0 2500 0 5E-3]);
end

%% toggle the windows
for i = 1:length(all_ok_ARL)
    figure(length(all_ok_ARL) - i + 1);
end
