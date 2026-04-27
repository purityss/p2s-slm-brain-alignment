clc; clear; close all;

save_fig_path = 'G:\Research\01 Speech_Comprehension\02 Figure_AI\Fig_sup_update_202601\Fig3_part';
save_fig_name_1 = 'Fig3_model_performance_bar';
save_fig_name_2 = 'Fig3_hierarchical_alignment_heatmap';
save_fig_name_3 = 'Fig3_sequential_alignment_heatmap';


%% Fig1 Model Performance 
% 1. 加载数据
try
    load('model_matrix.mat'); 
    data = model_matrix(:, 1:2);
catch
    warning('未找到文件，使用随机数据演示...');
    data = 0.5 + 0.5 * rand(12, 2); 
end

% 定义模型名称
model_names = {    'XLSR-53-ch', ...
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

% 2. 【关键步骤】数据排序处理
% 计算每一行的和 (总性能)
total_score = sum(data, 2);

% 获取排序后的索引 (descend表示降序，即总分最高的排在第一个)
[~, sort_idx] = sort(total_score, 'descend');

% 根据索引重新排列数据和名称
sorted_data = data(sort_idx, :);
sorted_names = model_names(sort_idx);

% 3. 绘制水平柱状图
figure('Color', 'w', 'Position', [100, 100, 220, 200]);

% 使用排序后的数据绘图
% b = barh(sorted_data, 'grouped'); 
b = barh(sorted_data, 'grouped', 'BarWidth', 0.9);

% --- 美化配色 ---
% b(1).FaceColor = [0.2 0.4 0.7]; % 蓝色
b(1).FaceColor = [26 77 178]/255; % 蓝色
b(1).EdgeColor = 'none';
% b(2).FaceColor = [0.9 0.4 0.3]; % 橙色
b(2).FaceColor = [204 178 51]/255; % 橙色
b(2).EdgeColor = 'none';

hold on;

% 4. 调整坐标轴与细节
ax = gca;

% 设置Y轴标签为排序后的名称
ax.YTick = 1:length(sorted_names);
ax.YTickLabel = sorted_names;

% 【重要】反转Y轴：让矩阵的第一行（即性能最好的）显示在图表的最上方
ax.YDir = 'reverse'; 

% 坐标轴设置
xlim([0 100]); 
xlabel('Model performance', 'FontSize', 6);
% title('各模型性能对比 (按总分降序排列)', 'FontSize', 7);

% 网格
grid on;
ax.YGrid = 'off';
ax.XGrid = 'on';
ax.GridAlpha = 0.3;
ax.LineWidth = 1.2;
set(gca, 'FontSize', 6, 'Box', 'off', 'FontName', 'Arial', 'TickDir', 'out', 'LineWidth', 0.5, 'XColor', 'k', 'YColor', 'k');

% 图例
% legend({'Dataset A', 'Dataset B'}, 'Location', 'northeast');

% (可选) 显示数值标签
% for i = 1:length(sorted_names)
%     % 这里使用的是 sorted_data
%     text(sorted_data(i,1), i-0.15, sprintf('%.2f', sorted_data(i,1)), ...
%         'VerticalAlignment', 'middle', 'FontSize', 7, 'Color', 'k');
%     text(sorted_data(i,2), i+0.15, sprintf('%.2f', sorted_data(i,2)), ...
%         'VerticalAlignment', 'middle', 'FontSize', 7, 'Color', 'k');
% end

exportgraphics(gcf, fullfile(save_fig_path,[save_fig_name_1,'.pdf']), 'Resolution', 600);

%% Fig2 Hierarchy alignment heatmap
% 1. 数据排序与处理 (直接使用工作区变量)
% 计算前两列的总分 (用于排序)
if exist('model_matrix', 'var') && exist('model_names', 'var')
    total_score = sum(model_matrix(:, 1:2), 2);
    
    % 获取降序排列的索引
    [~, sort_idx] = sort(total_score, 'descend');
    
    % 重排数据和名称
    sorted_matrix = model_matrix(sort_idx, :);
    sorted_names = model_names(sort_idx);
else
    error('工作区中未找到 model_matrix 或 model_names 变量，请先加载数据。');
end

% 2. 准备热力图数据 (列交换: 3->1, 5->2, 4->3)
% 提取原始的第3、4、5列
raw_cols = sorted_matrix(:, 3:5);

% 【关键步骤】调换顺序：变成 [Col3, Col5, Col4]
% 对应你的要求：第3列不变，第5列放到中间，第4列放到最后
heatmap_data = raw_cols(:, [1, 3, 2]);

% 更新X轴标签以匹配新的数据顺序
heatmap_x_labels = {'Phonological', 'Semantic', 'Shared'};

% 3. 定义经典的红-白-蓝配色 (Red-White-Blue Colormap)
% 这种配色方案通常用于表现正负相关性，白色代表 0
muted_blue = [0.27, 0.45, 0.70];   % 蓝色 (低值/负值) 0.27, 0.45, 0.70
% muted_blue = [59, 107, 47] / 255; 
light_gray = [0.98, 0.98, 0.98];   % 白色/极浅灰 (中间值/零) 0.98, 0.98, 0.98
muted_red  = [0.85, 0.35, 0.35];   % 红色 (高值/正值) 0.85, 0.35, 0.35
% muted_red  = [93, 38, 121] / 255;

n_steps = 128; % 渐变级数
% 蓝 -> 白
blue_to_gray = [linspace(muted_blue(1), light_gray(1), n_steps)', ...
                linspace(muted_blue(2), light_gray(2), n_steps)', ...
                linspace(muted_blue(3), light_gray(3), n_steps)'];
% 白 -> 红
gray_to_red = [linspace(light_gray(1), muted_red(1), n_steps)', ...
               linspace(light_gray(2), muted_red(2), n_steps)', ...
               linspace(light_gray(3), muted_red(3), n_steps)'];
% 合并
custom_rb_map = [blue_to_gray; gray_to_red(2:end, :)];

% 4. 绘制并美化热力图
figure('Color', 'w', 'Position', [100, 100, 260, 200]); % 调整长宽比

h = heatmap(heatmap_x_labels, sorted_names, heatmap_data);

% --- 应用配色与范围 ---
colormap(custom_rb_map);

% 【重要】设置颜色范围对称，确保白色准确对应 0 值
% 找出数据中绝对值最大的数
limit = max(abs(heatmap_data(:))); 
% 设置范围为 [-limit, limit]，这样 0 就在正中间的白色
% h.ColorLimits = [-limit, limit]; 
h.ColorLimits = [-1, 1]; 

% --- 细节美化 ---
h.Title = 'Hierarchical Alignment Index'; 
h.CellLabelFormat = '%.4f';       % 保留两位小数
h.XLabel = '';                    % 移除X轴标题
h.YLabel = '';                    % 移除Y轴标题

% --- 字体与样式 (修正了不支持的属性) ---
h.FontSize = 6;
h.FontName = 'Arial';
h.GridVisible = 'off'; % 相当于 Box off，去除网格线让画面更干净

% 确保标签正确显示
h.XDisplayLabels = heatmap_x_labels;
h.YDisplayLabels = repmat({''}, size(heatmap_data, 1), 1);
h.YDisplayLabels = sorted_names;
h.ColorbarVisible = 'off';

% 这里的 set 命令只保留 heatmap 支持的通用属性
% (注意：heatmap 对象不支持 Box, TickDir, XColor 等 Axes 属性)
set(gca, 'FontSize', 6, 'FontName', 'Arial');

exportgraphics(gcf, fullfile(save_fig_path,[save_fig_name_2,'.pdf']), 'Resolution', 600);

%% Fig3 Sequential alignment heatmap
% 1. 数据排序与处理 (直接使用工作区变量)
% 计算前两列的总分 (用于排序)
if exist('model_matrix', 'var') && exist('model_names', 'var')
    total_score = sum(model_matrix(:, 1:2), 2);
    
    % 获取降序排列的索引
    [~, sort_idx] = sort(total_score, 'descend');
    
    % 重排数据和名称
    sorted_matrix = model_matrix(sort_idx, :);
    sorted_names = model_names(sort_idx);
else
    error('工作区中未找到 model_matrix 或 model_names 变量，请先加载数据。');
end

% 2. 准备热力图数据 (列交换: 3->1, 5->2, 4->3)
% 提取原始的第3、4、5列
raw_cols = sorted_matrix(:, 6:8);

% 【关键步骤】调换顺序：变成 [Col3, Col5, Col4]
% 对应你的要求：第3列不变，第5列放到中间，第4列放到最后
heatmap_data = raw_cols(:, [1, 3, 2]);

% 更新X轴标签以匹配新的数据顺序
heatmap_x_labels = {'Phonological', 'Semantic', 'Shared'};

% 3. 定义经典的红-白-蓝配色 (Red-White-Blue Colormap)
% 这种配色方案通常用于表现正负相关性，白色代表 0
muted_blue = [0.27, 0.45, 0.70];   % 蓝色 (低值/负值)
light_gray = [0.98, 0.98, 0.98];   % 白色/极浅灰 (中间值/零)
muted_red  = [0.85, 0.35, 0.35];   % 红色 (高值/正值)

n_steps = 128; % 渐变级数
% 蓝 -> 白
blue_to_gray = [linspace(muted_blue(1), light_gray(1), n_steps)', ...
                linspace(muted_blue(2), light_gray(2), n_steps)', ...
                linspace(muted_blue(3), light_gray(3), n_steps)'];
% 白 -> 红
gray_to_red = [linspace(light_gray(1), muted_red(1), n_steps)', ...
               linspace(light_gray(2), muted_red(2), n_steps)', ...
               linspace(light_gray(3), muted_red(3), n_steps)'];
% 合并
custom_rb_map = [blue_to_gray; gray_to_red(2:end, :)];

% 4. 绘制并美化热力图
figure('Color', 'w', 'Position', [100, 100, 260, 200]); % 调整长宽比

h = heatmap(heatmap_x_labels, sorted_names, heatmap_data);

% --- 应用配色与范围 ---
colormap(custom_rb_map);

% 【重要】设置颜色范围对称，确保白色准确对应 0 值
% 找出数据中绝对值最大的数
limit = max(abs(heatmap_data(:))); 
% 设置范围为 [-limit, limit]，这样 0 就在正中间的白色
% h.ColorLimits = [-limit, limit]; 
h.ColorLimits = [-1, 1]; 

% --- 细节美化 ---
h.Title = 'Sequential Alignment Index'; 
h.CellLabelFormat = '%.4f';       % 保留两位小数
h.XLabel = '';                    % 移除X轴标题
h.YLabel = '';                    % 移除Y轴标题

% --- 字体与样式 (修正了不支持的属性) ---
h.FontSize = 6;
h.FontName = 'Arial';
h.GridVisible = 'off'; % 相当于 Box off，去除网格线让画面更干净

% 确保标签正确显示
h.XDisplayLabels = heatmap_x_labels;
h.YDisplayLabels = repmat({''}, size(heatmap_data, 1), 1);
h.YDisplayLabels = sorted_names;
h.ColorbarVisible = 'off';

% 这里的 set 命令只保留 heatmap 支持的通用属性
% (注意：heatmap 对象不支持 Box, TickDir, XColor 等 Axes 属性)
set(gca, 'FontSize', 6, 'FontName', 'Arial');

exportgraphics(gcf, fullfile(save_fig_path,[save_fig_name_3,'.pdf']), 'Resolution', 600);
