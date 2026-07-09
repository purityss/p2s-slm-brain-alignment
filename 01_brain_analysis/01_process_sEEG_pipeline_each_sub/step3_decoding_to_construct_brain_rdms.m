clear all
close all
name = 'Subject_ID'; % Anonymized name
folder_path = 'C:\Path\To\Your\Data_Folder\'; % Anonymized folder path
save_path = 'C:\Path\To\Your\Save_Folder\'; % Anonymized save path
idx_start_contact = 2;
idx_end_contact = 35;
file_name_NB = fullfile(folder_path, [num2str(name),  '_NB_200.mat']);
load(file_name_NB)
file_name_resp_contacts = fullfile(folder_path, [num2str(name),  '_resp_contacts.mat']);
load(file_name_resp_contacts)
%delete(gcp('nocreate'))
%parpool("local",14);
%%  Feature extraction (high-γ/θ + Power/Phase)
%%% Set frequency band range  [60 140] [4 8]
freqRange = [60 150];  
%%% Define data range
start_time = -100; % Start time (ms)
end_time = 900; % End time (ms) %1000
step_size = 50; % Step size (ms)
window_length = 200; % Window length (ms)
% Calculate the number of windows
num_windows = floor((end_time - start_time - window_length) / step_size) + 1; 
%%% Save_mat: feature + rdm
nchan = resp_contacts(2:length(resp_contacts));
feature = cell(max(nchan),num_windows);
nchan_rdm = cell(max(nchan),num_windows);
%for nchan = [1 3 4 5 6 7 16 17 18 19 20]%[21 22 36 61 62 63 64 65 66 67][68 69 70 73 86 87 88 89 90 91][92 93 94 95 97 111 112 113 114 118]
%for contact = 2:length(resp_contacts)
for contact = idx_start_contact:idx_end_contact
     nchan = resp_contacts(contact)
  tic
  num_conditions = length(ALLEEG);
  %num_conditions = 2;
  powerAvg = cell(num_conditions,1); 
    
for idx_condition = 1:num_conditions
%for idx_condition = [1:52];
Time = ALLEEG(idx_condition).times;
    
for i=1:length(Time)  %find baseline range
      if Time(i)<0
         ZeroPoint=i;
      else
        end
end
for j = 1:ALLEEG(idx_condition).trials 
       [wt,Freq] = cwt(ALLEEG(idx_condition).data(nchan,:,j),512,'amor');
       baselineMiu = mean(abs(wt(:,1:ZeroPoint)),2);
       baselineStd = std(abs(wt(:, 1:ZeroPoint)), [], 2);
       TimFreq(:,:,j,idx_condition) = ((abs(wt)-baselineMiu)./baselineStd);  % Baseline correction
       %TimFreq(:,:,j,idx_condition) = ((abs(wt)-baselineMiu)./baselineMiu)*100; %event-related perturbation x-u/u*100
end
end
for k = 1:num_windows    % Loop through each window
  % Calculate the start and end time of the current window
     window_start = start_time + (k - 1) * step_size;
     window_end = window_start + window_length;  
     segtime = window_start+100:100:window_end;    
     
 for idx_condition = 1:num_conditions
     
   for j = 1:ALLEEG(idx_condition).trials 
        for i = 1:length(segtime)
            target = segtime(i);  % Target value
            [~, startIdx] = min(abs(Time - (target - 100)));  % Start time of the time segment
            %startIdx = startIdx + 1;
            [~, endIdx] = min(abs(Time - target));  % End time of the time segment
            % Extract time-frequency data within the time segment   
            timFreqSegment = TimFreq(:, startIdx:endIdx,j, idx_condition);
            % Extract time-frequency data within the frequency band range
             freqIdx = find(Freq >= freqRange(1) & Freq <= freqRange(2));  % Frequency index range
             timFreqRange = timFreqSegment(freqIdx, :, :, :);
             % Calculate average power
             powerAvg_tmp(:,i,j) = double(mean(mean(mean(abs(timFreqRange).^2, 2), 3), 4));
             %powerAvg_tmp(i,j) = double(mean(abs(timFreqRange).^2, 'all'));
             %powerAvg(nchan,idx_condition,i,j) = mean(abs(timFreqRange).^2, 'all');
             % Calculate average phase
             %powerAvg_tmp(:,i,j) = double(mean(mean(mean(angle(timFreqRange), 2), 3), 4));
             %powerAvg_tmp(i,j) = mean(angle(timFreqRange), 'all');
             %phaseAvg(nchan,idx_condition,i,j) = mean(angle(timFreqRange), 'all'); 
        end
        
    end
              powerAvg{idx_condition,1} = powerAvg_tmp;
              clear powerAvg_tmp
 end  %for idx_condition
               feature{nchan,k} = powerAvg;
               clear powerAvg
