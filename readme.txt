%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%           Univariate Fast Initial Response Statistical Process Control with Taut Strings            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

This Matlab package implements the taut string SPC methododology by Michael Pokojovy and J. Marcus Jobe
introduced in their original publication "Univariate Fast Initial Response Statistical Process Control 
with Taut Strings"

Instructions:

A) Examples and demonstrations: TS chart and taut string estimator
  Run the following program:
  TS_chart_example.m

B) Evaluate out-of-control performance of the TS, CUSUM, CUSUM head start and Shewhart X charts
  Run evaluate_chart_performance.m (Note that the program will use precomputed control limits, etc.)

C) Compute TS chart control limits, run length standard deviation values, etc.
  Run TS_all_ok_simulation.m
  This will recompute TS control limits and other relevant statistics, which will can have a
  (marginal) impact on the out-of-control situation in B)

  Warning: The simulation is very time consuming! The full scale simulation (i.e., of size 1000000
  streams of length 10000) is very time  and space consuming. Carried out on a single machine
  (Dell (TM) PowerEdge (TM) 410 with Intel (R) Xeon (R) E5520 processor), it takes up to 30 full
  days and produces around 90 Gb output.


Copyright: Michael Pokojovy and J. Marcus Jobe (2020)
See license.txt for license conditions
