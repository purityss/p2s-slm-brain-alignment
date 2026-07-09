clc; clear; close all;

%% Fig 1: Model Performance 
% 1. Load Data
try
    load('model_matrix.mat'); 
    data = model_matrix(:, 1:2);
catch
    warning('File not found, using random data for demonstration...');
    data = 0.5 + 0.5 * rand(12, 2); 
end

% Define model names
model_names = {'XLSR-53-ch', 'Whisper-large-v3', 'LLaSM', 'SALMONN', ...
    'Qwen-Audio', 'Qwen-Audio-Chat', 'Qwen2-Audio', 'Qwen2-Audio-Instruct', ...
    'GLM-4-Voice', 'Freeze-Omni', 'MiniCPM-o 2.6', 'Qwen2.5-Omni'};

% 2. [Key Step] Data Sorting
% Calculate the sum of each row (total performance)
total_score = sum(data, 2);

% Get sorted indices (descending order so the highest score is first)
[~, sort_idx] = sort(total_score, 'descend');

% Rearrange data and names based on indices
sorted_data = data(sort_idx, :);
sorted_names = model_names(sort_idx);

% 3. Plot Horizontal Bar Chart
figure('Color', 'w', 'Position', [100, 100, 220, 200]);

b = barh(sorted_data, 'grouped', 'BarWidth', 0.9);

% --- Aesthetics & Colors ---
b(1).FaceColor = [26 77 178]/255;  % Blue
b(1).EdgeColor = 'none';

b(2).FaceColor = [204 178 51]/255; % Orange
b(2).EdgeColor = 'none';

hold on;

% 4. Adjust Axes and Details
ax = gca;

% Set Y-axis labels to sorted names
ax.YTick = 1:length(sorted_names);
ax.YTickLabel = sorted_names;

% [Important] Reverse Y-axis so the best performing matrix row is at the top
ax.YDir = 'reverse'; 

% Axis settings
xlim([0 100]); 
xlabel('Model performance', 'FontSize', 6);

% Grid styling
grid on;
ax.YGrid = 'off';
ax.XGrid = 'on';
ax.GridAlpha = 0.3;
ax.LineWidth = 1.2;
set(gca, 'FontSize', 6, 'Box', 'off', 'FontName', 'Arial', 'TickDir', 'out', 'LineWidth', 0.5, 'XColor', 'k', 'YColor', 'k');

%% Fig 2: Hierarchical Alignment Heatmap
% 1. Data Sorting & Processing
if exist('model_matrix', 'var') && exist('model_names', 'var')
    total_score = sum(model_matrix(:, 1:2), 2);
    [~, sort_idx] = sort(total_score, 'descend');
    sorted_matrix = model_matrix(sort_idx, :);
    sorted_names = model_names(sort_idx);
else
    error('Variables model_matrix or model_names not found in workspace. Please load data first.');
end

% 2. Prepare Heatmap Data 
% Extract original columns 3, 4, 5
raw_cols = sorted_matrix(:, 3:5);

% [Key Step] Reorder columns: [Col 3, Col 5, Col 4]
heatmap_data = raw_cols(:, [1, 3, 2]);

% Update X-axis labels to match the new data order
heatmap_x_labels = {'Phonological', 'Semantic', 'Shared'};

% 3. Define Red-White-Blue Colormap
muted_blue = [0.27, 0.45, 0.70];   % Blue (Low/Negative values)
light_gray = [0.98, 0.98, 0.98];   % White/Light Gray (Mid/Zero values)
muted_red  = [0.85, 0.35, 0.35];   % Red (High/Positive values)

n_steps = 128; % Number of gradient steps