end  %for k = 1:num_windows
                        
save([save_path, 'Subject_',num2str(nchan),'_HG_Power','.mat'],'feature');
%% decoding
%% set up for svm
%%% set k-fold
k_splits_num = 4;
%%% set options for libsvm
% parameters.s = 0;  % default 0
parameters.t = 2; % 0-linear,1-polynomial,2-radial basis function  % default 2  exp(-gamma*|u-v|^2)
% parameters.d = 3; % default 3
parameters.v = k_splits_num; %5; %3; %4;
% para.v = k_splits_num; % 3;
% num_features = size(signal_pair_training,2);
%%% set grid
grid_log2c = (-10:0.5:10); %(-4:0.5:20);
grid_log2g = (-10:0.5:10); %(-20:0.5:4); 
parameters.grid_log2c = grid_log2c;
parameters.grid_log2g = grid_log2g;
%% set idx_condition list
condition_list = [1:52];
%condition_list = [1:2];
idx_condition_pair_list=[];
for ic = condition_list
    idx_condition_pair_list = cat(2, idx_condition_pair_list, cat(1, condition_list, repmat([ic],1,length(condition_list)) ) ); % Combinations of ic with all conditions
end
idx_condition_pair_list = idx_condition_pair_list(:, idx_condition_pair_list(1,:)~=idx_condition_pair_list(2,:));  % Filter unequal condition pairs
idx_condition_pair_list = sort(idx_condition_pair_list,1);  % Sort by column (ascending for each column)
idx_condition_pair_list_temp = idx_condition_pair_list(1,:)*100+idx_condition_pair_list(2,:);  % Temporary index value to ensure subsequent uniqueness operation
[~,i_orig,~] = unique(idx_condition_pair_list_temp);   % Find unique indices
idx_condition_pair_list = idx_condition_pair_list(:,i_orig);  % Extract unique condition pairs
num_condition_pair = size(idx_condition_pair_list,2);
disp([ 'num_condition_pair: ', num2str(num_condition_pair) ])
% representational similarity matrix
%rdm = nan(length(condition_list),length(condition_list));
% acc output value
kfold_cv_acc_allchan_allrepeat = cell(nchan,num_condition_pair);
kfold_cv_acc_allchan_meanrepeat = cell(nchan,num_condition_pair);
%% loop through comparison pair
%n_pair_plot = randperm(num_condition_pair,1);  % Randomly select a condition pair number
for k = 1:num_windows 
    powerAvg = feature{nchan,k};
    rdm = nan(length(condition_list),length(condition_list));
    
