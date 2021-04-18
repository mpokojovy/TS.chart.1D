%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      COMPLETE OUT-OF-CONTROL SIMULATION FOR TS, CUSUM, CUSUM HEAD START AND SHEWHART CHARTS      %
%                                                                                                  %
% Evaluates the TS, CUSUM, CUSUM head start and Shewhart chart performance  - initial and steady   %
% state (the latter except for CUSUM head start) - and writes both text and Matlab output in       %
% output/out.of.control.performance                                                                %
%                                                                                                  %
% Warning: The full scale simulation (i.e., N = 1000000) can take 1 to 3 days depending on PC      %
% configuration. For a small scale simulation, consider taking N = 1000 or N = 10000.              %
%                                                                                                  %
% Copyright: Michael Pokojovy and J. Marcus Jobe (2020)                                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

poolobj = parpool('local', 'AttachedFiles', {'lib/TSChartSingleStep.m'});

% Save current entries in Matlab path list
CURRENT_PATHS = path; 
addpath '/lib/';

cd 'util/';

N  = 1000000; % N = 1000 or N = 10000 for small scale simulations

n  = 10000;
n0 = floor(n*0.75);

all_ok_ARL = [100 370 750];

restart_flag = true; % Carry out the simulation for both restart_flag = true and false

delta = [0.2000  0.4000  0.5000  0.6000  0.8000  1.0000  1.2000  1.4000  1.5000  1.6000  1.8000  2.0000  2.2000  2.4000  2.5000  2.6000  2.8000  3.0000]';

H = ...
    [ 8.5200    6.3200    5.6000    5.0100    4.1400    3.5000    3.0200    2.6400    2.4820    2.3370    2.0850    1.8740    1.6920    1.5320    1.4580    1.3880    1.2550    1.1320;
	 13.4860    9.2490    8.0100    7.0630    5.7070    4.7740    4.0882    3.5600    3.3400    3.1408    2.7988    2.5162    2.2793    2.0770    1.9860    1.9012    1.7450    1.6042;
	 16.5475   10.9238    9.3700    8.2085    6.5750    5.4720    4.6715    4.0616    3.8075    3.5800    3.1891    2.8662    2.5959    2.3671    2.2655    2.1705    1.9988    1.8415]';

H_HS = ...
    [ 9.8129    6.8781    5.9994    5.3201    4.3298    3.6357    3.1179    2.7153    2.5458    2.3933    2.1298    1.9093    1.7204    1.5547    1.4786    1.4062    1.2703    1.1438;
     14.6162    9.6477    8.2854    7.2663    5.8298    4.8560    4.1468    3.6046    3.3781    3.1750    2.8263    2.5383    2.2970    2.0914    1.9992    1.9129    1.7549    1.6121;
     17.5166   11.2407    9.5854    8.3644    6.6676    5.5332    4.7150    4.0942    3.8362    3.6053    3.2094    2.8826    2.6093    2.3780    2.2751    2.1794    2.0061    1.8518]';    

chart_name = {'TS', 'CUSUM', 'CUSUMHeadstart', 'ShewhartX'};

c1 = clock;

