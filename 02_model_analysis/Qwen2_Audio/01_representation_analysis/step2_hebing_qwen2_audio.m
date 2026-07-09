clear all
close all

% Specify the folder path (custom directory for storing activations)
folder_path = '/path/to/your/custom/activations/directory/'; 
layer = 66;
name = 'qwen2_audio';

% Initialize cell array
data_cell = cell(52, layer);

% Read data from .mat files one by one and save into the cell array
for idx_condition = 1:52
    for num_layer = 1:layer
      file_name = fullfile(folder_path, ['input_', num2str(idx_condition), '_layer_', num2str(num_layer), '_activation_', num2str(name),'.mat']);
      data = load(file_name);
      data_cell{idx_condition,num_layer} = data.activation;
    end
end

% Save the resulting cell array to a new .mat file
save([folder_path,'activation_', num2str(name),'_layer_',num2str(layer),'.mat'],'data_cell');