for n_pair = 1:num_condition_pair   % Iterate through all condition pairs
%%% set idx_condition
idx_condition_pair = sort( transpose( idx_condition_pair_list(:,n_pair) ) ); % Select specific condition pair indices (n_pair column)
disp(['n pair: ', num2str(n_pair),'  pair: ',num2str(idx_condition_pair)]);
%ALLEEG_decoding_perchan.pairwise_decoding(n_pair).idx_condition_pair = idx_condition_pair;
%ALLEEG_decoding_perchan.pairwise_decoding(n_pair).k_splits_num = k_splits_num;
%% setting for repeat kfold
%%% set num of fold for k-fold cv
num_repeat = 10; %num_trial_pair; %10;%100; Number of repetitions for cross-validation, repeat k-fold partitioning
grid_cv_repeat = [];  % Store grid search results for each repetition
grid_cv_repeat_max = nan(num_repeat,1);  % Store the maximum value for each repetition
bestlog2c_list = nan(num_repeat,1);  
bestlog2g_list = nan(num_repeat,1);
bestc_list = nan(num_repeat,1);
bestg_list = nan(num_repeat,1);  % Store the best parameter values for each repetition
kfold_cv_acc_meanfold = nan(num_repeat,1);  % Store the average accuracy of k-fold CV for each repetition
kfold_cv_acc = nan(num_repeat, k_splits_num);  % Store the accuracy of k-fold CV for each repetition
%% loop through repetition
%tic
for n_repeat=1:num_repeat
disp(['n repeat: ', num2str(n_repeat)]);
signal_training_testing = cell(k_splits_num, 2);  % Store training and testing data for k-fold CV
signal_training_testing_label = cell(k_splits_num, 2);  % Store labels for training and testing data in k-fold CV
for idx_cond=[1,2]
 
    idx_condition = idx_condition_pair(idx_cond);
    %signal_tbin_mean_tstep_twin = powerAvg(idx_condition,:,:);   % Model features
    %signal_tbin_mean_tstep_twin = powerAvg{nchan,idx_condition}; 
    signal_tbin_mean_tstep_twin = powerAvg{idx_condition,1}; 
   %%
    %%%%% k-fold cv (set up the training and testing groups)
    % (k-fold): 
    % def k splits;
    % for each trial, ave trials in each split; 
    % then for each condition, dividing all trials of this condition into [1st~(n-1)th] and [(n)th] into training and testing;
    n_trials_num = ALLEEG(1).trials;  %12
    nk_index = repmat( (1:k_splits_num), 1,3);  % Contains integers from 1 to k_splits_num, repeated 3 times. Ensures each data sample is assigned to a different k-fold CV fold.
    nk_index_idx = randperm(length(nk_index));  % Randomize
    nk_index = nk_index(nk_index_idx);   % Shuffle the order of folds
    nk_index = nk_index(1:n_trials_num);  % Final index vector
    
    tt_index = (1:k_splits_num); 
    for it = tt_index
        %%% dividing(randomly) into k groups
        %%% averaging within the asigned(randomly) split (out of k splits)
        
        %signal_temp_temp = nanmean( signal_tbin_mean_tstep_twin(:,:,nk_index==it) ,3);
        %signal_temp_temp = squeeze(signal_temp_temp);
        
        signal_temp_temp = nanmean( signal_tbin_mean_tstep_twin(:, nk_index==it) ,2); % Select signal data corresponding to specific conditions based on logical indices (each fold), averaged across trials.
%       %%% leave-one-trial-out
%       signal_temp_temp = signal_tbin_mean_tstep_twin(:,:, it);
        
        signal_training_testing{it,idx_cond}= reshape(signal_temp_temp, 1,[]); % Save as 4-fold training and testing data, each cell is a row vector (features)
%       signal_training_testing_label{it,idx_cond} = idx_condition;
        %%% set uo labels
        if idx_cond==1, idx_cond_label = -1; end
        if idx_cond==2, idx_cond_label = 1; end
        
        signal_training_testing_label{it,idx_cond} = idx_cond_label;
        
        % next to perform cross-validation (after this step, by using only the last one group as the testing group)
    end
    
