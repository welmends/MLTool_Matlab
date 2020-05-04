%% Machine Learning ToolBox

% Online and Sequential Algorithms
% Author: David Nascimento Coelho
% Last Update: 2020/04/08

%% DATA LOADING AND PRE-PROCESSING

% Load Dataset and Adjust its Labels

DATA = data_class_loading(OPT);     % Load Data Set

DATA = label_encode(DATA,OPT);      % adjust labels for the problem

[Nc,N] = size(DATA.output);        	% get number of classes and samples

% Set data for the cross validation step: min (0.2 * N, 1000)

if (N < 5000),
    Nhpo = floor(0.2 * N);
else
    Nhpo = 1000;
end

DATAhpo.input = DATA.input(:,1:Nhpo);
DATAhpo.output = DATA.output(:,1:Nhpo);

% Set remaining data for test-than-train step

Nttt = N - Nhpo;

DATAttt.input = DATA.input(:,Nhpo+1:end);
DATAttt.output = DATA.output(:,Nhpo+1:end);

%% DATA NORMALIZATION

% Get Normalization Parameters
PARnorm = normalize_fit(DATAhpo,OPT);

% Normalize all data
DATA = normalize_transform(DATA,PARnorm);

% Normalize hpo data
DATAhpo = normalize_transform(DATAhpo,PARnorm);

% Normalize ttt data
DATAttt = normalize_transform(DATAttt,PARnorm);

% Get statistics from data (For Video Function)
DATAn.Xmax = max(DATA.input,[],2);
DATAn.Xmin = min(DATA.input,[],2);
DATAn.Xmed = mean(DATA.input,2);
DATAn.Xstd = std(DATA.input,[],2);

%% DATA VISUALIZATION

figure; plot_data_pairplot(DATAttt);

%% ACCUMULATORS

samples_per_class = zeros(Nc,Nttt);	% Hold number of samples per class

predict_vector = zeros(Nc,Nttt);	% Hold predicted labels

no_of_correct = zeros(1,Nttt);      % Hold # of correctly classified x
no_of_errors = zeros(1,Nttt);       % Hold # of misclassified x

accuracy_vector = zeros(1,Nttt);	% Hold Acc / (Acc + Err)

prot_per_class = zeros(Nc+1,Nttt);	% Hold number of prot per class
                                    % Last is for the sum
                                    
VID = struct('cdata',cell(1,Nttt),'colormap', cell(1,Nttt));

%% CROSS VALIDATION FOR HYPERPARAMETERS OPTIMIZATION

display('begin grid search')

% Grid Search Parameters

GSp.lambda = 0.5;       % Jpbc = Ds + lambda * Err
GSp.preseq_type = 2;    % Uses directly test-than-train

% Get Hyperparameters Optimized and the Prototypes Initialized

HPo = grid_search_ttt(DATAhpo,HP_gs,@isk2nn_train,@isk2nn_test,GSp);

% They Are also the Initial Parameters

PAR = HPo;

%% PRESEQUENTIAL (TEST-THAN-TRAIN)

display('begin Test-than-train')

figure; % new figure for video ploting

for n = 1:Nttt,
    
    % Display number of samples already seen (for debug)
    
    if(mod(n,1000) == 0),
        disp(n);
        disp(datestr(now));
    end
    
    % Get current data
    
    DATAn.input = DATA.input(:,n);
    DATAn.output = DATA.output(:,n);
    [~,y_lbl] = max(DATAn.output);
    
    % Test  (classify arriving data with current model)
    % Train (update model with arriving data)
    
    PAR = isk2nn_train(DATAn,PAR);
    
    % Hold Number of Samples per Class 
    
    if n == 1,
        samples_per_class(y_lbl,n) = 1; % first element
    else
        samples_per_class(:,n) = samples_per_class(:,n-1);
        samples_per_class(y_lbl,n) = samples_per_class(y_lbl,n-1) + 1;
    end
    
    % Hold Predicted Labels
    
    predict_vector(:,n) = PAR.y_h;
    [~,yh_lbl] = max(PAR.y_h);
    
    % Hold Number of Errors and Hits
    
    if n == 1,
        if (y_lbl == yh_lbl),
            no_of_correct(n) = 1;
        else
            no_of_errors(n) = 1;
        end
    else
        if (y_lbl == yh_lbl),
            no_of_correct(n) = no_of_correct(n-1) + 1;
            no_of_errors(n) = no_of_errors(n-1);
        else
            no_of_correct(n) = no_of_correct(n-1);
            no_of_errors(n) = no_of_errors(n-1) + 1;
        end
    end
    
    % Hold Accuracy
    
    accuracy_vector(n) = no_of_correct(n) / ...
                        (no_of_correct(n) + no_of_errors(n));
    
    % Hold Number of prototypes per Class
    
    [~,lbls] = max(PAR.Cy);
    for c = 1:Nc,
        prot_per_class(c,n) = sum(lbls == c);
    end
    
    [~,Nprot] = size(PAR.Cy);
    prot_per_class(Nc+1,n) = Nprot;
    
    % Video Function
    
    if (HP.Von),
        VID(n) = prototypes_frame(PAR.Cx,DATAn);
    end
    
end

%% SAVE FILE

save(OPT.file,'-v7.3')

%% END