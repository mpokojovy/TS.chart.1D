%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            MONTGOMERY DATASET EXAMPLE: THE TS ESTIMATOR                          %
%                                                                                                  %
% For the Montgomery dataset, the program plots the TS estimator applied to the                    %
% # 1: first 3,                                                                                    %
% # 2: fist 20 and                                                                                 %
% # 3: all 36                                                                                      % 
% observations of the standardized dataset.                                                        %
%                                                                                                  %
% Source: Montgomery, D.C. (2009), Introduction to Statistical Quality Control,                    %
%         John Wiley & Sons, Inc., Hoboken, NJ}, 6th edition                                       %
%         Problem 9.9, p. 431                                                                      %
%                                                                                                  %
% CONTAINS: 36 univariates                                                                         %
% ALL-OK STANDARDS: mu_0 = 3200, sigma_0 = 19.3                                                    %
%                                                                                                  %
% Copyright: Michael Pokojovy and J. Marcus Jobe (2020)                                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

run 'datasets/dataset_montgomery.m';

x = (x - 3200)/19.3;

n = length(x);

%%
set(gcf, 'PaperUnits', 'centimeters');
xSize = 28; ySize = 12;
xLeft = (21 - xSize)/2; yTop = (30 - ySize)/2;
set(gcf,'PaperPosition', [xLeft yTop xSize ySize]);
set(gcf,'Position',[0 0 xSize*50 ySize*50]);
%%
cd '../lib/';

subplot_tight(1, 1, 1, [0.08 0.05]);
hold on;
plot(1:n, x, 'o', 'Color', [0    0.4470    0.7410]);

n = 3;
lambda = std(x)*max(1.149, 0.8*sqrt(2*log(log(max(n, 3)))))/sqrt(n);
regplot_modified(x(1:n), lambda, '-.', [0    0.4470    0.7410]);
text(n + 0.2, -1.6580, '$\hat{\mu}_{3}(t/3)$', 'interpreter', 'latex', 'FontSize', 18);

n = 20;
lambda = std(x)*max(1.149, 0.8*sqrt(2*log(log(max(n, 3)))))/sqrt(n);
regplot_modified(x(1:n), lambda, '--', [0    0.4470    0.7410]);
text(n + 0.1, -0.2073, '$\hat{\mu}_{20}(t/20)$', 'interpreter', 'latex', 'FontSize', 18);

n = 36;
lambda = std(x)*max(1.149, 0.8*sqrt(2*log(log(max(n, 3)))))/sqrt(n);
regplot_modified(x(1:n), lambda, '-', [0    0.4470    0.7410]);
text(n - 2.75, -0.4663, '$\hat{\mu}_{36}(t/36)$', 'interpreter', 'latex', 'FontSize', 18);

xlabel('Time period $t$', 'interpreter', 'latex', 'FontSize', 18);
ylabel('$x = (v - 3200)/19.3$', 'interpreter', 'latex', 'FontSize', 18);

ax = gca;
ax.XTick = [1 3:3:36];

axis([1 36 -3.25 1.00]);

cd '../examples'/;