% Blue -> White
blue_to_gray = [linspace(muted_blue(1), light_gray(1), n_steps)', ...
                linspace(muted_blue(2), light_gray(2), n_steps)', ...
                linspace(muted_blue(3), light_gray(3), n_steps)'];
% White -> Red
gray_to_red = [linspace(light_gray(1), muted_red(1), n_steps)', ...
               linspace(light_gray(2), muted_red(2), n_steps)', ...
               linspace(light_gray(3), muted_red(3), n_steps)'];

% Merge custom colormap
custom_rb_map = [blue_to_gray; gray_to_red(2:end, :)];

% 4. Plot and Format Heatmap
figure('Color', 'w', 'Position', [100, 100, 260, 200]); 
h = heatmap(heatmap_x_labels, sorted_names, heatmap_data);

% --- Apply Colormap and Limits ---
colormap(custom_rb_map);

% [Important] Set symmetric color range so 0 maps perfectly to white
limit = max(abs(heatmap_data(:))); 
h.ColorLimits = [-1, 1]; 

% --- Aesthetics ---
h.Title = 'Hierarchical Alignment Index'; 
h.CellLabelFormat = '%.4f';       % Keep two decimal places
h.XLabel = '';                    
h.YLabel = '';                    
h.FontSize = 6;
h.FontName = 'Arial';
h.GridVisible = 'off';            % Remove gridlines for a cleaner look

h.XDisplayLabels = heatmap_x_labels;
h.YDisplayLabels = sorted_names;
h.ColorbarVisible = 'off';

set(gca, 'FontSize', 6, 'FontName', 'Arial');


%% Fig 3: Sequential Alignment Heatmap
% 1. Data Sorting & Processing
if exist('model_matrix', 'var') && exist('model_names', 'var')
    total_score = sum(model_matrix(:, 1:2), 2);
    [~, sort_idx] = sort(total_score, 'descend');
    sorted_matrix = model_matrix(sort_idx, :);
    sorted_names = model_names(sort_idx);
else
    error('Variables model_matrix or model_names not found in workspace. Please load data first.');
end

% 2. Prepare Heatmap Data
% Extract original columns 6, 7, 8
raw_cols = sorted_matrix(:, 6:8);

% [Key Step] Reorder columns: [Col 6, Col 8, Col 7]
heatmap_data = raw_cols(:, [1, 3, 2]);

% Update X-axis labels to match the new data order
heatmap_x_labels = {'Phonological', 'Semantic', 'Shared'};

% 3. Define Red-White-Blue Colormap
muted_blue = [0.27, 0.45, 0.70];   % Blue (Low/Negative values)
light_gray = [0.98, 0.98, 0.98];   % White/Light Gray (Mid/Zero values)
muted_red  = [0.85, 0.35, 0.35];   % Red (High/Positive values)

n_steps = 128; 

% Blue -> White
blue_to_gray = [linspace(muted_blue(1), light_gray(1), n_steps)', ...
                linspace(muted_blue(2), light_gray(2), n_steps)', ...
                linspace(muted_blue(3), light_gray(3), n_steps)'];
% White -> Red
gray_to_red = [linspace(light_gray(1), muted_red(1), n_steps)', ...
               linspace(light_gray(2), muted_red(2), n_steps)', ...
               linspace(light_gray(3), muted_red(3), n_steps)'];

% Merge custom colormap
custom_rb_map = [blue_to_gray; gray_to_red(2:end, :)];

% 4. Plot and Format Heatmap
figure('Color', 'w', 'Position', [100, 100, 260, 200]); 
h = heatmap(heatmap_x_labels, sorted_names, heatmap_data);

% --- Apply Colormap and Limits ---
colormap(custom_rb_map);

% [Important] Set symmetric color range so 0 maps perfectly to white
limit = max(abs(heatmap_data(:))); 
h.ColorLimits = [-1, 1]; 

% --- Aesthetics ---
h.Title = 'Sequential Alignment Index'; 
h.CellLabelFormat = '%.4f';       
h.XLabel = '';                    
h.YLabel = '';                    
h.FontSize = 6;
h.FontName = 'Arial';
h.GridVisible = 'off';            

h.XDisplayLabels = heatmap_x_labels;
h.YDisplayLabels = sorted_names;
h.ColorbarVisible = 'off';

set(gca, 'FontSize', 6, 'FontName', 'Arial');