clear
close all

save_fig_path = 'G:\Research\01 Speech_Comprehension\02 Figure_AI\Fig_sup_update_202602\Suo_related_fig4_part';
save_fig_name = 'salmonn_lesion';

name = "salmonn";
load(strcat(name, '_lesion_rank_results_pho_num.mat'));
% load(strcat(name, '_lesion_rank_results_pho_num_aishell.mat'));
pho_lesion = lesion_results;
load(strcat(name, '_lesion_rank_results_sem_num.mat'));
% load(strcat(name, '_lesion_rank_results_sem_num_aishell.mat'));
sem_lesion = lesion_results;
load(strcat(name, '_lesion_rank_results_both_num.mat'));
% load(strcat(name, '_lesion_rank_results_both_num_aishell.mat'));
both_lesion = lesion_results;


% 假设已经加载了以下变量:
% pho_lesion, sem_lesion, both_lesion, none_lesion

% 提取横坐标（第1列为 lesion neuron 数量）
pho_x = pho_lesion(:, 1);
sem_x = sem_lesion(:, 1);
both_x = both_lesion(:, 1);

% 提取 CER 值（第4列）
pho_cer = 1 - pho_lesion(:, 4);
sem_cer = 1 - sem_lesion(:, 4);
both_cer = 1 - both_lesion(:, 4);

% 绘图
gcf = figure;
set(gcf, 'Position', [100, 100, 260, 160]);  % 更合理比例
% 定义颜色
color_p = [180, 37, 35] / 255;      % pho (红)
color_s = [34, 91, 142] / 255;      % sem (蓝)
color_both = [103, 38, 141] / 255;   % both (紫)

% 绘制曲线
% 1. pho: 实心圆 ('o')
plot(pho_x, pho_cer, '-o', 'LineWidth', 1, 'Color', color_p, ...
    'MarkerFaceColor', color_p, 'MarkerEdgeColor', 'none','MarkerSize',4); 
hold on;

% 2. sem: 实心正方形 ('s')
plot(sem_x, sem_cer, '-s', 'LineWidth', 1, 'Color', color_s, ...
    'MarkerFaceColor', color_s, 'MarkerEdgeColor', 'none','MarkerSize',4);

% 3. both: 实心菱形 ('d')
plot(both_x, both_cer, '-d', 'LineWidth', 1, 'Color', color_both, ...
    'MarkerFaceColor', color_both, 'MarkerEdgeColor', 'none','MarkerSize',4);hold off;

% 图形美化
xlim([0 300]); yticks(0:100:300);
ylim([0.45 0.55]); yticks(0.45:0.05:0.55);
% ylim([0.5 1]); yticks(0.5:0.1:1);
xlabel('Number of lesioned model neurons','FontSize', 7, 'FontName', 'Arial', 'Color', 'k');
% ylabel('Model performance(Aishell-1)','FontSize', 8, 'FontName', 'Arial', 'Color', 'k');
ylabel('Model performance(Fleurs-zh)','FontSize', 7, 'FontName', 'Arial', 'Color', 'k');
% title('CER vs Lesioned Neuron Count');
% legend('Phonetic Lesion', 'Semantic Lesion', 'Shared Lesions', 'No Specific Lesion', 'Location', 'northwest');
grid on;
set(gca, 'FontSize', 7, 'Box', 'off', 'TickDir', 'out', 'FontName', 'Arial','XColor', 'k', 'YColor', 'k');

exportgraphics(gcf, fullfile(save_fig_path,[save_fig_name,'.pdf']) ,'Resolution',600);