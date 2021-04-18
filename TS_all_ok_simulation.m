%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            COMPLETE IN-CONTROL SIMULATION FOR TS CHART                           %
%                                                                                                  %
% Computes important TS statistics in the all-ok scenario in the following three steps:            %
% # 1: precompute taut strings for a set of all-ok data streams and record their total variation   %
%      absolute initial jump values                                                                %
% # 2: Compute control limits, run length std, ARL std, etc. based on these precomputed streams    %
% # 3: Compute run length quantiles for selected all-ok ARL values                                 %
%                                                                                                  %
% Warning: The full scale simulation (i.e., of size 1000000 streams of length 10000) is very time  %
% and space consuming. Carried out on a single machine (Dell (TM) PowerEdge (TM) 410 with          %
% Intel (R) Xeon (R) E5520 processor), it takes up to 30 full days and produces around 90 Gb       %
% output. Because of this prohibitive size, the complete output data is not provided here, rather  % 
% only control limits, etc. generated from it. The complete set of simulated taut string total     %
% variation and absolute initial jump values are available upon request.                           %
%                                                                                                  %
% Copyright: Michael Pokojovy and J. Marcus Jobe (2020)                                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

cd 'util/';

%% Precompute taut string total variation and absolute initial jump values for a set of all-ok streams
SEEDS = 1:100;   % Seed for the random number generator. 
N     = 10000;   % Number of streams per seed

n = 10000;      % Length of any single stream

% Warning! Very time and space consuming! See util/precompute_TS_streams.m for details.
% If possible, run on many computers in parallel.

poolobj = parpool('local', 'AttachedFiles', {'../bin/TSChartSingleStep.m'});

precompute_TS_streams(SEEDS, N, n);

delete(poolobj);

%% Compute and save control limits and other relevant statistics
all_ok_ARL   = [100 370 750]; % all-ok ARL short list for a brief report
tail_cut_off = floor(n*0.75); % time period to start the taut string no-break violation test

for alpha = [3/5 5/8 2/3 3/4 1]
     compute_TS_statistics(alpha, all_ok_ARL, tail_cut_off);
end

%% Compute and save TS run length quantiles
conservative_flag = 1; % Use control limits for all-ok ARL + 3 std ARL

for alpha = [3/5 5/8 2/3 3/4 1]  % Replace with [3/5 5/8 2/3 3/4] to include all alpha's
    compute_TS_quantiles(alpha, all_ok_ARL, conservative_flag);
end

cd '../';