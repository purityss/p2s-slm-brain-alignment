clear all
close all

name = 'qwen2_audio';
load(strcat(name, '_start_pho_only_neurons.mat'));
load(strcat(name, '_start_sem_only_neurons.mat'));
load(strcat(name, '_start_both_neurons_p.mat'));
load(strcat(name, '_start_both_neurons_s.mat'));

% Set save folder to the current working directory
save_folder = [pwd, filesep];

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

% Define total layers
total_layers = layer_num_conv + layer_num_audio + layer_num_transformer;
num_all_p_s = zeros(total_layers, 6); % Create a 66 x 6 matrix
num_all_p_s(:,1) = (1:total_layers)'; % First column: layer number 1-66

% Set total number of neurons (second column)
num_all_p_s(layer_num_conv_start:layer_num_conv_end, 2) = neuron_conv;            % Layers 1-2 -> 1280
num_all_p_s(layer_num_audio_start:layer_num_audio_end, 2) = neuron_audio;          % Layers 3-34 -> 1280
num_all_p_s(layer_num_transformer_start:layer_num_transformer_end, 2) = neuron_transformer;   % Layers 35-66 -> 4096

% Calculate the number of unique neurons in each layer for each dataset
datasets = {start_pho_only_neurons, start_sem_only_neurons, start_both_neurons_p, start_both_neurons_s};
for k = 1:length(datasets)
    data = datasets{k};  % Select current dataset
    
    % Iterate through layers 1-66
    for layer = 1:total_layers
        % Get all neurons in the current layer
        neurons_in_layer = data(cell2mat(data(:,1)) == layer, 2);
        
        % Remove duplicates and count
        num_all_p_s(layer, k+2) = numel(unique(cell2mat(neurons_in_layer))); 
    end
end

save([save_folder, num2str(name),'_layer_neurons_counts','.mat'],'num_all_p_s');