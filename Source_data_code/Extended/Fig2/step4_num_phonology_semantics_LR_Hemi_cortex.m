clear
close all

load('brain_hemi_counts_cortex.mat')

save_fig_path = 'G:\Research\Auditory model\Figure_AI\Sup3_part';
save_fig_name = 'prop_LR_hemi_3unit_HG';
% save_fig_name = 'prop_LR_hemi_3unit_Insula';
% save_fig_name = 'prop_LR_hemi_3unit_pmSTG';
% save_fig_name = 'prop_LR_hemi_3unit_MTG';
% save_fig_name = 'prop_LR_hemi_3unit_ITG';
% save_fig_name = 'prop_LR_hemi_3unit_PCC';
% save_fig_name = 'prop_LR_hemi_3unit_Cuneus';
% save_fig_name = 'prop_LR_hemi_3unit_MFG';
% save_fig_name = 'prop_LR_hemi_3unit_IFG';
% save_fig_name = 'prop_LR_hemi_3unit_Sensorimotor';
% save_fig_name = 'prop_LR_hemi_3unit_MTL';
% save_fig_name = 'prop_LR_hemi_3unit_aSTG';
% save_fig_name = 'prop_LR_hemi_3unit_TemporalPole';
% save_fig_name = 'prop_LR_hemi_3unit_IPL';

% 筛选出 HG 区域左右脑数据
is_HG = strcmp(result_table.Region, 'HG');
% is_HG = strcmp(result_table.Region, 'Insula');
% is_HG = strcmp(result_table.Region, 'pmSTG');
% is_HG = strcmp(result_table.Region, 'MTG');
% is_HG = strcmp(result_table.Region, 'ITG');
% is_HG = strcmp(result_table.Region, 'PCC');
% is_HG = strcmp(result_table.Region, 'Cuneus');
% is_HG = strcmp(result_table.Region, 'MFG');
% is_HG = strcmp(result_table.Region, 'IFG');
% is_HG = strcmp(result_table.Region, 'Sensorimotor');
% is_HG = strcmp(result_table.Region, 'MTL');
% is_HG = strcmp(result_table.Region, 'aSTG');
% is_HG = strcmp(result_table.Region, 'TemporalPole');
% is_HG = strcmp(result_table.Region, 'IPL');
HG_data = result_table(is_HG, :);

% 确保 Left 在第1行，Right 在第2行（或相反）
[~, sort_idx] = sort(HG_data.Hemisphere);  % 'Left' < 'Right' 按字母排序
HG_data = HG_data(sort_idx, :);

% 提取比例数据
num = HG_data.TotalContacts;
num_p = HG_data.Phonology;
num_s = HG_data.Semantics;
num_both = HG_data.Both;

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

% 分别赋值给变量
% num      = data_numeric(:, 1);
% num_p    = data_numeric(:, 2);
% num_s    = data_numeric(:, 3);
% num_both = data_numeric(:, 4);

prop_all = num ./ num * 100;
prop_p = num_p ./ num * 100;
prop_s = num_s ./ num * 100;
prop_both = num_both ./ num * 100;

prop(:,1) = prop_p;
prop(:,2) = prop_s;
prop(:,3) = prop_both;

gcf = figure(1);
set(gcf, 'Position', [100, 100, 155, 190]);  % 更合理比例
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

x_pos = [1, 2];
% y_pos = [48, 48];
height = 45;

if p < 0.001
    text((x_pos(1) + x_pos(2))/2, height + 0.5, '***', 'FontSize', 15, 'HorizontalAlignment', 'center');
    line([x_pos(1), x_pos(2)],[height,height], 'Color', 'k', 'LineStyle', '-','LineWidth',0.5);

elseif p < 0.01
    text((x_pos(1) + x_pos(2))/2, height + 0.5, '**', 'FontSize', 15, 'HorizontalAlignment', 'center');
    line([x_pos(1), x_pos(2)],[height,height], 'Color', 'k', 'LineStyle', '-','LineWidth',0.5);

elseif p < 0.05
    text((x_pos(1) + x_pos(2))/2, height + 0.5, '*', 'FontSize', 15, 'HorizontalAlignment', 'center');   
    line([x_pos(1), x_pos(2)],[height,height], 'Color', 'k', 'LineStyle', '-','LineWidth',0.5);

end     

xlim([0.45, 2.55]);
xticks(group_centers);
xticklabels({'Left', 'Right'});

% for k = 1:length(b)
%     b(k).FaceColor = 'flat'; % 允许每个柱子有不同的颜色
%     b(k).CData = repmat(colors(k, :), size(prop, 1), 1); % 设置颜色
%     b(k).EdgeColor = 'none'; % 设置轮廓颜色为黑色
% end 

ylim([0 50]);
yticks(0:10:50);
set(gca, 'FontSize', 8, 'FontName', 'Arial', 'TickDir', 'out', 'LineWidth', 0.5, 'XColor', 'k', 'YColor', 'k');

ylabel('Proportion of contacts (%)', 'FontSize', 8, 'FontName', 'Arial', 'Color', 'k');

xlabel('HG', 'FontSize', 8, 'FontName', 'Arial', 'Color', 'k');
% xlabel('Insula', 'FontSize', 8, 'FontName', 'Arial', 'Color', 'k');
% xlabel('pmSTG', 'FontSize', 8, 'FontName', 'Arial', 'Color', 'k');
% xlabel('MTG', 'FontSize', 8, 'FontName', 'Arial', 'Color', 'k');
% xlabel('ITG', 'FontSize', 8, 'FontName', 'Arial', 'Color', 'k');
% xlabel('PCC', 'FontSize', 8, 'FontName', 'Arial', 'Color', 'k');
% xlabel('Cuneus', 'FontSize', 8, 'FontName', 'Arial', 'Color', 'k');
% xlabel('MFG', 'FontSize', 8, 'FontName', 'Arial', 'Color', 'k');
% xlabel('IFG', 'FontSize', 8, 'FontName', 'Arial', 'Color', 'k');
% xlabel('Sensorimotor', 'FontSize', 8, 'FontName', 'Arial', 'Color', 'k');
% xlabel('MTL', 'FontSize', 8, 'FontName', 'Arial', 'Color', 'k');
% xlabel('aSTG', 'FontSize', 8, 'FontName', 'Arial', 'Color', 'k');
% xlabel('Temporal Pole', 'FontSize', 8, 'FontName', 'Arial', 'Color', 'k');
% xlabel('IPL', 'FontSize', 8, 'FontName', 'Arial', 'Color', 'k');

box off; 
% title('Propotion of selective contacts in ROIs', 'FontWeight','bold', 'FontSize',36);
% ylabel('Propotion of contacts (%)', 'FontSize',25, 'FontName', 'Arial',  'Color', 'k');
% xlabel('ROIs','FontSize',30);
% set(gca, 'FontSize', 25, 'FontName', 'Arial', 'XColor', 'k', 'YColor', 'k');
% exportgraphics(gcf, fullfile(save_fig_path,[save_fig_name,'.pdf']) ,'Resolution',600);