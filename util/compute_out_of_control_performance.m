function compute_out_of_control_performance(varargin)
% PURPOSE: Evaluates the out-of-control performance of the TS, CUSUM, CUSUM head start or Shewhart X
% chart
% --------------------------------------------------------------------------------------------------
% CALL:  compute_out_of_control_performance(varargin)
%        e.g., compute_out_of_control_performance('ChartName', 'CUSUM', 'All_ok_ARL', 370, ...
%              'ShiftSize', 0, 'SimulationSize', 50000, 'TruncationTimePeriod', 10000, ...
%              'CUSUMParameterK', 0.1, 'SteadyStateSize', 0, 'ControlLimit', 13.49)
% Input:
%    Variable number of arguments
%
%    'ChartName', ...................... STRING 'TS', 'CUSUM', 'CUSUMHeadstart' or 'ShewhartX'
%    'alpha', .......................... DOUBLE(1, 1) 3/4, 2/3, 5/8, 3/5 or 1
%    'All_ok-ARL', ..................... DOUBLE(1, I) array of all-ok ARLs between 10 and 3000
%    'ShiftSize', ...................... DOUBLE(J, 1) array of shifts delta
%    'SimulationSize', ................. DOUBLE(1, 1) simulation size
%    'TruncationTimePeriod', ........... INTEGER(1, 1) data stream length (truncation point)
%    'SteadyStateSize', ................ INTEGER(1, I) array of steady state sizes, must be of same
%                                        size as all-ok ARL, use zero values for an initial state
%                                        simulation
%    'CUSUMParameterK', ................ 'optimal' or DOUBLE(J, I), only needed for CUSUM and CUSUM
%                                        head start
%    'TSNoBreakTestStartTimePeriod', ... INTEGER(1, 1)
%    'RestartFlag' ..................... BOOL(1, 1) restart chart? default = false
% Output: 
%    Saved to ../output/out.of.control.performance/:
%
%    A) Text output summarizing performance of the respective chart
%    B) MAT-file containing a DOUBLE(J, 7) matrix with its i-th row containing
%       1) i-th shift magnitude delta(i)
%       2) all-ok ARL for shift delta(i)
%       3) all-ok run length std for shift delta(i)
%       4) all-ok ARL std for shift delta(i)
%       5) probability of reaching the stream length/truncation point
%       6) probability of violating the no-break test given the truncation point is reached
%       7) percent (not probability!) of streams used in steady state simulation (100% for initial
%          state simulations (= 100 if RestartFlag = true)
%       8) average number of restarts (does not exist if RestartFlag = false)
%       9) standard deviation of restart number (does not exist if RestartFlag = false)
% Description:
%    Performs a simulation to the out-of-control performance of the TS, CUSUM, CUSUM head start or 
%    Shewhart X chart, produces a text report and saves resulting statistics in MAT-files.
%    Matlab parallelization via parfor is used. If your Matlab version does not support parallelization,
%    replace all occurrences of parfor with the regular for operator.
%
% Copyright: Michael Pokojovy and J. Marcus Jobe (2020)

    restart_flag = false;

    nvarargin = length(varargin);

    if (mod(nvarargin, 2) ~= 0)
        error('Number of arguments needs to be even');
    end
    
    for i = 1:nvarargin/2
        if strcmpi(varargin(2*(i - 1) + 1), 'ChartName')
            chart_name = varargin{2*i};
                
            if ~(strcmpi(chart_name, 'TS') || strcmpi(chart_name, 'CUSUM') || strcmpi(chart_name, 'ShewhartX') || strcmpi(chart_name, 'CUSUMHeadstart'))
                error('Wrong chart name. The selection available is ''TS'', ''CUSUM'', ''CUSUMHeadstart'', ''ShewhartX''.');
            end
        end    
    end

    for i = 1:nvarargin/2
        if strcmpi(varargin(2*(i - 1) + 1), 'All_ok_ARL')
            all_ok_ARL = varargin{2*i};
               
            if (min(all_ok_ARL) < 10) || (max(all_ok_ARL) > 3000)
            	ERROR_MESSAGE = 'all_ok_ARL needs to be between 10 and 3000';
                error(ERROR_MESSAGE);
            end
        end
    end
    
    for i = 1:nvarargin/2
        if strcmpi(varargin(2*(i - 1) + 1), 'ShiftSize')
            delta = varargin{2*i};
        end
    end
    
    for i = 1:nvarargin/2
        if strcmpi(varargin(2*(i - 1) + 1), 'ControlLimit')
            control_limit = varargin{2*i};
        elseif strcmpi(varargin(2*(i - 1) + 1), 'alpha')
            if strcmpi(chart_name, 'TS')
                alpha = varargin{2*i};
                    
                if isempty(find(abs([3/4 2/3 5/8 3/5 1] - alpha) < 1E-4))
                	ERROR_MESSAGE = 'Parameter alpha needs to be 3/4, 2/3, 5/8, 3/5 or 1';
                    error(ERROR_MESSAGE);
                end
            else
            	warning('Parameter alpha is not needed for CUSUM or Shewhart X chart.');
            end
        elseif strcmpi(varargin(2*(i - 1) + 1), 'SimulationSize')
            N = varargin{2*i};
        elseif strcmpi(varargin(2*(i - 1) + 1), 'TruncationTimePeriod')
            n = varargin{2*i};
        elseif strcmpi(varargin(2*(i - 1) + 1), 'TSNoBreakTestStartTimePeriod')
            if strcmpi(chart_name, 'TS')
                break_test_cutoff = varargin{2*i};
            else
                warning('TS no-break violation test start time period is only required for the TS chart.');
            end
        elseif strcmpi(varargin(2*(i - 1) + 1), 'SteadyStateSize')
            steady_state_size = varargin{2*i};
            
            if max(size(all_ok_ARL) ~= size(steady_state_size))
                error('All-ok ARL and steady state size arrays must be of same size');
            end 
        elseif strcmpi(varargin(2*(i - 1) + 1), 'CUSUMParameterK')
            CUSUM_parameter_k = varargin{2*i};
            
            CUSUM_opt_k_flag = false;
            
            if isstring(CUSUM_parameter_k)
                if strcmpi(CUSUM_parameter_k, 'Optimal')
                    CUSUM_parameter_k = 0.5*delta;
                    CUSUM_opt_k_flag = true;
                end
            end
        elseif strcmpi(varargin(2*(i - 1) + 1), 'RestartFlag')
            restart_flag = varargin{2*i};
        elseif strcmpi(varargin(2*(i - 1) + 1), 'ChartName') || strcmpi(varargin(2*(i - 1) + 1), 'All_ok_ARL') || strcmpi(varargin(2*(i - 1) + 1), 'ShiftSize')
        else
            error(['Wrong input argument name. ', ...
            	   'Only ''ChartName'', ''alpha'', ''SimulationSize'', ''All_ok_ARL'', ', ...
                   '''TruncationTimePeriod'', ''SteadyStateSize'', ''ShiftSize'', ''CUSUMParameterK'', ''TSNoBreakTestStartTimePeriod'' or ''RestartFlag'' are admissible.']);
        end
    end
    
    if (max(steady_state_size) > 0)
        BENCHMARK_TYPE_TXT = 'steady.state.size=';
        
        for i = 1:length(steady_state_size)
            BENCHMARK_TYPE_TXT = [BENCHMARK_TYPE_TXT num2str(steady_state_size(i))];

            if (i < length(steady_state_size))
                BENCHMARK_TYPE_TXT = [BENCHMARK_TYPE_TXT ','];
            end

            if (steady_state_size(i) > 0)
                BENCHMARK_TYPE_MAT{i} = ['steady.state.size=' num2str(steady_state_size(i))];
            else
                BENCHMARK_TYPE_MAT{i} = 'initial.state';
            end  
        end  
    else
        BENCHMARK_TYPE_TXT = 'initial.state';
        
        for i = 1:length(steady_state_size)
            BENCHMARK_TYPE_MAT{i} = 'initial.state';
        end
    end
    
    %% Prepare, save and display quantiles
    CURRENT_PATHS = path; 
    addpath '../lib/';
    value_func1 = [];
    value_func2 = [];
    
    if (restart_flag)
        restart_mask = '.restart';
    else
        restart_mask = '';
    end
    
    if strcmpi(chart_name, 'TS')
        PROTOCOL_OUTPUT_PATH = ['../output/out.of.control.performance/TS.', BENCHMARK_TYPE_TXT, '.performance.protocol.alpha=', num2str(alpha, '%6.4f'), restart_mask, '.txt'];
    elseif strcmpi(chart_name, 'CUSUM') || strcmpi(chart_name, 'CUSUMHeadstart')
        if (CUSUM_opt_k_flag)
            PROTOCOL_OUTPUT_PATH = ['../output/out.of.control.performance/', chart_name, '.', BENCHMARK_TYPE_TXT, '.performance.protocol.k=optimal', restart_mask, '.txt'];
        else
            PROTOCOL_OUTPUT_PATH = ['../output/out.of.control.performance/', chart_name, '.', BENCHMARK_TYPE_TXT, '.performance.protocol.k=', num2str(CUSUM_parameter_k, '%6.4f'), restart_mask, '.txt'];
        end
    elseif strcmpi(chart_name, 'ShewhartX')
        PROTOCOL_OUTPUT_PATH = ['../output/out.of.control.performance/ShewhartX.', BENCHMARK_TYPE_TXT, '.performance.protocol', restart_mask, '.txt'];
    end
    
    if exist(PROTOCOL_OUTPUT_PATH)
        delete(PROTOCOL_OUTPUT_PATH);  
    end
    fileID = fopen(PROTOCOL_OUTPUT_PATH, 'w');
    fclose(fileID);
    
    diary(PROTOCOL_OUTPUT_PATH);    
    diary on;

    SCREEN_WIDTH = 113 + 32;
    
    for k = 1:length(all_ok_ARL)
        tic;
        
        if (restart_flag)
            PERFORMANCE_TABLE = zeros(length(delta), 9);
        else
            PERFORMANCE_TABLE = zeros(length(delta), 7);
        end
        
        display(repmat('%', 2, SCREEN_WIDTH));
        
        if strcmpi(chart_name, 'CUSUMHeadstart')
            string = ['CUSUM Headstart Chart'];
        elseif strcmpi(chart_name, 'ShewhartX')
            string = ['Shewhart X Chart'];
        else
            string = [chart_name, ' Chart'];
        end
    
        if (steady_state_size(k) > 0)
            string = [string, ' Steady State'];
        else
            string = [string, ' Initial State'];
        end
    
        display([repmat('%', 1, 10) repmat(' ', 1, SCREEN_WIDTH - 20) repmat('%', 1, 10)]);
        display([repmat('%', 1, 10), repmat(' ', 1, ceil((SCREEN_WIDTH - 20 - length(string))/2)), string, repmat(' ', 1, floor((SCREEN_WIDTH - 20 - length(string))/2)), repmat('%', 1, 10)]);
        display([repmat('%', 1, 10) repmat(' ', 1, SCREEN_WIDTH - 20) repmat('%', 1, 10)]);
        display(repmat('%', 1, SCREEN_WIDTH));
        
        string = ['All-ok ARL                      = ', num2str(all_ok_ARL(k))];
        display([repmat('%', 1, 10) repmat(' ', 1, 10) string repmat(' ', 1, SCREEN_WIDTH - length(string) - 30) repmat('%', 1, 10)]);
        
        if strcmpi(chart_name, 'TS')
            string = ['alpha                           = ', num2str(alpha)];
            display([repmat('%', 1, 10) repmat(' ', 1, 10) string repmat(' ', 1, SCREEN_WIDTH - length(string) - 30) repmat('%', 1, 10)]);
        end
        
        if strcmpi(chart_name, 'CUSUM') || strcmpi(chart_name, 'CUSUMHeadstart')
            if (CUSUM_opt_k_flag)
                string = ['Parameter k                     = optimal'];
            else
                string = ['Parameter k                     = ', num2str(CUSUM_parameter_k)];
            end
            display([repmat('%', 1, 10) repmat(' ', 1, 10) string repmat(' ', 1, SCREEN_WIDTH - length(string) - 30) repmat('%', 1, 10)]);
        end
        
        if (steady_state_size(k) > 0)
            string = ['Steady state size               = ', num2str(steady_state_size(k))];
            display([repmat('%', 1, 10) repmat(' ', 1, 10) string repmat(' ', 1, SCREEN_WIDTH - length(string) - 30) repmat('%', 1, 10)]);
        end
        
        if strcmpi(chart_name, 'CUSUM') || strcmpi(chart_name, 'CUSUMHeadStart')
            if (CUSUM_opt_k_flag)
                string = ['Control limit                   = depends on delta'];
            else
                string = ['Control limit                   = ', num2str(control_limit(k))];
            end
        else
            string = ['Control limit                   = ', num2str(control_limit(k))];
        end
        
        display([repmat('%', 1, 10) repmat(' ', 1, 10) string repmat(' ', 1, SCREEN_WIDTH - length(string) - 30) repmat('%', 1, 10)]);
        
        string = ['Simulation size N               = ', num2str(N), ' reps'];
        display([repmat('%', 1, 10) repmat(' ', 1, 10) string repmat(' ', 1, SCREEN_WIDTH - length(string) - 30) repmat('%', 1, 10)]);
        string = ['Truncation time period n        = ', num2str(n)];
        display([repmat('%', 1, 10) repmat(' ', 1, 10) string repmat(' ', 1, SCREEN_WIDTH - length(string) - 30) repmat('%', 1, 10)]);   
            
        if strcmpi(chart_name, 'TS')
            string = ['TS break test start time period = ', num2str(break_test_cutoff)];
            display([repmat('%', 1, 10) repmat(' ', 1, 10) string repmat(' ', 1, SCREEN_WIDTH - length(string) - 30) repmat('%', 1, 10)]);
        end
        
        display(repmat('%', 1, SCREEN_WIDTH));
        
        string = ['|      delta    ', ...
                  '|       ARL     ', ...
                  '|     std RL    ', ...
                  '|     std ARL   ', ...
                  '|  tail. prob.  ', ...
                  '|cond.viol.prob.', ...
                  '|% streams used ', ...
                  '| av. restart # ', ...
                  '| restart # std |'];
                  
        display(['', string]);
        display(repmat('-', 1, SCREEN_WIDTH));
        
        for i = 1:length(delta)
            if strcmpi(chart_name, 'TS')
                [ARL, stdRL, stdARL, tail_prob, cond_viol_prob, fraction_streams_used, av_restart_cnt, std_restart_cnt] = ...
                                        getARLetc('TS', alpha, N, n, break_test_cutoff, delta(i), control_limit(k), steady_state_size(k), restart_flag);
            elseif strcmpi(chart_name, 'CUSUM') || strcmpi(chart_name, 'CUSUMHeadstart')
                if (CUSUM_opt_k_flag)         
                    [ARL, stdRL, stdARL, tail_prob, cond_viol_prob, fraction_streams_used, av_restart_cnt, std_restart_cnt] = ...
                                        getARLetc(chart_name, CUSUM_parameter_k(i), N, n, [], delta(i), control_limit(i, k), steady_state_size(k), restart_flag);
                else
                    [ARL, stdRL, stdARL, tail_prob, cond_viol_prob, fraction_streams_used, av_restart_cnt, std_restart_cnt] = ...
                                        getARLetc(chart_name, CUSUM_parameter_k, N, n, [], delta(i), control_limit(k), steady_state_size(k), restart_flag);
                end
            elseif strcmpi(chart_name, 'CUSUM') || strcmpi(chart_name, 'ShewhartX')
                [ARL, stdRL, stdARL, tail_prob, cond_viol_prob, fraction_streams_used, av_restart_cnt, std_restart_cnt] = ...
                                        getARLetc('ShewhartX', [], N, n, [], delta(i), control_limit(k), steady_state_size(k), restart_flag);
            end

            if (restart_flag)
                PERFORMANCE_TABLE(i, :) = [delta(i) ARL stdRL stdARL tail_prob cond_viol_prob 100*fraction_streams_used av_restart_cnt std_restart_cnt];
            else
                PERFORMANCE_TABLE(i, :) = [delta(i) ARL stdRL stdARL tail_prob cond_viol_prob 100*fraction_streams_used];
            end
                
            string = ['|  ', num2str(delta(i), '%011.4f'), '  ', ...
                      '|  ', num2str(ARL, '%011.4f'), '  ', ...
                      '|  ', num2str(stdRL, '%011.4f'), '  ', ...
                      '|  ', num2str(stdARL, '%011.4f'), '  ', ...
                      '|  ', num2str(tail_prob, '%011.4f'), '  ', ...
                      '|  ', num2str(cond_viol_prob, '%011.4f'), '  ', ...
                      '|  ', num2str(100*fraction_streams_used, '%011.4f'), '  ', ...
                      '|  ', num2str(av_restart_cnt, '%011.4f'), '  ', ...
                      '|  ', num2str(std_restart_cnt, '%011.4f'), '  |'];
                 
            display(['', string]);
        end       
        
        if strcmpi(chart_name, 'TS')
            OUTPUT_PATH = ['../output/out.of.control.performance/TS.', BENCHMARK_TYPE_MAT{k}, '.performance.protocol.alpha=', num2str(alpha, '%6.4f'), '.all-ok.ARL=', num2str(all_ok_ARL(k)), restart_mask, '.mat'];
        elseif strcmpi(chart_name, 'CUSUM') || strcmpi(chart_name, 'CUSUMHeadstart')
            if (CUSUM_opt_k_flag)
                OUTPUT_PATH = ['../output/out.of.control.performance/', chart_name, '.', BENCHMARK_TYPE_MAT{k}, '.performance.protocol.k=optimal.all-ok.ARL=', num2str(all_ok_ARL(k)), restart_mask, '.mat'];
            else
                OUTPUT_PATH = ['../output/out.of.control.performance/', chart_name, '.', BENCHMARK_TYPE_MAT{k}, '.performance.protocol.k=', num2str(CUSUM_parameter_k, '%6.4f'), '.all-ok.ARL=', num2str(all_ok_ARL(k)), restart_mask, '.mat'];
            end
        elseif strcmpi(chart_name, 'ShewhartX')
            OUTPUT_PATH = ['../output/out.of.control.performance/ShewhartX.', BENCHMARK_TYPE_MAT{k}, '.performance.protocol.all-ok.ARL=', num2str(all_ok_ARL(k)), restart_mask, '.mat'];
        end
        
        save(OUTPUT_PATH, 'PERFORMANCE_TABLE', '-mat');
    end
    
    display(repmat('%', 2, SCREEN_WIDTH));
    
    toc;
    
    diary off;
    clear diary;
    
    path(CURRENT_PATHS);
end

function [ARL, stdRL, stdARL, tail_prob, cond_viol_prob, fraction_streams_used, av_restart_cnt, std_restart_cnt] = getARLetc(chart_name, alpha_or_k, N, n, n0, delta, control_limit, steady_state_size, restart_flag)
    alpha = alpha_or_k;

    if strcmpi(chart_name, 'TS')
        HJB_value_functions;
    end
    
%     %% Theoretic values, uncomment to use
%     elseif strcmpi(chart_name, 'ShewhartX')
%         p = normcdf(control_limit - delta) - normcdf(-control_limit - delta);
%         
%         ARL   = 1/(1 - p);
%         stdRL = sqrt(p/((1 - p)^2));
%         
%         stdARL                = 0;
%         tail_prob             = 0;
%         cond_viol_prob        = 0; 
%         fraction_streams_used = 1; % since no memory effect
%         
%         return;
%     end
    
    m = 1;
    t = n/m;

    ARL  = 0;
    ASRL = 0;

    CNT      = 0;
    TAIL_CNT = 0;
    VIOL_CNT = 0;
    
    AV_RESTART_CNT    = 0;
    AV_SQ_RESTART_CNT = 0;

    parfor i = 1:N
        if (restart_flag)     
            restart_cnt = 0;
        end
        
        x = [];

        stopped = 0;

        if strcmpi(chart_name, 'CUSUM') || strcmpi(chart_name, 'CUSUMHeadstart')
            k_par = alpha_or_k;

            if (strcmpi(chart_name, 'CUSUMHeadstart'))
                L = -control_limit/2;
                U =  control_limit/2;
            else
                L = 0;
                U = 0;
            end

            if (steady_state_size > 0)
                for m = 1:steady_state_size
                    x = randn(1);

                    U = max([0 (x - k_par) + U]);
                    L = min([0 (x + k_par) + L]);

                    stopped = (U > control_limit) | (L < -control_limit) | stopped;

                    if (stopped)
                        if (restart_flag)
                            restart_cnt = restart_cnt + 1;

                            if (strcmpi(chart_name, 'CUSUMHeadstart'))
                                L = -control_limit/2;
                                U =  control_limit/2;
                            else
                                L = 0;
                                U = 0;
                            end

                            continue;
                        else
                            break;
                        end
                    end
                end
            end
        elseif strcmpi(chart_name, 'ShewhartX')
            if (steady_state_size > 0)
                for m = 1:steady_state_size
                    x = randn(1);

                    stopped = (abs(x) >= control_limit) | stopped;

                    if (stopped)
                        if (restart_flag)
                            restart_cnt = restart_cnt + 1;

                            continue;
                        else
                            break;
                        end
                    end
                end
            end
        elseif strcmpi(chart_name, 'TS')
            alpha = alpha_or_k;

            if (steady_state_size > 0)
                for m = 1:steady_state_size
                    x = [x; randn(1)];

                    sig = TSChartSingleStep(x, 0, 1, alpha);

                    stopped = (sig > control_limit) | stopped;

                    if (stopped)
                        if (restart_flag)
                            restart_cnt = restart_cnt + 1;

                            x = [];
                            continue;
                        else
                            break;
                        end
                    end
                end
            end
        end

        if (restart_flag)
            AV_RESTART_CNT    = AV_RESTART_CNT    + restart_cnt/N;
            AV_SQ_RESTART_CNT = AV_SQ_RESTART_CNT + restart_cnt^2/(N - 1);
        end

        if ((restart_flag) || (~restart_flag && ~stopped))
            CNT = CNT + 1;

            RL  = 0;

            if strcmpi(chart_name, 'TS')
                TS_broke = 0;
            end

            for k = (steady_state_size + 1):n
                if strcmpi(chart_name, 'TS')
                    x  = [x; delta + randn(1)];

                    [sig, TV] = TSChartSingleStep(x, 0, 1, alpha);

                    RL = RL + (1 - stopped);

                    if ~isempty(n0)
                        if (k >= n0)
                            TS_broke = TS_broke || ((TV*k^0.5) > 1E-4);
                        end
                    end

                    stopped = (sig > control_limit) | stopped;

                    if (k == n)
                        TAIL_CNT = TAIL_CNT + 1;

                        if (~stopped)
                            if (~TS_broke)
                                ARL  = ARL +  (n   + m*  value_func1(t, m^(0.5 - alpha)*sig, m^(0.5 - alpha)*control_limit));
                                ASRL = ASRL + (n^2 + m^2*value_func2(t, m^(0.5 - alpha)*sig, m^(0.5 - alpha)*control_limit));
                            else
                                VIOL_CNT = VIOL_CNT + 1;
                            end

                            break;
                        end
                    end
                elseif strcmpi(chart_name, 'CUSUM') || strcmpi(chart_name, 'CUSUMHeadstart')
                    x = delta + randn(1);

                    U = max([0 (x - k_par) + U]);
                    L = min([0 (x + k_par) + L]);

                    RL  = RL + (1 - stopped);

                    stopped = (U > control_limit) | (L < -control_limit) | stopped;

                    if (k == n)
                        TAIL_CNT = TAIL_CNT + 1;
                        RL = n;
                    end
                elseif strcmpi(chart_name, 'ShewhartX')
                    x = delta + randn(1);

                    RL  = RL + (1 - stopped);

                    stopped = (abs(x) >= control_limit) | stopped;

                    if (k == n)
                        TAIL_CNT = TAIL_CNT + 1;
                        RL = n;
                    end
                end

                if (stopped)
                    ARL  = ARL  + RL;
                    ASRL = ASRL + RL^2;

                    break;
                end
            end
        end
    end

    ARL = ARL/CNT;
    VRL = ASRL/(CNT - 1) - CNT*ARL^2/(CNT - 1);

    stdRL = sqrt(VRL);
    stdARL = stdRL/sqrt(CNT); 
    
    tail_prob = TAIL_CNT/N;
    cond_viol_prob = VIOL_CNT/(TAIL_CNT + (TAIL_CNT == 0));
    fraction_streams_used = CNT/N;
    
    if (restart_flag)
        av_restart_cnt  = AV_RESTART_CNT;
        std_restart_cnt = sqrt(AV_SQ_RESTART_CNT - N*av_restart_cnt^2/(N - 1));
    else
        av_restart_cnt  = 0;
        std_restart_cnt = 0;
    end
end

function flag = isstring(S)
	flag = logical(ischar(S) && ndims(S) == 2 && any(size(S) <= 1));
end
