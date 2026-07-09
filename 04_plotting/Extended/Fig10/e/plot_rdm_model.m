clear all
close all

% --- Load Data ---
name = 'qwen2_audio';
% Load data file containing token RDMs (assumes a cell array named 'sem_avg_token_rdm')
load(strcat(name, '_sem_avg_token_rdm.mat')); 

token = 1;  % Select token {1, 2}
mean_rdm = sem_avg_token_rdm{token};

% Load sorted normalization factor
load('Y_normalized.mat')
if length(Y_normalized) ~= 26
    error('Y_normalized length must be 26, but got %d. Please check MDS calculation.', length(Y_normalized));
end

% --- Reorder Words ---
similarityMatrix = mean_rdm;

% Duplicate Y_normalized to make it 52x1
Y_normalized_52 = [Y_normalized; Y_normalized]; 

% Get the new sorting order (ascending order)
[~, sortedIdx1] = sort(Y_normalized_52(1:26));  
[~, sortedIdx2] = sort(Y_normalized_52(27:52)); 
newOrder = [sortedIdx1; sortedIdx2 + 26];

% Create a new RDM and preallocate with NaN
reorderedRDM = NaN(52, 52); 

% Iterate through the lower triangular part of the original RDM
for i = 2:52
    for j = 1:i-1  % Only operate on the lower triangle (i > j)
        % Get the original value
        original_value = similarityMatrix(i, j);
        
        % Get the new indices for i and j based on the sorting order
        new_i = find(newOrder == i);
        new_j = find(newOrder == j);
        
        % Ensure new_i > new_j so it stays in the lower triangle
        if new_i > new_j
            reorderedRDM(new_i, new_j) = original_value;
        else
            reorderedRDM(new_j, new_i) = original_value;
        end
    end
end
reorderedRDM_all = reorderedRDM;

% --- Plot the Reordered RDM Heatmap ---
figure(1); clf;
set(gcf, 'Position', [300, 300, 102, 100]); 

% Draw heatmap
h = imagesc(reorderedRDM_all); 

% Define custom colormap nodes (bottom to top)
color1 = [50, 28, 90] / 255;    % Dark Blue (bottom)
color2 = [40, 100, 120] / 255;  % Purple-Blue
color3 = [45, 175, 120] / 255;  % Teal/Green
color4 = [170, 215, 60] / 255;  % Light Green
color5 = [252, 245, 65] / 255;  % Bright Yellow (top)

% Combine control points
control_colors = [color1; color2; color3; color4; color5];

% Generate smooth 256-level gradient
n = 256;
x = linspace(1, 5, size(control_colors, 1)); % Positions of the 5 original color nodes
xi = linspace(1, 5, n);                      % 256 interpolated positions
custom_map = interp1(x, control_colors, xi);

% Apply colormap
colormap(custom_map);

% Set NaN values to be transparent
set(h, 'AlphaData', ~isnan(reorderedRDM_all)); 

% Format axes and remove borders
set(gca, 'FontSize', 16, 'TickDir', 'out');
box off;

% Hide coordinate axes, ticks, labels, and borders
set(gca, 'XColor', 'none', 'YColor', 'none'); 
set(gca, 'XTick', [], 'YTick', []); 
xlabel('');
ylabel('');
axis off;