clear all
close all
clf

name = 'llasm';
load(strcat(name, '_layer_neurons_counts.mat'));

num = num_all_p_s(:,2);
num_p = num_all_p_s(:,3);
num_s = num_all_p_s(:,4);
num_both = num_all_p_s(:,5);

prop_all = num ./ num * 100;
prop_p = num_p ./ num * 100;
prop_s = num_s ./ num * 100;
prop_both = num_both ./ num * 100;

prop(:,1) = prop_p;
prop(:,2) = prop_s;
prop(:,3) = prop_both;

%%
% Layer index
layers = 1:length(prop_p);

% Set colors
color_p = [180, 37, 35] / 255;          % pho (Red)
color_s = [34, 91, 142] / 255;          % sem (Blue)
color_both = [103, 38, 141] / 255;      % both (Purple)

%% Figure: Customized Axes (First two layers take up 1/5 of the X-axis length)
% ==========================================================
% 1. Y-axis mapping rule (0-3 takes up the first 25%)
y_breaks_orig = [0,  3,  20, 50, 100]; 
y_breaks_vis  = [0, 25,  50, 75, 100]; 
trans_y = @(y) interp1(y_breaks_orig, y_breaks_vis, y, 'linear');

% 2. X-axis mapping rule
% ==========================================================
x_max = length(layers); % Total number of layers

% Define anchor points: 
% Original layer 1 -> Visual position 0%
% Original layer 2 -> Visual position 20% (1/5 of total length)
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

% --- Plotting (Applying both X and Y transformations) ---
% 1. Smooth the data (Window size adjustable, e.g., 3/5/7)
w = 5;
prop_p_sm    = smoothdata(prop_p,    'movmean', w);
prop_s_sm    = smoothdata(prop_s,    'movmean', w);
prop_both_sm = smoothdata(prop_both, 'movmean', w);

% 2. Plot the smoothed data (Note: apply trans_y to smoothed data)
plot(trans_x(layers), trans_y(prop_p_sm),    '-', 'LineWidth', 1.5, 'Color', color_p);
plot(trans_x(layers), trans_y(prop_s_sm),    '-', 'LineWidth', 1.5, 'Color', color_s);
plot(trans_x(layers), trans_y(prop_both_sm), '-', 'LineWidth', 1.5, 'Color', color_both);

% --- Axis Formatting (Custom Scale) ---
% Y-axis ticks setup
y_ticks_vals = [3, 20, 50, 100]; 
ylim([0 100]); 
set(gca, 'YTick', trans_y(y_ticks_vals));       
set(gca, 'YTickLabel', string(y_ticks_vals));   

% X-axis ticks setup
x_ticks_vals = [2, 34, 66];      
% Set visual range to 0-100 (corresponding to x_breaks_vis)
xlim([0 100]); 
% Transform tick positions
set(gca, 'XTick', trans_x(x_ticks_vals));       
% Labels show original values
set(gca, 'XTickLabel', string(x_ticks_vals));   

% --- Aesthetics ---
set(gca, 'FontSize', 7, 'Box', 'off', 'FontName', 'Arial', ...
    'TickDir', 'out', 'LineWidth', 0.5, 'XColor', 'k', 'YColor', 'k');
ylabel('Proportion of model neurons (%)', 'FontSize', 7, 'FontName', 'Arial');
xlabel('Layer', 'FontSize', 7, 'FontName', 'Arial');

% Fix plot area position
set(gca, 'Units', 'normalized', 'Position', [0.13 0.15 0.775 0.8]);