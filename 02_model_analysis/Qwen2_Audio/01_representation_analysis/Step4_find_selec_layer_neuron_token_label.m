clear all
close all
name = 'qwen2_audio';
load(strcat(name, '_Cos_dist_rdm_conv_layer_neuron.mat'));
load(strcat(name, '_Cos_dist_rdm_audio_layer_neuron.mat'));
load(strcat(name, '_Cos_dist_rdm_transformer_layer_neuron.mat'));

% Set save path to a subfolder inside the current working directory
save_folder_2 = fullfile(pwd, 'all_layers_selective_neuron_token_t_label');
if ~exist(save_folder_2, 'dir')
    mkdir(save_folder_2); % Create the folder if it does not exist
end
save_folder_2 = [save_folder_2, filesep];

p_thresh = 0.05;

layer_num_conv = 2;
layer_num_audio = 32;
layer_num_transformer = 32;

neuron_conv = 1280;
neuron_audio = 1280;
neuron_transformer = 4096;

layer_num_conv_start = 1;
layer_num_conv_end = layer_num_conv;
layer_num_audio_start = layer_num_conv_end + 1;
layer_num_audio_end = layer_num_conv + layer_num_audio;
layer_num_transformer_start = layer_num_audio_end + 1;
layer_num_transformer_end = layer_num_audio_end + layer_num_transformer;

% Initialize storage structures
% phonology_representation_005 = struct(); semantics_representation_005 = struct(); both_representation_005 = struct(); none_representation_005 = struct();
% p_only_neuron = struct(); s_only_neuron = struct(); both_neuron_p = struct(); both_neuron_s = struct();
pho_only_neurons = {};
sem_only_neurons = {};
both_neurons_p = {};
both_neurons_s = {};
all_layer_neuron_token_selective_label = {};

i_neuron = 0;

for layer = layer_num_conv_start:layer_num_conv_end
    layer = layer
    
    % Initialize variables
    p_only_layer_005 = []; p_only_neuron_005 = []; p_only_token_005 = []; p_only_t_005 = [];
    s_only_layer_005 = []; s_only_neuron_005 = []; s_only_token_005 = []; s_only_t_005 = [];
    p_s_both_layer_005 = []; p_s_both_neuron_005 = []; p_s_both_token_005 = []; p_s_both_pt_005 = []; p_s_both_st_005 = [];
    p_s_none_layer_005 = []; p_s_none_neuron_005 = []; p_s_none_token_005 = []; p_s_none_pt_005 = []; p_s_none_st_005 = [];
    
        for neuron = 1:neuron_conv
        neuron = neuron
        i_neuron = i_neuron + 1;
        
        selec1_temp = [];
        selec2_temp = [];
        
        for token = 1:2
            rdm = rdm_cell_conv{neuron,token,layer};
            
            % Phonology processing
            elements_tongyin = []; % Similar-Phonology (only different semantics)
            elements_yiyin = [];   % Different-Phonology (different semantics + similar semantics)
            for x = 27:52
                for y = 1:26
                    if x == y + 26
                        elements_tongyin = [elements_tongyin, rdm(x, y)];
                    end
                end
            end
            for x = 2:52
                for y = 1:x-1
                    if x ~= y + 26
                        elements_yiyin = [elements_yiyin, rdm(x, y)];
                    end
                end
            end
            
            % Calculate mean values
            mean_tongyin = mean(elements_tongyin);
            mean_yiyin = mean(elements_yiyin);
            
            % Semantics processing
            elements_tongyi = [];  % Similar-Semantics (only different phonology)
            elements_yiyi = [];    % Different-Semantics (different phonology + similar phonology)
            for x = 2:26
                for y = 1:(x-1)
                    elements_tongyi = [elements_tongyi, rdm(x, y)];
                end
            end
            for x = 28:52
                for y = 27:(x-1)
                    elements_tongyi = [elements_tongyi, rdm(x, y)];
                end
            end
            for x = 27:52
                for y = 1:26
                    elements_yiyi = [elements_yiyi, rdm(x, y)];
                end
            end           
            
            % Calculate t-test
            [h1, p1, ~, stats1] = ttest2(elements_yiyin, elements_tongyin);
            [h2, p2, ~, stats2] = ttest2(elements_yiyi, elements_tongyi);
            
            if p1 < 0.05 && stats1.tstat > 0 
                selec1_temp(token) = 1;
            else
                selec1_temp(token) = 0;
            end
            
           if p2 < 0.05 && stats2.tstat > 0 
                selec2_temp(token) = 1;
           else
                selec2_temp(token) = 0;
           end
                
            % Record classification
            if p1 < 0.05 && stats1.tstat > 0 
                if p2 < 0.05 && stats2.tstat > 0
                    p_s_both_layer_005 = [p_s_both_layer_005, layer];
                    p_s_both_neuron_005 = [p_s_both_neuron_005, neuron];
                    p_s_both_token_005 = [p_s_both_token_005, token];
                    p_s_both_pt_005 = [p_s_both_pt_005, stats1.tstat];
                    p_s_both_st_005 = [p_s_both_st_005, stats2.tstat];
                else 
                    p_only_layer_005 = [p_only_layer_005, layer];
                    p_only_neuron_005 = [p_only_neuron_005, neuron];
                    p_only_token_005 = [p_only_token_005, token];
                    p_only_t_005 = [p_only_t_005, stats1.tstat];
                end
            else
                if p2 < 0.05 && stats2.tstat > 0  
                    s_only_layer_005 = [s_only_layer_005, layer];
                    s_only_neuron_005 = [s_only_neuron_005, neuron];
                    s_only_token_005 = [s_only_token_005, token];
                    s_only_t_005 = [s_only_t_005, stats2.tstat];
                else
                    p_s_none_layer_005 = [p_s_none_layer_005, layer];
                    p_s_none_neuron_005 = [p_s_none_neuron_005, neuron];
                    p_s_none_token_005 = [p_s_none_token_005, token];
                    p_s_none_pt_005 = [p_s_none_pt_005, stats1.tstat];
                    p_s_none_st_005 = [p_s_none_st_005, stats2.tstat];
                end
            end
        end
        
        indices1 = find(selec1_temp == 1);
        indices2 = find(selec2_temp == 1);
        if ~isempty(indices1)
          all_layer_neuron_token_selective_label{i_neuron,3} = 1;  %pho
          all_layer_neuron_token_selective_label{i_neuron,4} = indices1;
        end 
        
        if ~isempty(indices2)
          all_layer_neuron_token_selective_label{i_neuron,5} = 1;  %sem
          all_layer_neuron_token_selective_label{i_neuron,6} = indices2;  
        end 
        
        if ~isempty(indices1) 
            if ~isempty(indices2)
               all_layer_neuron_token_selective_label{i_neuron,7} = 1;  %both
