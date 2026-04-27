clear all
close all
clf

name = 'xlsr';
load(strcat(name, '_layer_neurons_counts.mat'));
save_fig_path = 'G:\Research\01 Speech_Comprehension\02 Figure_AI\Fig_sup_update_202603\Fig2_related_sup_part';
save_fig_name = 'xlsr_prop_3unit';

% load('num_all_p_s.mat')

num = num_all_p_s(:,2);
num_p = num_all_p_s(:,3);
num_s = num_all_p_s(:,4);
num_both = num_all_p_s(:,5);

prop_all = num ./ num * 100;
prop_p = num_p ./ num * 100;
prop_s = num_s ./ num * 100;
prop_both = num_both ./ num * 100;

prop(:,1) = prop_p;
prop(:,2) = prop_s;
prop(:,3) = prop_both;

% figure(1)
% set(gcf, 'Position', [50, 50, 1500, 900]); 
% b = bar(prop, 'grouped');
% 
% % 设置每个柱子的颜色
% colors = [249/256, 196/256, 194/256;   % 第一组柱子的颜色（RGB）pho
%           156/256, 196/256, 226/256    % 第三组柱子的颜色（RGB）sem
%           0.751, 0.691, 0.857 ]; % 第二 组柱子的颜色（RGB）both
% 
% for k = 1:length(b)
%     b(k).FaceColor = 'flat'; % 允许每个柱子有不同的颜色
%     b(k).CData = repmat(colors(k, :), size(prop, 1), 1); % 设置颜色
%     b(k).EdgeColor = 'none'; % 设置轮廓颜色为黑色
% end
% 
% ylim([0 100]);
% yticks(0:20:100);
% set(gca, 'TickDir', 'out');
% set(gca,'FontSize',16);
% title('Propotion of selective neurons in layers', 'FontWeight','bold', 'FontSize',36);
% ylabel('Propotion of neurons（%）', 'FontSize',24);
% xlabel('Layer', 'FontSize',24);
% % xticks([1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19]);
% box off; 

%%
% 层数索引
layers = 1:length(prop_p);

% 设置颜色
color_p = [180, 37, 35] / 255;   % pho
color_s = [34, 91, 142] / 255;   % sem
color_both = [103, 38, 141] / 255;      % both
% color_p = [231/256, 126/256, 121/256];   % pho
% color_s = [112/256, 166/256, 202/256];   % sem
% color_both = [158/256, 137/256, 193/256];      % both


%% Figure 2: 定制化坐标轴 (X轴前两层占1/5长度)
% ==========================================================
% 1. Y 轴映射规则 (保持之前设定: 0-1 占前 25%)
y_breaks_orig = [0,  3,  20, 50, 100]; 
y_breaks_vis  = [0, 25,  50, 75, 100]; 
trans_y = @(y) interp1(y_breaks_orig, y_breaks_vis, y, 'linear');

% 2. X 轴映射规则 (修改此处)
% ==========================================================
x_max = length(layers); % 总层数 (65)
% 定义锚点: 
% 原始层数 1 -> 视觉位置 0%
% 原始层数 2 -> 视觉位置 20% (即总长度的 1/5)
% 原始层数 End -> 视觉位置 100%
x_breaks_orig = [1,  2,  x_max]; 
x_breaks_vis  = [0, 20,  100];   

% X轴转换函数
trans_x = @(x) interp1(x_breaks_orig, x_breaks_vis, x, 'linear');
% ==========================================================

gcf = figure(1);
set(gcf, 'Position', [100, 100, 195, 126]); 
set(gcf, 'Color', 'w');
hold on;

% % --- 绘图 (同时应用 X 和 Y 的转换) ---
% plot(trans_x(layers), trans_y(prop_p),    '-', 'LineWidth', 1.5, 'Color', color_p);
% plot(trans_x(layers), trans_y(prop_s),    '-', 'LineWidth', 1.5, 'Color', color_s);
% plot(trans_x(layers), trans_y(prop_both), '-', 'LineWidth', 1.5, 'Color', color_both);

% --- 绘图 (同时应用 X 和 Y 的转换) ---
% ① 先平滑（窗口大小可调，比如 3/5/7）
w = 5;
prop_p_sm    = smoothdata(prop_p,    'movmean', w);
prop_s_sm    = smoothdata(prop_s,    'movmean', w);
prop_both_sm = smoothdata(prop_both, 'movmean', w);

% ② 再画（注意：对平滑后的数据做 trans_y）
plot(trans_x(layers), trans_y(prop_p_sm),    '-', 'LineWidth', 1.5, 'Color', color_p);
plot(trans_x(layers), trans_y(prop_s_sm),    '-', 'LineWidth', 1.5, 'Color', color_s);
plot(trans_x(layers), trans_y(prop_both_sm), '-', 'LineWidth', 1.5, 'Color', color_both);

% --- 坐标轴伪装 ---

% Y 轴刻度设置
y_ticks_vals = [3, 20, 50, 100]; 
ylim([0 100]); 
set(gca, 'YTick', trans_y(y_ticks_vals));       
set(gca, 'YTickLabel', string(y_ticks_vals));   

% X 轴刻度设置
x_ticks_vals = [7, 31];      
% 设置视觉范围为 0 到 100 (对应 x_breaks_vis 的范围)
xlim([0 100]); 
% 刻度位置需转换
set(gca, 'XTick', trans_x(x_ticks_vals));       
% 标签显示原始值
set(gca, 'XTickLabel', string(x_ticks_vals));   

% --- 美化 ---
% legend({'phonological', 'semantic', 'shared'}, 'FontSize', 8, 'Location', 'NorthWest', 'Box', 'off');
set(gca, 'FontSize', 7, 'Box', 'off', 'FontName', 'Arial', ...
    'TickDir', 'out', 'LineWidth', 0.5, 'XColor', 'k', 'YColor', 'k');

ylabel('Proportion of model neurons (%)', 'FontSize', 7, 'FontName', 'Arial');
xlabel('Layer', 'FontSize', 7, 'FontName', 'Arial');

% grid on;
% set(gca, 'XGrid', 'on', 'YGrid', 'on', 'GridAlpha', 0.15);

% 固定绘图区域位置
set(gca, 'Units', 'normalized', 'Position', [0.13 0.15 0.775 0.8]);

exportgraphics(gcf, fullfile(save_fig_path,[save_fig_name,'.pdf']) ,'Resolution',600);