end % for idx_cond=[1,2]
%%
signal_pair_cv_for_bestcg = [];  % Store merged training and testing data
signal_pair_cv_for_bestcg_label = [];  % Store labels for merged training and testing data
%%% set cv cate1
signal_pair_cv_for_bestcg      = cat( 1, signal_pair_cv_for_bestcg,       signal_training_testing{      :, 1} ); % First column, first word, 12 trials divided into 4 folds (average of every 3 epochs)
signal_pair_cv_for_bestcg_label= cat( 1, signal_pair_cv_for_bestcg_label, signal_training_testing_label{:, 1} );
signal_pair_cv_for_bestcg      = cat( 1, signal_pair_cv_for_bestcg,       signal_training_testing{      :, 2} ); % Second column, second word
signal_pair_cv_for_bestcg_label= cat( 1, signal_pair_cv_for_bestcg_label, signal_training_testing_label{:, 2} );
%%%%%
% then choose the pair of condition to SVM
% find better way for grid-search of parameters c and g
%% grid search par and get best acc
%%%%% libsvm-3.32/FAQ.html
%%%%% Conduct CV on a grid of parameters
% bestcv = 0;
% for log2c = -1:3,
%   for log2g = -4:1,
%     cmd = ['-v 5 -c ', num2str(2^log2c), ' -g ', num2str(2^log2g)];
%     cv = svmtrain(heart_scale_label, heart_scale_inst, cmd);
%     if (cv >= bestcv),
%       bestcv = cv; bestc = 2^log2c; bestg = 2^log2g;
%     end
%     fprintf('%g %g %g (best c=%g, g=%g, rate=%g)\n', log2c, log2g, cv, bestc, bestg, bestcv);
%   end
% end
%%%%%
% tic
% ticBytes(gcp)
%%% loop through grid
% bestcv = 0;
[log2c_coor,log2g_coor]=meshgrid(1:numel(grid_log2c),1:numel(grid_log2g)); % Represents all combinations of grid_log2c and grid_log2g
log2c_list = reshape(log2c_coor,1,[]);  % Flatten to a 1D vector for easier iteration
log2g_list = reshape(log2g_coor,1,[]);
grid_cv = nan(1,numel(grid_log2c)*numel(grid_log2g));  % Store CV results and corresponding parameter values for each parameter combination
grid_cv_c = nan(1,numel(grid_log2c)*numel(grid_log2g));
grid_cv_g = nan(1,numel(grid_log2c)*numel(grid_log2g));  
parfor i_grid = 1: numel(grid_log2c)*numel(grid_log2g)   % Iterate through all parameter combinations
% for i_grid = 1: numel(grid_log2c)*numel(grid_log2g)
% for log2c = grid_log2c
% for log2g = grid_log2g
      
    log2c = grid_log2c(log2c_list(i_grid));
    log2g = grid_log2g(log2g_list(i_grid));
    grid_cv_c(1,i_grid) = log2c;
    grid_cv_g(1,i_grid) = log2g;
    
%     clear cmd model
    cmd = ['-q ',' -t ',num2str(parameters.t), ' -v ',num2str(parameters.v), ' -c ', num2str(2^log2c), ' -g ', num2str(2^log2g)];
    cv = svmtrain(signal_pair_cv_for_bestcg_label, signal_pair_cv_for_bestcg, cmd);
    grid_cv(1,i_grid) = cv;
    
%   end
% end
end
% tocBytes(gcp)
%toc
%elapsedTime = toc
% grid_cv = transpose(grid_cv);
% grid_cv_repeat(:,:,n_repeat) = grid_cv;
disp(['grid_cv: ',num2str(max(grid_cv,[],'all'))]);  
grid_cv_repeat(:,:,n_repeat) = grid_cv;
grid_cv_cg = cat(1,grid_cv_c,grid_cv_g);
% grid_cv_cg_repeat(:,:,n_repeat) = grid_cv_cg;
[grid_cv_max,idx_max] = max(grid_cv);  % Calculate the max value of grid_cv and its index
grid_cv_repeat_max(n_repeat) = grid_cv_max;
bestlog2c = grid_cv_cg(1,idx_max);   
bestlog2g = grid_cv_cg(2,idx_max);
bestc = 2^bestlog2c;
bestg = 2^bestlog2g;
bestlog2c_list(n_repeat) = bestlog2c;  % Store the best parameter values for each repetition
bestlog2g_list(n_repeat) = bestlog2g;
bestc_list(n_repeat) = bestc;
bestg_list(n_repeat) = bestg;
%% perform k-fold
signal_pair_training = [];
signal_pair_training_label = [];
signal_pair_testing = [];
signal_pair_testing_label = [];
kfold_cv_acc_ifold = nan(1,k_splits_num); % Store cross-validation accuracy for each fold
for n_fold=1:k_splits_num
disp(['n fold: ', num2str(n_fold)]);
%%% set training cate1 Concatenate training data and labels from folds other than the current fold into signal_pair_training and signal_pair_training_label
signal_pair_training      = cat( 1, signal_pair_training,       signal_training_testing{      [1:n_fold-1,n_fold+1:end], 1} ); % All rows except n_fold, 1st column
signal_pair_training_label= cat( 1, signal_pair_training_label, signal_training_testing_label{[1:n_fold-1,n_fold+1:end], 1} );
%%% set testing cate1  Concatenate current fold's testing data and labels into signal_pair_testing and signal_pair_testing_label
signal_pair_testing        = cat( 1, signal_pair_testing,       signal_training_testing{      n_fold, 1}); % n_fold row, 1st column
signal_pair_testing_label  = cat( 1, signal_pair_testing_label, signal_training_testing_label{n_fold, 1} );
%%% set training cate2
signal_pair_training      = cat( 1, signal_pair_training,       signal_training_testing{      [1:n_fold-1,n_fold+1:end], 2} );
signal_pair_training_label= cat( 1, signal_pair_training_label, signal_training_testing_label{[1:n_fold-1,n_fold+1:end], 2} );
%%% set testing cate2
signal_pair_testing        = cat( 1, signal_pair_testing,       signal_training_testing{      n_fold, 2});
signal_pair_testing_label  = cat( 1, signal_pair_testing_label, signal_training_testing_label{n_fold, 2} );
%if strcmp(decoding_type,'_perm') % scrambled label decoding for permutation test
	% only shuffle the training label
	%signal_pair_training_label = shuffle(signal_pair_training_label);
