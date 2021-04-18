function statistic = get_TS_statistic(alpha, all_ok_ARL, statistic_type)
% PURPOSE: statistic = get_TS_statistic(alpha, all_ok_ARL, statistic_type)
% --------------------------------------------------------------------------------------------------
% CALL:  statistic = get_TS_statistic(alpha, all_ok_ARL, statistic_type)
% Input:
%    alpha ............ DOUBLE(1, 1) TS chart exponent alpha (3/4, 2/3, 5/8 and 3/5)
%    all_ok_ARL ....... DOUBLE(1, K) array of preselected all-ok ARLs, for which the all-ok
%                              statistics are directly displayed, e.g., all_ok_ARL = [100 370 750]
%    statistic_type ... STRING from the set
%                       'SimulationSize'
%                       'ControlLimit' 
%                       'ControlLimitConservative'
%                       'stdRL'
%                       'stdARL'                       
%                       'TailProb'
%                       'JointTailAndViolationProb'
%                       'ConditionalTailAndViolationProb'
% Output:
%    statistic ... depends on statistic_type:
%                  'SimulationSize' .................... total number of precomputed streams 
%                                                        (size of Monte-Carlo simulation)
%                  'ControlLimit' ...................... control limit for nomimal all-ok ARL
%                  'ControlLimitConservative' .......... control limit for all-ok ARL + 3 std ARL
%                  'stdRL' ............................. run length std for nominal all-ok ARL
%                  'stdARL' ............................ ARL std for nominal all-ok ARL                      
%                  'TailProb' .......................... estimated probability of reaching the end
%                                                        of the truncated stream w/o hitting the
%                                                        nominal control limit
%                  'JointTailAndViolationProb' ......... estimated probability of reaching the end
%                                                        of the truncated stream w/o hitting the
%                                                        nominal control limit and violating the
%                                                        taut string no-break test
%                  'ConditionalTailAndViolationProb' ... conditional probability of reaching the end
%                                                        of the truncated stream and violating the 
%                                                        taut no-break test
%
% Description:
%    Return a TS statistic of interest such as control limit, simulation size, all-ok run length
%    std, all-ok ARL std, tec.
%
% Copyright: Michael Pokojovy and J. Marcus Jobe (2020)  
    
    if isempty(find(abs([3/4 2/3 5/8 3/5 1] - alpha) < 1E-4))
        ERROR_MESSAGE = 'alpha needs to be 3/4, 2/3, 5/8, 3/5 or 1';
        error(ERROR_MESSAGE);
    end
    
    if (min(all_ok_ARL) < 10) || (max(all_ok_ARL) > 3000)
        ERROR_MESSAGE = 'all_ok_ARL needs to be between 10 and 3000';
        error(ERROR_MESSAGE);
    end
    
    INPUT_PATH = ['../output/control.limits/control.limits.alpha=', num2str(alpha, '%6.4f'), '.mat'];
    
    if ~exist(INPUT_PATH)
        ERROR_MESSAGE = ['The file control.limits.alpha=', num2str(alpha, '%6.4f'), '.mat does not exist. Please run compute_control_limits.m first.'];
        error(ERROR_MESSAGE);
    else
        load(INPUT_PATH);
    end
    
    switch lower(statistic_type)
        case lower('SimulationSize')
            statistic = ALL_OK_SIMULATION_SIZE;
        
        case lower('ControlLimit')
            statistic = interp1(ALL_OK_ARL_GRID, CONTROL_LIMIT_GRID, all_ok_ARL, 'linear');
            
        case lower('ControlLimitConservative')
            stdARL    = sqrt(interp1(ALL_OK_ARL_GRID, ALL_OK_VRL_GRID, all_ok_ARL, 'linear')/(ALL_OK_SIMULATION_SIZE));
            statistic = interp1(ALL_OK_ARL_GRID, CONTROL_LIMIT_GRID, all_ok_ARL + 3*stdARL, 'linear');
            
        case lower('stdRL')
            statistic = sqrt(interp1(ALL_OK_ARL_GRID, ALL_OK_VRL_GRID, all_ok_ARL, 'linear'));
            
        case lower('stdARL')
            statistic = sqrt(interp1(ALL_OK_ARL_GRID, ALL_OK_VRL_GRID, all_ok_ARL, 'linear')/(ALL_OK_SIMULATION_SIZE));
            
        case lower('TailProb')
            statistic = interp1(ALL_OK_ARL_GRID, TAIL_PROB_GRID, all_ok_ARL, 'linear');
            
        case lower('JointTailAndViolationProb')
            statistic = interp1(ALL_OK_ARL_GRID, VIOLATION_PROB_GRID, all_ok_ARL, 'linear');
            
        case lower('ConditionalTailAndViolationProb')
            PA     = interp1(ALL_OK_ARL_GRID, TAIL_PROB_GRID, all_ok_ARL, 'linear');
            PAandB = interp1(ALL_OK_ARL_GRID, VIOLATION_PROB_GRID, all_ok_ARL, 'linear');
            
            statistic = PAandB./(PA + (PA == 0));
            
        otherwise
            ERROR_MESSAGE = ['type needs to be ''SimulationSize'', ''ControlLimit'', ''ControlLimitConservative'', ''stdRL'', ''stdARL'', ', ...
                             '''TailProb'', ''JointTailAndViolationProb'' or ''ConditionalTailAndViolationProb'''];
            error(ERROR_MESSAGE);
    end
end