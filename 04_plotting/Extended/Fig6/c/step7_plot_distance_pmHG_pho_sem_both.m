% Clear environment
clear; clc; close all;

% ==========================================
% 1. Load distance data
% ==========================================
disp('Loading distance data...');
d_pho = load('distance_pho.mat');
d_sem = load('distance_sem.mat');
d_both = load('distance_both.mat');

% Dynamically extract the data variables from the structures
f_pho = fieldnames(d_pho); dist_pho = d_pho.(f_pho{1});
f_sem = fieldnames(d_sem); dist_sem = d_sem.(f_sem{1});
f_both = fieldnames(d_both); dist_both = d_both.(f_both{1});

% Ensure data are standard numeric column vectors
dist_pho = dist_pho(:);
dist_sem = dist_sem(:);
dist_both = dist_both(:);

% ==========================================
% 2. Define Distance Bins
% ==========================================
% Setting a 5mm Bin width
bin_width = 5; 

% Calculate maximum distance to determine X-axis right boundary
max_dist = max([dist_pho; dist_sem; dist_both]);
max_edge = ceil(max_dist / bin_width) * bin_width;

% Define edges [0, 5, 10, 15... max_edge]
edges = 0:bin_width:max_edge;

% X-axis: Center position of each bar (2.5, 7.5, 12.5...)
centers = edges(1:end-1) + bin_width / 2;

% ==========================================
% 3. Calculate Proportion of Contacts for each bin
% ==========================================
count_pho = histcounts(dist_pho, edges);
count_sem = histcounts(dist_sem, edges);
count_both = histcounts(dist_both, edges);

% Convert to proportions based on total brain contacts (962)
total_contacts = 962;
prop_pho = count_pho / total_contacts;
prop_sem = count_sem / total_contacts;
prop_both = count_both / total_contacts;

% Find global maximum proportion for unified Y-axis, adding 20% top margin
max_y = max([prop_pho, prop_sem, prop_both]) * 1.2; 
if max_y == 0
    max_y = 1; 
end

% ==========================================
% 4. Plotting Settings and Initialization
% ==========================================
% Define colors
c_pho = [180, 37, 35] / 255;
c_sem = [34, 91, 142] / 255;
c_both = [103, 38, 141] / 255;

% Create a dense X-axis grid for smooth interpolation (curve fitting)
x_fit = linspace(min(centers), max(centers), 300);

% Create figure
figure('Color', 'w', 'Position', [100, 100, 400, 400]);
t = tiledlayout(3, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

% ==========================================
% 5. Plotting Subplots
% ==========================================
% ---- Subplot 1: Phonology only ----
nexttile;
hold on;
% width=1 indicates bars fill the bin_width interval without gaps
bar(centers, prop_pho, 1, 'FaceColor', c_pho, 'FaceAlpha', 0.6, 'EdgeColor', 'w');
y_fit_pho = max(0, pchip(centers, prop_pho, x_fit));
plot(x_fit, y_fit_pho, 'Color', c_pho, 'LineWidth', 1.5);
title('Phonology only (n = 210)', 'Color','k', 'FontSize', 8, 'FontName', 'Arial', 'FontWeight', 'bold');
hold off;

% ---- Subplot 2: Semantics only ----
nexttile;
hold on;
bar(centers, prop_sem, 1, 'FaceColor', c_sem, 'FaceAlpha', 0.6, 'EdgeColor', 'w');
y_fit_sem = max(0, pchip(centers, prop_sem, x_fit));
plot(x_fit, y_fit_sem, 'Color', c_sem, 'LineWidth', 1.5);
title('Semantics only (n = 218)', 'Color', 'k', 'FontSize', 8, 'FontName', 'Arial', 'FontWeight', 'bold');
hold off;

% ---- Subplot 3: Both ----
nexttile;
hold on;
bar(centers, prop_both, 1, 'FaceColor', c_both, 'FaceAlpha', 0.6, 'EdgeColor', 'w');
y_fit_both = max(0, pchip(centers, prop_both, x_fit));
plot(x_fit, y_fit_both, 'Color', c_both, 'LineWidth', 1.5);
title('P2S-transfer sEEG contacts (n = 43)', 'Color', 'k', 'FontSize', 8, 'FontName', 'Arial', 'FontWeight', 'bold');
hold off;

% ==========================================
% 6. Formatting Axes
% ==========================================
all_axes = findobj(gcf, 'Type', 'axes');
for i = 1:length(all_axes)
    ax = all_axes(i);
    
    % Dynamically adjust boundaries
    set(ax, 'XLim', [0 - bin_width/2, max_edge + bin_width/2]); 
    set(ax, 'YLim', [0, max_y]);
    
    % Set X-axis ticks every 10mm
    set(ax, 'XTick', 0:10:max_edge);  
    
    % Aesthetics
    ax.TickDir = 'out';
    box(ax, 'off');
    grid(ax, 'on');
    ax.XGrid = 'off';
    ax.GridLineStyle = '--';
    ax.GridAlpha = 0.4;
    
    ax.LineWidth = 0.5;       % Set line and tick width to 0.5 points
    ax.XColor = 'k';          % Set X-axis line and labels to solid black
    ax.YColor = 'k';          % Set Y-axis line and labels to solid black
    ax.Layer = 'top';         % Force axes to the top layer
    
    % Hide X-axis labels for all but the bottom plot
    if i > 1
        ax.XTickLabel = []; 
    end
end

% ==========================================
% 7. Global Labels
% ==========================================
xlabel(t, 'Distance from pmHG (mm)', 'FontSize', 8, 'FontName', 'Arial');
ylabel(t, 'Proportion of total contacts', 'FontSize', 8, 'FontName', 'Arial');
disp('Distance distribution plotting complete!');

% ==========================================
% 8. Save fitted curve data as matrix
% ==========================================
% Convert fitted vectors to column vectors (N x 1)
y_pho_col = y_fit_pho(:);
y_sem_col = y_fit_sem(:);
y_both_col = y_fit_both(:); 

% Merge into an N x 3 matrix
distance_fitted_curves_matrix = [y_pho_col, y_sem_col, y_both_col];

% Save matrix and x_fit to a .mat file
save('distance_fitted_curves_data.mat', 'distance_fitted_curves_matrix', 'x_fit');
disp('Fitted distance distribution data exported to distance_fitted_curves_data.mat!');