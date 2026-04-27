clear all
close all

% --- Setup Paths and Load Data ---
save_fig_path = 'G:\Research\01 Speech_Comprehension\02 Figure_AI\Fig_sup_update_202512\Fig6_part';
save_fig_name = 'Fig6_Combined_Layout_sequential';
load('model_matrix.mat')

% --- Color Setup ---
custom_cmap = [68 1 84; 59 82 139; 33 145 140; 94 201 98; 253 231 37]/255;
n_models_total = size(model_matrix, 1);
t = linspace(0,1,n_models_total).^0.7;
colors_all_models = interp1(linspace(0,1,size(custom_cmap,1)), ...
                     custom_cmap, t, 'pchip');

% =========================================================================
% ★★★ 用户自定义设置区域 ★★★
% =========================================================================

% 【设置 1：定义6张子图各自的坐标轴范围】
% 每一行代表一张图 (k=1到6)，格式为: [X_min, X_max, Y_min, Y_max]
% 您可以在这里分别修改每一张图的范围
axis_settings = [
    % Row 1: Phonological (Col 3)
    0, 100,  0.8, 1.0;   % 图1 (左上)
    0, 100,  0.8, 1.0;   % 图2 (右上)
    
    % Row 2: Semantic (Col 4)
    0, 100,  0.5, 1.5;   % 图3 (左中)
    0, 100,  0.5, 1.5;   % 图4 (右中)
    
    % Row 3: P2S-transfer (Col 5)
    0, 100, -0.2, 1.0;   % 图5 (左下)
    0, 100, -0.2, 1.0    % 图6 (右下)
];

% =========================================================================

figure;
% 【设置 2：调整图片尺寸】
% 增加高度 (350 -> 450) 以便拉大行距时图片不会被压扁
set(gcf, 'Position', [100, 50, 190, 329]); 

% 【设置 3：拉大行距】
% 将 TileSpacing 设置为 'loose' 可以显著增加子图间的间隙
% 如果您的 MATLAB 版本是 R2021a 及以上，可以使用具体的像素值，例如: t.TileSpacing = [10, 30]; (水平10, 垂直30)
t = tiledlayout(3, 2, 'TileSpacing', 'loose', 'Padding', 'compact'); 

% Define configurations [x_col, y_col]
plot_configs = [
    1, 6; 2, 6; % Row 1
    1, 8; 2, 8; % Row 2
    1, 7; 2, 7  % Row 3
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
    
    % 计算文字位置：基于设定的Y轴范围，放置在顶部向下 10% 处，防止出界
    text_pos_y = this_ylim(2) - 0.1 * (this_ylim(2) - this_ylim(1));
    % 文字X位置：放在 X 轴起点的右侧一点
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
% ylabel(han, 'Hierarchical alignment index', 'FontSize', 8, 'FontWeight', 'bold', 'Color', 'k');
% xlabel(han, 'Model performance', 'FontSize', 8, 'FontWeight', 'bold', 'Color', 'k');
han.XLabel.Position(2) = han.XLabel.Position(2) - 0.02;

% 11 个模型名（按表格自上而下）
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

% %%% 图例
% hs = gobjects(numel(x),1);
% for k = 1:numel(x)
%     hs(k) = scatter(x(k), y(k), 28, colors(k,:), 'filled'); hold on
% end
% legend(hs, labels, 'Location','bestoutside', 'Box','off', 'FontSize',7);
% %%% 图例

% --- Save ---
% exportgraphics(gcf, fullfile(save_fig_path,[save_fig_name,'.pdf']), 'Resolution', 600);