% =========================================================================
% Nature-style Grouped Bar Chart with Double Y-Axes
% Objective: Show the synergistic jump in accuracy (macro) and \chi_{P2S} 
% (micro mechanism) under the optimal \alpha value
% =========================================================================
clear; clc; close all;

% 1. Load the steering matrix data
load('steer_matrix.mat');

% Extract data based on rows: Row 1 (Baseline), Row 3 (Optimal, alpha = 0.1)
% Column 2 is the correct count (total count is 52), Column 3 is the \chi_{P2S} value
total_count = 52;

acc_baseline = steer_matrix(1, 2) / total_count;
chi_baseline = steer_matrix(1, 3);

acc_optimal = steer_matrix(3, 2) / total_count;
chi_optimal = steer_matrix(3, 3);

% Form the data arrays for plotting
acc_data = [acc_baseline, acc_optimal]; 
chi_data = [chi_baseline, chi_optimal];   

labels = {'Baseline', 'Targeted Steering (\alpha = 0.1)'};

% 2. Basic plot settings
fig = figure('Position', [100, 100, 180, 230], 'Color', 'w');
x = [0.6, 1.4];

% =========================================================================
% [Core Modification Area]: Precisely control bar width and spacing
% =========================================================================
bar_width = 0.35;  % Bar width (narrowed to fit the tight frame)
gap = 0.01;        % Gap between two bars
shift = bar_width/2 + gap/2; % Calculate absolute distance for perfect symmetry

% Color scheme (Classic academic dual-color: Deep blue + Vibrant orange)
color_acc = [0.1216, 0.4706, 0.7059]; % #1f77b4
color_chi = [0.8392, 0.3765, 0.1569]; % #d66028

% =========================================================================
% 3. Plot Left Y-axis (Accuracy / Performance)
% =========================================================================
yyaxis left

% Shift perfectly to the left using x - shift
b1 = bar(x - shift, acc_data, bar_width, 'FaceColor', color_acc, 'EdgeColor', 'none');
ylabel('Model performance', 'FontSize', 8, 'Color', color_acc);
set(gca, 'YColor', color_acc);

% Set tick range
ylim([0.75, 0.90]); 
yticks(0.75:0.05:0.90);

% Keep text X-coordinates perfectly aligned with the bar's X-coordinates
for i = 1:length(x)
    text(x(i) - shift, acc_data(i) + 0.005, sprintf('%.3f', acc_data(i)), ...
        'HorizontalAlignment', 'center', 'Color', color_acc, 'FontSize', 8);
end

% =========================================================================
% 4. Plot Right Y-axis (\Delta P2S)
% =========================================================================
yyaxis right

% Shift perfectly to the right using x + shift
b2 = bar(x + shift, chi_data, bar_width, 'FaceColor', color_chi, 'EdgeColor', 'none');
ylabel('\Delta(P2S)', 'FontSize', 8, 'Color', color_chi, 'Interpreter', 'tex');
set(gca, 'YColor', color_chi);

% Set right axis range
ylim([9.0, 10]); 
yticks(9.0:0.5:10);

% Keep text X-coordinates perfectly aligned with the bar's X-coordinates
for i = 1:length(x)
    text(x(i) + shift, chi_data(i) + 0.05, sprintf('%.2f', chi_data(i)), ...
        'HorizontalAlignment', 'center', 'Color', color_chi, 'FontSize', 8);
end

% =========================================================================
% 5. Overall Axis Aesthetics (The "Nature" Look)
% =========================================================================
% Set X-axis labels and global font
set(gca, 'XTick', x, 'XTickLabel', labels, 'FontSize', 8, 'FontName', 'Arial');

% [Control margin padding]: Bring bars closer to the axes on both sides for a fuller look
xlim([0.1, 1.9]);

% Unify axis line width to 0.5 for a more refined look
ax = gca;
ax.XAxis.LineWidth = 0.5;
ax.YAxis(1).LineWidth = 0.5;
ax.YAxis(2).LineWidth = 0.5;

% Remove the top box border
box off;