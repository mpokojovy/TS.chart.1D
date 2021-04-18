%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                   Plot the control limits curve                                  %
%                                                                                                  %
% PURPOSE: Based on precomputed control limits, plots the control limit curve for given TS chart   %
% exponent alpha.                                                                                  % 
%                                                                                                  %
% Copyright: Michael Pokojovy and J. Marcus Jobe (2020)                                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

cd '../util/';

alpha = 0.6;

selected_all_ok_ARL = [100 370 750];
selected_conservative_all_ok_ARL = selected_all_ok_ARL + 3*get_TS_statistic(alpha, selected_all_ok_ARL, 'stdARL');

figure(1);

%%
set(gcf, 'PaperUnits', 'centimeters');
xSize = 24; ySize = 12;
xLeft = (21 - xSize)/2; yTop = (30 - ySize)/2;
set(gcf, 'PaperPosition', [xLeft yTop xSize ySize]);
set(gcf, 'Position',[0 0 xSize*50 ySize*50]);
%%
cd '../lib/';
subplot_tight(1, 1, 1, [0.08 0.05]);
cd '../util/';
hold on;

all_ok_ARL_grid = linspace(50, 2500, 5000);
control_limits = get_TS_statistic(alpha, all_ok_ARL_grid, 'ControlLimit');

plot(all_ok_ARL_grid, control_limits, 'LineWidth', 2, 'Color', [0    0.4470    0.7410]);

CL_min = min(control_limits);
CL_max = CL_min/5 + 12/5;

axis([50 2500 (CL_min + CL_max)/2 - (CL_max - CL_min)*0.75 (CL_min + CL_max)/2 + (CL_max - CL_min)*0.75]);

grid on;

xlabel('IC ARL', 'interpreter', 'latex', 'FontSize', 18);
ylabel('Control limit', 'interpreter', 'latex', 'FontSize', 18);

selected_control_limits = interp1(all_ok_ARL_grid, control_limits, selected_conservative_all_ok_ARL, 'linear');

for i = 1:length(selected_all_ok_ARL)
    plot([selected_conservative_all_ok_ARL(i) selected_conservative_all_ok_ARL(i)], [(CL_min + CL_max)/2 - (CL_max - CL_min)*0.75 selected_control_limits(i)], 'k');
    plot([selected_conservative_all_ok_ARL(i)], [selected_control_limits(i)], 'ko');
    
    text(selected_conservative_all_ok_ARL(i) + 5, (CL_min + CL_max)/2 - (CL_max - CL_min)*0.75 + 0.05, num2str(selected_conservative_all_ok_ARL(i), '%8.4f'), 'interpreter', 'latex', 'FontSize', 18);
    text(selected_conservative_all_ok_ARL(i) + 5, selected_control_limits(i)                   - 0.05, num2str(selected_control_limits(i),          '%8.4f'), 'interpreter', 'latex', 'FontSize', 18);
end

cd '../plots';
