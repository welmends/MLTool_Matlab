function [accuracy] = cross_valid(DATA,HP,CVp,f_train,f_class)

% --- Cross Validation Function ---
%
%   [accuracy] = cross_valid(DATA,HP,CVp,f_train,f_class)
%
%   Input:
%       DATA.
%           input = Matrix of training attributes             	[p x N]
%           output = Matrix of training labels                 	[Nc x N]
%       HP = set of HyperParameters to be tested
%       CVp.
%           fold = number of partitions                      	[cte]
%       f_train = handler for classifier's training function
%       f_class = handler for classifier's classification function       
%   Output:
%       accuracy = mean accuracy for data set and parameters

%% INIT

X = DATA.input;     	% Attributes Matrix [p x N]
Y = DATA.output;     	% labels Matriz [Nc x N]

[~,N] = size(X);      	% Number of samples

Nfold = CVp.fold;     	% Number of folds
part = floor(N/Nfold); 	% Size of each data partition

accuracy = 0;          	% Init accurary

%% ALGORITHM

for fold = 1:Nfold;

    % Define Data division

    if fold == 1,
        DATAtr.input  = X(:,part+1:end);
        DATAtr.output = Y(:,part+1:end);
        DATAts.input  = X(:,1:part);
        DATAts.output = Y(:,1:part);
    elseif fold == Nfold,
        DATAtr.input  = X(:,1:(Nfold-1)*part);
        DATAtr.output = Y(:,1:(Nfold-1)*part);
        DATAts.input  = X(:,(Nfold-1)*part+1:end);
        DATAts.output = Y(:,(Nfold-1)*part+1:end);
    else
        DATAtr.input  = [X(:,1:(fold-1)*part) X(:,fold*part+1:end)];
        DATAtr.output = [Y(:,1:(fold-1)*part) Y(:,fold*part+1:end)];
        DATAts.input  = X(:,(fold-1)*part+1:fold*part);
        DATAts.output = Y(:,(fold-1)*part+1:fold*part);
    end

    % Training of classifier
    [PAR] = f_train(DATAtr,HP);

    % Test of classifier
    [OUT] = f_class(DATAts,PAR);

    % Statistics of Classifier
    [STATS_ts] = class_stats_1turn(DATAts,OUT);

    % Accumulate Accuracy rate
    accuracy = accuracy + STATS_ts.acc;

end

accuracy = accuracy/CVp.fold;

%% END