clear all
close all

% Load activation data from a custom directory
load('/path/to/your/custom/activations/directory/activation_qwen2_audio_layer_66.mat')
name = 'qwen2_audio';

% Specify a custom directory for saving the output
save_folder = '/path/to/your/custom/save/directory/Cos_dist_token_neuron/';

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

rdm_cell_conv = cell(neuron_conv,2,layer_num_conv );
rdm_cell_audio = cell(neuron_audio,2,layer_num_audio);
rdm_cell_transformer = cell(neuron_transformer,2,layer_num_transformer);
%%
% Iterate through each layer and each neuron
for layer = layer_num_conv_start:layer_num_conv_end
    layer = layer
    length_scale = size(data_cell{1,layer},2)/2
    
    for token = 1:2
        token = token
        if floor(length_scale) == length_scale
           start_idx = 1 + (token - 1) * length_scale;
           end_idx = token * length_scale;
        elseif token == 1
           start_idx = 1 + (token - 1) * length_scale;
           end_idx = token * round(length_scale);
        else
           start_idx = 1 + round(length_scale);
           end_idx = token * length_scale;
        end
         
    for neuron = 1:neuron_conv
        nrueon = neuron;
        % Initialize a 52x52 RDM matrix
        rdm = nan(52, 52);
        
        % Calculate the activation distance for each pair of words
        for i = 1:52
            for j = i+1:52  % Avoid redundant calculations because the RDM is symmetric
                % Get the activation values of the two words for the current layer and neuron
                activation_i = data_cell{i, layer}(neuron, start_idx:end_idx);
                activation_j = data_cell{j, layer}(neuron, start_idx:end_idx);
                
                % If the two activations have different lengths, truncate to the shorter length
                min_length = min(length(activation_i), length(activation_j));
                activation_i = activation_i(1:min_length);
                activation_j = activation_j(1:min_length);
                
                if any(isnan(activation_i)) || any(isnan(activation_j)) || any(isinf(activation_i)) || any(isinf(activation_j))
                   warning('NaN or Inf detected in activation vectors!');
                end
                
                % Calculate Euclidean distance
%                 dist = norm(activation_i - activation_j);
                
                % Calculate Cosine distance
                dot_product = dot(activation_i, activation_j);
                norm_i = norm(activation_i);
                norm_j = norm(activation_j);
                % dist = 1 - (dot_product / (norm_i * norm_j));
                if norm_i == 0 || norm_j == 0
                    warning('Zero vector encountered. Setting distance to NaN.');
                    dist = NaN; % Or set to a reasonable default value, such as 1
                else
                    cosine_similarity = dot_product / (norm_i * norm_j);
                    cosine_similarity = max(min(cosine_similarity, 1), -1); % Limit to [-1, 1]
                    dist = 1 - cosine_similarity;
                end
                
                % Calculate correlation distance
%                   correlation_matrix = corrcoef(activation_i, activation_j);
%                   correlation_coefficient = correlation_matrix(1, 2);
%                   dist = 1 - correlation_coefficient;
                
                % Store into the RDM matrix
%                 rdm(i, j) = dist;
                rdm(j, i) = dist;  % Symmetric matrix
            end
        end
        
        % Store the RDM into the corresponding cell
        rdm_cell_conv{neuron, token, layer} = rdm;
    end
    end
end

