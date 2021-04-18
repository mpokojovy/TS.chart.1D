%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                          LAKE ERIE EXAMPLE                                       %
%                                                                                                  %
% For the Lake Erie dataset, the program plots                                                     %
% # 1: the dataset with the sample mean subtracted                                                 %
% # 2: the taut string estimator applied to this transformed dataset                               %
% # 3: the cumulative process and the taut string through a tube around the cumulative process     %
%                                                                                                  %
% Source: DataMarket, Qlik (R)                                                                     %
%         https://datamarket.com/data/set/22pw/monthly-lake-erie-levels-1921-1970                  %
%                                                                                                  %
% CONTAINS: 600 univariate Lake Erie levels monthly measured over 1921--1970                       %
%                                                                                                  %
% Copyright: Michael Pokojovy and J. Marcus Jobe (2020)                                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

run 'datasets/dataset_lake_erie.m';

x = x - mean(x);

n = size(x, 1);

sigma = 1.48/sqrt(2)*median(abs(x(2:end) - x(1:end-1)));

T = linspace(0, 1, n)';

plot(T, x, 'o');

h = max(1.149, 0.8*sqrt(2*log(log(max(n, 3)))))*sqrt(1/n)*sigma;

cd '../lib/';
regplot(x, h);
cd '../examples'/;