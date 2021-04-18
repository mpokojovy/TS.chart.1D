function compute_TS_quantiles(alpha, all_ok_ARL, conservative_flag)
% PURPOSE: computes TS all-ok run length quantiles
% --------------------------------------------------------------------------------------------------
% CALL:  compute_TS_quantiles(alpha, all_ok_ARL, conservative_flag)
% Input:
%    alpha ................... DOUBLE(1, 1) TS chart exponent alpha (3/4, 2/3, 5/8, 3/5 and 1)
%    ALL_OK_ARL .............. DOUBLE(1, K) array of preselected all-ok ARLs, for which the all-ok
%                              statistics are directly displayed, e.g., ALL_OK_ARL = [100 370 750]
%    conservative_flag ....... BOOL(1, 1) If true, use a "conservative" control limit (i.e., the one
%                              corresponding to all-ok ARL + 3 std ARL, otherwise, use the control
%                              limit for the nomimal all-ok ARL
% Output:
%    Saved to ../output/quantiles/:
%
%    RUN_LENGTH_QUANTILES .......... DOUBLE(1, 10000) all-run length quantiles for p-values from 
%                                    linspace(0, 1, 10000)
%    QUANTILES_CONSERVATIVE_FLAG ... = conservative_flag
%    CONTROL_LIMIT_GRID .... DOUBLE(1, 2000) array of control limits (values depend on alpha)
%    ALL_OK_ARL_GRID ....... DOUBLE(1, 2000) array of associated all-ok ARLs
%    ALL_OK_VRL_GRID ....... DOUBLE(1, 2000) array of associated all-ok run length variances
%    TAIL_PROB_GRID ........ DOUBLE(1, 2000) array of associated probabilities of reaching the end
%                            of the truncated stream of length n0
%    VIOLATION_PROB_GRID ... DOUBLE(1, 2000) array of associated probabilities of reaching the end
%                            of the truncated stream and violated the taut string no-break test 
%                            between TAIL_CUT_OFF_FRACTION*n0, ..., n0
% 
%    Saved to ../FLAGS.ini:
%
%    PRECOMPUTED_CONTROL_LIMITS_FLAG ... = true
%
% Description:
%    For a set of precomputed all-ok data streams and precomputed control limits, compute selected
%    all-ok run length quantiles. Matlab parallelization via parfor is used. If your Matlab version 
%    does not support parallelization, replace all occurrences of parfor with the regular for operator.
%
% Copyright: Michael Pokojovy and J. Marcus Jobe (2020)   

    %% Load up precomputed data streams
    if ~exist('../FLAGS.ini')
        INIT_ERROR_MESSAGE = 'The main directory does not contain the FLAGS.ini file. Please run util/precompute_streams.m first.';
        
        error(INIT_ERROR_MESSAGE);
    else
        load('../FLAGS.ini', '-mat');
        
        if ~exist('PRECOMPUTED_STREAMS_FLAG')
            INIT_ERROR_MESSAGE = 'The main directory does not contain the FLAGS.ini file. Please run util/precompute_streams.m first.';

            error(INIT_ERROR_MESSAGE);
        else
            if (PRECOMPUTED_STREAMS_FLAG == 0)
                INIT_ERROR_MESSAGE = 'Precomputed streams do not exist in the precomp.streams directory. Please run util/precompute_streams.m first.';

                error(INIT_ERROR_MESSAGE);
            end
        end
    end
    
    SEEDS = PRECOMPUTED_STREAMS_SEEDS;
    n     = PRECOMPUTED_STREAMS_LENGTH;
    N     = PRECOMPUTED_STREAMS_COUNT_PER_DATA_CHUNK;
    
    ALL_OK_SIMULATION_SIZE = length(SEEDS)*N;
    TAIL_CUT_OFF = floor(n*0.75);
    
    %% Load up precomputed control limits    
    if isempty(find(abs([3/4 2/3 5/8 3/5 1] - alpha) < 1E-4))
        ERROR_MESSAGE = 'Parameter alpha needs to be 3/4, 2/3, 5/8, 3/5 or 1';
        error(ERROR_MESSAGE);
    end
    
    if (min(all_ok_ARL) < 10) || (max(all_ok_ARL) > 3000)
        ERROR_MESSAGE = 'all_ok_ARL needs to be between 10 and 3000';
        error(ERROR_MESSAGE);
    end
    
    INPUT_PATH = ['../output/control.limits/control.limits.alpha=', num2str(alpha, '%6.4f'), '.mat'];
    
    if ~exist(INPUT_PATH)
        ERROR_MESSAGE = ['The file control.limits.alpha=', num2str(alpha, '%6.4f'), '.mat does not exist. Please run compute_TS_statistics.m first.'];
    else
        load(INPUT_PATH);
    end
  
    stdRL          = sqrt(interp1(ALL_OK_ARL_GRID, ALL_OK_VRL_GRID, all_ok_ARL, 'linear'));
    stdARL         = stdRL/sqrt(ALL_OK_SIMULATION_SIZE);
    
    if (conservative_flag)
        CONTROL_LIMITS = interp1(ALL_OK_ARL_GRID, CONTROL_LIMIT_GRID, all_ok_ARL + 3*stdARL, 'linear');
    else
        CONTROL_LIMITS = interp1(ALL_OK_ARL_GRID, CONTROL_LIMIT_GRID, all_ok_ARL,            'linear');
    end
    
    poolobj = gcp;
    addAttachedFiles(poolobj, {'../lib/HJB_value_functions.m'})
    updateAttachedFiles(poolobj);
    
    %% Load up the HJB functions
    value_func1 = [];
    value_func2 = [];
    run('../lib/HJB_value_functions.m');
    
    % Initialize parameters for the asymptotic run length expectation computation
    m = 1;
    t = n/m;
    
    RUN_LENGTHS = zeros(ALL_OK_SIMULATION_SIZE, length(all_ok_ARL));
    
    %% Compute RL distribution
    tic;
    
    for DATA_CHUNK_IND = 1:length(SEEDS)
        precomp_streams = 0;
        
        display(['Data chunk: ', num2str(DATA_CHUNK_IND), ' out of ', num2str(length(SEEDS))]);
        
        seed = SEEDS(DATA_CHUNK_IND);
        
        PATH = ['../precomp.streams/precomp.streams.', num2str(seed - 1, '%04d') '.mat'];
        load(PATH);
        
        TIME_GRID        = 1:n;
        TIME_GRID_SCALED = TIME_GRID.^0.5;
        
        RUN_LENGTHS_TMP = zeros(N, length(all_ok_ARL));
        
        for j = 1:length(all_ok_ARL)
            parfor i = 1:N            
                SIGNALS = (sum(precomp_streams(i, :, 1:2), 3)).*(TIME_GRID.^alpha);
            
                IND = n;

                for k = 1:n
                    if (SIGNALS(k) > CONTROL_LIMITS(j))
                        IND = k;
                        break;
                    end
                end
                
                RUN_LENGTHS_TMP(i, j) = IND;

                if (IND == n) && (SIGNALS(n) < CONTROL_LIMITS(j))
                    MAX_BREAK = max(precomp_streams(i, TAIL_CUT_OFF:n, 1).*TIME_GRID_SCALED(TAIL_CUT_OFF:n));
                        
                    if (MAX_BREAK <= 1E-4)
                    	RUN_LENGTHS_TMP(i, j) = n + m*value_func1(t, m^(0.5 - alpha)*SIGNALS(n), m^(0.5 - alpha)*CONTROL_LIMITS(j))/ALL_OK_SIMULATION_SIZE;
                    end
                end                    
            end                            
        end
        
        RUN_LENGTHS(((DATA_CHUNK_IND - 1)*N + 1):DATA_CHUNK_IND*N, :) = RUN_LENGTHS_TMP;
    end
    
    delete(poolobj);
    
    %% Prepare, save and display quantiles
    PROTOCOL_OUTPUT_PATH = ['../output/quantiles/RL.quantiles.protocol.alpha=', num2str(alpha, '%6.4f'), '.txt'];
    if exist(PROTOCOL_OUTPUT_PATH)
        delete(PROTOCOL_OUTPUT_PATH);  
    end
    fileID = fopen(PROTOCOL_OUTPUT_PATH, 'w');
    fclose(fileID);
    
    diary(PROTOCOL_OUTPUT_PATH);    
    diary on;
    
    display(['%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%']);
    display(['%%%%%                                All-okay TS run length quantiles                                   %%%%']);
    display(['%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%']);
    display(['alpha                                          = ', num2str(alpha,                  '%08.6f')]);
    display(['Data stream count (N)                          = ', num2str(ALL_OK_SIMULATION_SIZE, '%08d')]);    
    display(['Data stream length/truncation time period (n0) = ', num2str(TAIL_CUT_OFF,           '%08d')]);
    display(' ');
    
    for j = 1:length(all_ok_ARL)
        OUTPUT_PATH = ['../output/quantiles/RL.quantiles.alpha=', num2str(alpha, '%6.4f'), '.all-ok.ARL=', num2str(all_ok_ARL(j)), '.mat'];
        
        RUN_LENGTH_QUANTILES_GRID_SIZE = 10000;
        RUN_LENGTH_QUANTILES           = quantile(RUN_LENGTHS(:, j), linspace(0, 1, RUN_LENGTH_QUANTILES_GRID_SIZE)');
        
        QUANTILES_CONSERVATIVE_FLAG    = conservative_flag;
        
        save(OUTPUT_PATH, 'RUN_LENGTH_QUANTILES', 'QUANTILES_CONSERVATIVE_FLAG', '-mat');
        
        display(['------------------------------------------------------------------------------------------------------------']);
        display(['All-ok ARL = ', num2str(all_ok_ARL(j))]);
        display(['------------------------------------------------------------------------------------------------------------']);
        for k = 1:99
            display([num2str(k, '%03.0f'),'th percentile: ', num2str(quantile(RUN_LENGTH_QUANTILES, k/100), '%08.2f')]);
        end
    end
    
    display(['%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%']);
    
    toc;
    
    diary off;
    clear diary;
    
    cd '../util/';
end