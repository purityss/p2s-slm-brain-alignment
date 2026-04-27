% 清理环境
clear; clc; close all;

save_fig_path = 'G:\Research\01 Speech_Comprehension\02 Figure_AI\Fig_sup_update_202603\Fig4_related_sup_part';
save_fig_name = 'lesion_all_models';

% 1. 数据准备
models = {'Xlsr-53-ch', 'Whisper-large-v3', 'LLaSM', 'SALMONN', 'Qwen-Audio', ...
          'Qwen-Audio-Chat', 'Qwen2-Audio', 'Awen2-Audio-Instruct', ...
          'GLM-4-Voice', 'Freeze-Omni', 'Minicpm-o 2.6', 'Qwen2.5-Omni'};

baselines = [76.15; 81.71; 4.84; 52.61; 84.33; 91.14; 90.90; 89.86; 74.49; 68.37; 93.22; 93.69];
pho = [76.12; 81.60; 4.37; 52.33; 77.57; 91.19; 89.37; 86.52; 32.55; 67.95; 92.43; 93.11];
sem = [76.12; 81.60; 4.57; 51.46; 74.71; 90.95; 74.31; 88.14; 74.15; 77.00; 92.87; 93.45];
p2s = [76.14; 81.42; 4.75; 49.16; 47.23; 87.24; 60.72; 84.87; 64.49; 71.26; 93.42; 93.25];

% 计算 Performance 的变化量 (Lesion - Baseline)
change_pho = pho - baselines;
change_sem = sem - baselines;
change_p2s = p2s - baselines;

% 2. 定义颜色 (RGB 归一化到 0-1 范围)
colors = [
    180/255, 37/255, 35/255;   % pho lesion
    34/255, 91/255, 142/255;   % sem lesion
    103/255, 38/255, 141/255   % p2s lesion
];

% 3. 创建图形与布局
figure('Position', [100, 100, 700, 450], 'Color', 'w');

% 使用 tiledlayout 方便控制子图间距和全局标签 (适用于 R2019b 及以上版本)
t = tiledlayout(3, 4, 'TileSpacing', 'compact', 'Padding', 'compact');

% 4. 循环绘制 12 个模型的子图
for i = 1:12
    nexttile;
    
    % 当前模型的三个变化数据
    data = [change_pho(i), change_sem(i), change_p2s(i)];
    
    % 绘制柱状图，取消边框线
    b = bar(1:3, data, 'FaceColor', 'flat', 'EdgeColor', 'none', 'BarWidth', 0.5);
    
    % 为三根柱子分别赋色
    b.CData = colors;
    
    hold on;
    % 在 Y=0 处添加黑色实线基准线
    yline(0, 'k-', 'LineWidth', 0.5);
    hold off;
    
    % 设置标题与 X 轴刻度
    % xticks(1:3);
    xticks([]); % 清空 X 轴的所有刻度和标签
    
    % 在 MATLAB 中，直接对 X 轴标签分别上色比较繁琐，这里使用标准文字
    % 若需追求极高还原度，可隐藏此标签并用 text() 补充
    % xticklabels({'pho\newline lesion', 'sem\newline lesion', 'p2s\newline lesion'});
    
    % 样式美化：网格线和边框
    grid on;
    set(gca, 'FontName', 'Arial','XGrid', 'off', 'YGrid', 'on', 'GridColor', [0.8 0.8 0.8], 'GridAlpha', 0.5,'FontSize', 8, 'XColor', 'k', 'YColor', 'k');
    box off;
    
    % 隐藏 X 轴和 Y 轴的主干黑线 (只保留网格线和刻度，贴近目标图的极简感)
    ax = gca;
    ax.XRuler.Axle.LineStyle = 'none';
    ax.YRuler.Axle.LineStyle = 'none';
    ax.TickDir = 'out';

    % 设置标题
    title(models{i}, 'Interpreter', 'none', 'FontSize', 8, 'FontWeight', 'bold','Color','k');

end

% 5. 添加全局共享的 Y 轴标签
ylabel(t, 'Change in model performance (%)', 'FontName', 'Arial', 'FontSize', 8);

exportgraphics(gcf, fullfile(save_fig_path,[save_fig_name,'.pdf']) ,'Resolution',600);