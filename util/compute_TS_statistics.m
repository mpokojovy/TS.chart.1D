function compute_TS_statistics(alpha, ALL_OK_ARL, TAIL_CUT_OFF)
% PURPOSE: computes TS all-ok ARLs, std RLs, control limits, etc.
% --------------------------------------------------------------------------------------------------
% CALL:  compute_TS_statistics(alpha, ALL_OK_ARL, TAIL_CUT_OFF)
% Input:
%    alpha .......... DOUBLE(1, 1) TS chart exponent alpha (3/4, 2/3, 5/8, 3/5 or 1)
%    ALL_OK_ARL ..... DOUBLE(1, K) array of preselected all-ok ARLs, for which the all-ok statistics 
%                     are directly displayed, e.g., ALL_OK_ARL = [100 370 750]
%    TAIL_CUT_OFF ... DOUBLE(1, 1) a number between 1 and the truncated stream length n0. Specifies 
%                     where the taut string no-break violation test is started. With n0 denoting the 
%                     length of a precomputed data stream in the all-ok simulation, each stream 
%                     whose signals do not hit the control limit at n0 or before, will be tested if 
%                     one of the taut strings based on the first TAIL_CUT_OFF, ..., n0 data values 
%                     has a least one jump. If no, the asymptotic HJB function will be used to
%                     compute the expected run length/squared run length.
% Output:
%    Saved to ../output/control.limits/:
%
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
%    For a set of precomputed all-ok data streams and a grid of control limits, computes the all-ok
%    ARL, the variance of RL, probability of reaching the end of the truncated stream as well as
%    probability of reaching the end of the truncated stream and violating the taut string no-break
%    test. Matlab parallelization via parfor is used. If your Matlab version does not support 
%    parallelization, replace all occurrences of parfor with the regular for operator.
%
% Copyright: Michael Pokojovy and J. Marcus Jobe (2020)   

    if ~exist('../FLAGS.ini')
        INIT_ERROR_MESSAGE = 'The main directory does not contain the FLAGS.ini file. Please run util/precompute_streams.m first.';
        
        error(INIT_ERROR_MESSAGE);
    else
        load('../FLAGS.ini', '-mat');
        
        if (PRECOMPUTED_STREAMS_FLAG == 0)
            INIT_ERROR_MESSAGE = 'Precomputed streams do not exist in the precomp.streams directory. Please run util/precompute_streams.m first.';
        
            error(INIT_ERROR_MESSAGE);
        end
    end
    
    % Load-up the HJB functions
    value_func1 = [];
    value_func2 = [];
    cd '../lib/';    
    HJB_value_functions;
    
    % Number of seeds
    SEEDS    = PRECOMPUTED_STREAMS_SEEDS;
    SEED_CNT = length(SEEDS);
    
    tic;
    
    OUTPUT_PATH = ['../output/control.limits/protocol.alpha=', num2str(alpha, '%6.4f'), '.txt'];
    if exist(OUTPUT_PATH)
        delete(OUTPUT_PATH);  
    end
    fileID = fopen(OUTPUT_PATH, 'w');
    fclose(fileID);
    
    diary(OUTPUT_PATH);    
    diary on;
    
    % Loading precomputed data specifications
    SEEDS = PRECOMPUTED_STREAMS_SEEDS;
    n     = PRECOMPUTED_STREAMS_LENGTH;
    N     = PRECOMPUTED_STREAMS_COUNT_PER_DATA_CHUNK;
    
    %%%
    poolobj = gcp;
    addAttachedFiles(poolobj, {'../lib/HJB_value_functions.m'})
    updateAttachedFiles(poolobj);
    
    % Initialize parameters for the asymptotic run length expectation computation
    m     = 1;
    t     = n/m;
    
    % Initialize the control limits grid
    GRID_SIZE = 2000;
    if (alpha == 1)
        CONTROL_LIMIT_GRID = linspace(3.00, 50.00, GRID_SIZE);
    elseif (alpha == 3/4)
        CONTROL_LIMIT_GRID = linspace(2.00, 9.20, GRID_SIZE);
    elseif (alpha == 2/3)
        CONTROL_LIMIT_GRID = linspace(1.70, 4.90, GRID_SIZE);
    elseif (alpha == 5/8)
        CONTROL_LIMIT_GRID = linspace(1.50, 3.60, GRID_SIZE);
    elseif (alpha == 3/5)
        CONTROL_LIMIT_GRID = linspace(1.40, 3.00, GRID_SIZE);
    end
        
    %% Initialize ARL and ASRL (average square RL) grids
    ALL_OK_ARL_GRID  = zeros(size(CONTROL_LIMIT_GRID));
    ALL_OK_ASRL_GRID = zeros(size(CONTROL_LIMIT_GRID));
    
    %% 
    TAIL_PROB_GRID      = zeros(size(CONTROL_LIMIT_GRID));
    VIOLATION_PROB_GRID = zeros(size(CONTROL_LIMIT_GRID));
    
    for seed = SEEDS
        precomp_streams = 0;
        
        PATH = ['../precomp.streams/precomp.streams.', num2str(seed - 1, '%04d') '.mat'];
        load(PATH);
        
        parfor i = 1:N
            TIME_GRID        = 1:n;
            TIME_GRID_SCALED = TIME_GRID.^0.5;
            
            SIGNALS = (sum(precomp_streams(i, :, 1:2), 3)).*(TIME_GRID.^alpha);
            
            ALL_OK_ARL_GRID_TEMP  = zeros(size(CONTROL_LIMIT_GRID));
            ALL_OK_ASRL_GRID_TEMP = zeros(size(CONTROL_LIMIT_GRID));
            
            TAIL_PROB_GRID_TEMP      = zeros(size(CONTROL_LIMIT_GRID));
            VIOLATION_PROB_GRID_TEMP = zeros(size(CONTROL_LIMIT_GRID));
            
            
            for j = 1:GRID_SIZE
                IND = n;

                for k = 1:n
                    if (SIGNALS(k) > CONTROL_LIMIT_GRID(j))
                        IND = k;
                        break;
                    end
                end

                if (IND < n)
                    ALL_OK_ARL_GRID_TEMP(j)  = ALL_OK_ARL_GRID_TEMP(j)  + IND/(SEED_CNT*N);
                    ALL_OK_ASRL_GRID_TEMP(j) = ALL_OK_ASRL_GRID_TEMP(j) + IND^2/(SEED_CNT*N);
                else
                    if (SIGNALS(n) < CONTROL_LIMIT_GRID(j))
                        TAIL_PROB_GRID_TEMP(j)      = TAIL_PROB_GRID_TEMP(j) + 1/(SEED_CNT*N);
                        
                        MAX_BREAK = max(precomp_streams(i, TAIL_CUT_OFF:n, 1).*TIME_GRID_SCALED(TAIL_CUT_OFF:n));
                        
                        if (MAX_BREAK <= 1E-4)
                            ALL_OK_ARL_GRID_TEMP(j)  = ALL_OK_ARL_GRID_TEMP(j)  + ...
                                                  (n   + m*  value_func1(t, m^(0.5 - alpha)*SIGNALS(n), m^(0.5 - alpha)*CONTROL_LIMIT_GRID(j)))/(SEED_CNT*N);
                                           
                            ALL_OK_ASRL_GRID_TEMP(j) = ALL_OK_ASRL_GRID_TEMP(j) + ...
                                                  (n^2 + m^2*value_func2(t, m^(0.5 - alpha)*SIGNALS(n), m^(0.5 - alpha)*CONTROL_LIMIT_GRID(j)))/(SEED_CNT*N);
                        else
                            ALL_OK_ARL_GRID_TEMP(j)  = ALL_OK_ARL_GRID_TEMP(j)  + n/(SEED_CNT*N);
                            ALL_OK_ASRL_GRID_TEMP(j) = ALL_OK_ASRL_GRID_TEMP(j) + n^2/(SEED_CNT*N);
                            
                            VIOLATION_PROB_GRID_TEMP(j) = VIOLATION_PROB_GRID_TEMP(j) + 1/(SEED_CNT*N);
                        end
                    end
                end            
            end

            ALL_OK_ARL_GRID  = ALL_OK_ARL_GRID + ALL_OK_ARL_GRID_TEMP;
            ALL_OK_ASRL_GRID = ALL_OK_ASRL_GRID + ALL_OK_ASRL_GRID_TEMP;
            
            TAIL_PROB_GRID      = TAIL_PROB_GRID + TAIL_PROB_GRID_TEMP;
            VIOLATION_PROB_GRID = VIOLATION_PROB_GRID + VIOLATION_PROB_GRID_TEMP;
        end
    end
    
    delete(poolobj);
    
    ALL_OK_VRL_GRID = (SEED_CNT*N)/(SEED_CNT*N - 1)*ALL_OK_ASRL_GRID - (SEED_CNT*N)/(SEED_CNT*N - 1)*ALL_OK_ARL_GRID.^2;
    
    [ALL_OK_ARL_GRID, IND] = unique(ALL_OK_ARL_GRID);
    ALL_OK_VRL_GRID        = ALL_OK_VRL_GRID(IND);
    CONTROL_LIMIT_GRID     = CONTROL_LIMIT_GRID(IND);
    TAIL_PROB_GRID         = TAIL_PROB_GRID(IND);
    VIOLATION_PROB_GRID    = VIOLATION_PROB_GRID(IND);
    
    ALL_OK_SIMULATION_SIZE     =      SEED_CNT*N;
    CONTROL_LIMIT              =      interp1(ALL_OK_ARL_GRID, CONTROL_LIMIT_GRID, ALL_OK_ARL, 'linear');
    ALL_OK_STDRL               = sqrt(interp1(ALL_OK_ARL_GRID, ALL_OK_VRL_GRID,   ALL_OK_ARL, 'linear'));
    CONTROL_LIMIT_CONSERVATIVE =      interp1(ALL_OK_ARL_GRID, CONTROL_LIMIT_GRID, ALL_OK_ARL + 3*ALL_OK_STDRL/sqrt(SEED_CNT*N), 'linear');
    TAIL_PROB                  =      interp1(ALL_OK_ARL_GRID, TAIL_PROB_GRID, ALL_OK_ARL, 'linear');
    VIOLATION_PROB             =      interp1(ALL_OK_ARL_GRID, VIOLATION_PROB_GRID, ALL_OK_ARL, 'linear');
    
    %% Display summary statistics for selected ALL_OK_ARL values
    display(['%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%']);
    display(['%%%%%                                       All-okay simulation                                         %%%%']);
    display(['%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%']);
    display(['alpha                                          = ', num2str(alpha,      '%08.6f')]);
    display(['Data stream count (N)                          = ', num2str(SEED_CNT*N, '%08d')]);
    display(['Data stream length/truncation time period (n0) = ', num2str(n,          '%08d')]);
    display(['------------------------------------------------------------------------------------------------------------']);
    display(['All-ok ARL                                                         ', num2str(ALL_OK_ARL,                          '%011.5f    ')]);
    display(['All-ok std RL                                                      ', num2str(ALL_OK_STDRL,                        '%011.5f    ')]);
    display(['All-ok std RL/sqrt(N)                                              ', num2str(ALL_OK_STDRL/sqrt(SEED_CNT*N),       '%011.5f    ')]);
    display(['Control limits for respective all-ok ARL                           ', num2str(CONTROL_LIMIT,                       '%011.5f    ')]);
    display(['Control limits for all-ok ARL + 3*std RL/sqrt(N)                   ', num2str(CONTROL_LIMIT_CONSERVATIVE,          '%011.5f    ')]);
    display(['------------------------------------------------------------------------------------------------------------']);
    display(['Time period cut-off value (n1) for testing if TS breaks            ', num2str(ones(size(ALL_OK_ARL))*TAIL_CUT_OFF, '%011.5f    ')]);
    display(['Probability of reaching the truncation point n0                    ', num2str(TAIL_PROB,                           '%011.5f    ')]);
    display(['Probability of violating the TS no-break test between n1 and n0    ', num2str(VIOLATION_PROB,                      '%011.5f    ')]);
    display(['%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%']);
    
    toc;
    
    diary off;
    clear diary;
    
    %% Write output
    OUTPUT_PATH = ['../output/control.limits/control.limits.alpha=', num2str(alpha, '%6.4f'), '.mat'];
    save(OUTPUT_PATH, 'ALL_OK_SIMULATION_SIZE', 'ALL_OK_ARL_GRID', 'ALL_OK_VRL_GRID', 'CONTROL_LIMIT_GRID', 'TAIL_PROB_GRID', 'VIOLATION_PROB_GRID', '-mat');
    
    %% Update FLAGS.ini
    PRECOMPUTED_CONTROL_LIMITS_FLAG = 1;
    save('../FLAGS.ini', 'PRECOMPUTED_CONTROL_LIMITS_FLAG', '-mat', '-append');
    
    cd('../util/');
end