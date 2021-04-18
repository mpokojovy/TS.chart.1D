function [index,z] = TautString(x,y_low,y_upp);
% [index,z] = TautString(x,y_low,y_upp);
% computes the knots of a "taut string".
% This is an auxilary program for smoothing in regression 
% and density estimation.
% 
% Input:
% - x : a vector with components
%       x(1) < x(2) < ... < x(n) ,
% - y_low, y_upp : two vectors of the same size as x, where
%    y_low(1) = y_upp(1) ,
%    y_low(n) = y_upp(n) ,
%    y_low(i) <= y_upp(i) for i=2,3,...,n-1 .
% 
% The "taut string" is a piecewise linear function F on [x(1), x(n)] 
% such that the length of its graph is minimal under the constraint 
%    y_low(x(i))  <=  F(x(i))  <=  y_upp(x(i))
% for 1 <= i <= n. Let the knots of its graph (endpoints and kinks) be
%    (x(index(i)), z(i)), 1 <= i <= length(index),
% where 1 = index(1) < index(2) < ... < index(end) = n.
% The output consists of these two row vectors index and z.
% 
% In order to see what this algorithm does, just run the 
% program TautStringDemo.m without input arguments.
% 
% Source:
% - P.L. Davies and A. Kovac (2001).
%   Local Extremes, runs, strings and multiresolution (with discussion). 
%   Annals of Statistics 29, 1-65
% 
% Lutz Duembgen, April 3, 2002

n = length(x);

% Initialize lower string:
index_low =  ones(1,n);
slope_low = zeros(1,n);
s_low = 1;
c_low = 1;
slope_low(1) = inf;

% Initialize upper string:
index_upp =  ones(1,n);
slope_upp = zeros(1,n);
s_upp = 1;
c_upp = 1;
slope_upp(1) = -inf;

% Initialize taut string
index = ones(1,n);
z = zeros(1,n);
z(1) = y_low(1);
c = 1;

for j=2:n
	% append new knot, {j}, to list index_low:
	c_low = c_low+1;
	index_low(c_low) = j;
	slope_low(c_low) = (y_low(j) - y_low(j-1)) / (x(j) - x(j-1));
	% check slope_low for antitonicity:
	while c_low > s_low + 1 ...
	      & slope_low(max(s_low,c_low-1)) <= slope_low(c_low)
		% ("pool adjacent violators") 
		% knot number c_low-1 is removed:
		c_low = c_low-1;
		index_low(c_low) = j;
		if c_low > s_low+1
			slope_low(c_low) = ...
				(y_low(j) - y_low(index_low(c_low-1))) ...
					/ (x(j) - x(index_low(c_low-1)));
		else
			slope_low(c_low) = ...
				(y_low(j) - z(c)) / (x(j) - x(index(c)));
		end
	end
	
	% append new knot, {j}, to list index_upp:
	c_upp = c_upp+1;
	index_upp(c_upp) = j;
	slope_upp(c_upp) = (y_upp(j) - y_upp(j-1)) / (x(j) - x(j-1));
	% check slope_upp for isotonicity:
	while c_upp > s_upp + 1 ...
		& slope_upp(max(c_upp-1,s_upp)) >= slope_upp(c_upp)
		% ("pool adjacent violators") 
		% knot number c_upp-1 is removed:
		c_upp = c_upp-1;
		index_upp(c_upp) = j;
		if c_upp > s_upp + 1
			slope_upp(c_upp) = ...
				(y_upp(j) - y_upp(index_upp(c_upp-1))) ...
					/ (x(j) - x(index_upp(c_upp-1)));
		else
			slope_upp(c_upp) = ...
				(y_upp(j) - z(c)) / (x(j) - x(index(c)));
		end
	end
	
	% check whether slope_low(s_low+1) <= slope_upp(s_upp+1):
	while c_low == s_low+1 & c_upp > s_upp+1 ...
	      & slope_low(c_low) >= slope_upp(s_upp+1)
		% Remove first knot of upper string:
		s_upp = s_upp+1;
		% Add a knot to the taut string:
		c = c+1;
		index(c) = index_upp(s_upp);
		z(c) = y_upp(index(c));
		% Shift first knot of the lower string
		index_low(s_low) = index(c);
		slope_low(c_low) = (y_low(j) - z(c)) ...
			/ (x(j) - x(index(c)));
	end
	while c_upp == s_upp+1 & c_low > s_low+1 ...
	      & slope_upp(c_upp) <= slope_low(s_low+1)
		% Remove first knot of the lower string:
		s_low = s_low+1;
		% Add a knot to the taut string:
		c = c+1;
		index(c) = index_low(s_low);
		z(c) = y_low(index(c));
		% Shift first knot of the upper string
		index_upp(s_upp) = index(c);
		slope_upp(c_upp) = (y_upp(j) - z(c)) ...
			/ (x(j) - x(index(c)));
	end
end

% Augment taut string by lower (or upper) string:
index(c+1:c+c_low-s_low) = index_low(s_low+1:c_low);
z(c+1:c+c_low-s_low) = y_low(index_low(s_low+1:c_low));
% Remove superfluous components:
c = c + c_low-s_low;
index = index(1:c);
z = z(1:c);
return
