clear all
close all
clc

% ==========================================
% 1. Data Loading & Settings
% ==========================================
% 设置路径 (根据你的第一部分代码)
save_fig_path = 'G:\Research\01 Speech_Comprehension\02 Figure_AI\Fig_sup_update_202601\Fig2_part';
save_fig_name = 'Combined_t_Heatmap_Line_Index';
% save_fig_name = 'Combined_t_Heatmap_Line_Index_legend';

% --- Load Heatmap Data ---
load('numeric_p_s_t.mat'); 
Data_Heatmap = numeric_p_s_t; % 完整矩阵

% --- Load Line Plot Data ---
load('numeric_phonology_t.mat');
Data_Line_Pho = numeric_phonology_t(:, 1:11); % 截取前11个点 (参考第一部分代码)

load('numeric_semantics_t.mat');
Data_Line_Sem = numeric_semantics_t(:, 1:11); % 截取前11个点

% --- Define Indices ---
num_pho = 210;
num_both = 43;
num_sem = 218;

p2 = num_pho;
b1 = p2 + 1;
b2 = p2 + num_both;
s1 = b2 + 1;
s2 = b2 + num_sem;

% ==========================================
% 2. Data Processing (Sorting & Means)
% ==========================================

% --- 2.1 Heatmap Sorting ---
% Region 1: Phonological (Sort by Sum Descend)
H1 = Data_Heatmap(1:p2, :);
[~, idx1] = sort(sum(H1, 2), 'descend');
H1_sorted = H1(idx1, :);

% Region 2: Shared/Both (Sort by Row Max Descend - 参考第一部分逻辑)
H2 = Data_Heatmap(b1:b2, :);
rowMax = max(H2, [], 2); 
[~, idx2] = sort(rowMax, 'descend');
H2_sorted = H2(idx2, :);

% Region 3: Semantic (Sort by Sum Descend)
H3 = Data_Heatmap(s1:s2, :);
[~, idx3] = sort(sum(H3, 2), 'descend');
H3_sorted = H3(idx3, :);

% 打包数据 (Order: Phonology -> Semantic -> Shared 对应图表从上到下的顺序)
% 注意：通常顺序是 Pho, Sem, Both 或者 Pho, Both, Sem。
% 模板代码顺序是 {H1, H3, H2} (Pho, Sem, Both)，这里保持模板结构。
Heatmaps = {H1_sorted, H3_sorted, H2_sorted}; 
Row_Titles = {'Phonological', 'Semantic', 'Shared (Transfer)'};

% --- 2.2 Line Plot Means ---
% Region 1
mA1 = mean(Data_Line_Pho(1:p2, :), 1);
mB1 = mean(Data_Line_Sem(1:p2, :), 1);
% Region 2 (Both)
mA2 = mean(Data_Line_Pho(b1:b2, :), 1);
mB2 = mean(Data_Line_Sem(b1:b2, :), 1);
% Region 3 (Sem)
mA3 = mean(Data_Line_Pho(s1:s2, :), 1);
mB3 = mean(Data_Line_Sem(s1:s2, :), 1);

% 对应 Heatmaps 的顺序 {Pho, Sem, Both} 打包
Means_A = {mA1, mA3, mA2};
Means_B = {mB1, mB3, mB2};

% ==========================================
% 3. Plotting
% ==========================================
figure(1);
set(gcf, 'Position', [100, 100, 315, 260]); % 调整长宽比例以适应3行
set(gcf, 'Color', 'w');

% 布局：3行5列 (左2列热力图，右3列折线图)
t = tiledlayout(3, 5, 'TileSpacing', 'loose', 'Padding', 'compact');

% 自定义 Colormap (红白蓝)
cmap = [186/256, 48/256, 49/256; 1 1 1; 35/256, 100/256, 156/256];
cmap = flipud(cmap); 
cmap_smooth = interp1(linspace(0, 1, size(cmap, 1)), cmap, linspace(0, 1, 256));

% 时间轴设置 (50ms step)
time_points = 50 * (1:size(Data_Line_Pho, 2)); 
x_limit = [0, 600];
y_limit = [-1, 1];

for k = 1:3
    % ---------------------------
    % Left Column: Heatmap
    % ---------------------------
    tile_idx_heatmap = (k-1)*5 + 1;
    nexttile(tile_idx_heatmap, [1 2]);
    
    imagesc(Heatmaps{k});
    colormap(gca, cmap_smooth); 
    caxis([-3, 3]); 
    % colorbar;
    
    % 样式设置
    set(gca, 'FontSize', 6, 'FontName', 'Arial', ...
        'TickDir', 'out', 'TickLength', [0, 0], ...
        'XColor', 'k', 'YColor', 'k', ...
        'LineWidth', 0.5, 'Box', 'on');
    set(gca, 'XTick', []); % 隐藏热力图的 X 轴刻度
    
    % 标题 (作为行标题显示在左侧或上方)
    title(Row_Titles{k}, 'FontSize', 10, 'Color', 'w', 'FontWeight', 'bold');
    
    % YLabel (Contact Number) - 仅在第一列需要，或者都加上
    ylabel('Contact number', 'FontSize', 6);

    % ---------------------------
    % Right Column: Line Plot
    % ---------------------------
    tile_idx_line = (k-1)*5 + 3;
    nexttile(tile_idx_line, [1 3]);
    
    hold on; % 【关键】：单轴绘图
    
    % 画水平零线 (可选)
    % yline(0, '--', 'Color', [0.8 0.8 0.8], 'LineWidth', 0.5);
    
    % Line A (Phonological - Red)
    plot(time_points, Means_A{k}, '-o', 'LineWidth', 1, ...
        'Color', [186/256, 48/256, 49/256], ...
        'MarkerEdgeColor', [186/256, 48/256, 49/256], 'MarkerSize', 4);
   
    % Line B (Semantic - Blue)
    plot(time_points, Means_B{k}, '-o', 'LineWidth', 1, ...
        'Color', [35/256, 100/256, 156/256], ...
        'MarkerEdgeColor', [35/256, 100/256, 156/256], 'MarkerSize', 4);
    
    hold off;
    
    % 坐标轴设置
    ylim(y_limit);
    yticks([-1, 0, 1]); % 简化刻度
    xlim(x_limit);
    
    % X 轴刻度：仅在最后一行显示，或者全部显示
    if k == 3
        xticks([0, 200, 400, 600]);
        xlabel('Time (ms)', 'FontSize', 6);
    else
        xticks([0, 200, 400, 600]);
        % xticklabels({}); % 隐藏前两行的 X 轴标签
    end

    % 【新增】：仅在第一行添加图例 (如果想每行都加，删掉 if k==1 即可)
    % if k == 1
    %     legend({'Phonological representation index', 'Semantic representation index'}, 'Box', 'off', 'Location', 'best', 'FontSize', 6);
    % end
    
    set(gca, 'FontSize', 6, 'FontName', 'Arial', ...
        'TickDir', 'out', 'LineWidth', 0.5, ...
        'Box', 'off', 'XColor', 'k', 'YColor', 'k'); 

    % 标题保持对齐
     title(Row_Titles{k}, 'FontSize', 10, 'Color', 'w', 'FontWeight', 'bold');
    
    % 【修改】：单 Y 轴标签，分两行书写
    ylabel({'Representation', 'index'}, 'Color', 'k', 'FontSize', 6);
end

% Optional: Save
% exportgraphics(gcf, fullfile(save_fig_path, [save_fig_name, '.pdf']), 'Resolution', 600);