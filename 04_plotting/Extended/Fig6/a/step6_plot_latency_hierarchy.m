% Clean environment
clear; clc; close all;

% ==========================================
% 1. Load real data and convert to physical time (ms)
% ==========================================
disp('Loading real data...');
d_pho = load('time_start_phonology_only.mat'); 
d_sem = load('time_start_semantics_only.mat');
d_both = load('time_start_both_all.mat');

% Dynamically extract real data variables from structs
f_pho = fieldnames(d_pho); val_pho = d_pho.(f_pho{1});
f_sem = fieldnames(d_sem); val_sem = d_sem.(f_sem{1});
f_both = fieldnames(d_both); val_both = d_both.(f_both{1});

% Ensure data are standard numeric column vectors
if iscell(val_pho), val_pho = cell2mat(val_pho); end
if iscell(val_sem), val_sem = cell2mat(val_sem); end
if iscell(val_both), val_both = cell2mat(val_both); end

% Core modification 1: Direct mapping to physical milliseconds
val_pho_ms = (val_pho(:) - 1) * 50;
val_sem_ms = (val_sem(:) - 1) * 50;
val_both_ms = (val_both(:) - 1) * 50;

% ==========================================
% 2. Define 100ms bins and compute statistics
% ==========================================
% Edge settings: [-25, 75) includes 0 and 50; [75, 175) includes 100 and 150...
edges = -25:100:875; 

% X-axis: Center position of each 100ms bar
latencies = 25:100:825; 

% Count the number of contacts falling into each 100ms window
count_pho = histcounts(val_pho_ms, edges);
count_sem = histcounts(val_sem_ms, edges);
count_both = histcounts(val_both_ms, edges);

% Core modification 2: Convert to proportions based on total brain contacts (962)
total_contacts = 962;
prop_pho = count_pho / total_contacts;
prop_sem = count_sem / total_contacts;
prop_both = count_both / total_contacts;

% Find the global maximum proportion to unify Y-axis, adding 20% top margin
max_y = max([prop_pho, prop_sem, prop_both]) * 1.2; 
if max_y == 0
    max_y = 1; 
end

% ==========================================
% 3. Plot settings and initialization
% ==========================================
% Define specific colors
c_pho = [180, 37, 35] / 255;
c_sem = [34, 91, 142] / 255;
c_both = [103, 38, 141] / 255;

% Create a denser X-axis grid for smooth interpolation (curve fitting)
x_fit = linspace(min(latencies), max(latencies), 300);

% Create figure
figure('Color', 'w', 'Position', [100, 100, 400, 400]);
t = tiledlayout(3, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

% ==========================================
% 4. Plot three subplots
% ==========================================
% ---- Subplot 1: Phonology only ----
nexttile;
hold on;
% width=1 means bars fill the 100ms interval without gaps
bar(latencies, prop_pho, 1, 'FaceColor', c_pho, 'FaceAlpha', 0.6, 'EdgeColor', 'w');
y_fit_pho = max(0, pchip(latencies, prop_pho, x_fit));
plot(x_fit, y_fit_pho, 'Color', c_pho, 'LineWidth', 1.5);
title('Phonology sEEG contacts (n = 210)', 'Color', 'k', 'FontName', 'Arial','FontSize', 8, 'FontWeight', 'bold');
hold off;

% ---- Subplot 2: Semantics only ----
nexttile;
hold on;
bar(latencies, prop_sem, 1, 'FaceColor', c_sem, 'FaceAlpha', 0.6, 'EdgeColor', 'w');
y_fit_sem = max(0, pchip(latencies, prop_sem, x_fit));
plot(x_fit, y_fit_sem, 'Color', c_sem, 'LineWidth', 1.5);
title('Semantics sEEG contacts (n = 218)', 'Color', 'k', 'FontName', 'Arial', 'FontSize', 8, 'FontWeight', 'bold');
hold off;

% ---- Subplot 3: Both ----
nexttile;
hold on;
bar(latencies, prop_both, 1, 'FaceColor', c_both, 'FaceAlpha', 0.6, 'EdgeColor', 'w');
y_fit_both = max(0, pchip(latencies, prop_both, x_fit));
plot(x_fit, y_fit_both, 'Color', c_both, 'LineWidth', 1.5);
title('P2S-transfer sEEG contacts (n = 43)', 'Color', 'k', 'FontName', 'Arial', 'FontSize', 8, 'FontWeight', 'bold');
hold off;

% ==========================================
% 5. Unify formatting for all axes
% ==========================================
all_axes = findobj(gcf, 'Type', 'axes');
for i = 1:length(all_axes)
    ax = all_axes(i);
    
    % Adjust boundaries so the leftmost and rightmost 100ms bars are not clipped
    set(ax, 'XLim', [-50, 850]); 
    set(ax, 'YLim', [0, max_y]);
    
    % Keep X-axis ticks at integer hundreds (0, 100, 200) for readability
    % (Removed forced YTick steps, letting MATLAB assign appropriate ticks automatically)
    set(ax, 'XTick', 0:100:800);  
    
    % Minimalist aesthetics
    ax.TickDir = 'out';
    box(ax, 'off');
    grid(ax, 'on');
    ax.XGrid = 'off';
    ax.GridLineStyle = '--';
    ax.GridAlpha = 0.4;
    
    % Added/modified the following four lines
    ax.LineWidth = 0.5;       % Set the axis main line and tick line width to 0.5 points
    ax.XColor = 'k';          % Set X-axis line and tick labels to solid black ('k')
    ax.YColor = 'k';          % Set Y-axis line and tick labels to solid black ('k')
    ax.Layer = 'top';         % Force axes to the top layer, overlaying the transparent bars
    
    % Hide X-axis labels for all but the bottom plot
    if i > 1
        ax.XTickLabel = []; 
    end
end

% ==========================================
% 6. Add global labels
% ==========================================
xlabel(t, 'Latency (ms)', 'FontName', 'Arial', 'FontSize', 8);
% Core modification 3: Update global Y-axis label
ylabel(t, 'Proportion of total contacts', 'FontName', 'Arial', 'FontSize', 8);

disp('100ms Bin chart plotting complete!');

% ==========================================
% 7. Save fitted curve data as a 3-column matrix
% ==========================================
% Convert fitted row vectors to column vectors (N x 1)
y_pho_col = y_fit_pho(:);
y_sem_col = y_fit_sem(:);
y_p2s_col = y_fit_both(:); 

% Combine the three columns into an N x 3 matrix
latency_fitted_curves_matrix = [y_pho_col, y_sem_col, y_p2s_col];

% Save to a .mat file in the working directory
save('latency_fitted_curves_data.mat', 'latency_fitted_curves_matrix', 'x_fit');
disp('Fitted curve data successfully exported to latency_fitted_curves_data.mat!');