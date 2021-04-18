function regplot(y, lambda)
% PURPOSE: Computes and plots the taut string estimator (including the taut string and function
%          tube around the cumulative process)
% --------------------------------------------------------------------------------------------------
% CALL:  regplot(y, lambda)
% Input:
%    y ........ DOUBLE(n, 1) data vector of n data values
%    lambda ... DOUBLE(1, 1) function tube radius
% Description:
%    Performs the taut string regression, plots the original data stream, the associated taut string
%    estimator, the function tube around the cumulative process and the taut string through the tube
%
% Copyright: Michael Pokojovy and J. Marcus Jobe (2020)    

    set(gcf, 'PaperUnits', 'centimeters');
    xSize = 26; ySize = 12;
    xLeft = (21 - xSize)/2; yTop = (30 - ySize)/2;
    set(gcf,'PaperPosition', [xLeft yTop xSize ySize]);
    set(gcf,'Position',[0 0 xSize*50 ySize*50]);

    N = size(y, 1);
    
    x = linspace(1, N, N)'/N;
    x0 = [0; x];
    
    cy = [0; 1/N*cumsum(y)];
    
    cyl = cy - lambda; 
    cyl(1) = 0; 
    cyl(end) = cy(end);
    
    cyu = cy + lambda; 
    cyu(1) = 0; 
    cyu(end) = cy(end);
    
    [index, cyr] = TautString(x0, cyl, cyu);
    
    yr = zeros(N, 1);
    
    for i = 1:length(index)-1
        I = index(i):min(index(i+1), N);
        yr(I) = (cyr(i+1) - cyr(i))/(x0(index(i+1)) - x0(index(i)));
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    subplot_tight(1, 2, 1, [0.08 0.05]);
    hold on;
    xlabel('$t$', 'interpreter', 'latex', 'FontSize', 18);
    ylabel('$y(t)$', 'interpreter', 'latex', 'FontSize', 18);
    plot(x, y, 'o', 'Color', [0    0.4470    0.7410]);
    
    T = 1;
    YR = yr(1);
    
    for i = 2:N
        T  = [T; i; i];
        YR = [YR; yr(i-1); yr(i)];
    end
    
    T  = [T; N];
    YR = [YR; yr(end)];
    
    plot(T/N, YR, '-', 'LineWidth', 2, 'Color', [0.8500    0.3250    0.0980]);
    
    mY = min(min(x), min(YR));
    MY = max(max(x), max(YR));
    
    axis([min(T/N) max(T/N) 0.5*(mY + MY) - 1.5*(MY - mY) 0.5*(mY + MY) + 1.5*(MY - mY)]);
    
    legend({'Scaled process data $y_{n}(t)$', 'Taut string estimator $\hat{\mu}_{n}(t)$ of $\mu(t)$'}, ...
            'Location', 'Best', 'interpreter', 'latex', 'FontSize', 18);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    subplot_tight(1, 2, 2, [0.08 0.05]);
    hold on;
    xlabel('$t$', 'interpreter', 'latex', 'FontSize', 18);
    ylabel('$y^{\circ}(t)$', 'interpreter', 'latex', 'FontSize', 18);
    
    X = []; Y = [];
	for i = 1:length(index)-1
        X = [X x0(index(i)) x0(index(i+1))];
        Y = [Y cyr(i) cyr(i+1)];
    end
    plot(X, Y, '.-', 'LineWidth', 2, 'Color', [0.8500    0.3250    0.0980]);
    
    axis([0 1 -0.65 0.1]);
    
    plot([0; x], cy - lambda, '-', 'LineWidth', 0.5, 'Color', [0    0.4470    0.7410]);
    plot([0; x], cy + lambda, '-', 'LineWidth', 0.5, 'Color', [0    0.4470    0.7410]);
    plot([0 1], [cyl(1) cyl(end)], '*', 'LineWidth', 2, 'Color', [0.8500    0.3250    0.0980]);
    
    legend({'Taut string $s_{n}^{\ast}(t)$', 'Functional tube $B(y_{n}^{\circ}(t), \lambda_{n})$'}, ...
           'Location', 'Best', 'interpreter', 'latex', 'FontSize', 18);      
end