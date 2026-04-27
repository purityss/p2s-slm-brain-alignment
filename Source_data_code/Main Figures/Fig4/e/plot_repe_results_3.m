% =========================================================================
% Nature-style Grouped Bar Chart with Double Y-Axes
% 目标：展示最优 \alpha 取值下，准确率(宏观)与 \chi_{P2S} (微观机制) 的协同跃升
% =========================================================================
clear; clc; close all;
name = 'qwen2_audio';
save_fig_path = 'G:\Research\01 Speech_Comprehension\02 Figure_AI\Fig_sup_update_202603\Fig4_related_sup_part';
save_fig_name = sprintf('%s_steering', name);

% 1. 提取的最优对比数据 (Baseline vs Alpha=0.1)
acc_data = [0.807692308, 0.865384615]; % Performance
chi_data = [9.41117855505014, 9.90926822443645];   % 原 M_mean，现改为 \chi_{P2S}
% labels = {'Baseline', {'Targeted Steering', '(\alpha = 0.1)'}}; % X轴标签优化为换行
labels = {'Baseline', 'Targeted Steering (\alpha = 0.1)'};


% 2. 基础绘图设置
fig = figure('Position', [100, 100, 180, 230], 'Color', 'w');
x = [0.6, 1.4];

% =========================================================================
% 【核心修改区】：精确控制柱宽与间距
% =========================================================================
bar_width = 0.35;  % 柱子宽度 (调细一点以适应狭窄的画幅)
gap = 0.01;        % 两个柱子之间的间隙
shift = bar_width/2 + gap/2; % 计算对称平移的绝对距离，确保红蓝柱子完美对称

% 配色方案 (经典学术双色：深邃科研蓝 + 机制活力橙)
color_acc = [0.1216, 0.4706, 0.7059]; % #1f77b4
color_chi = [0.8392, 0.3765, 0.1569]; % #d66028

% =========================================================================
% 3. 绘制左侧 Y 轴 (Accuracy / Performance)
% =========================================================================
yyaxis left
% 利用 x - shift 完美向左平移
b1 = bar(x - shift, acc_data, bar_width, 'FaceColor', color_acc, 'EdgeColor', 'none');
ylabel('Model performance', 'FontSize', 8, 'Color', color_acc);
set(gca, 'YColor', color_acc);

% 设置完美的刻度范围
ylim([0.75, 0.90]); 
yticks(0.75:0.05:0.90);

% 文本的 X 坐标与柱子的 X 坐标(x - shift)保持绝对一致
for i = 1:length(x)
    text(x(i) - shift, acc_data(i) + 0.005, sprintf('%.3f', acc_data(i)), ...
        'HorizontalAlignment', 'center', 'Color', color_acc, 'FontSize', 8);
end

% =========================================================================
% 4. 绘制右侧 Y 轴 (\Delta P2S)
% =========================================================================
yyaxis right
% 利用 x + shift 完美向右平移
b2 = bar(x + shift, chi_data, bar_width, 'FaceColor', color_chi, 'EdgeColor', 'none');

ylabel('\Delta(P2S)', 'FontSize', 8, 'Color', color_chi, 'Interpreter', 'tex');
set(gca, 'YColor', color_chi);

% 设置右轴范围
ylim([9.0, 10]); 
yticks(9.0:0.5:10);

% 文本的 X 坐标与柱子的 X 坐标(x + shift)保持绝对一致
for i = 1:length(x)
    text(x(i) + shift, chi_data(i) + 0.05, sprintf('%.2f', chi_data(i)), ...
        'HorizontalAlignment', 'center', 'Color', color_chi, 'FontSize', 8);
end

% =========================================================================
% 5. 整体坐标轴美化 (The "Nature" Look)
% =========================================================================
% 设定 X 轴标签和全局字体
set(gca, 'XTick', x, 'XTickLabel', labels, 'FontSize', 8, 'FontName', 'Arial');

% 【控制两端留白】：让柱子向两侧的坐标轴靠拢，画面更紧凑饱满
xlim([0.1, 1.9]);

% 将坐标轴线宽统一设置为 0.5，显得更加精致
ax = gca;
ax.XAxis.LineWidth = 0.5;
ax.YAxis(1).LineWidth = 0.5;
ax.YAxis(2).LineWidth = 0.5;
% ax.TickDir = 'out'; % 刻度朝外更清爽

% 去除土气的顶部边框
box off; 

% 输出 PDF
exportgraphics(gcf, fullfile(save_fig_path, [save_fig_name, '.pdf']), 'Resolution', 600);