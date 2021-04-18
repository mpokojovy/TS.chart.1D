function TS_quantile = get_TS_init_state_RL_quantile(alpha, all_ok_ARL, p_value, conservative_flag)
% PURPOSE: TS_quantile = get_TS_init_state_RL_quantile(alpha, all_ok_ARL, p_value, ...
%                                                      conservative_flag)
% --------------------------------------------------------------------------------------------------
% CALL:  TS_quantile = get_TS_init_state_RL_quantile(alpha, all_ok_ARL, p_value, conservative_flag)
% Input:
%    alpha ............... DOUBLE(1, 1) TS chart exponent alpha (3/4, 2/3, 5/8 and 3/5)
%    all_ok_ARL .......... DOUBLE(1, K) array of preselected all-ok ARLs, for which the all-ok
%                          statistics are directly displayed, e.g., all_ok_ARL = [100 370 750]
%    p_value ............. DOUBLE(L, 1) array of p-values
%    conservative_flag ... BOOL(1, 1) If true, a "conservative" control limit (i.e., the one
%                          corresponding to all-ok ARL + 3 std ARL, otherwise is used, otherwise, 
%                          the control limit for the nomimal all-ok ARL
% Output:
%    TS_quantile ... TS chart run length quantile(s)
%
% Description:
%    Return TS chart all-ok run length quantile(s)
%
% Copyright: Michael Pokojovy and J. Marcus (2020)  

    TS_quantile = [];
    
    if size(p_value, 2) > size(p_value, 1)
        p_value = p_value';
    end
    
    for i = 1:length(all_ok_ARL)
        INPUT_PATH = ['../output/quantiles/RL.quantiles.alpha=', num2str(alpha, '%6.4f'), '.all-ok.ARL=', num2str(all_ok_ARL(i)), '.mat'];
        
        if ~exist(INPUT_PATH)
            ERROR_MESSAGE = ['The file ../quantiles/output/RL.quantiles.alpha=', num2str(alpha, '%6.4f'), '.all-ok.ARL=', num2str(all_ok_ARL(i)), '.mat', ' does not exist. Please run util/precompute_quantiles.m first.'];
            error(ERROR_MESSAGE);
        else
            load(INPUT_PATH);
           
            if (QUANTILES_CONSERVATIVE_FLAG ~= conservative_flag)
                WARNING_MESSAGE = ['The conservative_flag value differs from the precomputed one. Computing quantile with conservative_flag = ', num2str(QUANTILES_CONSERVATIVE_FLAG), ...
                                   ' Please re-run precompute_quantiles.m if another option is desired.'];
            	warning(WARNING_MESSAGE);
            end
            
            TS_quantile = [TS_quantile quantile(RUN_LENGTH_QUANTILES, p_value)];
        end
    end
end
