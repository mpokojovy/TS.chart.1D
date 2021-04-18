%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%           LUCAS & CROSIER IN-CONTROL DATASET EXAMPLE: COMPARISON AMONG VARIOUS CHARTS            %
%                                                                                                  %
% For the Montgomery dataset, the program plots the                                                %
% # 1: TS chart,                                                                                   %
% # 2: CUSUM FIR and                                                                               %
% # 3: CUSUM                                                                                       %
% signals at various time periods, respective control limits anddetection/restart times            %
% (if applicable).                                                                                 %
%                                                                                                  %
% Source: Lucas, J.M. and Crosier, R.B. (1982). Initial Response for CUSUM Quality Control         %
%         Schemes: Give Your CUSUM A Head Start, Technometrics, Vol. 24, No. 3 (Aug. 1982),        %
%         pp. 199-205                                                                              %
%                                                                                                  %
% CONTAINS: 20 univariates                                                                         %
% ALL-OK STANDARDS: mu_0 = 0.0, sigma_0 = 1.0                                                      %
%                                                                                                  %
% Copyright: Michael Pokojovy and J. Marcus Jobe (2020)                                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Select TS parameter alpha from 3/4, 2/3, 5/8, 3/5, 1
alpha = 0.6; % 3/4 % 2/3 % 5/8 % 3/5 % 1

% Select all-ok ARL from 100, 370 or 750
all_ok_ARL = 370; % 100 % 370 % 750

% Load up the dataset
run 'datasets/dataset_lucas_crosier_01.m';

% Standardize the sample
n = length(x);

% Initialize signal vectors
TS_SIGNALS    = zeros(1, n);
CUSUM_L_NO_HS = zeros(1, n);
CUSUM_U_NO_HS = zeros(1, n);
CUSUM_L_HS    = zeros(1, n);
CUSUM_U_HS    = zeros(1, n);

% Load up the TS chart control limit

cd '../util/';
CL_TS = get_TS_statistic(alpha, all_ok_ARL, 'ControlLimitConservative');
cd '../examples/';

% Initialize CUSUM parameters/control limit

% Set of k values
K = [0.1000  0.2000  0.2500  0.3000  0.4000  0.5000  0.6000  0.7000  0.7500  0.8000  0.9000  1.0000  1.1000  1.2000  1.2500  1.3000  1.4000  1.5000]';
% Set of control limits h for CUSUM
H = ...
    [ 8.5200    6.3200    5.6000    5.0100    4.1400    3.5000    3.0200    2.6400    2.4820    2.3370    2.0850    1.8740    1.6920    1.5320    1.4580    1.3880    1.2550    1.1320;
	 13.4860    9.2490    8.0100    7.0630    5.7070    4.7740    4.0882    3.5600    3.3400    3.1408    2.7988    2.5162    2.2793    2.0770    1.9860    1.9012    1.7450    1.6042;
	 16.5475   10.9238    9.3700    8.2085    6.5750    5.4720    4.6715    4.0616    3.8075    3.5800    3.1891    2.8662    2.5959    2.3671    2.2655    2.1705    1.9988    1.8415]';
% Set of control limits h for CUSUM head start
H_HS = ...
    [ 9.8129    6.8781    5.9994    5.3201    4.3298    3.6357    3.1179    2.7153    2.5458    2.3933    2.1298    1.9093    1.7204    1.5547    1.4786    1.4062    1.2703    1.1438;
     14.6162    9.6477    8.2854    7.2663    5.8298    4.8560    4.1468    3.6046    3.3781    3.1750    2.8263    2.5383    2.2970    2.0914    1.9992    1.9129    1.7549    1.6121;
     17.5166   11.2407    9.5854    8.3644    6.6676    5.5332    4.7150    4.0942    3.8362    3.6053    3.2094    2.8826    2.6093    2.3780    2.2751    2.1794    2.0061    1.8518]';   
 
% Index of the (k, h)-pair
ind = 6; % 1 through 18, e.g., 1 2 3 6 12 18

k = K(ind);

switch all_ok_ARL
    case 100
        h    = H(ind, 1);
        h_HS = H_HS(ind, 1);
    case 370
        h    = H(ind, 2);
        h_HS = H_HS(ind, 2);
    case 750
        h    = H(ind, 3);
        h_HS = H_HS(ind, 3);
end
    
%% Signal computation
% CUSUM chart w/o head start
L = 0;
U = 0;

for m = 1:n
    L = min([0 (x(m) + k) + L]);
    U = max([0 (x(m) - k) + U]);
    
    CUSUM_L_NO_HS(m) = L;
    CUSUM_U_NO_HS(m) = U;
    
    if (L < -h) || (U > h)
        L = 0;
        U = 0;
    end
end

% CUSUM chart w/ head start
L = -h/2;
U =  h/2;

for m = 1:n
    L = min([0 (x(m) + k) + L]);
    U = max([0 (x(m) - k) + U]);
    
    CUSUM_L_HS(m) = L;
    CUSUM_U_HS(m) = U;
    
    if (L < -h_HS) || (U > h_HS)
        L = -h_HS/2;
        U =  h_HS/2;
    end
end

% TS chart
cd '../lib/';

i0 = 1;
for m = 1:n
    [TS_SIGNALS(m), ~] = TSChartSingleStep(x(i0:m), 0, 1, alpha);
    
    if (TS_SIGNALS(m) > CL_TS)
        i0 = m + 1;
    end
end

%% Plotting
set(gcf, 'PaperUnits', 'centimeters');
xSize = 26; ySize = 12;
xLeft = (21 - xSize)/2; yTop = (30 - ySize)/2;
set(gcf,'PaperPosition', [xLeft yTop xSize ySize]);
set(gcf,'Position', [0 0 xSize*50 ySize*50]);

