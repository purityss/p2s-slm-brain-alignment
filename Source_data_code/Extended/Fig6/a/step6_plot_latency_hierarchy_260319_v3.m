% 清理环境
clear; clc; close all;

% --- Setup Paths and Load Data ---
save_fig_path = 'G:\Research\01 Speech_Comprehension\02 Figure_AI\Fig_sup_update_202603\Fig3_related_sup_part';
save_fig_name = 'hierarchy_latency';

% ==========================================
% 1. 加载真实数据并转换为物理时间 (ms)
% ==========================================
disp('正在加载真实数据...');
d_pho = load('time_start_phonology_only.mat'); 
d_sem = load('time_start_semantics_only.mat');
d_both = load('time_start_both_all.mat');

% 动态提取结构体中的真实数据变量
f_pho = fieldnames(d_pho); val_pho = d_pho.(f_pho{1});
f_sem = fieldnames(d_sem); val_sem = d_sem.(f_sem{1});
f_both = fieldnames(d_both); val_both = d_both.(f_both{1});

% 确保数据为标准的数值列向量
if iscell(val_pho), val_pho = cell2mat(val_pho); end
if iscell(val_sem), val_sem = cell2mat(val_sem); end
if iscell(val_both), val_both = cell2mat(val_both); end

% 🌟 核心修改 1：直接映射为真实的物理毫秒数
val_pho_ms = (val_pho(:) - 1) * 50;
val_sem_ms = (val_sem(:) - 1) * 50;
val_both_ms = (val_both(:) - 1) * 50;

% ==========================================
% 2. 划定 100ms 的 Bin 并统计
% ==========================================
% 边缘设置：[-25, 75) 包含 0 和 50; [75, 175) 包含 100 和 150...
edges = -25:100:875; 

% X轴: 每根 100ms 柱子的中心位置
latencies = 25:100:825; 

% 统计落入每个 100ms 窗口的 contacts 数量
count_pho = histcounts(val_pho_ms, edges);
count_sem = histcounts(val_sem_ms, edges);
count_both = histcounts(val_both_ms, edges);

% 🌟 核心修改 2：转换为基于全脑 contacts 总数 (962) 的比例
total_contacts = 962;
prop_pho = count_pho / total_contacts;
prop_sem = count_sem / total_contacts;
prop_both = count_both / total_contacts;

% 找到全局最大的比例，用于统一 Y 轴，加上20%顶部留白
max_y = max([prop_pho, prop_sem, prop_both]) * 1.2; 
if max_y == 0
    max_y = 1; 
end

% ==========================================
% 3. 绘图设置与初始化
% ==========================================
% 定义指定颜色
c_pho = [180, 37, 35] / 255;
c_sem = [34, 91, 142] / 255;
c_both = [103, 38, 141] / 255;

% 创建更密集的 X 轴网格用于平滑插值 (曲线拟合)
x_fit = linspace(min(latencies), max(latencies), 300);

% 创建图形
figure('Color', 'w', 'Position', [100, 100, 400, 400]);
t = tiledlayout(3, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

% ==========================================
% 4. 绘制三张子图
% ==========================================
% ---- 子图 1: Phonology only ----
nexttile;
hold on;
% width=1 表示柱子填满 100ms 间距，无缝隙
bar(latencies, prop_pho, 1, 'FaceColor', c_pho, 'FaceAlpha', 0.6, 'EdgeColor', 'w');
y_fit_pho = max(0, pchip(latencies, prop_pho, x_fit));
plot(x_fit, y_fit_pho, 'Color', c_pho, 'LineWidth', 1.5);
title('Phonology sEEG contacts (n = 210)', 'Color', 'k', 'FontName', 'Arial','FontSize', 8, 'FontWeight', 'bold');
hold off;

% ---- 子图 2: Semantics only ----
nexttile;
hold on;
bar(latencies, prop_sem, 1, 'FaceColor', c_sem, 'FaceAlpha', 0.6, 'EdgeColor', 'w');
y_fit_sem = max(0, pchip(latencies, prop_sem, x_fit));
plot(x_fit, y_fit_sem, 'Color', c_sem, 'LineWidth', 1.5);
title('Semantics sEEG contacts (n = 218)', 'Color', 'k', 'FontName', 'Arial', 'FontSize', 8, 'FontWeight', 'bold');
hold off;

% ---- 子图 3: Both ----
nexttile;
hold on;
bar(latencies, prop_both, 1, 'FaceColor', c_both, 'FaceAlpha', 0.6, 'EdgeColor', 'w');
y_fit_both = max(0, pchip(latencies, prop_both, x_fit));
plot(x_fit, y_fit_both, 'Color', c_both, 'LineWidth', 1.5);
title('P2S-transfer sEEG contacts (n = 43)', 'Color', 'k', 'FontName', 'Arial', 'FontSize', 8, 'FontWeight', 'bold');
hold off;

% ==========================================
% 5. 统一格式化所有坐标轴
% ==========================================
all_axes = findobj(gcf, 'Type', 'axes');
for i = 1:length(all_axes)
    ax = all_axes(i);
    
    % 调整边界，让最左侧和最右侧的 100ms 柱子不被裁切
    set(ax, 'XLim', [-50, 850]); 
    set(ax, 'YLim', [0, max_y]);
    
    % X 轴坐标依然保持 0, 100, 200 的整百刻度，方便阅读
    % (去掉了强制的 YTick 步长，让 MATLAB 自动分配合适的刻度)
    set(ax, 'XTick', 0:100:800);  
    
    % 极简美化
    ax.TickDir = 'out';
    box(ax, 'off');
    grid(ax, 'on');
    ax.XGrid = 'off';
    ax.GridLineStyle = '--';
    ax.GridAlpha = 0.4;

    % 👇 新增/修改下面这四行 👇
    ax.LineWidth = 0.5;       % 将坐标轴主线和刻度线宽度统一设为 0.5 磅
    ax.XColor = 'k';          % 将 X 轴线条和刻度文字设为纯黑色 ('k')
    ax.YColor = 'k';          % 将 Y 轴线条和刻度文字设为纯黑色 ('k')
    ax.Layer = 'top';         % 将坐标轴强制置于顶层，覆盖在透明的柱子之上
    
    % 隐藏除了最下面一张图以外的 X 轴标签
    if i > 1
        ax.XTickLabel = []; 
    end
end

% ==========================================
% 6. 添加全局标签
% ==========================================
xlabel(t, 'Latency (ms)', 'FontName', 'Arial', 'FontSize', 8);
% 🌟 核心修改 3：更新 Y 轴全局标签
ylabel(t, 'Proportion of total contacts', 'FontName', 'Arial', 'FontSize', 8);
disp('100ms Bin 图表绘制完成！');

% --- Save ---
exportgraphics(gcf, fullfile(save_fig_path,[save_fig_name,'.pdf']), 'Resolution', 600);

% ==========================================
% 7. 保存拟合的曲线数据为三列的矩阵
% ==========================================
% 将拟合出的行向量转换为列向量 (N x 1)
y_pho_col = y_fit_pho(:);
y_sem_col = y_fit_sem(:);
y_p2s_col = y_fit_both(:); 

% 将三列数据合并成一个 N x 3 的矩阵
latency_fitted_curves_matrix = [y_pho_col, y_sem_col, y_p2s_col];

% 保存到工作目录下的 mat 文件中
save('latency_fitted_curves_data.mat', 'latency_fitted_curves_matrix', 'x_fit');
disp('拟合曲线数据已成功导出为 latency_fitted_curves_data.mat！');