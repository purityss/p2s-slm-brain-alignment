clear all
close all
clc

% ==========================================
% 1. Data Loading & Settings
% ==========================================
name = 'freezeomni';

% Load Data
load([name, '_numeric_p_s_t.mat']); 
A_raw = numeric_p_s_t; 
load([name, '_numeric_phonology_t.mat']);
Line_A = numeric_phonology_t;
load([name, '_numeric_semantics_t.mat']);
Line_B = numeric_semantics_t;

% Define indices
num_pho = 29572;
num_both = 920;
num_sem = 9620;
p2 = num_pho;
b1 = p2 + 1;
b2 = p2 + num_both;
s1 = b2 + 1;
s2 = b2 + num_sem;

% ==========================================
% 2. Data Processing
% ==========================================
% --- Heatmap Data Preparation ---
H1 = A_raw(1:p2, :);
[~, idx1] = sort(sum(H1, 2), 'descend');
H1_sorted = H1(idx1, :);

H2 = A_raw(b1:b2, :);
[~, idx2] = sort(sum(H2, 2), 'descend');
H2_sorted = H2(idx2, :);

H3 = A_raw(s1:s2, :);
[~, idx3] = sort(sum(H3, 2), 'descend');
H3_sorted = H3(idx3, :);

% Order: Phonology -> Semantics -> Both
Heatmaps = {H1_sorted, H3_sorted, H2_sorted};

% --- Line Plot Data Preparation ---
mA1 = mean(Line_A(1:p2, :), 1);
mB1 = mean(Line_B(1:p2, :), 1);
mA2 = mean(Line_A(b1:b2, :), 1);
mB2 = mean(Line_B(b1:b2, :), 1);
mA3 = mean(Line_A(s1:s2, :), 1);
mB3 = mean(Line_B(s1:s2, :), 1);

Means_A = {mA1, mA3, mA2};
Means_B = {mB1, mB3, mB2};

% Row Titles for spacing
row_titles = {'Phonological', 'Semantic', 'Shared (Transfer)'};

% ==========================================
% 3. Plotting
% ==========================================
figure(1);
% Increase height to accommodate titles and larger spacing
set(gcf, 'Position', [100, 100, 190, 260]); 
set(gcf, 'Color', 'w');

t = tiledlayout(3, 5, 'TileSpacing', 'loose', 'Padding', 'compact');

% Colormap
cmap = [186/256, 48/256, 49/256; 1 1 1; 35/256, 100/256, 156/256];
cmap = flipud(cmap); 
cmap_smooth = interp1(linspace(0, 1, size(cmap, 1)), cmap, linspace(0, 1, 256));

for k = 1:3
    % --- Left Column: Heatmap ---
    tile_idx_heatmap = (k-1)*5 + 1;
    nexttile(tile_idx_heatmap, [1 2]);
    imagesc(Heatmaps{k});
    colormap(gca, cmap_smooth); 
    caxis([-3, 3]); 
    
    set(gca, 'FontSize', 6, 'FontName', 'Arial', ...
        'TickDir', 'out', 'TickLength', [0, 0], ...
        'XColor', 'k', 'YColor', 'k', ...
        'LineWidth', 0.5, 'Box', 'on');
    set(gca, 'XTick', []); 
    
    % Add title to increase vertical spacing
    t_obj = title(row_titles{k}, 'FontSize', 11, 'Color', 'w'); 
    
    % --- Right Column: Line Plot ---
    tile_idx_line = (k-1)*5 + 3;
    nexttile(tile_idx_line, [1 3]);
    
    time_points = [1, 2];
    yl = [-10, 10];
    
    hold on; % Hold on to draw both lines on the same axis
    
    % Draw first line (Phonological - Red)
    plot(time_points, Means_A{k}, '-o', 'LineWidth', 1, ...
        'Color', [186/256, 48/256, 49/256], ...
        'MarkerEdgeColor', [186/256, 48/256, 49/256],'MarkerSize', 4);
   
    % Draw second line (Semantic - Blue)
    plot(time_points, Means_B{k}, '-o', 'LineWidth', 1, ...
        'Color', [35/256, 100/256, 156/256], ...
        'MarkerEdgeColor', [35/256, 100/256, 156/256],'MarkerSize', 4);
    
    % Uniformly set axis limits and ticks
    ylim(yl);
    yticks(-10:10:10);
    
    % Aesthetics
    xlim([0.8, 2.2]);
    
    % X-axis ticks
    if k == 3
        xticks([1,2]);
        xlabel('Sequence segment', 'FontSize', 6);
    else
        xticks([1,2]);
    end
    
    set(gca, 'FontSize', 6, 'FontName', 'Arial', ...
        'TickDir', 'out', 'LineWidth', 0.5, ...
        'Box', 'off', 'XColor', 'k', 'YColor', 'k'); 
        
    % Keep titles aligned with a white placeholder title
    t_obj2 = title(row_titles{k}, 'FontSize', 11, 'Color', 'w'); 
    
    % Uniform Y-axis label
    ylabel({'Representation', 'index'}, 'Color', 'k', 'FontSize', 6);
    
    hold off;
end