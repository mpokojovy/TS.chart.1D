function precompute_TS_streams(SEEDS, N, n)
% PURPOSE: Precomputes total variation and absolute initial jump statistics for a set of iid
% standard normal data streams
% --------------------------------------------------------------------------------------------------
% CALL:  precompute_TS_streams(SEEDS, N, n)
% Input:
%    SEEDS ... INTEGER(K, 1) or INTEGER(1, K) of K seeds for the pseudorandom number generator
%    N ....... DOUBLE(1, 1) number of data streams per each seed in SEEDS
%    n ....... DOUBLE(1, 1) length of each data stream
% Output: 
%    Saved to ../precomp.streams/:
%
%    precomp_streams ............................ DOUBLE(N, n, 2) array of total variation and
%                                                 absolute initial jump values, one for each seed
%    
%    Saved to ../FLAGS.ini:
%
%    PRECOMPUTED_STREAMS_FLAG ................... = true   
%    PRECOMPUTED_STREAMS_SEEDS .................. = SEEDS
%    PRECOMPUTED_STREAMS_LENGTH ................. = n
%    PRECOMPUTED_STREAMS_COUNT_PER_DATA_CHUNK ... = N
% Description:
%    Generates length(SEEDS)*N streams of iid standard normal data, for each of the streams,
%    sequentially computes total variation and absolute initial jump of the taut string estimators
%    based on first k = 1, ..., N data values and saves the resulting output to ../precomp.streams/, 
%    which is later used to compute various TS statistics such as control limits, empirical 
%    TS all-ok run length PDF and CDF, etc.
%
%    Respective status flags and internal variables are saved to ../FLAGS.ini
%
%    For the "full simulation", SEED = 1:1000, N = 1000, n = 10000 correspond to a total of
%    1,000,000 data streams of length 10,000 each. Warning: The "full" simulation on a single
%    machine (Dell (TM) PowerEdge (TM) 410 with Intel (R) Xeon (R) E5520 processor)
%    takes about 25 full days and produces around 90 Gb output. Because of this prohibitive size,
%    this data is not provided here, rather only control limits, etc. generated from it. The
%    complete set of simulated taut string total variation and absolute initial jump values are
%    available upon request.
%
% Copyright: Michael Pokojovy and J. Marcus Jobe (2020)  

    tic;
    for k = 1:length(SEEDS)
        cd '../lib/';
        precomp_streams = precompute_chunk(N, n, SEEDS(k));
        cd '../precomp.streams/';
        
        save(['precomp.streams.' num2str(SEEDS(k) - 1, '%04d') '.mat'], 'precomp_streams');
    end
    toc
    
    PRECOMPUTED_STREAMS_FLAG                 = 1;
    PRECOMPUTED_STREAMS_SEEDS                = SEEDS;
    PRECOMPUTED_STREAMS_LENGTH               = n;
    PRECOMPUTED_STREAMS_COUNT_PER_DATA_CHUNK = N;

    save('../FLAGS.ini', ...
         'PRECOMPUTED_STREAMS_FLAG', 'PRECOMPUTED_STREAMS_SEEDS', 'PRECOMPUTED_STREAMS_LENGTH', ...
         'PRECOMPUTED_STREAMS_COUNT_PER_DATA_CHUNK', '-mat');
     
    cd '../util/';
end

function precomp_streams = precompute_chunk(N, n, seed)
    precomp_streams = zeros(N, n, 2);
    
    % setting-up the random number generator with seed = SEED(k)
    rng(seed);
    
    parfor i = 1:N
        x = randn(n, 1);
        
        precomp_stream = zeros(n, 2);

        display(['seed = ', num2str(seed), ', stream i = ', num2str(i), ' out of ', num2str(N)]);

        for j = 1:n
            mu    = 0;
            sigma = 1;
            alpha = 0;
            
            [TV, InitJmp] = TSChartSingleStep(x(1:j), mu, sigma, alpha);
            precomp_stream(j, 1) = TV;
            precomp_stream(j, 2) = InitJmp;
        end
        
        precomp_streams(i, :, :) = precomp_stream;
    end
    
    return;
end
