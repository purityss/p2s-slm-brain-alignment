clear all
close all
clf

% --- Data Loading & Processing ---
load('num_all_p_s_2.mat')
num = num_all_p_s(:,1);
num_p = num_all_p_s(:,2);
num_s = num_all_p_s(:,3);
num_both = num_all_p_s(:,4);

% Calculate proportions
prop_p = num_p ./ num * 100;
prop_s = num_s ./ num * 100;
prop_both = num_both ./ num * 100;

% --- Define Colors ---
color_p = [180, 37, 35] / 255;       % pho (Red)
color_s = [34, 91, 142] / 255;       % sem (Blue)
color_both = [103, 38, 141] / 255;   % both (Purple)

% --- Plotting ---
gcf = figure(1);
set(gcf, 'Position', [100, 100, 360, 170]);
set(gcf, 'Color', 'w');
hold on;

% Define X-axis coordinates
x_axis = 1:length(prop_p);

% --- Draw line plot ---
% 1. Smooth the data (Window size adjustable, e.g., 3/5/7)
w = 3;
prop_p_smooth    = smoothdata(prop_p,    'movmean', w);
prop_both_smooth = smoothdata(prop_both, 'movmean', w);
prop_s_smooth    = smoothdata(prop_s,    'movmean', w);

% 2. Plot the smoothed curves
plot(x_axis, prop_p_smooth,    '-', 'Color', color_p,    'LineWidth', 1.5, 'MarkerSize', 4, 'MarkerFaceColor', color_p);
plot(x_axis, prop_both_smooth, '-', 'Color', color_both, 'LineWidth', 1.5, 'MarkerSize', 4, 'MarkerFaceColor', color_both);
plot(x_axis, prop_s_smooth,    '-', 'Color', color_s,    'LineWidth', 1.5, 'MarkerSize', 4, 'MarkerFaceColor', color_s);

% --- Axis Settings ---
xlim([0.5, 14.5]); % Leave some margin
xticks(1:14);
xticklabels({'HG', 'Insula','pmSTG','MTG','ITG','PCC','Cuneus','MFG','IFG','Sensorimotor','MTL','aSTG','Temporal Pole','IPL'});
xtickangle(90);    % Keep vertical alignment

% Y-axis range (Set to 0-50 based on previous code; adjust to 0-100 if needed)
ylim([0 50]); 
yticks(0:10:50);

% --- Aesthetics & Labels ---
ylabel('Proportion of sEEG contacts (%)', 'FontSize', 6, 'FontName', 'Arial', 'Color', 'k');

% Unified font and axis styling
set(gca, 'FontSize', 6, 'Box', 'off', 'FontName', 'Arial', ...
    'TickDir', 'out', 'LineWidth', 0.5, 'XColor', 'k', 'YColor', 'k');