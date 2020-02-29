function [Dout] = k2nn_dict_prun(Din,PAR)

% --- Sparsification Procedure for Dictionary Pruning ---
%
%   [Dout] = k2nn_dict_prun(xt,yt,Din,PAR)
%
%   Input:
%       Din.
%           x = Attributes of input dictionary                  [p x Nk]
%           y = Classes of input dictionary                     [Nc x Nk]
%           Km = Kernel matrix of dictionary                    [Nk x Nk]
%           Kinv = Inverse Kernel matrix of dicitionary         [Nk x Nk]
%           score = used for prunning method                    [1 x Nk]
%       PAR.
%           Dm = Design Method                                  [cte]
%               = 1 -> all data set
%               = 2 -> per class
%           Ss = Sparsification strategy                        [cte]
%               = 1 -> ALD
%               = 2 -> Coherence
%               = 3 -> Novelty
%               = 4 -> Surprise
%           Ps = Prunning strategy                              [cte]
%               = 0 -> do not remove prototypes
%               = 1 -> score-based method
%           min_score = score that leads to prune prototype     [cte]
%   Output: 
%       Dout.
%           x = Attributes of output dictionary                 [p x Nk]
%           y = Classes of  output dictionary                   [Nc x Nk]
%           Km = Kernel matrix of dictionary                    [Nk x Nk]
%           Kinv = Inverse Kernel matrix of dicitionary         [Nk x Nk]
%           score = score of each prototype from dictionary     [1 x Nk]

%% INITIALIZATIONS

% Get dictionary
Dx = Din.x;         % Attributes of dictionary
Dy = Din.y;         % Classes of dictionary
Km = Din.Km;        % Dictionary Kernel Matrix
Kinv = Din.Kinv;    % Dictionary Inverse Kernel Matrix
score = Din.score;  % Score of each prototype from dictionary

% Get Hyperparameters
Dm = PAR.Dm;                % Design Method
Ss = PAR.Ss;                % Sparsification strategy
Ps = PAR.Ps;                % Pruning Strategy
min_score = PAR.min_score;  % Score that leads the prototype to be pruned

% Get problem parameters
[~,m] = size(Dx);   % hold dictionary size

%% 1 DICTIONARY FOR ALL DATA SET

if(Dm == 1),
    
    if (Ps == 0),
        
        % Does nothing
        
    elseif (Ps == 1),
        
        [~,Dy_seq] = max(Dy);	% get sequential label of dictionary
        
        for k = 1:m,
            
            % class of prototype
            c = Dy_seq(k);

            % number of elements from the same class as the prototypes'
            mc = sum(Dy_seq == c);
            
            % dont rem element if it is the only element of its class
            if (mc == 1),
                continue;
            end
            
            % Remove element
            if (score(k) < min_score),
                
                % Remove Prototype and its score
                Dx(:,k) = [];
                Dy(:,k) = [];
                score(k) = [];
                
                % If ALD or Surprise method, update kernel matrix
                if (Ss == 1 || Ss == 4),
                    % Remove line and column from inverse kernel matrix
                    ep = zeros(m,1);
                    ep(k) = 1;
                    u = Km(:,k) - ep;
                    eq = zeros(m,1);
                    eq(k) = 1;
                    v = eq;
                    Kinv = Kinv + (Kinv * u)*(v' * Kinv) / ...
                               (1 - v' * Kinv * u);
                    Kinv(k,:) = [];
                    Kinv(:,k) = [];
                    % Remove line and column from kernel matrix
                    Km(k,:) = [];
                    Km(:,k) = [];
                end
                
                % Just remove one prototype per loop
                break;
                
            end
        end
    end
    
end

%% 1 DICTIONARY FOR EACH CLASS

if(Dm == 2),
    
    if (Ps == 0),

        % Does nothing
    
    elseif (Ps == 1),
        
        [~,Dy_seq] = max(Dy);	% get sequential label of dictionary
        
        for k = 1:m,
            
            % class of prototype
            c = Dy_seq(k);
            
            % number of elements from the same class as of prototype
            mc = sum(Dy_seq == c);
            
            % dont rem element if it is the only element of its class
            if (mc == 1),
                continue;
            end
            
            % Remove element
            if (score(k) < min_score),
                
                % Get prototypes from the same class
                Dx_c = Dx(:,Dy_seq == c);
                
                % Find position of prototype between elements of same class
                win_c = prototypes_win(Dx_c,Dx(:,k),PAR);
                
                % Remove Prototype and its score
                Dx(:,k) = [];
                Dy(:,k) = [];
                score(k) = [];
                
             	% If ALD or Surprise method, update kernel matrix
                if (Ss == 1 || Ss == 4),
                    % Remove line and column from inverse kernel matrix
                    ep = zeros(mc,1);
                    ep(win_c) = 1;
                    u = Km{c}(:,win_c) - ep;
                    eq = zeros(mc,1);
                    eq(win_c) = 1;
                    v = eq;
                    Kinv{c} = Kinv{c} + (Kinv{c}*u)*(v'*Kinv{c}) / ...
                                  (1 - v'*Kinv{c}*u);
                    Kinv{c}(win_c,:) = [];
                    Kinv{c}(:,win_c) = [];
                    % Remove line and column from kernel matrix
                    Km{c}(win_c,:) = [];
                    Km{c}(:,win_c) = [];
                end
                
                % Just remove one prototype per loop
                break;
                
            end
        end

    end
    
end

%% FILL OUTPUT STRUCTURE

Dout.x = Dx;
Dout.y = Dy;
Dout.Km = Km;
Dout.Kinv = Kinv;
Dout.score = score;

%% END