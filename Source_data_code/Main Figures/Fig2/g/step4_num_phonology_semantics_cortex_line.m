clear all
close all
clf
save_fig_path = 'G:\Research\01 Speech_Comprehension\02 Figure_AI\Fig_sup_update_202601\Fig2_part';
save_fig_name = 'prop_3unit_line';
% save_fig_name = 'prop_3unit_line_legend';


% --- 数据加载与处理 ---
load('num_all_p_s_2.mat')
num = num_all_p_s(:,1);
num_p = num_all_p_s(:,2);
num_s = num_all_p_s(:,3);
num_both = num_all_p_s(:,4);

% 计算比例
prop_p = num_p ./ num * 100;
prop_s = num_s ./ num * 100;
prop_both = num_both ./ num * 100;

% --- 颜色定义 (保持一致) ---
% color_p = [231/256, 126/256, 121/256];      % pho (红)
% color_s = [112/256, 166/256, 202/256];      % sem (蓝)
% color_both = [158/256, 137/256, 193/256];   % both (紫)
color_p = [180, 37, 35] / 255;      % pho (红)
color_s = [34, 91, 142] / 255;      % sem (蓝)
color_both = [103, 38, 141] / 255;   % both (紫)

% --- 绘图 ---
gcf = figure(1);
set(gcf, 'Position', [100, 100, 360, 170]);
set(gcf, 'Color', 'w');
hold on;

% 定义 X 轴坐标 (1 到 14)
x_axis = 1:length(prop_p);

% 绘制折线
% 为了视觉清晰，加了 Marker ('o') 和稍微粗一点的线 ('LineWidth', 1.5)
% plot(x_axis, prop_p,    '-', 'Color', color_p,    'LineWidth', 1.5, 'MarkerSize', 4, 'MarkerFaceColor', color_p);
% plot(x_axis, prop_both, '-', 'Color', color_both, 'LineWidth', 1.5, 'MarkerSize', 4, 'MarkerFaceColor', color_both);
% plot(x_axis, prop_s,    '-', 'Color', color_s,    'LineWidth', 1.5, 'MarkerSize', 4, 'MarkerFaceColor', color_s);

% --- 绘制折线（替换原来的三行 plot） ---
% ① 先平滑（窗口大小可调，比如 3/5/7）
w = 3;
prop_p_smooth    = smoothdata(prop_p,    'movmean', w);
prop_both_smooth = smoothdata(prop_both, 'movmean', w);
prop_s_smooth    = smoothdata(prop_s,    'movmean', w);

% ② 再画平滑后的曲线
plot(x_axis, prop_p_smooth,    '-', 'Color', color_p,    'LineWidth', 1.5, 'MarkerSize', 4, 'MarkerFaceColor', color_p);
plot(x_axis, prop_both_smooth, '-', 'Color', color_both, 'LineWidth', 1.5, 'MarkerSize', 4, 'MarkerFaceColor', color_both);
plot(x_axis, prop_s_smooth,    '-', 'Color', color_s,    'LineWidth', 1.5, 'MarkerSize', 4, 'MarkerFaceColor', color_s);


% --- 坐标轴设置 ---
xlim([0.5, 14.5]); % 留一点边距
xticks(1:14);
xticklabels({'HG', 'Insula','pmSTG','MTG','ITG','PCC','Cuneus','MFG','IFG','Sensorimotor','MTL','aSTG','Temporal Pole','IPL'});
xtickangle(90);    % 保持垂直排列

% Y轴范围 (根据你的之前代码设为 0-50，如果数据超出请改为 0-100)
ylim([0 50]); 
yticks(0:10:50);

% --- 美化与标注 ---
ylabel('Proportion of sEEG contacts (%)', 'FontSize', 6, 'FontName', 'Arial', 'Color', 'k');

% 统一设置字体和坐标轴样式
set(gca, 'FontSize', 6, 'Box', 'off', 'FontName', 'Arial', ...
    'TickDir', 'out', 'LineWidth', 0.5, 'XColor', 'k', 'YColor', 'k');

% 图例
% legend({'phonological', 'shared', 'semantic'}, ...
%        'FontSize', 7, 'Box', 'off', 'Location', 'NorthWest'); % 位置可以根据曲线走势调整，如 'Best'

% exportgraphics(gcf, fullfile(save_fig_path,[save_fig_name,'.pdf']) ,'Resolution',600);