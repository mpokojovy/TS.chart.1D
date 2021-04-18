%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                  MONTGOMERY DATASET EXAMPLE: COMPARISON AMONG VARIOUS CHARTS                     %
%                                                                                                  %
% For the Montgomery dataset, the program plots the                                                %
% # 1: TS chart,                                                                                   %
% # 2: CUSUM w/ and w/o headstart and                                                              %
% # 3: Shewhart X chart                                                                            %
% signals at various time periods, respective control limits and detection times (if applicable).  %
%                                                                                                  %
% Source: Montgomery, D.C. (2009), Introduction to Statistical Quality Control,                    %
%         John Wiley & Sons, Inc., Hoboken, NJ, 6th edition                                        %
%         Problem 9.9, p. 431                                                                      %
%                                                                                                  %
% CONTAINS: 36 univariates                                                                         %
% ALL-OK STANDARDS: mu_0 = 3200, sigma_0 = 19.3                                                    %
%                                                                                                  %
% Copyright: Michael Pokojovy and J. Marcus Jobe (2020)                                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Select TS parameter alpha from 3/4, 2/3, 5/8, 3/5, 1
alpha = 0.6; % 3/4 % 2/3 % 5/8 % 3/5 % 1

% Select all-ok ARL from 100, 370 or 750
all_ok_ARL = 750; % 100 % 370 % 750

% Load up the dataset
run 'datasets/dataset_montgomery.m';

% Standardize the sample
n = length(x);
x = (x - 3200)/19.3;
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
ind = 1; % 1 through 18, e.g., 1 2 3 6 12 18

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

% Shewhart X chart control limit
if (all_ok_ARL == 370)
    CL_SHEWHART = 3;
else
    CL_SHEWHART = icdf('normal', 1 - 0.5/all_ok_ARL, 0, 1);
end
    
%% CUSUM chart w/o head start
L = 0;
U = 0;

for m = 1:n
    L = min([0 (x(m) + k) + L]);
    U = max([0 (x(m) - k) + U]);
    
    CUSUM_L_NO_HS(m) = L;
    CUSUM_U_NO_HS(m) = U;
end

%% CUSUM chart w/ head start
L = -h/2;
U =  h/2;

for m = 1:n
    L = min([0 (x(m) + k) + L]);
    U = max([0 (x(m) - k) + U]);
    
    CUSUM_L_HS(m) = L;
    CUSUM_U_HS(m) = U;
end

%% TS chart
cd '../lib/';
for m = 1:n
    [TS_SIGNALS(m), ~] = TSChartSingleStep(x(1:m), 0, 1, alpha);
end

%%
set(gcf, 'PaperUnits', 'centimeters');
xSize = 30; ySize = 14;
xLeft = (21 - xSize)/2; yTop = (30 - ySize)/2;
set(gcf,'PaperPosition', [xLeft yTop xSize ySize]);
set(gcf,'Position', [0 0 xSize*50 ySize*50]);

%%
subplot_tight(1, 3, 1, [0.08 0.05]);
hold on;
p1 = plot(1:n, TS_SIGNALS,       '-',  'Color', [0    0.4470    0.7410]);
p2 = plot(1:n, ones(n, 1)*CL_TS, '-.', 'Color', [0    0.4470    0.7410]);
p3 = plot(1:n, TS_SIGNALS,       'o',  'Color', [0    0.4470    0.7410]);

legend([p3, p2], {'TS signals', 'Control limit'}, ...
        'Location', 'Best', 'interpreter', 'latex', 'FontSize', 18);

xlabel('Time period $t$', 'interpreter', 'latex', 'FontSize', 18);
ylabel('TS signal', 'interpreter', 'latex', 'FontSize', 18);

ax = gca;
ax.XTick = [1 3:3:36];

axis([1 36 0 25]);

%% TS detection time
IND = min(find(TS_SIGNALS > CL_TS));

if ~isempty(IND)
    plot([IND IND], [-40 TS_SIGNALS(IND)], 'k--', IND, -40, 'k*');
    text(IND + 0.5, CL_TS/2, ['Detection time = ', num2str(IND)], 'interpreter', 'latex', 'FontSize', 18);
end

%%
subplot_tight(1, 3, 2, [0.08 0.05]);
hold on;

p1 = plot(1:n, CUSUM_L_NO_HS, '-',  'Color', [0.0000 0.4470 0.7410]);
p2 = plot(1:n, CUSUM_U_NO_HS, '-',  'Color', [0.0000 0.4470 0.7410]);
p3 = plot(1:n, CUSUM_L_HS,    '-',  'Color', [0.8500 0.3250 0.0980]);
p4 = plot(1:n, CUSUM_U_HS,    '-',  'Color', [0.8500 0.3250 0.0980]);

p5a = plot(1:n,  h*ones(1, n), '-.', 'Color', [0.0000 0.4470 0.7410]);
p6a = plot(1:n, -h*ones(1, n), '-.', 'Color', [0.0000 0.4470 0.7410]);
p5b = plot(1:n,  h_HS*ones(1, n), '.-', 'Color', [0.8500 0.3250 0.0980]);
p6b = plot(1:n, -h_HS*ones(1, n), '.-', 'Color', [0.8500 0.3250 0.0980]);