if (restart_flag)
    %% Simulation w/ restarts
    chart_name = {'TS', 'CUSUMHeadstart'};

    for i = 1:length(chart_name)
        if strcmpi(chart_name{i}, 'TS')
            for init_state_flag = [0 1]
            for alpha = [3/5] %[3/5 5/8 2/3 3/4 1]
                if (init_state_flag)
                    steady_state_size = [0 0 0];
                else             
                    steady_state_size = [1 3 5 7 9;
                                         1 3 5 7 9;
                                         1 3 5 7 9]';
                end
                
                for steady_state_ind = 1:size(steady_state_size, 1)
                    control_limit = get_TS_statistic(alpha, all_ok_ARL, 'ControlLimitConservative');

                    compute_out_of_control_performance('ChartName', 'TS', 'alpha', alpha, 'SimulationSize', N, 'TruncationTimePeriod', n, 'TSNoBreakTestStartTimePeriod', n0, ...
                                                       'All_ok_ARL', all_ok_ARL, 'ControlLimit', control_limit, 'SteadyStateSize', steady_state_size(steady_state_ind, :), 'ShiftSize', delta, 'RestartFlag', true);                         
                end                                   
            end
            end
        elseif strcmpi(chart_name{i}, 'CUSUM') || strcmpi(chart_name{i}, 'CUSUMHeadstart')
            for init_state_flag = [0 1]
                if (init_state_flag)
                    steady_state_size = [0 0 0];
                else
                    steady_state_size = [1 3 5 7 9;
                                         1 3 5 7 9;
                                         1 3 5 7 9]';
                end

                for steady_state_ind = 1:size(steady_state_size, 1)
                    if (strcmpi(chart_name{i}, 'CUSUMHeadstart'))
                        compute_out_of_control_performance('ChartName', chart_name{i}, 'CUSUMParameterK', 'Optimal', 'SimulationSize', N, 'TruncationTimePeriod', n, ...
                                                           'All_ok_ARL', all_ok_ARL, 'ControlLimit', H_HS, 'SteadyStateSize', steady_state_size(steady_state_ind, :), 'ShiftSize', delta, 'RestartFlag', true);
                    else
                        compute_out_of_control_performance('ChartName', chart_name{i}, 'CUSUMParameterK', 'Optimal', 'SimulationSize', N, 'TruncationTimePeriod', n, ...
                                                           'All_ok_ARL', all_ok_ARL, 'ControlLimit', H, 'SteadyStateSize', steady_state_size(steady_state_ind, :), 'ShiftSize', delta, 'RestartFlag', true);
                    end

                    K = [0.10 0.25 0.50 0.75 1.00 1.25 1.50];

                    for j = 1:length(K)
                        ind = find(delta/2 == K(j));

                        if (strcmpi(chart_name{i}, 'CUSUMHeadstart'))
                            compute_out_of_control_performance('ChartName', chart_name{i}, 'CUSUMParameterK', delta(ind)/2, 'SimulationSize', N, 'TruncationTimePeriod', n, ...
                                                               'All_ok_ARL', all_ok_ARL, 'ControlLimit', H_HS(ind, :), 'SteadyStateSize', steady_state_size(steady_state_ind, :), 'ShiftSize', delta, 'RestartFlag', true);
                        else
                            compute_out_of_control_performance('ChartName', chart_name{i}, 'CUSUMParameterK', delta(ind)/2, 'SimulationSize', N, 'TruncationTimePeriod', n, ...
                                                               'All_ok_ARL', all_ok_ARL, 'ControlLimit', H(ind, :), 'SteadyStateSize', steady_state_size(steady_state_ind, :), 'ShiftSize', delta, 'RestartFlag', true);
                        end
                    end  
                end      
            end
        elseif strcmpi(chart_name{i}, 'ShewhartX')
            if (init_state_flag)
                steady_state_size = [0 0 0];
            else
                steady_state_size = [1 3 5 7 9;
                                     1 3 5 7 9;
                                     1 3 5 7 9]';
            end

            control_limit = norminv(1 - 0.5./all_ok_ARL);
            
            if (~isempty(find(all_ok_ARL == 370)))
                control_limit(find(all_ok_ARL == 370)) = 3;
            end

            for steady_state_ind = 1:size(steady_state_size, 1)
                compute_out_of_control_performance('ChartName', chart_name{i}, 'SimulationSize', N, 'TruncationTimePeriod', n, ...
                                                   'All_ok_ARL', all_ok_ARL, 'ControlLimit', control_limit, 'SteadyStateSize', steady_state_size(steady_state_ind, :), 'ShiftSize', delta, 'RestartFlag', true);
            end
        end
    end
