clear all
close all
name = 'qwen2_audio';
load(strcat(name, '_pho_only_neurons.mat'));
load(strcat(name, '_sem_only_neurons.mat'));
load(strcat(name, '_both_neurons_p.mat'));
load(strcat(name, '_both_neurons_s.mat'));

% Set save folder to the current working directory
save_folder = [pwd, filesep];
 
% 1. Convert to 'table' for deduplication
T = cell2table(pho_only_neurons, 'VariableNames', {'Layer', 'Neuron', 'Token', 'Col4'});
% 2. Group by (Layer, Neuron) and select the row with the earliest Token (time)
T_sorted = sortrows(T, {'Layer', 'Neuron', 'Token'}); % Sort first to ensure the earliest token index is at the top
[~, idx] = unique(T_sorted(:, {'Layer', 'Neuron'}), 'rows', 'stable'); % Get the row indices of the earliest tokens
T_filtered = T_sorted(idx, :); % Select the rows with the earliest tokens
% 3. Convert back to cell array
start_pho_only_neurons = table2cell(T_filtered);

% 1. Convert to 'table' for deduplication
T = cell2table(sem_only_neurons, 'VariableNames', {'Layer', 'Neuron', 'Token', 'Col4'});
% 2. Group by (Layer, Neuron) and select the row with the earliest Token (time)
T_sorted = sortrows(T, {'Layer', 'Neuron', 'Token'}); % Sort first to ensure the earliest token index is at the top
[~, idx] = unique(T_sorted(:, {'Layer', 'Neuron'}), 'rows', 'stable'); % Get the row indices of the earliest tokens
T_filtered = T_sorted(idx, :); % Select the rows with the earliest tokens
% 3. Convert back to cell array
start_sem_only_neurons = table2cell(T_filtered);

% 1. Convert to 'table' for deduplication
T = cell2table(both_neurons_p, 'VariableNames', {'Layer', 'Neuron', 'Token', 'Col4'});
% 2. Group by (Layer, Neuron) and select the row with the earliest Token (time)
T_sorted = sortrows(T, {'Layer', 'Neuron', 'Token'}); % Sort first to ensure the earliest token index is at the top
[~, idx] = unique(T_sorted(:, {'Layer', 'Neuron'}), 'rows', 'stable'); % Get the row indices of the earliest tokens
T_filtered = T_sorted(idx, :); % Select the rows with the earliest tokens
% 3. Convert back to cell array
start_both_neurons_p = table2cell(T_filtered);

% 1. Convert to 'table' for deduplication
T = cell2table(both_neurons_s, 'VariableNames', {'Layer', 'Neuron', 'Token', 'Col4'});
% 2. Group by (Layer, Neuron) and select the row with the earliest Token (time)
T_sorted = sortrows(T, {'Layer', 'Neuron', 'Token'}); % Sort first to ensure the earliest token index is at the top
[~, idx] = unique(T_sorted(:, {'Layer', 'Neuron'}), 'rows', 'stable'); % Get the row indices of the earliest tokens
T_filtered = T_sorted(idx, :); % Select the rows with the earliest tokens
% 3. Convert back to cell array
start_both_neurons_s = table2cell(T_filtered);

save([save_folder, num2str(name),'_start_pho_only_neurons','.mat'],'start_pho_only_neurons');
save([save_folder, num2str(name),'_start_sem_only_neurons','.mat'],'start_sem_only_neurons');
save([save_folder, num2str(name),'_start_both_neurons_p','.mat'],'start_both_neurons_p');
save([save_folder, num2str(name),'_start_both_neurons_s','.mat'],'start_both_neurons_s');