p7  = plot(1:n, CUSUM_L_HS,    'p', 'Color', [0.8500 0.3250 0.0980], 'MarkerEdgeColor', [0.8500 0.3250 0.0980], 'MarkerFaceColor', [0.8500 0.3250 0.0980]);
p8  = plot(1:n, CUSUM_U_HS,    'p', 'Color', [0.8500 0.3250 0.0980], 'MarkerEdgeColor', [0.8500 0.3250 0.0980], 'MarkerFaceColor', [0.8500 0.3250 0.0980]);
p9  = plot(1:n, CUSUM_L_NO_HS, 'o', 'Color', [0.0000 0.4470 0.7410]);
p10 = plot(1:n, CUSUM_U_NO_HS, 'o', 'Color', [0.0000 0.4470 0.7410]);

%% CUSUM head start detection time
[~, I1] = find(CUSUM_L_HS < -h_HS);
[~, I2] = find(CUSUM_U_HS >  h_HS);

IND_HS = min(union(I1, I2));

if ~isempty(IND_HS)
    if (IND_HS == min(I1))
        plot([IND_HS IND_HS], [-40 CUSUM_L_HS(IND_HS)], 'k--', IND_HS, -40, 'k*');
    else
        plot([IND_HS IND_HS], [-40 CUSUM_U_HS(IND_HS)], 'k--', IND_HS, -40, 'k*');
    end
end

%% CUSUM no head start detection time
[~, I1] = find(CUSUM_L_NO_HS < -h);
[~, I2] = find(CUSUM_U_NO_HS >  h);

IND_NO_HS = min(union(I1, I2));

if ~isempty(IND_NO_HS)
    if (IND_NO_HS == min(I1))
        plot([IND_NO_HS IND_NO_HS], [-40 CUSUM_L_NO_HS(IND_NO_HS)], 'k--', IND_NO_HS, -40, 'k*');
    else
        plot([IND_NO_HS IND_NO_HS], [-40 CUSUM_U_NO_HS(IND_NO_HS)], 'k--', IND_NO_HS, -40, 'k*');
    end
end

if isempty(IND_HS) && ~isempty(IND_NO_HS)
    text(IND_NO_HS + 0.5, -37, ['Detection time = ', num2str(IND_NO_HS)], 'interpreter', 'latex', 'FontSize', 18);
elseif ~isempty(IND_HS) && isempty(IND_NO_HS)
    text(IND_HS + 0.5, -37, ['Detection time = ', num2str(IND_HS)], 'interpreter', 'latex', 'FontSize', 18);    
elseif ~isempty(IND_HS) && ~isempty(IND_NO_HS)
    text(max(IND_HS, IND_NO_HS) + 0.5, -37, ['Detection times = ', num2str(min(IND_HS, IND_NO_HS)), ' and ', num2str(max(IND_HS, IND_NO_HS))], ...
        'interpreter', 'latex', 'FontSize', 18);    
end

legend([p9, p7, p5a, p5b], {'CUSUM signals', 'CUSUM head start signals', 'CUSUM control limits', 'CUSUM head start control limits'}, ...
        'Location', 'North', 'interpreter', 'latex', 'FontSize', 17);

xlabel('Time period $t$', 'interpreter', 'latex', 'FontSize', 18);
ylabel('CUSUM signal', 'interpreter', 'latex', 'FontSize', 18);

ax = gca;
ax.XTick = [1 3 5 7 9 12:3:36];

axis([1 36 -40 36]);

%%
subplot_tight(1, 3, 3, [0.08 0.05]);
hold on;
p1 = plot(1:n, x, '-', 'Color', [0    0.4470    0.7410]);
plot(1:n, x, 'o', 'Color', [0    0.4470    0.7410]);
p2 = plot(1:n, -CL_SHEWHART*ones(n, 1), '-.', 'Color', [0    0.4470    0.7410]);
plot(1:n,  CL_SHEWHART*ones(n, 1), '-.', 'Color', [0    0.4470    0.7410]);

legend([p1, p2], {'Shewhart signals', 'Control limit'}, ...
        'Location', 'Best', 'interpreter', 'latex', 'FontSize', 18);

xlabel('Time period $t$', 'interpreter', 'latex', 'FontSize', 18);
ylabel('Shewhart signal', 'interpreter', 'latex', 'FontSize', 18);

ax = gca;
ax.XTick = [1 3:3:36];

axis([1 36 -4 4]);

%% Shewhart X chart detection time
IND = min(find(abs(x) > CL_SHEWHART));

if ~isempty(IND)
    plot([IND IND], [-40 x(IND)], 'k--', IND, -40, 'k*');
    text(IND + 0.5, -3.65, ['Detection time = ', num2str(IND)], 'interpreter', 'latex', 'FontSize', 18);
end

%%
cd '../examples'/;
