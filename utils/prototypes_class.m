function [OUT] = prototypes_class(DATA,PAR)

% --- Prototype-Based Classify Function ---
%
%   [OUT] = prototypes_class(DATA,PAR)
% 
%   Input:
%       DATA.
%           input = input matrix                  	[p x N]
%       PAR.
%           Cx = prototypes' attributes            	[p x Nk(1) x ... x Nk(Nd)]
%           Cy = prototypes' labels                 [Nc x Nk(1) x ... x Nk(Nd)]
%           K = number of nearest neighbors        	[cte]
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
%           y_h = classifier's output                       [Nc x N]
%           win = closest prototype to each sample          [1 x N]

%% INITIALIZATION

% Data Initialization
X = DATA.input;                 % Input matrix
[~,N] = size(X);                % Number of samples

% Get Hyperparameters

if(isfield(PAR,'K'))            % Number of nearest neighbors
    K = PAR.K;                      
else
    K = 1;
end

if(isfield(PAR,'knn_type'))
    knn_type = PAR.knn_type;
else
    knn_type = 1;
end

% Prototypes and its labels
Cx = PAR.Cx;                 	% Prototype attributes
Cy = PAR.Cy;                 	% Prototype labels

% Vectorize prototypes and labels
Cx = prototypes_vect(Cx);
Cy = prototypes_vect(Cy);

% Problem Initilization
[Nc,Nk] = size(Cy);             % Number of prototypes and classes

% Init outputs
y_h = -1*ones(Nc,N);            % One output for each sample
win = zeros(1,N);               % One closest prototype for each sample

%% ALGORITHM

if (K == 1),        % if it is a nearest neighbor case
    
    for i = 1:N,
        
        % Display classification iteration (for debug)
        if(mod(i,1000) == 0)
            display(i);
        end
        
        % Get test sample
        sample = X(:,i);
        
        % Get closest prototype and min distance from sample to each class
        d_min = -1*ones(Nc,1);
        d_min_all = -1;
        for k = 1:Nk(1),
            prot = Cx(:,k);                         % Get prototype
            [~,class] = max(Cy(:,k));               % Get prototype label
            d = vectors_dist(prot,sample,PAR);      % Calculate distance
            if(d_min(class) == -1 || d < d_min(class)),
                d_min(class) = d;
            end
            % Get closest prototype
            if(d_min_all == -1 || d < d_min_all),
                d_min_all = d;
                win(i) = k;
            end
        end
        
        % Fill output
        for class = 1:Nc,
            
            % Invert signal for second class in binary problems

            if(class == 2 && Nc == 2),
            	y_h(2,:) = -y_h(1,:);
                break;
            end
            
            % Calculate Class output for the sample
            
            % Get minimum distance from class
            dp = d_min(class);
            % no prototypes from this class
            if (dp == -1),
                y_h(class,i) = -1;
            else
                % get minimum distance from other classes
                dm = -1;        
                for j = 1:Nc,
                    if(j == class), % looking for other classes
                        continue;
                    elseif (d_min(j) == -1), % no prot from this class
                        continue;
                    elseif (dm == -1 || d_min(j) < dm),
                        dm = d_min(j);
                    end
                end
                if (dm == -1),  % no prototypes from other classes
                    y_h(class,i) = 1;
                else
                    y_h(class,i) = (dm - dp) / (dm + dp);
               end
            end
        end
        
    end
    
elseif (K > 1),    % if it is a knn case
    
    for i = 1:N,
        
        % Display classification iteration (for debug)
        if(mod(i,1000) == 0)
            display(i);
        end
        
        % Get test sample
        sample = X(:,i);
        
        % Measure distance from sample to each prototype
        Vdist = zeros(1,Nk);
        for k = 1:Nk,
            prot = Cx(:,k);
            Vdist(k) = vectors_dist(prot,sample,PAR);
        end
        
        % Sort distances and get nearest neighbors
        out = bubble_sort(Vdist,1);
        
        % Get closest prototype
        win(i) = out.ind(1);
        
        % Verify number of prototypes and neighbors
        if(Nk <= K),
            nearest_indexes = out.ind(1:Nk);
            number_of_nearest = Nk;
        else
            nearest_indexes = out.ind(1:K+1);
            number_of_nearest = K;
        end
        
        % Get labels of nearest neighbors
        lbls_near = Cy(:,nearest_indexes);
        
        if (knn_type == 1), % majority voting method
            
            % Compute votes
            votes = zeros(1,Nc);
            for k = 1:number_of_nearest,
                [~,class] = max(lbls_near(:,k));
                votes(class) = votes(class) + 1;
            end
            
            % Update class
            [~,class] = max(votes);
            y_h(class,i) = 1;

        else % weighted knn
            
            % Avoid weights of 0
            epsilon = 0.001;
            
            % Auxiliary output and weight
            y_aux = zeros(Nc,1);
            w_sum = 0;
            
            % Get distances of nearest neighbors
            Dnear = Vdist(nearest_indexes);
            
            % Calculate Output
            for k = 1:number_of_nearest,
                % Compute Weight
                if (knn_type == 2), % Triangular
                    Dnorm = Dnear(k)/(Dnear(end) + epsilon);
                    w = 1 - Dnorm;
                end
                w_sum = w_sum + w;
                % Compute weighted outptut
                y_aux = y_aux + w*lbls_near(:,k);

            end
            y_h(:,i) = y_aux / w_sum;
            
        end
        
    end
    
end

%% FILL OUTPUT STRUCTURE

OUT.y_h = y_h;
OUT.win = win;

%% END