% Iterate through each layer and each neuron
for layer = layer_num_audio_start:layer_num_audio_end
    layer = layer
    length_scale = size(data_cell{1,layer},1)/2
    
    for token = 1:2
        token = token
        if floor(length_scale) == length_scale
           start_idx = 1 + (token - 1) * length_scale;
           end_idx = token * length_scale;
        elseif token == 1
           start_idx = 1 + (token - 1) * length_scale;
           end_idx = token * round(length_scale);
        else
           start_idx = 1 + round(length_scale);
           end_idx = token * length_scale;
        end
        
    for neuron = 1:neuron_audio
        nrueon = neuron;
        % Initialize a 52x52 RDM matrix
        rdm = nan(52, 52);
        
        % Calculate the activation distance for each pair of words
        for i = 1:52
            for j = i+1:52  % Avoid redundant calculations because the RDM is symmetric
                % Get the activation values of the two words for the current layer and neuron
                activation_i = data_cell{i, layer}(start_idx:end_idx, neuron);
                activation_j = data_cell{j, layer}(start_idx:end_idx, neuron);
                
                % If the two activations have different lengths, truncate to the shorter length
                min_length = min(length(activation_i), length(activation_j));
                activation_i = activation_i(1:min_length);
                activation_j = activation_j(1:min_length);
                
                if any(isnan(activation_i)) || any(isnan(activation_j)) || any(isinf(activation_i)) || any(isinf(activation_j))
                   warning('NaN or Inf detected in activation vectors!');
                end
                
                % Calculate Euclidean distance
%                 dist = norm(activation_i - activation_j);
                
                % Calculate Cosine distance
                dot_product = dot(activation_i, activation_j);
                norm_i = norm(activation_i);
                norm_j = norm(activation_j);
                % dist = 1 - (dot_product / (norm_i * norm_j));
                if norm_i == 0 || norm_j == 0
                    warning('Zero vector encountered. Setting distance to NaN.');
                    dist = NaN; % Or set to a reasonable default value, such as 1
                else
                    cosine_similarity = dot_product / (norm_i * norm_j);
                    cosine_similarity = max(min(cosine_similarity, 1), -1); % Limit to [-1, 1]
                    dist = 1 - cosine_similarity;
                end
                
                % Calculate correlation distance
%                 corr_coef = corr(activation_i, activation_j);  % Calculate correlation coefficient
%                 dist = 1 - corr_coef;  % Correlation distance
                
                % Store into the RDM matrix
%                 rdm(i, j) = dist;
                rdm(j, i) = dist;  % Symmetric matrix
            end
        end
        
        % Store the RDM into the corresponding cell
        rdm_cell_audio{neuron, token, layer} = rdm;
    end
    end
end

% Iterate through each layer and each neuron
for layer = layer_num_transformer_start:layer_num_transformer_end
    layer = layer
    
    for token = 1:2
        token = token
        
    for neuron = 1:neuron_transformer
        nrueon = neuron;
        % Initialize a 52x52 RDM matrix
        rdm = nan(52, 52);
        
        % Calculate the activation distance for each pair of words
        for i = 1:52
            for j = i+1:52  % Avoid redundant calculations because the RDM is symmetric
                length_scale_i = size(data_cell{i,layer},1)/2;
                if floor(length_scale_i) == length_scale_i  % Even number
                  start_idx_i = 1 + (token - 1) * length_scale_i;
                  end_idx_i = token * length_scale_i;
               elseif token == 1   
                  start_idx_i = 1 + (token - 1) * length_scale_i;
                  end_idx_i = token * round(length_scale_i);
               else
                  start_idx_i = 1 + round(length_scale_i);
                  % start_idx_i = 1;  
                  end_idx_i = token * length_scale_i;
               end
               
                length_scale_j = size(data_cell{j,layer},1)/2;
                if floor(length_scale_j) == length_scale_j
                  start_idx_j = 1 + (token - 1) * length_scale_j;
                  end_idx_j = token * length_scale_j;
               elseif token == 1
                  start_idx_j = 1 + (token - 1) * length_scale_j;
                  end_idx_j = token * round(length_scale_j);
               else
                  start_idx_j = 1 + round(length_scale_j);
                  % start_idx_j = 1;
                  end_idx_j = token * length_scale_j;
               end
        
                % Get the activation values of the two words for the current layer and neuron
                activation_i = data_cell{i, layer}(start_idx_i:end_idx_i, neuron);
                activation_j = data_cell{j, layer}(start_idx_j:end_idx_j, neuron);
                
                % If the two activations have different lengths, truncate to the shorter length
                min_length = min(length(activation_i), length(activation_j));
                activation_i = activation_i(1:min_length);
                activation_j = activation_j(1:min_length);
                if any(isnan(activation_i)) || any(isnan(activation_j)) || any(isinf(activation_i)) || any(isinf(activation_j))
                   warning('NaN or Inf detected in activation vectors!');
                end
                
                % Calculate Euclidean distance
