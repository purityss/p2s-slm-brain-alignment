clear all
close all
clc

% ==========================================
% 1. Data Loading & Settings
% ==========================================
% --- Load Heatmap Data ---
load('numeric_p_s_t.mat'); 
Data_Heatmap = numeric_p_s_t; % Complete matrix

% --- Load Line Plot Data ---
load('numeric_phonology_t.mat');
Data_Line_Pho = numeric_phonology_t(:, 1:11); % Extract first 11 points 
load('numeric_semantics_t.mat');
Data_Line_Sem = numeric_semantics_t(:, 1:11); % Extract first 11 points

% --- Define Indices ---
num_pho = 210;
num_both = 43;
num_sem = 218;

p2 = num_pho;
b1 = p2 + 1;
b2 = p2 + num_both;
s1 = b2 + 1;
s2 = b2 + num_sem;

% ==========================================
% 2. Data Processing (Sorting & Means)
% ==========================================
% --- 2.1 Heatmap Sorting ---
% Region 1: Phonological (Sort by sum descending)
H1 = Data_Heatmap(1:p2, :);
[~, idx1] = sort(sum(H1, 2), 'descend');
H1_sorted = H1(idx1, :);

% Region 2: Shared/Both (Sort by row max descending)
H2 = Data_Heatmap(b1:b2, :);
rowMax = max(H2, [], 2); 
[~, idx2] = sort(rowMax, 'descend');
H2_sorted = H2(idx2, :);

% Region 3: Semantic (Sort by sum descending)
H3 = Data_Heatmap(s1:s2, :);
[~, idx3] = sort(sum(H3, 2), 'descend');
H3_sorted = H3(idx3, :);

% Package data (Order: Phonological -> Semantic -> Shared)
Heatmaps = {H1_sorted, H3_sorted, H2_sorted}; 
Row_Titles = {'Phonological', 'Semantic', 'Shared (Transfer)'};

% --- 2.2 Line Plot Means ---
% Region 1 (Phonological)
mA1 = mean(Data_Line_Pho(1:p2, :), 1);
mB1 = mean(Data_Line_Sem(1:p2, :), 1);

% Region 2 (Both)
mA2 = mean(Data_Line_Pho(b1:b2, :), 1);
mB2 = mean(Data_Line_Sem(b1:b2, :), 1);

% Region 3 (Semantic)
mA3 = mean(Data_Line_Pho(s1:s2, :), 1);
mB3 = mean(Data_Line_Sem(s1:s2, :), 1);

% Package means matching the Heatmaps order {Pho, Sem, Both}
Means_A = {mA1, mA3, mA2};
Means_B = {mB1, mB3, mB2};

% ==========================================
% 3. Plotting
% ==========================================
figure(1);
set(gcf, 'Position', [100, 100, 315, 260]); % Adjust figure proportions for 3 rows
set(gcf, 'Color', 'w');

% Layout: 3 rows, 5 columns (Left 2 cols for heatmap, Right 3 cols for line plot)
t = tiledlayout(3, 5, 'TileSpacing', 'loose', 'Padding', 'compact');

% Custom Colormap (Red-White-Blue)
cmap = [186/256, 48/256, 49/256; 1 1 1; 35/256, 100/256, 156/256];
cmap = flipud(cmap); 
cmap_smooth = interp1(linspace(0, 1, size(cmap, 1)), cmap, linspace(0, 1, 256));

% Time axis setup (50ms steps)
time_points = 50 * (1:size(Data_Line_Pho, 2)); 
x_limit = [0, 600];
y_limit = [-1, 1];

for k = 1:3
    % ---------------------------
    % Left Column: Heatmap
    % ---------------------------
    tile_idx_heatmap = (k-1)*5 + 1;
    nexttile(tile_idx_heatmap, [1 2]);
    
    imagesc(Heatmaps{k});
    colormap(gca, cmap_smooth); 
    caxis([-3, 3]); 
    
    % Styling
    set(gca, 'FontSize', 6, 'FontName', 'Arial', ...
        'TickDir', 'out', 'TickLength', [0, 0], ...
        'XColor', 'k', 'YColor', 'k', ...
        'LineWidth', 0.5, 'Box', 'on');
    set(gca, 'XTick', []); % Hide X-axis ticks for heatmaps
    
    % Title (Row headers)
    title(Row_Titles{k}, 'FontSize', 10, 'Color', 'w', 'FontWeight', 'bold');
    
    % YLabel (Contact Number)
    ylabel('Contact number', 'FontSize', 6);

    % ---------------------------
    % Right Column: Line Plot
    % ---------------------------
    tile_idx_line = (k-1)*5 + 3;
    nexttile(tile_idx_line, [1 3]);
    
    hold on; % Single-axis plotting
    
    % Line A (Phonological - Red)
    plot(time_points, Means_A{k}, '-o', 'LineWidth', 1, ...
        'Color', [186/256, 48/256, 49/256], ...
        'MarkerEdgeColor', [186/256, 48/256, 49/256], 'MarkerSize', 4);
   
    % Line B (Semantic - Blue)
    plot(time_points, Means_B{k}, '-o', 'LineWidth', 1, ...
        'Color', [35/256, 100/256, 156/256], ...
        'MarkerEdgeColor', [35/256, 100/256, 156/256], 'MarkerSize', 4);
    
    hold off;
    
    % Axis limits and ticks
    ylim(y_limit);
    yticks([-1, 0, 1]); % Simplified ticks
    xlim(x_limit);
    
    % X-axis tick settings
    if k == 3
        xticks([0, 200, 400, 600]);
        xlabel('Time (ms)', 'FontSize', 6);
    else
        xticks([0, 200, 400, 600]);
    end
    
    set(gca, 'FontSize', 6, 'FontName', 'Arial', ...
        'TickDir', 'out', 'LineWidth', 0.5, ...
        'Box', 'off', 'XColor', 'k', 'YColor', 'k'); 
        
    % Title (Keep aligned)
    title(Row_Titles{k}, 'FontSize', 10, 'Color', 'w', 'FontWeight', 'bold');
    
    % Single Y-axis label, split into two lines
    ylabel({'Representation', 'index'}, 'Color', 'k', 'FontSize', 6);
end