color_order = get(gca, 'colororder');

%% TS
subplot_tight(1, 3, 1, [0.08 0.05]);
hold on;
p1 = plot(1:n, TS_SIGNALS,       '-',  'Color', color_order(1, :));
p2 = plot(1:n, ones(n, 1)*CL_TS, '-.', 'Color', color_order(1, :));
p3 = plot(1:n, TS_SIGNALS,       'o',  'Color', color_order(1, :));

xlabel('Time period $t$', 'interpreter', 'latex', 'FontSize', 18);
ylabel('TS signal', 'interpreter', 'latex', 'FontSize', 18);

% TS detection time
IND = find(TS_SIGNALS > CL_TS);

for i = 1:length(IND)
    plot([IND(i) IND(i)], [-40 TS_SIGNALS(IND(i))], 'k--', IND(i), -40, 'k*');
    %text(IND(i) + 0.5, CL_TS/2, ['restart time ' num2str(i) ' = ', num2str(IND(i))], 'interpreter', 'latex', 'FontSize', 18);
end

ax = gca;
ax.XTick = sort(union([1:3:n], IND));

axis([1 n 0.0 4.5]);

legend([p3, p2], {'TS signals', 'Control limit'}, ...
        'Location', 'Best', 'interpreter', 'latex', 'FontSize', 18);

%% CUSUM FIR
subplot_tight(1, 3, 2, [0.08 0.05]);
hold on;

p1a = plot(1:n, CUSUM_L_HS,    '-',  'Color', color_order(2, :));
p1b = plot(1:n, CUSUM_U_HS,    '-',  'Color', color_order(2, :));

p2a = plot(1:n,  h_HS*ones(1, n), '-.', 'Color', color_order(2, :));
p2b = plot(1:n, -h_HS*ones(1, n), '-.', 'Color', color_order(2, :));

p3a = plot(1:n, CUSUM_L_HS,    'p', 'Color', color_order(2, :), 'MarkerEdgeColor', color_order(2, :), 'MarkerFaceColor', color_order(2, :));
p3b = plot(1:n, CUSUM_U_HS,    'p', 'Color', color_order(2, :), 'MarkerEdgeColor', color_order(2, :), 'MarkerFaceColor', color_order(2, :));

% CUSUM head start detection time
[~, I1] = find(CUSUM_L_HS < -h_HS);
[~, I2] = find(CUSUM_U_HS >  h_HS);

for i = 1:length(I1)
    plot([I1(i) I1(i)], [-40 CUSUM_L_HS(I1(i))], 'k--', I1(i), -40, 'k*');
end

for i = 1:length(I2)
    plot([I2(i) I2(i)], [-40 CUSUM_U_HS(I2(i))], 'k--', I2(i), -40, 'k*');
end

legend([p3a, p1a], {'CUSUM FIR signals', 'CUSUM FIR control limits'}, ...
        'Location', 'North', 'interpreter', 'latex', 'FontSize', 16);

xlabel('Time period $t$', 'interpreter', 'latex', 'FontSize', 18);
ylabel('CUSUM FIR signal', 'interpreter', 'latex', 'FontSize', 18);

ax = gca;
ax.XTick = sort(union(union([1:3:n], I1), I2));

axis([1 n -7 8]);

%% CUSUM

subplot_tight(1, 3, 3, [0.08 0.05]);
hold on;

p1a = plot(1:n, CUSUM_L_NO_HS,    '-',  'Color', color_order(5, :));
p1b = plot(1:n, CUSUM_U_NO_HS,    '-',  'Color', color_order(5, :));

p2a = plot(1:n,  h*ones(1, n), '-.', 'Color', color_order(5, :));
p2b = plot(1:n, -h*ones(1, n), '-.', 'Color', color_order(5, :));

p3a = plot(1:n, CUSUM_L_NO_HS,    'p', 'Color', color_order(5, :), 'MarkerEdgeColor', color_order(5, :), 'MarkerFaceColor', color_order(5, :));
p3b = plot(1:n, CUSUM_U_NO_HS,    'p', 'Color', color_order(5, :), 'MarkerEdgeColor', color_order(5, :), 'MarkerFaceColor', color_order(5, :));

% CUSUM head start detection time
[~, I1] = find(CUSUM_L_NO_HS < -h_HS);
[~, I2] = find(CUSUM_U_NO_HS >  h_HS);

for i = 1:length(I1)
    plot([I1(i) I1(i)], [-40 CUSUM_L_NO_HS(I1(i))], 'k--', I1(i), -40, 'k*');
end

for i = 1:length(I2)
    plot([I2(i) I2(i)], [-40 CUSUM_U_NO_HS(I2(i))], 'k--', I2(i), -40, 'k*');
end

legend([p3a, p1a], {'CUSUM signals', 'CUSUM control limits'}, ...
        'Location', 'North', 'interpreter', 'latex', 'FontSize', 17);

xlabel('Time period $t$', 'interpreter', 'latex', 'FontSize', 18);
ylabel('CUSUM FIR signal', 'interpreter', 'latex', 'FontSize', 18);

ax = gca;
ax.XTick = sort(union(union([1:3:n], I1), I2));

axis([1 n -7 8]);

%%
cd '../examples'/;

display('    index| raw data|TS signal|CUSUM FIR L|CUSUM FIR U| CUSUM L |CUSUM U ');
display([(1:length(x))' x TS_SIGNALS' CUSUM_L_HS' CUSUM_U_HS' CUSUM_L_NO_HS' CUSUM_U_NO_HS']);