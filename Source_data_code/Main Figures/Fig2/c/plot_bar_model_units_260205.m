clear
close all
load('num_units.mat')

save_fig_path = 'G:\Research\01 Speech_Comprehension\02 Figure_AI\Fig_sup_update_202601\Fig2_part';
save_fig_name = 'all_modles_prop_3unit_v3';

%% 1. 准备模型名称
models = { ...
    'XLSR-53-ch', 'Whisper-large-v3', 'LLaSM', 'SALMONN', ...
    'Qwen-Audio', 'Qwen-Audio-Chat', 'Qwen2-Audio', 'Qwen2-Audio-Instruct', ...
    'GLM-4-Voice', 'Freeze-Omni', 'MiniCPM-o 2.6', 'Qwen2.5-Omni'};

%% 2. 提取数据并计算百分比
% 修改点①：重排顺序为 [shared, pho, sem, ns]，确保紫色在最底层
plot_data_raw = num_units(:, [4, 2, 3, 5]); 
row_totals = sum(plot_data_raw, 2);
percentages = (plot_data_raw ./ row_totals) * 100;

%% 3. 定义颜色
color_p = [180, 37, 35] / 255;      % pho (红)
color_s = [34, 91, 142] / 255;      % sem (蓝)
color_both = [103, 38, 141] / 255;   % shared (紫)
color_ns = [0.7 0.7 0.7];           % non-sensitive (灰)
colors = [color_both; color_p; color_s; color_ns];

%% 4. 修改点②：三段式 Y 轴拉伸逻辑
% 定义视觉节点：
% 0% 对应位置 0
% 1% 对应位置 10 (50的五分之一，假设总高度100，50在中点50，其1/5为10)
% 50% 对应位置 50
% 100% 对应位置 100

transform_y = @(x) ...
    (x <= 1) .* (x * 15) + ...
    (x > 1 & x <= 50) .* (15 + (x - 1) * (35 / 49)) + ...
    (x > 50) .* (50 + (x - 50) * (50 / 50));

% 对堆叠数据进行变换
cum_perc = cumsum(percentages, 2);
trans_cum = zeros(size(cum_perc));
for i = 1:size(cum_perc, 1)
    for j = 1:size(cum_perc, 2)
        trans_cum(i,j) = transform_y(cum_perc(i,j));
    end
end
trans_plot_data = [trans_cum(:, 1), diff(trans_cum, 1, 2)];

%% 5. 绘制堆叠柱状图
figure('Color', 'w', 'Position', [100, 100, 370, 160]);
b = bar(trans_plot_data, 'stacked', 'EdgeColor', 'none', 'BarWidth', 0.65);

for k = 1:4
    b(k).FaceColor = colors(k, :);
end

%% 6. 图表美化与刻度设置
set(gca, 'XTick', 1:12, 'XTickLabel', models, ...
    'TickLabelInterpreter', 'none', 'FontSize', 6);
xtickangle(45); 

% 仅标注 0, 1, 50, 100
tick_values = [0, 1, 50, 100];
set(gca, 'YTick', [transform_y(0), transform_y(1), transform_y(50), transform_y(100)], ...
    'YTickLabel', {'0', '1', '50', '100'});

ylabel('Proportion (%)', 'FontSize', 6);
title('Proportion of Units Types per Model', 'FontSize', 6);

set(gca, 'FontSize', 6, 'Box', 'off', 'FontName', 'Arial', 'TickDir', 'out', ...
    'LineWidth', 0.5, 'XColor', 'k', 'YColor', 'k');

grid off;
set(gca, 'Layer', 'top');
ylim([0 100]);

% 保存
if ~exist(save_fig_path, 'dir'), mkdir(save_fig_path); end
exportgraphics(gcf, fullfile(save_fig_path, [save_fig_name, '.pdf']), 'Resolution', 600);
