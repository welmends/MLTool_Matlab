function [OUT] = k2nn_classify(DATA,PAR)

% --- Kernel KNN Prototype-Based Classify Function ---
%
%   [OUT] = k2nn_classify(DATA,PAR)
% 
%   Input:
%       DATA.
%           input = input matrix                    [p x N]
%       PAR.
%           Cx = prototypes' attributes             [p x Nk]
%           Cy = prototypes' labels                 [Nc x Nk]
%           K = number of nearest neighbors      	[cte]
%           dist = type of distance (if Ktype = 0) 	[cte]
%               0: Dot product
%               inf: Chebyshev distance
%               -inf: Minimum Minkowski distance
%               1: Manhattam (city-block) distance  
%               2: Euclidean distance
%           Ktype = kernel type ( see kernel_func() )           [cte]
%           sigma = kernel hyperparameter ( see kernel_func() ) [cte]
%           order = kernel hyperparameter ( see kernel_func() ) [cte]
%           alpha = kernel hyperparameter ( see kernel_func() ) [cte]
%           theta = kernel hyperparameter ( see kernel_func() ) [cte]
%           gamma = kernel hyperparameter ( see kernel_func() ) [cte]
%   Output:
%       OUT.
%           y_h = classifier's output               [Nc x N]

%% ALGORITHM

[OUT] = prototypes_class(DATA,PAR);

%% END