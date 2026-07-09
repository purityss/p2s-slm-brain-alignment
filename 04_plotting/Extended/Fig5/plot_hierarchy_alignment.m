clear all
close all

% --- Setup Paths and Load Data ---
load('model_matrix.mat')

% --- Color Setup ---
custom_cmap = [68 1 84; 59 82 139; 33 145 140; 94 201 98; 253 231 37]/255;
n_models_total = size(model_matrix, 1);
t = linspace(0,1,n_models_total).^0.7;
colors_all_models = interp1(linspace(0,1,size(custom_cmap,1)), ...
                     custom_cmap, t, 'pchip');

% =========================================================================
% *** User Defined Settings Area ***
% =========================================================================
% [Setting 1: Define axis limits for each of the 6 subplots]
% Each row represents a plot (k=1 to 6), format: [X_min, X_max, Y_min, Y_max]
% You can modify the limits for each plot here respectively
axis_settings = [
    % Row 1: Phonological (Col 3)
    0, 100,  0, 1.0;   % Plot 1 (Top Left)
    0, 100,  0, 1.0;   % Plot 2 (Top Right)
    
    % Row 2: Semantic (Col 4)
    0, 100,  0, 1.0;   % Plot 3 (Middle Left)
    0, 100,  0, 1.0;   % Plot 4 (Middle Right)
    
    % Row 3: P2S-transfer (Col 5)
    0, 100, -1, 1.0;   % Plot 5 (Bottom Left)
    0, 100, -1, 1.0    % Plot 6 (Bottom Right)
];
% =========================================================================

figure;
% [Setting 2: Adjust figure size]
% Increase height to prevent image compression when increasing row spacing
set(gcf, 'Position', [100, 50, 190, 330]); 

% [Setting 3: Increase row spacing]
% Setting TileSpacing to 'loose' significantly increases gaps between subplots
t = tiledlayout(3, 2, 'TileSpacing', 'loose', 'Padding', 'compact'); 

% Define configurations [x_col, y_col]
plot_configs = [
    1, 3; 2, 3; % Row 1
    1, 5; 2, 5; % Row 2
    1, 4; 2, 4  % Row 3
];
row_titles = {'phonological units', 'semantic units', 'P2S-transfer units'};

for k = 1:6
    nexttile; 
    
    col_x = plot_configs(k, 1);
    col_y = plot_configs(k, 2);
    
    x_raw = model_matrix(:, col_x);
    y_raw = model_matrix(:, col_y);
    
    % Remove NaNs
    valid_idx = ~isnan(x_raw) & ~isnan(y_raw);
    x = x_raw(valid_idx);
    y = y_raw(valid_idx);
    colors = colors_all_models(valid_idx, :);
    
    % Linear Fitting
    p = polyfit(x, y, 1);
    x_fit = linspace(min(x), max(x), 100)';
    y_fit = polyval(p, x_fit);
    
    % CI Calculation
    X_mat = [ones(length(x), 1), x];
    b = X_mat \ y;
    y_hat = X_mat * b;
    residuals = y - y_hat;
    df = length(x) - 2;
    s_err = sqrt(sum(residuals.^2) / df);
    CI = tinv(0.975, df) * s_err * sqrt(1/length(x) + (x_fit - mean(x)).^2 / sum((x - mean(x)).^2));
    y_upper = y_fit + CI;
    y_lower = y_fit - CI;
    
    % Draw Plot
    hold on;
    fill([x_fit; flipud(x_fit)], [y_upper; flipud(y_lower)], [0.85 0.85 0.85], ...
         'EdgeColor', 'none', 'FaceAlpha', 0.5); 
    plot(x_fit, y_fit, 'k-', 'LineWidth', 1);
    scatter(x, y, 10, colors, 'filled');
    
    % --- Apply Individual Axis Limits ---
    this_xlim = axis_settings(k, 1:2);
    this_ylim = axis_settings(k, 3:4);
    
    xlim(this_xlim);
    ylim(this_ylim);
    
    % --- Correlation Text (Dynamic Position) ---
    [r, pval] = corr(x, y, 'Type', 'Pearson');
    
    if pval < 0.001
        stars = '***';
    elseif pval < 0.01
        stars = '**';
    elseif pval < 0.05
        stars = '*';
    else
        stars = '';
    end
    
    % Calculate text position: 10% from the top based on Y-axis limits to prevent clipping
    text_pos_y = this_ylim(2) - 0.1 * (this_ylim(2) - this_ylim(1));
    % Text X position: Slightly to the right of the X-axis starting point
    text_pos_x = this_xlim(1) + 0.05 * (this_xlim(2) - this_xlim(1));
    
    text(text_pos_x, text_pos_y, sprintf('\\it r = %.2f%s', r, stars), 'FontSize', 7, 'FontAngle', 'italic');
    
    % Aesthetics
    box off;
    set(gca, 'FontSize', 7, 'Box', 'off', 'FontName', 'Arial', 'TickDir', 'out', 'LineWidth', 0.5, 'XColor', 'k', 'YColor', 'k');
    
    % --- Row Titles ---
    if k == 1 || k == 2
        title(row_titles{1}, 'FontWeight', 'normal', 'FontSize', 11);
    elseif k == 3 || k == 4
        title(row_titles{2}, 'FontWeight', 'normal', 'FontSize', 11);
    elseif k == 5 || k == 6
        title(row_titles{3}, 'FontWeight', 'normal', 'FontSize', 11);
    end
end

% --- Global Labels ---
han = axes(gcf,'visible','off'); 
han.Title.Visible='on';
han.XLabel.Visible='on';
han.YLabel.Visible='on';

han.XLabel.Position(2) = han.XLabel.Position(2) - 0.02;

% Model names (top to bottom as in the table)
labels_all = { ...
    'XLSR-53-ch', ...
    'Whisper-large-v3', ...
    'LLaSM', ...
    'SALMONN', ...
    'Qwen-Audio', ...
    'Qwen-Audio-Chat', ...
    'Qwen2-Audio', ...
    'Qwen2-Audio-Instruct', ...
    'GLM-4-Voice', ...
    'Freeze-Omni', ...
    'MiniCPM-o 2.6', ...
    'Qwen2.5-Omni'};
labels = labels_all(valid_idx);