%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                           PLOT OF HAMILTON-JACOBI-BELLMAN VALUE FUNCTIONS                        %
%                                                                                                  %
% For given TS parameter alpha, the program plots                                                  %
%                                                                                                  % 
% # 1: in Figure 1 the value functions V_1(10000, x; R) and V_2(10000, x; R), which quantify the   %
% 1st and 2nd conditional moments of the all-ok run length of the TS chart with the control limit  %
% R = 3 past the 10000th time period given the TS signal at 10000 is x.                            %
%                                                                                                  %
% #2: in Figure 2 polynomial approximations of V_1(10000, x; R) and V_2(10000, x; R) over a range  %
% of x and R. Respective equations are written in the command window.                              %
%                                                                                                  %
% Copyright: Michael Pokojovy and J. Marcus Jobe (2020)                                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

display(['\section{Value Functions $V_{1}$ and $V_{2}$}']);

% Select TS parameter alpha from 3/4, 2/3, 5/8, 3/5, 1
for alpha = [3/5 5/8 2/3 3/4 1/1]
    display(['\subsection{TS $\alpha = ' num2str(alpha, '%6.2f') '$}']);
    
    % Load up the value functions
    cd '../lib';
    HJB_value_functions;

    fig1 = figure(1);
    clf;

    grid on;

    set(gcf, 'PaperUnits', 'centimeters');
    xSize = 34; ySize = 12;
    xLeft = (21 - xSize)/2; yTop = (30 - ySize)/2;
    set(gcf,'PaperPosition', [xLeft yTop xSize ySize]);
    set(gcf,'Position', [0 0 xSize*50 ySize*50]);

    R = 3;
    t = 10000;

    x_grid = linspace(-R, R, 1000);

    %%
    subplot_tight(1, 2, 1, [0.175 0.10]);
    hold on;
    grid on;
    plot(x_grid, value_func1(t, x_grid, R), 'LineWidth', 2, 'Color', [0    0.4470    0.7410]);

    xlabel('$x$', 'interpreter', 'latex', 'FontSize', 18);
    ylabel(['$V_{1}(', num2str(t), ', x; ', num2str(R, '%6.1f'), ')$ for $\alpha = ' num2str(alpha, '%6.2f') '$'], 'interpreter', 'latex', 'FontSize', 18);

    axis([-R R 0 max(value_func1(t, x_grid, R))*1.1]);

    %%
    subplot_tight(1, 2, 2, [0.175 0.10]);
    hold on;
    grid on;
    plot(x_grid, value_func2(t, x_grid, R), 'LineWidth', 2, 'Color', [0    0.4470    0.7410]);

    xlabel('$x$', 'interpreter', 'latex', 'FontSize', 18);
    ylabel(['$V_{2}(', num2str(t), ', x; ', num2str(R, '%6.1f'), ')$ for $\alpha = ' num2str(alpha, '%6.2f') '$'], 'interpreter', 'latex', 'FontSize', 18);

    axis([-R R 0 max(value_func2(t, x_grid, R))*1.1]);

    %%
    n = 10000;

    fig2 = figure(2);
    clf;

    set(gcf, 'PaperUnits', 'centimeters');
    xSize = 34; ySize = 12;
    xLeft = (21 - xSize)/2; yTop = (30 - ySize)/2;
    set(gcf,'PaperPosition', [xLeft yTop xSize ySize]);
    set(gcf,'Position', [0 0 xSize*50 ySize*50]);

    %% p = 1
    %subplot_tight(1, 2, 1, [0.125 0.075]);
    subplot_tight(1, 2, 1, [0.075 0.10]);

    R = 1.4 + rand(n, 1)*(3 - 1.4);

    x = R;
    F = R;

    for i = 1:n
        x(i) = (rand(1) - 0.5)*2*R(i);
        F(i) = value_func1(t, x(i), R(i));
    end

    sf = fit([R, x], F, 'poly52');

    %plot(sf, [R, x], F); hold on;

    R_array       = linspace(1.4, 3.0, 30);
    x_scale_array = linspace(-1, 1, 30);

    R = zeros(length(R_array));
    x = zeros(length(R_array));
    V = zeros(length(R_array));

    for i = 1:30
    for j = 1:30
        R(i, j) = R_array(i);
        x(i, j) = R_array(i)*x_scale_array(j);
        V(i, j) = feval(sf, R(i, j), x(i, j));
    end
    end

    surf(R, x, V);
    axis([min(R(:)) max(R(:)) min(x(:)) max(x(:)) min(V(:)) max(V(:))]);
    view([-75 47]);

    xlabel('$R$', 'interpreter', 'latex', 'FontSize', 18);
    ylabel('$x$', 'interpreter', 'latex', 'FontSize', 18);
    zlabel(['$V_{1}(', num2str(t), ', x; R)$ for $\alpha = ' num2str(alpha, '%6.2f') '$'], 'interpreter', 'latex', 'FontSize', 18);

    %% p = 2
    %subplot_tight(1, 2, 2, [0.125 0.075]);
    subplot_tight(1, 2, 2, [0.075 0.10]);

    R = 1.4 + rand(n, 1)*(3 - 1.4);

    x = R;
    F = R;

    for i = 1:n
        x(i) = (rand(1) - 0.5)*2*R(i);
        F(i) = value_func2(t, x(i), R(i));
    end

    sf = fit([R, x], F, 'poly52');

    %plot(sf, [R, x], F); hold on;

    R_array       = linspace(1.4, 3.0, 30);
    x_scale_array = linspace(-1, 1, 30);

    R = zeros(length(R_array));
    x = zeros(length(R_array));
    V = zeros(length(R_array));

    for i = 1:30
    for j = 1:30
        R(i, j) = R_array(i);
        x(i, j) = R_array(i)*x_scale_array(j);
        V(i, j) = feval(sf, R(i, j), x(i, j));
    end
    end

    surf(R, x, V);
    axis([min(R(:)) max(R(:)) min(x(:)) max(x(:)) min(V(:)) max(V(:))]);
    view([-75 47]);

    xlabel('$R$', 'interpreter', 'latex', 'FontSize', 18);
    ylabel('$x$', 'interpreter', 'latex', 'FontSize', 18);
    zlabel(['$V_{2}(', num2str(t), ', x; R)$ for $\alpha = ' num2str(alpha, '%6.2f') '$'], 'interpreter', 'latex', 'FontSize', 18);
    
    %%
    cd '../examples/';
    
    %%
    file_name1 = ['HJB.2D.alpha=' num2str(alpha, '%6.2f')];
    set(gcf, 'renderer', 'painters');
    print(fig1, '-depsc', [file_name1 '.eps']);
    
    file_name2 = ['HJB.3D.alpha=' num2str(alpha, '%6.2f')];
    set(gcf, 'renderer', 'painters');
    print(fig2, '-depsc', [file_name2 '.eps']);
    
    %%
    display(['\begin{figure}[H]']);
	display(['	\centering']);
    display(['	\includegraphics[scale = 0.45]{fig/{' file_name1 '}.eps}']);
    display(['	\caption{\small Approximation of the value functions $V_{p}(', num2str(t), ', x; 3.0)$, $p = 1, 2$.}']);
    display(['\end{figure}']);
    display([' ']);
    
    display(['\begin{figure}[H]']);
	display(['	\centering']);
    display(['	\includegraphics[scale = 0.45]{fig/{' file_name2 '}.eps}']);
    display(['	\caption{\small Approximation of the value function $V_{p}(', num2str(t), ', x; R)$, $p = 1, 2$.}']);
    display(['\end{figure}']);
    display([' ']);
    
    %%
    sgn = ' +';

    display(['Value functions for $\alpha = ' num2str(alpha, '%6.2f') '$: {\small']);
    display('\begin{align}\begin{split}');
    display(['V_{1}(' num2str(t) ' , x; R) &\approx ', num2str(sf.p00, '%6.2f'), ' ', ...
             sgn((sf.p10 > 0) + 1), num2str(sf.p10, '%6.2f'), ' R ', ... 
             sgn((sf.p01 > 0) + 1), num2str(sf.p01, '%6.2f'), ' x ', ...
             sgn((sf.p20 > 0) + 1), num2str(sf.p20, '%6.2f'), ' R^2 ', ...
             sgn((sf.p11 > 0) + 1), num2str(sf.p11, '%6.2f'), ' Rx \\ ']);
    display([' & ', ...
             sgn((sf.p02 > 0) + 1), num2str(sf.p02, '%6.2f'), ' x^2 ', ...
             sgn((sf.p30 > 0) + 1), num2str(sf.p30, '%6.2f'), ' R^3 ', ...
             sgn((sf.p21 > 0) + 1), num2str(sf.p21, '%6.2f'), ' R^2 x ', ...
             sgn((sf.p12 > 0) + 1), num2str(sf.p12, '%6.2f'), ' R x^2 ', ...
             sgn((sf.p40 > 0) + 1), num2str(sf.p40, '%6.2f'), ' R^4 \\ ']);
    display([' & ', ...
             sgn((sf.p31 > 0) + 1), num2str(sf.p31, '%6.2f'), ' R^3 x ', ...
             sgn((sf.p22 > 0) + 1), num2str(sf.p22, '%6.2f'), ' R^2 x^2 ', ...
             sgn((sf.p50 > 0) + 1), num2str(sf.p50, '%6.2f'), ' R^5 ', ...
             sgn((sf.p41 > 0) + 1), num2str(sf.p41, '%6.2f'), ' R^4 x ', ...
             sgn((sf.p32 > 0) + 1), num2str(sf.p32, '%6.2f'), ' R^3 x^2, \\']);         
    display(['V_{2}(' num2str(t) ' , x; R) &\approx ', num2str(sf.p00, '%6.2f'), ' ', ...
             sgn((sf.p10 > 0) + 1), num2str(sf.p10, '%6.2f'), ' R ', ... 
             sgn((sf.p01 > 0) + 1), num2str(sf.p01, '%6.2f'), ' x ', ...
             sgn((sf.p20 > 0) + 1), num2str(sf.p20, '%6.2f'), ' R^2 ', ...
             sgn((sf.p11 > 0) + 1), num2str(sf.p11, '%6.2f'), ' Rx \\ ']);
    display([' & ', ...
             sgn((sf.p02 > 0) + 1), num2str(sf.p02, '%6.2f'), ' x^2 ', ...
             sgn((sf.p30 > 0) + 1), num2str(sf.p30, '%6.2f'), ' R^3 ', ...
             sgn((sf.p21 > 0) + 1), num2str(sf.p21, '%6.2f'), ' R^2 x ', ...
             sgn((sf.p12 > 0) + 1), num2str(sf.p12, '%6.2f'), ' R x^2 ', ...
             sgn((sf.p40 > 0) + 1), num2str(sf.p40, '%6.2f'), ' R^4 \\ ']);
    display([' & ', ...
             sgn((sf.p31 > 0) + 1), num2str(sf.p31, '%6.2f'), ' R^3 x ', ...
             sgn((sf.p22 > 0) + 1), num2str(sf.p22, '%6.2f'), ' R^2 x^2 ', ...
             sgn((sf.p50 > 0) + 1), num2str(sf.p50, '%6.2f'), ' R^5 ', ...
             sgn((sf.p41 > 0) + 1), num2str(sf.p41, '%6.2f'), ' R^4 x ', ...
             sgn((sf.p32 > 0) + 1), num2str(sf.p32, '%6.2f'), ' R^3 x^2.']);
    display('\end{split}\end{align}}');
    display(' ');
end