%end
        
 
%%% features [num of instances, num of features]
%%% labels   [num of instances, 1]
disp(['size training:       ', num2str(size(signal_pair_training))]);
disp(['size training_label: ', num2str(size(signal_pair_training_label))]);
disp(['size testing:       ', num2str(size(signal_pair_testing))]);
disp(['size testing_label: ', num2str(size(signal_pair_testing_label))]);
disp([' ']);
%% svmtrain and svmpredict
cmd_kfold_cv = ['-q ',' -t ',num2str(parameters.t), ' -c ', num2str(bestc), ' -g ', num2str(bestg)];
model = svmtrain(signal_pair_training_label, signal_pair_training, cmd_kfold_cv);
[~, accuracy, ~] = svmpredict(signal_pair_testing_label, signal_pair_testing, model);
%%%   accuracy, is a vector including accuracy (for classification), mean
%%%   squared error, and squared correlation coefficient (for regression).
% kfold_cv_acc(n_repeat) = accuracy(1);
kfold_cv_acc_ifold(n_fold) = accuracy(1);  % Cross-validation accuracy for each fold
end % for n_fold=1:k_splits_num
clear bestc bestg
kfold_cv_acc(n_repeat,:) = kfold_cv_acc_ifold; % Store all k-fold CV accuracies
kfold_cv_acc_meanfold(n_repeat) = nanmean(kfold_cv_acc_ifold);  % Calculate the average accuracy across all folds for each repetition and store the result
end % for n_repeat=1:num_repeat
%elapsedTime = toc
kfold_cv_acc_allchan_allrepeat{nchan,n_pair} = kfold_cv_acc;
acc_mean = (mean(kfold_cv_acc_meanfold))/100; % Average accuracy of all repetitions (i.e., average accuracy for a word pair), converted to decimal
%kfold_cv_acc_allchan_meanrepeat{nchan,n_pair} = acc_mean;
%rdm(idx_condition_pair_list(2,n_pair),idx_condition_pair_list(1,n_pair)) = acc_mean;
%save([save_path, num2str(nchan),'_',num2str(num_repeat),'_','HG','_','Power','_','meanrepeat_',num2str(k),'.mat'],'kfold_cv_acc_allchan_meanrepeat');
%acc_mean = kfold_cv_acc_allchan_meanrepeat{nchan,n_pair};
rdm(idx_condition_pair_list(2,n_pair),idx_condition_pair_list(1,n_pair)) = acc_mean;
end % for n_pair = 1:num_condition_pair
%% Save RDM
nchan_rdm{nchan,k} = rdm;
end %for k = 1:num_windows
elapsedTime = toc
save([save_path, num2str(name),'_',num2str(nchan),'_elapsedTime','.mat'],'elapsedTime');
save([save_path, num2str(name),'_',num2str(nchan),'_HG_RDM','.mat'],'nchan_rdm');
end %for nchan