%                 dist = norm(activation_i - activation_j);
                
                % Calculate Cosine distance
                dot_product = dot(activation_i, activation_j);
                norm_i = norm(activation_i);
                norm_j = norm(activation_j);
                % dist = 1 - (dot_product / (norm_i * norm_j));
                if norm_i == 0 || norm_j == 0
                    warning('Zero vector encountered. Setting distance to NaN.');
                    dist = NaN; % Or set to a reasonable default value, such as 1
                else
                    cosine_similarity = dot_product / (norm_i * norm_j);
                    cosine_similarity = max(min(cosine_similarity, 1), -1); % Limit to [-1, 1]
                    dist = 1 - cosine_similarity;
                end
                
                % Calculate correlation distance
%                 corr_coef = corr(activation_i, activation_j);  % Calculate correlation coefficient
%                 dist = 1 - corr_coef;  % Correlation distance
                
                % Store into the RDM matrix
%                 rdm(i, j) = dist;
                rdm(j, i) = dist;  % Symmetric matrix
            end
        end
        
        % Store the RDM into the corresponding cell
        rdm_cell_transformer{neuron, token, layer} = rdm;
    end
end
end

save([save_folder,num2str(name),'_Cos_dist_rdm_conv_layer_neuron.mat'],'rdm_cell_conv');
save([save_folder,num2str(name),'_Cos_dist_rdm_audio_layer_neuron.mat'], 'rdm_cell_audio');
save([save_folder,num2str(name),'_Cos_dist_rdm_transformer_layer_neuron.mat'], 'rdm_cell_transformer');

%% Check for negative values in RDM rdm_cell_conv
[num_rdm1, num_rdm2, num_rdm3] = size(rdm_cell_conv);
has_negative_value = false;
% Iterate through all RDMs
for i = 1:num_rdm1
    for j = 1:num_rdm2
        for k = 1:num_rdm3
            rdm = rdm_cell_conv{i, j, k};  % Extract RDM
            if any(rdm(:) < 0)
                has_negative_value = true;
                fprintf('Error: The (%d, %d, %d) RDM Negative! \n', i, j, k);
            end
        end
    end
end
if has_negative_value
    disp('Error: rdm_cell_conv Negative RDM !!!!!!!!!!!!!!!!!!!!!!!!!');
else
    disp('Right: rdm_cell_conv No negative RDM!');
end

%% Check for negative values in RDM rdm_cell_audio
[num_rdm1, num_rdm2, num_rdm3] = size(rdm_cell_audio);
has_negative_value = false;
% Iterate through all RDMs
for i = 1:num_rdm1
    for j = 1:num_rdm2
        for k = 1:num_rdm3
            rdm = rdm_cell_audio{i, j, k};  % Extract RDM
            if any(rdm(:) < 0)
                has_negative_value = true;
                fprintf('Error: The (%d, %d, %d) RDM Negative! \n', i, j, k);
            end
        end
    end
end
if has_negative_value
    disp('Error: rdm_cell_audio Negative RDM !!!!!!!!!!!!!!!!!!!!!!!!!');
else
    disp('Right: rdm_cell_audio No negative RDM!');
end

%% Check for negative values in RDM rdm_cell_transformer
[num_rdm1, num_rdm2, num_rdm3] = size(rdm_cell_transformer);
has_negative_value = false;
% Iterate through all RDMs
for i = 1:num_rdm1
    for j = 1:num_rdm2
        for k = 1:num_rdm3
            rdm = rdm_cell_transformer{i, j, k};  % Extract RDM
            if any(rdm(:) < 0)
                has_negative_value = true;
                fprintf('Error: The (%d, %d, %d) RDM Negative! \n', i, j, k);
            end
        end
    end
end
if has_negative_value
    disp('Error: rdm_cell_transformer Negative RDM !!!!!!!!!!!!!!!!!!!!!!!!!');
else
    disp('Right: rdm_cell_transformer No negative RDM!');
end