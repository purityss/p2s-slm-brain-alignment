clear all
close all
name = 'qwen2_audio';
load(strcat(name, '_start_pho_only_neurons.mat'));
load(strcat(name, '_start_sem_only_neurons.mat'));
load(strcat(name, '_start_both_neurons_p.mat'));
load(strcat(name, '_all_layer_neuron_token_phonology_t.mat'));
load(strcat(name, '_all_layer_neuron_token_semantics_t.mat'));
load(strcat(name, '_all_layer_neuron_token_p_s_t.mat'));

% Set save folder to the current working directory
save_folder = [pwd, filesep];

% **Ensure all electrode numbers are strings**
% all_layer_neuron_token_phonology_t(:,4) = cellfun(@num2str, all_layer_neuron_token_phonology_t(:,18), 'UniformOutput', false);
% all_layer_neuron_token_semantics_t(:,4) = cellfun(@num2str, all_layer_neuron_token_semantics_t(:,18), 'UniformOutput', false);
% all_layer_neuron_token_p_s_t(:,4) = cellfun(@num2str, all_layer_neuron_token_p_s_t(:,18), 'UniformOutput', false);
% start_pho_only_neurons(:,2) = cellfun(@num2str, start_pho_only_neurons(:,2), 'UniformOutput', false);
% start_both_neurons_p(:,2) = cellfun(@num2str, start_both_neurons_p(:,2), 'UniformOutput', false);
% start_sem_only_neurons(:,2) = cellfun(@num2str, start_sem_only_neurons(:,2), 'UniformOutput', false);

% **Initialize matching indices**
idx_pho = [];
idx_both = [];
idx_sem = [];

% **Match start_pho_only_neurons**
for i = 1:size(start_pho_only_neurons, 1)
     pho_only_neuron = i
%     match_layer = strcmp(all_layer_neuron_token_phonology_t(:,3), start_pho_only_neurons{i,1});  
%     match_neuron = strcmp(all_layer_neuron_token_phonology_t(:,4), start_pho_only_neurons{i,2}); 
    match_layer = cell2mat(all_layer_neuron_token_phonology_t(:,3)) == start_pho_only_neurons{i,1};
    match_neuron = cell2mat(all_layer_neuron_token_phonology_t(:,4)) == start_pho_only_neurons{i,2};
    match_idx = find(match_layer & match_neuron);
    
    if ~isempty(match_idx)
        idx_pho = [idx_pho; match_idx]; 
    end
end
filtered_pho_1 = all_layer_neuron_token_phonology_t(idx_pho, :);
filtered_pho_2 = all_layer_neuron_token_semantics_t(idx_pho, :);
filtered_pho_3 = all_layer_neuron_token_p_s_t(idx_pho, :);

% **Match start_both_neuron_p**
for i = 1:size(start_both_neurons_p, 1)
      both_neuron = i
%     match_layer = strcmp(all_layer_neuron_token_phonology_t(:,3), start_both_neurons_p{i,1});  
%     match_neuron = strcmp(all_layer_neuron_token_phonology_t(:,4), start_both_neurons_p{i,2}); 
     match_layer = cell2mat(all_layer_neuron_token_phonology_t(:,3)) == start_both_neurons_p{i,1};
     match_neuron = cell2mat(all_layer_neuron_token_phonology_t(:,4)) == start_both_neurons_p{i,2};
    match_idx = find(match_layer & match_neuron);
    
    if ~isempty(match_idx)
        idx_both = [idx_both; match_idx]; 
    end
end
filtered_both_1 = all_layer_neuron_token_phonology_t(idx_both, :);
filtered_both_2 = all_layer_neuron_token_semantics_t(idx_both, :);
filtered_both_3 = all_layer_neuron_token_p_s_t(idx_both, :);

% **Match start_sem_only_neuron**
for i = 1:size(start_sem_only_neurons, 1)
    sem_only_neurons = i
%     match_layer = strcmp(all_layer_neuron_token_phonology_t(:,3), start_sem_only_neurons{i,1});  
%     match_neuron = strcmp(all_layer_neuron_token_phonology_t(:,4), start_sem_only_neurons{i,2}); 
    match_layer = cell2mat(all_layer_neuron_token_phonology_t(:,3)) == start_sem_only_neurons{i,1};
    match_neuron = cell2mat(all_layer_neuron_token_phonology_t(:,4)) == start_sem_only_neurons{i,2};
    match_idx = find(match_layer & match_neuron);
    
    if ~isempty(match_idx)
        idx_sem = [idx_sem; match_idx]; 
    end