%                all_layer_neuron_token_selective_label{i_neuron,14} = 0;
            else
                all_layer_neuron_token_selective_label{i_neuron,8} = 1;  %pho only
%                 all_layer_neuron_token_selective_label{i_neuron,14} = 1;
            end
        elseif  ~isempty(indices2)
            all_layer_neuron_token_selective_label{i_neuron,9} = 1;   %sem only
%             all_layer_neuron_token_selective_label{i_neuron,14} = -1;
%         else
%             all_layer_neuron_token_selective_label{i_neuron,14} = 2;
        end
        
        all_layer_neuron_token_selective_label{i_neuron,1} = layer;
        all_layer_neuron_token_selective_label{i_neuron,2} = neuron;
        end
        
% % Store results
% layer_cell = num2cell(repmat(layer, length(p_only_neuron_005), 1));
% phonology_representation_005.(layer) = [layer_cell, num2cell(p_only_neuron_005'), num2cell(p_only_token_005'), num2cell(p_only_t_005')];
% 
% layer_cell = num2cell(repmat(layer, length(s_only_neuron_005), 1));
% semantics_representation_005.(layer) = [layer_cell, num2cell(s_only_neuron_005'), num2cell(s_only_token_005'), num2cell(s_only_t_005')];
% 
% layer_cell = num2cell(repmat(layer, length(p_s_both_neuron_005), 1));
% both_representation_005.(layer) = [layer_cell, num2cell(p_s_both_neuron_005'), num2cell(p_s_both_token_005'), num2cell(p_s_both_pt_005'), num2cell(p_s_both_st_005')];
% 
% layer_cell = num2cell(repmat(layer, length(p_s_none_neuron_005), 1));
% none_representation_005.(layer) = [layer_cell, num2cell(p_s_none_neuron_005'), num2cell(p_s_none_token_005'), num2cell(p_s_none_pt_005'), num2cell(p_s_none_st_005')];
A = [num2cell(p_only_layer_005'), num2cell(p_only_neuron_005'), num2cell(p_only_token_005'), num2cell(p_only_t_005')];
B = [num2cell(s_only_layer_005'), num2cell(s_only_neuron_005'), num2cell(s_only_token_005'), num2cell(s_only_t_005')];
% both_representation_005.(layer) = [num2cell(p_s_both_layer_005'), num2cell(p_s_both_neuron_005'), num2cell(p_s_both_token_005'), num2cell(p_s_both_pt_005'), num2cell(p_s_both_st_005')];
% none_representation_005.(layer) = [num2cell(p_s_none_layer_005'), num2cell(p_s_none_neuron_005'), num2cell(p_s_none_token_005'), num2cell(p_s_none_pt_005'), num2cell(p_s_none_st_005')];
% Extract RDMs representing only phonology and semantics
% A = phonology_representation_005.(layer);  
% B = semantics_representation_005.(layer);  
% Create C and D to respectively store cases representing both phonology and semantics
% layer_cell = num2cell(repmat(layer, length(p_s_both_neuron_005), 1));
% C = [layer_cell, num2cell(p_s_both_neuron_005'), num2cell(p_s_both_token_005'), num2cell(p_s_both_pt_005')];
% layer_cell = num2cell(repmat(layer, length(p_s_both_neuron_005), 1));
% D = [layer_cell, num2cell(p_s_both_neuron_005'), num2cell(p_s_both_token_005'), num2cell(p_s_both_st_005')];
C = [num2cell(p_s_both_layer_005'), num2cell(p_s_both_neuron_005'), num2cell(p_s_both_token_005'), num2cell(p_s_both_pt_005')];
D = [num2cell(p_s_both_layer_005'), num2cell(p_s_both_neuron_005'), num2cell(p_s_both_token_005'), num2cell(p_s_both_st_005')];
% **Find elements with identical second columns (neuron numbers) in A and B** (Within the loop, the first column 'layer' is identical)
if isempty(A) || isempty(B) || size(A,2) < 2 || size(B,2) < 2
    warning('A or B is empty, or has fewer than 2 columns, skipping intersect calculation.');
    common_values = [];  % Set as an empty array to avoid errors
else
    common_values = intersect(cell2mat(A(:,2)), cell2mat(B(:,2)));
end
% Extract rows in A with second columns matching B, store in C
for i = 1:length(common_values)
    matching_rows = cell2mat(A(:,2)) == common_values(i);
    C = [C; A(matching_rows, :)];
end
% Extract rows in B with second columns matching A, store in D
for i = 1:length(common_values)
    matching_rows = cell2mat(B(:,2)) == common_values(i);
    D = [D; B(matching_rows, :)];
end
% **Delete these matching rows from A and B**
% A(ismember(cell2mat(A(:,2)), common_values), :) = [];
% B(ismember(cell2mat(B(:,2)), common_values), :) = [];
% **Delete rows from A that have identical first and second columns to C**
if isempty(A) || isempty(C) || size(A,2) < 2 || size(C,2) < 2
    warning('A or C is empty, or has fewer than 2 columns, skipping deletion.');
else
    A(ismember(cell2mat(A(:,1:2)), cell2mat(C(:,1:2)), 'rows'), :) = [];
end
% **Delete rows from B that have identical first and second columns to D**
if isempty(B) || isempty(D) || size(B,2) < 2 || size(D,2) < 2
    warning('B or D is empty, or has fewer than 2 columns, skipping deletion.');
else
    B(ismember(cell2mat(B(:,1:2)), cell2mat(D(:,1:2)), 'rows'), :) = [];
end
% **Store final results**
% p_only_neuron.(layer) = A;
pho_only_neurons = [pho_only_neurons; A];
% s_only_neuron.(layer) = B;
sem_only_neurons = [sem_only_neurons; B];
% both_neuron_p.(layer) = C;
both_neurons_p = [both_neurons_p; C];
% both_neuron_s.(layer) = D;
both_neurons_s = [both_neurons_s; D];
end

for layer = layer_num_audio_start:layer_num_audio_end
    layer = layer
    
    % Initialize variables
    p_only_layer_005 = []; p_only_neuron_005 = []; p_only_token_005 = []; p_only_t_005 = [];
    s_only_layer_005 = []; s_only_neuron_005 = []; s_only_token_005 = []; s_only_t_005 = [];
    p_s_both_layer_005 = []; p_s_both_neuron_005 = []; p_s_both_token_005 = []; p_s_both_pt_005 = []; p_s_both_st_005 = [];
    p_s_none_layer_005 = []; p_s_none_neuron_005 = []; p_s_none_token_005 = []; p_s_none_pt_005 = []; p_s_none_st_005 = [];
        for neuron = 1:neuron_audio
        neuron = neuron
        i_neuron = i_neuron + 1;
        
        selec1_temp = [];
        selec2_temp = [];
        
        for token = 1:2
            rdm = rdm_cell_audio{neuron,token,layer};
            
            % Phonology processing
            elements_tongyin = []; % Similar-Phonology (only different semantics)
            elements_yiyin = [];   % Different-Phonology (different semantics + similar semantics)
            for x = 27:52
                for y = 1:26
                    if x == y + 26
                        elements_tongyin = [elements_tongyin, rdm(x, y)];
                    end
                end
            end
            for x = 2:52
                for y = 1:x-1
                    if x ~= y + 26
                        elements_yiyin = [elements_yiyin, rdm(x, y)];
                    end
                end
            end
            
            % Calculate mean values
            mean_tongyin = mean(elements_tongyin);
            mean_yiyin = mean(elements_yiyin);
            
            % Semantics processing
            elements_tongyi = [];  % Similar-Semantics (only different phonology)
            elements_yiyi = [];    % Different-Semantics (different phonology + similar phonology)
            for x = 2:26
                for y = 1:(x-1)
                    elements_tongyi = [elements_tongyi, rdm(x, y)];
                end
            end
            for x = 28:52
                for y = 27:(x-1)
                    elements_tongyi = [elements_tongyi, rdm(x, y)];
                end
            end
            for x = 27:52
                for y = 1:26
                    elements_yiyi = [elements_yiyi, rdm(x, y)];
                end
            end           
            
            % Calculate t-test
            [h1, p1, ~, stats1] = ttest2(elements_yiyin, elements_tongyin);
            [h2, p2, ~, stats2] = ttest2(elements_yiyi, elements_tongyi);
            
            if p1 < 0.05 && stats1.tstat > 0 
                selec1_temp(token) = 1;
            else
                selec1_temp(token) = 0;
            end
            
           if p2 < 0.05 && stats2.tstat > 0 
                selec2_temp(token) = 1;
           else
                selec2_temp(token) = 0;
           end
                
            % Record classification
            if p1 < 0.05 && stats1.tstat > 0 
                if p2 < 0.05 && stats2.tstat > 0
                    p_s_both_layer_005 = [p_s_both_layer_005, layer];
                    p_s_both_neuron_005 = [p_s_both_neuron_005, neuron];
                    p_s_both_token_005 = [p_s_both_token_005, token];
                    p_s_both_pt_005 = [p_s_both_pt_005, stats1.tstat];
                    p_s_both_st_005 = [p_s_both_st_005, stats2.tstat];
                else 
                    p_only_layer_005 = [p_only_layer_005, layer];
                    p_only_neuron_005 = [p_only_neuron_005, neuron];
                    p_only_token_005 = [p_only_token_005, token];
                    p_only_t_005 = [p_only_t_005, stats1.tstat];
                end
            else
                if p2 < 0.05 && stats2.tstat > 0  
                    s_only_layer_005 = [s_only_layer_005, layer];
                    s_only_neuron_005 = [s_only_neuron_005, neuron];
                    s_only_token_005 = [s_only_token_005, token];
                    s_only_t_005 = [s_only_t_005, stats2.tstat];
                else
                    p_s_none_layer_005 = [p_s_none_layer_005, layer];
                    p_s_none_neuron_005 = [p_s_none_neuron_005, neuron];
                    p_s_none_token_005 = [p_s_none_token_005, token];
                    p_s_none_pt_005 = [p_s_none_pt_005, stats1.tstat];
                    p_s_none_st_005 = [p_s_none_st_005, stats2.tstat];
                end
            end
        end
        
        indices1 = find(selec1_temp == 1);
        indices2 = find(selec2_temp == 1);
        if ~isempty(indices1)
          all_layer_neuron_token_selective_label{i_neuron,3} = 1;  %pho
          all_layer_neuron_token_selective_label{i_neuron,4} = indices1;
        end 
        
        if ~isempty(indices2)
          all_layer_neuron_token_selective_label{i_neuron,5} = 1;  %sem
          all_layer_neuron_token_selective_label{i_neuron,6} = indices2;  
        end 
        
        if ~isempty(indices1) 
            if ~isempty(indices2)
               all_layer_neuron_token_selective_label{i_neuron,7} = 1;  %both
%                all_layer_neuron_token_selective_label{i_neuron,14} = 0;
            else
                all_layer_neuron_token_selective_label{i_neuron,8} = 1;  %pho only
%                 all_layer_neuron_token_selective_label{i_neuron,14} = 1;
            end
        elseif  ~isempty(indices2)
            all_layer_neuron_token_selective_label{i_neuron,9} = 1;   %sem only
%             all_layer_neuron_token_selective_label{i_neuron,14} = -1;
%         else
%             all_layer_neuron_token_selective_label{i_neuron,14} = 2;
        end
        
        all_layer_neuron_token_selective_label{i_neuron,1} = layer;
        all_layer_neuron_token_selective_label{i_neuron,2} = neuron;
        end
    
% % Store results
% layer_cell = num2cell(repmat(layer, length(p_only_neuron_005), 1));
% phonology_representation_005.(layer) = [layer_cell, num2cell(p_only_neuron_005'), num2cell(p_only_token_005'), num2cell(p_only_t_005')];
% 
% layer_cell = num2cell(repmat(layer, length(s_only_neuron_005), 1));
% semantics_representation_005.(layer) = [layer_cell, num2cell(s_only_neuron_005'), num2cell(s_only_token_005'), num2cell(s_only_t_005')];
% 
% layer_cell = num2cell(repmat(layer, length(p_s_both_neuron_005), 1));
% both_representation_005.(layer) = [layer_cell, num2cell(p_s_both_neuron_005'), num2cell(p_s_both_token_005'), num2cell(p_s_both_pt_005'), num2cell(p_s_both_st_005')];
% 
% layer_cell = num2cell(repmat(layer, length(p_s_none_neuron_005), 1));
% none_representation_005.(layer) = [layer_cell, num2cell(p_s_none_neuron_005'), num2cell(p_s_none_token_005'), num2cell(p_s_none_pt_005'), num2cell(p_s_none_st_005')];
A = [num2cell(p_only_layer_005'), num2cell(p_only_neuron_005'), num2cell(p_only_token_005'), num2cell(p_only_t_005')];
B = [num2cell(s_only_layer_005'), num2cell(s_only_neuron_005'), num2cell(s_only_token_005'), num2cell(s_only_t_005')];
% both_representation_005.(layer) = [num2cell(p_s_both_layer_005'), num2cell(p_s_both_neuron_005'), num2cell(p_s_both_token_005'), num2cell(p_s_both_pt_005'), num2cell(p_s_both_st_005')];
% none_representation_005.(layer) = [num2cell(p_s_none_layer_005'), num2cell(p_s_none_neuron_005'), num2cell(p_s_none_token_005'), num2cell(p_s_none_pt_005'), num2cell(p_s_none_st_005')];
% Extract RDMs representing only phonology and semantics
% A = phonology_representation_005.(layer);  
% B = semantics_representation_005.(layer);  
% Create C and D to respectively store cases representing both phonology and semantics
% layer_cell = num2cell(repmat(layer, length(p_s_both_neuron_005), 1));
% C = [layer_cell, num2cell(p_s_both_neuron_005'), num2cell(p_s_both_token_005'), num2cell(p_s_both_pt_005')];
% layer_cell = num2cell(repmat(layer, length(p_s_both_neuron_005), 1));
% D = [layer_cell, num2cell(p_s_both_neuron_005'), num2cell(p_s_both_token_005'), num2cell(p_s_both_st_005')];
C = [num2cell(p_s_both_layer_005'), num2cell(p_s_both_neuron_005'), num2cell(p_s_both_token_005'), num2cell(p_s_both_pt_005')];
D = [num2cell(p_s_both_layer_005'), num2cell(p_s_both_neuron_005'), num2cell(p_s_both_token_005'), num2cell(p_s_both_st_005')];
% **Find elements with identical second columns (neuron numbers) in A and B** (Within the loop, the first column 'layer' is identical)
if isempty(A) || isempty(B) || size(A,2) < 2 || size(B,2) < 2
    warning('A or B is empty, or has fewer than 2 columns, skipping intersect calculation.');
    common_values = [];  % Set as an empty array to avoid errors
else
    common_values = intersect(cell2mat(A(:,2)), cell2mat(B(:,2)));
end
% Extract rows in A with second columns matching B, store in C
for i = 1:length(common_values)
    matching_rows = cell2mat(A(:,2)) == common_values(i);
    C = [C; A(matching_rows, :)];
end
% Extract rows in B with second columns matching A, store in D
for i = 1:length(common_values)
    matching_rows = cell2mat(B(:,2)) == common_values(i);
    D = [D; B(matching_rows, :)];
end
% **Delete these matching rows from A and B**
% A(ismember(cell2mat(A(:,2)), common_values), :) = [];
% B(ismember(cell2mat(B(:,2)), common_values), :) = [];
% **Delete rows from A that have identical first and second columns to C**
if isempty(A) || isempty(C) || size(A,2) < 2 || size(C,2) < 2
    warning('A or C is empty, or has fewer than 2 columns, skipping deletion.');
else
    A(ismember(cell2mat(A(:,1:2)), cell2mat(C(:,1:2)), 'rows'), :) = [];
end
% **Delete rows from B that have identical first and second columns to D**
if isempty(B) || isempty(D) || size(B,2) < 2 || size(D,2) < 2
    warning('B or D is empty, or has fewer than 2 columns, skipping deletion.');
else
    B(ismember(cell2mat(B(:,1:2)), cell2mat(D(:,1:2)), 'rows'), :) = [];
end
% **Store final results**
% p_only_neuron.(layer) = A;
pho_only_neurons = [pho_only_neurons; A];
% s_only_neuron.(layer) = B;
sem_only_neurons = [sem_only_neurons; B];
% both_neuron_p.(layer) = C;
both_neurons_p = [both_neurons_p; C];
% both_neuron_s.(layer) = D;
both_neurons_s = [both_neurons_s; D];
end

for layer = layer_num_transformer_start:layer_num_transformer_end
    layer = layer
    
    % Initialize variables
    p_only_layer_005 = []; p_only_neuron_005 = []; p_only_token_005 = []; p_only_t_005 = [];
    s_only_layer_005 = []; s_only_neuron_005 = []; s_only_token_005 = []; s_only_t_005 = [];
    p_s_both_layer_005 = []; p_s_both_neuron_005 = []; p_s_both_token_005 = []; p_s_both_pt_005 = []; p_s_both_st_005 = [];
    p_s_none_layer_005 = []; p_s_none_neuron_005 = []; p_s_none_token_005 = []; p_s_none_pt_005 = []; p_s_none_st_005 = [];
        for neuron = 1:neuron_transformer
        neuron = neuron
        i_neuron = i_neuron + 1;
        
        selec1_temp = [];
        selec2_temp = [];
        
        for token = 1:2
            rdm = rdm_cell_transformer{neuron,token,layer};
            
            % Phonology processing
            elements_tongyin = []; % Similar-Phonology (only different semantics)
            elements_yiyin = [];   % Different-Phonology (different semantics + similar semantics)
            for x = 27:52
                for y = 1:26
                    if x == y + 26
                        elements_tongyin = [elements_tongyin, rdm(x, y)];
                    end
                end
            end
            for x = 2:52
                for y = 1:x-1
                    if x ~= y + 26
                        elements_yiyin = [elements_yiyin, rdm(x, y)];
                    end
                end
            end
            
            % Calculate mean values
            mean_tongyin = mean(elements_tongyin);
            mean_yiyin = mean(elements_yiyin);
            
            % Semantics processing
            elements_tongyi = [];  % Similar-Semantics (only different phonology)
            elements_yiyi = [];    % Different-Semantics (different phonology + similar phonology)
            for x = 2:26
                for y = 1:(x-1)
                    elements_tongyi = [elements_tongyi, rdm(x, y)];
                end
            end
            for x = 28:52
                for y = 27:(x-1)
                    elements_tongyi = [elements_tongyi, rdm(x, y)];
                end
            end
            for x = 27:52
                for y = 1:26
                    elements_yiyi = [elements_yiyi, rdm(x, y)];
                end
            end           
            
            % Calculate t-test
            [h1, p1, ~, stats1] = ttest2(elements_yiyin, elements_tongyin);
            [h2, p2, ~, stats2] = ttest2(elements_yiyi, elements_tongyi);
            
            if p1 < 0.05 && stats1.tstat > 0 
                selec1_temp(token) = 1;
            else
                selec1_temp(token) = 0;
            end
            
           if p2 < 0.05 && stats2.tstat > 0 
                selec2_temp(token) = 1;
           else
                selec2_temp(token) = 0;
           end
                
            % Record classification
            if p1 < 0.05 && stats1.tstat > 0 
                if p2 < 0.05 && stats2.tstat > 0
                    p_s_both_layer_005 = [p_s_both_layer_005, layer];
                    p_s_both_neuron_005 = [p_s_both_neuron_005, neuron];
                    p_s_both_token_005 = [p_s_both_token_005, token];
                    p_s_both_pt_005 = [p_s_both_pt_005, stats1.tstat];
                    p_s_both_st_005 = [p_s_both_st_005, stats2.tstat];
                else 
                    p_only_layer_005 = [p_only_layer_005, layer];
                    p_only_neuron_005 = [p_only_neuron_005, neuron];
                    p_only_token_005 = [p_only_token_005, token];
                    p_only_t_005 = [p_only_t_005, stats1.tstat];
                end
            else
                if p2 < 0.05 && stats2.tstat > 0  
                    s_only_layer_005 = [s_only_layer_005, layer];
                    s_only_neuron_005 = [s_only_neuron_005, neuron];
                    s_only_token_005 = [s_only_token_005, token];
                    s_only_t_005 = [s_only_t_005, stats2.tstat];
                else
                    p_s_none_layer_005 = [p_s_none_layer_005, layer];
                    p_s_none_neuron_005 = [p_s_none_neuron_005, neuron];
                    p_s_none_token_005 = [p_s_none_token_005, token];
                    p_s_none_pt_005 = [p_s_none_pt_005, stats1.tstat];
                    p_s_none_st_005 = [p_s_none_st_005, stats2.tstat];
                end
            end
        end
        
        indices1 = find(selec1_temp == 1);
        indices2 = find(selec2_temp == 1);
        if ~isempty(indices1)
          all_layer_neuron_token_selective_label{i_neuron,3} = 1;  %pho
          all_layer_neuron_token_selective_label{i_neuron,4} = indices1;
        end 
        
        if ~isempty(indices2)
          all_layer_neuron_token_selective_label{i_neuron,5} = 1;  %sem
          all_layer_neuron_token_selective_label{i_neuron,6} = indices2;  
        end 
        
        if ~isempty(indices1) 
            if ~isempty(indices2)
               all_layer_neuron_token_selective_label{i_neuron,7} = 1;  %both
%                all_layer_neuron_token_selective_label{i_neuron,14} = 0;
            else
                all_layer_neuron_token_selective_label{i_neuron,8} = 1;  %pho only
%                 all_layer_neuron_token_selective_label{i_neuron,14} = 1;
            end
        elseif  ~isempty(indices2)
            all_layer_neuron_token_selective_label{i_neuron,9} = 1;   %sem only
%             all_layer_neuron_token_selective_label{i_neuron,14} = -1;
%         else
%             all_layer_neuron_token_selective_label{i_neuron,14} = 2;
        end
        
        all_layer_neuron_token_selective_label{i_neuron,1} = layer;
        all_layer_neuron_token_selective_label{i_neuron,2} = neuron;
        end
        
% % Store results
% layer_cell = num2cell(repmat(layer, length(p_only_neuron_005), 1));
% phonology_representation_005.(layer) = [layer_cell, num2cell(p_only_neuron_005'), num2cell(p_only_token_005'), num2cell(p_only_t_005')];
% 
% layer_cell = num2cell(repmat(layer, length(s_only_neuron_005), 1));
% semantics_representation_005.(layer) = [layer_cell, num2cell(s_only_neuron_005'), num2cell(s_only_token_005'), num2cell(s_only_t_005')];
% 
% layer_cell = num2cell(repmat(layer, length(p_s_both_neuron_005), 1));
% both_representation_005.(layer) = [layer_cell, num2cell(p_s_both_neuron_005'), num2cell(p_s_both_token_005'), num2cell(p_s_both_pt_005'), num2cell(p_s_both_st_005')];
% 
% layer_cell = num2cell(repmat(layer, length(p_s_none_neuron_005), 1));
% none_representation_005.(layer) = [layer_cell, num2cell(p_s_none_neuron_005'), num2cell(p_s_none_token_005'), num2cell(p_s_none_pt_005'), num2cell(p_s_none_st_005')];
A = [num2cell(p_only_layer_005'), num2cell(p_only_neuron_005'), num2cell(p_only_token_005'), num2cell(p_only_t_005')];
B = [num2cell(s_only_layer_005'), num2cell(s_only_neuron_005'), num2cell(s_only_token_005'), num2cell(s_only_t_005')];
% both_representation_005.(layer) = [num2cell(p_s_both_layer_005'), num2cell(p_s_both_neuron_005'), num2cell(p_s_both_token_005'), num2cell(p_s_both_pt_005'), num2cell(p_s_both_st_005')];
% none_representation_005.(layer) = [num2cell(p_s_none_layer_005'), num2cell(p_s_none_neuron_005'), num2cell(p_s_none_token_005'), num2cell(p_s_none_pt_005'), num2cell(p_s_none_st_005')];
% Extract RDMs representing only phonology and semantics
% A = phonology_representation_005.(layer);  
% B = semantics_representation_005.(layer);  
% Create C and D to respectively store cases representing both phonology and semantics
% layer_cell = num2cell(repmat(layer, length(p_s_both_neuron_005), 1));
% C = [layer_cell, num2cell(p_s_both_neuron_005'), num2cell(p_s_both_token_005'), num2cell(p_s_both_pt_005')];
% layer_cell = num2cell(repmat(layer, length(p_s_both_neuron_005), 1));
% D = [layer_cell, num2cell(p_s_both_neuron_005'), num2cell(p_s_both_token_005'), num2cell(p_s_both_st_005')];
C = [num2cell(p_s_both_layer_005'), num2cell(p_s_both_neuron_005'), num2cell(p_s_both_token_005'), num2cell(p_s_both_pt_005')];
D = [num2cell(p_s_both_layer_005'), num2cell(p_s_both_neuron_005'), num2cell(p_s_both_token_005'), num2cell(p_s_both_st_005')];
% **Find elements with identical second columns (neuron numbers) in A and B** (Within the loop, the first column 'layer' is identical)
if isempty(A) || isempty(B) || size(A,2) < 2 || size(B,2) < 2
    warning('A or B is empty, or has fewer than 2 columns, skipping intersect calculation.');
    common_values = [];  % Set as an empty array to avoid errors
else
    common_values = intersect(cell2mat(A(:,2)), cell2mat(B(:,2)));
end
% Extract rows in A with second columns matching B, store in C
for i = 1:length(common_values)
    matching_rows = cell2mat(A(:,2)) == common_values(i);
    C = [C; A(matching_rows, :)];
end
% Extract rows in B with second columns matching A, store in D
for i = 1:length(common_values)
    matching_rows = cell2mat(B(:,2)) == common_values(i);
    D = [D; B(matching_rows, :)];
end
% **Delete these matching rows from A and B**
% A(ismember(cell2mat(A(:,2)), common_values), :) = [];
% B(ismember(cell2mat(B(:,2)), common_values), :) = [];
% **Delete rows from A that have identical first and second columns to C**
if isempty(A) || isempty(C) || size(A,2) < 2 || size(C,2) < 2
    warning('A or C is empty, or has fewer than 2 columns, skipping deletion.');
else
    A(ismember(cell2mat(A(:,1:2)), cell2mat(C(:,1:2)), 'rows'), :) = [];
end
% **Delete rows from B that have identical first and second columns to D**
if isempty(B) || isempty(D) || size(B,2) < 2 || size(D,2) < 2
    warning('B or D is empty, or has fewer than 2 columns, skipping deletion.');
else
    B(ismember(cell2mat(B(:,1:2)), cell2mat(D(:,1:2)), 'rows'), :) = [];
end
% **Store final results**
% p_only_neuron.(layer) = A;
pho_only_neurons = [pho_only_neurons; A];
% s_only_neuron.(layer) = B;
sem_only_neurons = [sem_only_neurons; B];
% both_neuron_p.(layer) = C;
both_neurons_p = [both_neurons_p; C];
% both_neuron_s.(layer) = D;
both_neurons_s = [both_neurons_s; D];
end

% Save the overall structure for all models
% save([save_folder, num2str(name),'all_layers_phonology_representation_005.mat'], 'phonology_representation_005');
% save([save_folder, num2str(name),'all_layers_semantics_representation_005.mat'], 'semantics_representation_005');
% save([save_folder, num2str(name),'all_layers_both_representation_005.mat'], 'both_representation_005');
% save([save_folder, num2str(name),'all_layers_none_representation_005.mat'], 'none_representation_005');
% 
% save([save_folder, num2str(name),'all_layers_p_only_contact.mat'], 'p_only_contact');
% save([save_folder, num2str(name),'all_layers_s_only_contact.mat'], 's_only_contact');
% save([save_folder, num2str(name),'all_layers_both_contact_p.mat'], 'both_contact_p');
% save([save_folder, num2str(name),'all_layers_both_contact_s.mat'], 'both_contact_s');
save([save_folder_2, num2str(name), '_pho_only_neurons.mat'], 'pho_only_neurons');
save([save_folder_2, num2str(name),'_sem_only_neurons.mat'], 'sem_only_neurons');
save([save_folder_2, num2str(name), '_both_neurons_p.mat'], 'both_neurons_p');
save([save_folder_2, num2str(name), '_both_neurons_s.mat'], 'both_neurons_s');    
save([save_folder_2, num2str(name), '_all_layer_neuron_token_selective_label.mat'], 'all_layer_neuron_token_selective_label');