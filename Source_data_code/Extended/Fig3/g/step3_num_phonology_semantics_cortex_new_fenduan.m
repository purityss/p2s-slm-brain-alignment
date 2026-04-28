clear all
close all
clf

name = 'minicpm';
load(strcat(name, '_layer_neurons_counts.mat'));

% Extract data from matrix
num = num_all_p_s(:,2);
num_p = num_all_p_s(:,3);
num_s = num_all_p_s(:,4);
num_both = num_all_p_s(:,5);

% Calculate proportions
prop_p = num_p ./ num * 100;
prop_s = num_s ./ num * 100;
prop_both = num_both ./ num * 100;

% Layer index
layers = 1:length(prop_p);

% Set colors
color_p = [180, 37, 35] / 255;   % Phonology (Red)
color_s = [34, 91, 142] / 255;   % Semantics (Blue)
color_both = [103, 38, 141] / 255; % Shared/Both (Purple)

%% Customized Axes (First two layers on X-axis occupy 1/5 of length)
% ==========================================================
% 1. Y-axis mapping rule (0-3 occupies the first 25%)
y_breaks_orig = [0,  3,  20, 50, 100]; 
y_breaks_vis  = [0, 25,  50, 75, 100]; 
trans_y = @(y) interp1(y_breaks_orig, y_breaks_vis, y, 'linear');

% 2. X-axis mapping rule 
% ==========================================================
x_max = length(layers); % Total number of layers (65)

% Define anchor points: 
% Original layer 1 -> Visual position 0%
% Original layer 2 -> Visual position 20% (i.e., 1/5 of total length)
% Original layer End -> Visual position 100%
x_breaks_orig = [1,  2,  x_max]; 
x_breaks_vis  = [0, 20,  100];   

% X-axis transformation function
trans_x = @(x) interp1(x_breaks_orig, x_breaks_vis, x, 'linear');

% ==========================================================
gcf = figure(1);
set(gcf, 'Position', [100, 100, 195, 126]); 
set(gcf, 'Color', 'w');
hold on;

% --- Draw plot (apply both X and Y transformations) ---
% 1. Smooth the data (window size adjustable, e.g., 3/5/7)
w = 5;
prop_p_sm    = smoothdata(prop_p,    'movmean', w);
prop_s_sm    = smoothdata(prop_s,    'movmean', w);
prop_both_sm = smoothdata(prop_both, 'movmean', w);

% 2. Plot lines (Note: apply trans_y to smoothed data)
plot(trans_x(layers), trans_y(prop_p_sm),    '-', 'LineWidth', 1.5, 'Color', color_p);
plot(trans_x(layers), trans_y(prop_s_sm),    '-', 'LineWidth', 1.5, 'Color', color_s);
plot(trans_x(layers), trans_y(prop_both_sm), '-', 'LineWidth', 1.5, 'Color', color_both);

% --- Axis Formatting ---
% Y-axis ticks setup
y_ticks_vals = [3, 20, 50, 100]; 
ylim([0 100]); 
set(gca, 'YTick', trans_y(y_ticks_vals));       
set(gca, 'YTickLabel', string(y_ticks_vals));   

% X-axis ticks setup
x_ticks_vals = [2, 26, 54];      
% Set visual range from 0 to 100 (corresponding to x_breaks_vis range)
xlim([0 100]); 
% Transform tick positions
set(gca, 'XTick', trans_x(x_ticks_vals));       
% Display original values as labels
set(gca, 'XTickLabel', string(x_ticks_vals));   

% --- Aesthetics ---
set(gca, 'FontSize', 7, 'Box', 'off', 'FontName', 'Arial', ...
    'TickDir', 'out', 'LineWidth', 0.5, 'XColor', 'k', 'YColor', 'k');
ylabel('Proportion of model neurons (%)', 'FontSize', 7, 'FontName', 'Arial');
xlabel('Layer', 'FontSize', 7, 'FontName', 'Arial');

% Fix plot area position
set(gca, 'Units', 'normalized', 'Position', [0.13 0.15 0.775 0.8]);