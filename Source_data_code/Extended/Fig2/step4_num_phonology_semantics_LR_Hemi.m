clear
close all

load('brain_hemi_counts_2.mat')

save_fig_path = 'G:\Research\Auditory model\Figure_AI\Fig2_part_update';
save_fig_name = 'prop_LR_hemi_3unit';

data_numeric = cell2mat(brain_hemisphere_counts(:, 2:5));

% 分别赋值给变量
num      = data_numeric(:, 1);
num_p    = data_numeric(:, 2);
num_s    = data_numeric(:, 3);
num_both = data_numeric(:, 4);

% 构建 2×3 的列联表（行：Left/Right，列：Phonology/Semantics/Both）
tbl = [num_p(1), num_s(1), num_both(1); 
       num_p(2), num_s(2), num_both(2)];

% 执行卡方独立性检验
[chi2, p, df] = chi2test_independence(tbl);

% 显示结果
fprintf('卡方检验结果（左右脑在三类电极点的分布差异）：\n');
fprintf('χ²(%.f) = %.3f, p = %.4f\n', df, chi2, p);
if p < 0.05
    fprintf('** 左右脑在三类电极点的比例分布有显著差异 (p < 0.05) **\n');
else
    fprintf('左右脑在三类电极点的比例分布无显著差异 (p > 0.05)\n');
end

%% 卡方独立性检验函数（适用于任意R×C表）
function [chi2, p, df] = chi2test_independence(tbl)
    % 计算期望频数
    row_totals = sum(tbl, 2);
    col_totals = sum(tbl, 1);
    n = sum(tbl(:));
    expected = (row_totals * col_totals) / n;
    
    % 计算卡方统计量
    chi2 = sum((tbl(:) - expected(:)).^2 ./ expected(:), 'omitnan');
    
    % 计算自由度 (df = (rows-1)*(cols-1))
    df = (size(tbl, 1)-1) * (size(tbl, 2)-1);
    
    % 计算p值
    p = 1 - chi2cdf(chi2, df);
    
    % 如果期望频数太小（<5的格子超过20%），建议用Fisher精确检验或Monte Carlo模拟
    if sum(expected(:) < 5) > (0.2 * numel(expected))
        warning('超过20%%的格子期望频数<5，建议使用Fisher精确检验或Monte Carlo模拟');
    end
end

prop_all = num ./ num * 100;
prop_p = num_p ./ num * 100;
prop_s = num_s ./ num * 100;
prop_both = num_both ./ num * 100;

prop(:,1) = prop_p;
prop(:,2) = prop_s;
prop(:,3) = prop_both;

gcf = figure(1);
set(gcf, 'Position', [100, 100, 180, 213]);  % 更合理比例
set(gcf, 'Color', 'w');  % 背景白色

% 设置每个柱子的颜色
% colors = [249/256, 196/256, 194/256;   % 第一组柱子的颜色（RGB）
%           156/256, 196/256, 226/256    % 第二组柱子的颜色（RGB）
%           0.751, 0.691, 0.857];   %0.716, 0.659, 0.816; 0.791, 0.766, 0.820; 0.791, 0.727, 0.902; 0.712, 0.655, 0.812; 0.751, 0.691, 0.857; 0.728, 0.669, 0.830
%           %198/256, 197/256, 196/256 ]; % 第三组柱子的颜色（RGB）
colors = [231/256, 126/256, 121/256;   % 第一组柱子的颜色（RGB）
          112/256, 166/256, 202/256;    % 第二组柱子的颜色（RGB）
          158/256, 137/256, 193/256];  
% 位置参数设置
group_centers = [1, 2];      % 两组位置（Left, Right）
bar_width = 0.2;  % 缩小每根柱子宽度
offsets = [-0.24, 0, 0.24];  % 增大组内柱子间距

hold on
% 绘制柱子
for i = 1:3  % 三种类型：p, s, both
    x = group_centers + offsets(i);
    y = prop(:, i);
    bar(x, y, bar_width, ...
        'FaceColor', colors(i,:), ...
        'EdgeColor', 'none');
end

xlim([0.35, 2.65]);
xticks(group_centers);
xticklabels({'Left', 'Right'});

% for k = 1:length(b)
%     b(k).FaceColor = 'flat'; % 允许每个柱子有不同的颜色
%     b(k).CData = repmat(colors(k, :), size(prop, 1), 1); % 设置颜色
%     b(k).EdgeColor = 'none'; % 设置轮廓颜色为黑色
% end 

ylim([0 50]);
yticks(0:10:50);
set(gca, ...
    'FontSize', 8, ...
    'FontName', 'Arial', ...
    'TickDir', 'out', ...
    'LineWidth', 0.5, ...
    'XColor', 'k', ...
    'YColor', 'k');

ylabel('Proportion of contacts (%)', ...
    'FontSize', 8, ...
    'FontName', 'Arial', ...
    'Color', 'k');

xlabel('Hemisphere', ...
    'FontSize', 8, ...
    'FontName', 'Arial', ...
    'Color', 'k');

box off; 
% title('Propotion of selective contacts in ROIs', 'FontWeight','bold', 'FontSize',36);
% ylabel('Propotion of contacts (%)', 'FontSize',25, 'FontName', 'Arial',  'Color', 'k');
% xlabel('ROIs','FontSize',30);
% set(gca, 'FontSize', 25, 'FontName', 'Arial', 'XColor', 'k', 'YColor', 'k');
% exportgraphics(gcf, fullfile(save_fig_path,[save_fig_name,'.pdf']) ,'Resolution',600);