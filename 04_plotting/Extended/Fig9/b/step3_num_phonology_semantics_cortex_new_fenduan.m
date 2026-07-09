clear all
close all
clc

% ==========================================
% 1. Data Loading & Settings
% ==========================================
name = 'qwen2_audio';
load(strcat(name, '_layer_neurons_counts.mat'));

% Data Extraction
% num_all_p_s structure expected: [unused, total, pho, sem, both]
num = num_all_p_s(:,2);
num_p = num_all_p_s(:,3);
num_s = num_all_p_s(:,4);
num_both = num_all_p_s(:,5);

% Calculate Proportions (%)
prop_p = num_p ./ num * 100;
prop_s = num_s ./ num * 100;
prop_both = num_both ./ num * 100;

layers = 1:length(prop_p);

% Define categorical colors
color_p = [180, 37, 35] / 255;      % Phonology (Red)
color_s = [34, 91, 142] / 255;      % Semantics (Blue)
color_both = [103, 38, 141] / 255;   % Both/Shared (Purple)

% ==========================================
% 2. Axis Transformation Logic
% ==========================================
% --- Y-axis mapping: 0-3% occupies the first 25% of visual space ---
y_breaks_orig = [0,  3,  20, 50, 100]; 
y_breaks_vis  = [0, 25,  50, 75, 100]; 
trans_y = @(y) interp1(y_breaks_orig, y_breaks_vis, y, 'linear');

% --- X-axis mapping: First 2 layers occupy 20% of visual space ---
x_max = length(layers);
x_breaks_orig = [1,  2,  x_max]; 
x_breaks_vis  = [0, 20,  100];   
trans_x = @(x) interp1(x_breaks_orig, x_breaks_vis, x, 'linear');

% ==========================================
% 3. Plotting
% ==========================================
figure(1);
set(gcf, 'Position', [100, 100, 195, 126]); 
set(gcf, 'Color', 'w');
hold on;

% --- Data Smoothing ---
w = 5; % Moving average window size
prop_p_sm    = smoothdata(prop_p,    'movmean', w);
prop_s_sm    = smoothdata(prop_s,    'movmean', w);
prop_both_sm = smoothdata(prop_both, 'movmean', w);

% --- Drawing curves with transformations ---
plot(trans_x(layers), trans_y(prop_p_sm),    '-', 'LineWidth', 1.5, 'Color', color_p);
plot(trans_x(layers), trans_y(prop_s_sm),    '-', 'LineWidth', 1.5, 'Color', color_s);
plot(trans_x(layers), trans_y(prop_both_sm), '-', 'LineWidth', 1.5, 'Color', color_both);

% --- Axis Customization ---
% Y-Axis Ticks
y_ticks_vals = [3, 20, 50, 100]; 
ylim([0 100]); 
set(gca, 'YTick', trans_y(y_ticks_vals));       
set(gca, 'YTickLabel', string(y_ticks_vals));   

% X-Axis Ticks
x_ticks_vals = [2, 34, 66];      
xlim([0 100]); 
set(gca, 'XTick', trans_x(x_ticks_vals));       
set(gca, 'XTickLabel', string(x_ticks_vals));   

% --- Aesthetics ---
set(gca, 'FontSize', 6, 'Box', 'off', 'FontName', 'Arial', ...
    'TickDir', 'out', 'LineWidth', 0.5, 'XColor', 'k', 'YColor', 'k');

ylabel('Proportion of model neurons (%)', 'FontSize', 6, 'FontName', 'Arial');
xlabel('Layer', 'FontSize', 6, 'FontName', 'Arial');

% Fix axes position within figure
set(gca, 'Units', 'normalized', 'Position', [0.13 0.15 0.775 0.8]);