end
filtered_sem_1 = all_layer_neuron_token_phonology_t(idx_sem, :);
filtered_sem_2 = all_layer_neuron_token_semantics_t(idx_sem, :);
filtered_sem_3 = all_layer_neuron_token_p_s_t(idx_sem, :);

% **Merge the three parts**
filtered_all_1 = [filtered_pho_1; filtered_both_1; filtered_sem_1];
selective_all_layer_neuron_token_phonology_t = filtered_all_1;
filtered_all_2 = [filtered_pho_2; filtered_both_2; filtered_sem_2];
selective_all_layer_neuron_token_semantics_t = filtered_all_2;
filtered_all_3 = [filtered_pho_3; filtered_both_3; filtered_sem_3];
selective_all_layer_neuron_token_p_s_t = filtered_all_3;

save([save_folder, num2str(name), '_selective_all_layer_neuron_token_phonology_t.mat'], 'selective_all_layer_neuron_token_phonology_t');
save([save_folder, num2str(name), '_selective_all_layer_neuron_token_semantics_t.mat'], 'selective_all_layer_neuron_token_semantics_t');
save([save_folder, num2str(name), '_selective_all_layer_neuron_token_p_s_t.mat'], 'selective_all_layer_neuron_token_p_s_t');

%%
% **Convert selective_all_layer_neuron_token_phonology_t**
numeric_phonology_t = cell2mat(selective_all_layer_neuron_token_phonology_t(:,1:2));
% **Convert selective_all_layer_neuron_token_semantics_t**
numeric_semantics_t = cell2mat(selective_all_layer_neuron_token_semantics_t(:,1:2));
% **Convert selective_all_layer_neuron_token_p_s_t**
numeric_p_s_t = cell2mat(selective_all_layer_neuron_token_p_s_t(:,1:2));

save([save_folder, 'numeric_phonology_t.mat'], 'numeric_phonology_t');
save([save_folder, 'numeric_semantics_t.mat'], 'numeric_semantics_t');
save([save_folder, 'numeric_p_s_t.mat'], 'numeric_p_s_t');

%%
% **Calculate start and end indices**
start_pho = 1;
end_pho = size(filtered_pho_1, 1);
start_both = end_pho + 1;
end_both = start_both + size(filtered_both_1, 1) - 1;
start_sem = end_both + 1;
end_sem = start_sem + size(filtered_sem_1, 1) - 1;

% **Display matching results**
disp(['✅ Total rows in the new merged cell: ', num2str(size(filtered_all_1,1))]);
disp(['✅ Index range for start_pho_only_neurons: ', num2str(start_pho), ' - ', num2str(end_pho)]);
disp(['✅ Index range for start_both_neurons_p: ', num2str(start_both), ' - ', num2str(end_both)]);
disp(['✅ Index range for start_sem_only_neurons: ', num2str(start_sem), ' - ', num2str(end_sem)]);

% **Ensure electrode numbers are strings**
filtered_all_1(:,3) = cellfun(@num2str, filtered_all_1(:,3), 'UniformOutput', false);
filtered_all_1(:,4) = cellfun(@num2str, filtered_all_1(:,4), 'UniformOutput', false);

% **Get (Subject Name, Electrode Number) pairs**
layer_neuron_pairs = [filtered_all_1(:, 3), filtered_all_1(:, 3)];  % 2-column cell

% **Convert (Subject Name, Electrode Number) to string format for easy deduplication**
layer_neuron_str = strcat(layer_neuron_pairs(:,1), '_', layer_neuron_pairs(:,2)); 

% **Find unique (Subject Name, Electrode Number) combinations**
[unique_str, ~, pair_idx] = unique(layer_neuron_str, 'stable');

% **Split the unique strings back into cells**
unique_pairs = cellfun(@(x) strsplit(x, '_'), unique_str, 'UniformOutput', false);
unique_pairs = vertcat(unique_pairs{:});  % Convert to Nx2 cell matrix

% **Count the occurrences of each combination**
pair_counts = accumarray(pair_idx, 1);

% **Find duplicates**
duplicate_idx = find(pair_counts > 1);

if isempty(duplicate_idx)
    disp('✅ No duplicate (layer, neuron) combinations');
else
    disp('⚠️ Duplicate (layer, neuron) combinations exist:');
    for i = 1:length(duplicate_idx)
        disp(['layer: ', unique_pairs{duplicate_idx(i), 1}, ...
              ', neuron: ', unique_pairs{duplicate_idx(i), 2}, ...
              ', Count: ', num2str(pair_counts(duplicate_idx(i)))]);
    end
end