else
    %% Simulation w/o restarts
    for i = 1:length(chart_name)
        if strcmpi(chart_name{i}, 'TS')
            for init_state_flag = [0 1]
            for alpha = [3/5] %[3/5 5/8 2/3 3/4 1]
                if (init_state_flag)
                    steady_state_size = [0 0 0];
                else
                    steady_state_size = [5 10 20 50 100;
                                         5 10 20 50 100;
                                         5 10 20 50 100]';
                    steady_state_size = [steady_state_size;
                                         all_ok_ARL];
                end

                for steady_state_ind = 1:size(steady_state_size, 1)
                    control_limit = get_TS_statistic(alpha, all_ok_ARL, 'ControlLimitConservative');

                    compute_out_of_control_performance('ChartName', 'TS', 'alpha', alpha, 'SimulationSize', N, 'TruncationTimePeriod', n, 'TSNoBreakTestStartTimePeriod', n0, ...
                                                       'All_ok_ARL', all_ok_ARL, 'ControlLimit', control_limit, 'SteadyStateSize', steady_state_size(steady_state_ind, :), 'ShiftSize', delta);                                
                end                                   
            end
            end
        elseif strcmpi(chart_name{i}, 'CUSUM') || strcmpi(chart_name{i}, 'CUSUMHeadstart')
            for init_state_flag = [0 1]
                if (init_state_flag)
                    steady_state_size = [0 0 0];
                else
                    if (strcmpi(chart_name{i}, 'CUSUM'))
                        steady_state_size = [5 10 20 50  75;
                                             5 10 20 50 100;
                                             5 10 20 50 100]';
                        steady_state_size = [steady_state_size;
                                             all_ok_ARL];
                    else
                        steady_state_size = [0 0 0];
                    end
                end

                if (strcmpi(chart_name{i}, 'CUSUMHeadstart'))
                    if ((min(steady_state_size) > 0) || (init_state_flag == 0))
                        continue;
                    end 
                end

                for steady_state_ind = 1:size(steady_state_size, 1)
                    if (strcmpi(chart_name{i}, 'CUSUMHeadstart'))
                        compute_out_of_control_performance('ChartName', chart_name{i}, 'CUSUMParameterK', 'Optimal', 'SimulationSize', N, 'TruncationTimePeriod', n, ...
                                                           'All_ok_ARL', all_ok_ARL, 'ControlLimit', H_HS, 'SteadyStateSize', steady_state_size(steady_state_ind, :), 'ShiftSize', delta);
                    else
                        compute_out_of_control_performance('ChartName', chart_name{i}, 'CUSUMParameterK', 'Optimal', 'SimulationSize', N, 'TruncationTimePeriod', n, ...
                                                           'All_ok_ARL', all_ok_ARL, 'ControlLimit', H, 'SteadyStateSize', steady_state_size(steady_state_ind, :), 'ShiftSize', delta);
                    end

                    K = [0.10 0.25 0.50 0.75 1.00 1.25 1.50];

                    for j = 1:length(K)
                        ind = find(delta/2 == K(j));

                        if (strcmpi(chart_name{i}, 'CUSUMHeadstart'))
                            compute_out_of_control_performance('ChartName', chart_name{i}, 'CUSUMParameterK', delta(ind)/2, 'SimulationSize', N, 'TruncationTimePeriod', n, ...
                                                               'All_ok_ARL', all_ok_ARL, 'ControlLimit', H_HS(ind, :), 'SteadyStateSize', steady_state_size(steady_state_ind, :), 'ShiftSize', delta);
                        else
                            compute_out_of_control_performance('ChartName', chart_name{i}, 'CUSUMParameterK', delta(ind)/2, 'SimulationSize', N, 'TruncationTimePeriod', n, ...
                                                               'All_ok_ARL', all_ok_ARL, 'ControlLimit', H(ind, :), 'SteadyStateSize', steady_state_size(steady_state_ind, :), 'ShiftSize', delta);
                        end
                    end  
                end      
            end
        elseif strcmpi(chart_name{i}, 'ShewhartX')
            steady_state_size = [0 0 0];

            control_limit = norminv(1 - 0.5./all_ok_ARL);
            control_limit(find(all_ok_ARL == 370)) = 3;

            compute_out_of_control_performance('ChartName', chart_name{i}, 'SimulationSize', N, 'TruncationTimePeriod', n, ...
                                               'All_ok_ARL', all_ok_ARL, 'ControlLimit', control_limit, 'SteadyStateSize', steady_state_size, 'ShiftSize', delta);
        end
    end    
end

c2 = clock;

etime(c2, c1)

cd '../';

% Restore previous Matlab path list
path(CURRENT_PATHS);