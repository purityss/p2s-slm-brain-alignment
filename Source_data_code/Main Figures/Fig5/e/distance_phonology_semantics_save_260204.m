clear all
close all

%% 1. 基础路径与数据加载
save_fig_path = 'G:\Research\01 Speech_Comprehension\02 Figure_AI\Fig_sup_update_202601\Fig5_part';
save_fig_name_1 = 'qwen2_audio_mds_sample_1';
save_fig_name_2 = 'qwen2_audio_distance_both_1';
name = 'qwen2_audio';
load(strcat(name, '_both_avg_token_rdm.mat'));
token = 1;  % {1,2}
data = both_avg_token_rdm{token};

num_words = 52;
mean_rdm = data;

%% 2. 归一化处理 (基于 RDM 的最大最小值映射到 0-1)
rdm_min = min(mean_rdm(:));
rdm_max = max(mean_rdm(:));
rdm_norm = (mean_rdm - rdm_min) / (rdm_max - rdm_min);

%% 3. MDS 降维与绘图 (Figure 1)
mean_rdm_all = mean_rdm;
for i = 1:num_words
    for j = i+1:num_words
        mean_rdm_all(i, j) = mean_rdm_all(j, i);
    end
end
mean_rdm_all(1:num_words+1:end) = 0;
distances = mean_rdm_all; 
[Y, ~] = mdscale(distances, 2);

% 颜色设置
startColor = [180/255, 0, 0];    % 红
endColor = [252/255, 229/255, 228/255];      % 浅粉
numColors = 256;
customColormap = [linspace(startColor(1), endColor(1), numColors)', ...
                  linspace(startColor(2), endColor(2), numColors)', ...
                  linspace(startColor(3), endColor(3), numColors)'];

% 这里的 YY 计算保留你的特征提取逻辑，简略处理以保证代码流畅
% ... [此处省略你代码中复杂的音频特征计算部分，直接使用你已有的 word_colors 逻辑] ...

figure(1); clf;
set(gcf, 'Position', [500, 300, 115, 110]); 
hold on;
light_blue = [149/255, 180/255, 243/255];
dark_blue = [17/255, 67/255, 167/255];

for i = 1:26
    scatter(Y(i,1), Y(i,2), 26, 'MarkerEdgeColor', light_blue, 'LineWidth', 1.15);
end
for i = 27:52
    scatter(Y(i,1), Y(i,2), 26, 'MarkerEdgeColor', dark_blue, 'LineWidth', 1.15);
end
axis equal; axis off; set(gcf, 'Color', 'white');
% exportgraphics(gcf, fullfile(save_fig_path,[save_fig_name_1,'.pdf']) ,'Resolution',600);

%% 4. 提取归一化后的数据：Phonology
elements_tongyin = []; elements_yiyin = [];
for x = 27:52
    for y = 1:26
        if x == y + 26, elements_tongyin = [elements_tongyin, rdm_norm(x, y)]; end
    end
end
for x = 2:52
    for y = 1:x-1
        if x ~= y + 26, elements_yiyin = [elements_yiyin, rdm_norm(x, y)]; end
    end
end
mean_tongyin = mean(elements_tongyin); SE_tongyin = std(elements_tongyin)/sqrt(length(elements_tongyin));
mean_yiyin = mean(elements_yiyin); SE_yiyin = std(elements_yiyin)/sqrt(length(elements_yiyin));
[h_phon, p_phon] = ttest2(elements_tongyin, elements_yiyin);

%% 5. 提取归一化后的数据：Semantics
elements_tongyi = []; elements_yiyi = [];
for x = 2:26
    for y = 1:(x-1), elements_tongyi = [elements_tongyi, rdm_norm(x, y)]; end
end
for x = 28:52
    for y = 27:(x-1), elements_tongyi = [elements_tongyi, rdm_norm(x, y)]; end
end
for x = 27:52
    for y = 1:26, elements_yiyi = [elements_yiyi, rdm_norm(x, y)]; end
end           
mean_tongyi = mean(elements_tongyi); SE_tongyi = std(elements_tongyi)/sqrt(length(elements_tongyi));
mean_yiyi = mean(elements_yiyi); SE_yiyi = std(elements_yiyi)/sqrt(length(elements_yiyi));
[h_sem, p_sem] = ttest2(elements_tongyi, elements_yiyi);

%% 6. 绘制单 Y 轴柱状图 (Figure 2)
figure(2); clf;
set(gcf, 'Position', [500, 300, 100, 100]); 
hold on;

% 布局参数
bar_width = 0.5;
bar_spacing = 0.65;
height_line = 0.85; % 显著性横线高度

x1 = 1; x2 = x1 + bar_spacing;
x3 = x2 + bar_spacing + 0.13; 
x4 = x3 + bar_spacing;

% Phonology (红色系)
% bar(x1, mean_tongyin, bar_width, 'FaceColor', [147/255, 37/255, 29/255], 'EdgeColor', 'none');
bar(x1, mean_tongyin, bar_width, 'FaceColor', [203/255, 43/255, 35/255], 'EdgeColor', 'none');
errorbar(x1, mean_tongyin, SE_tongyin, 'k', 'LineWidth', 0.5, 'CapSize', 0);
% bar(x2, mean_yiyin, bar_width, 'FaceColor', [231/255, 126/255, 121/255], 'EdgeColor', 'none');
bar(x2, mean_yiyin, bar_width, 'FaceColor', [234/255, 139/255, 134/255], 'EdgeColor', 'none');
errorbar(x2, mean_yiyin, SE_yiyin, 'k', 'LineWidth', 0.5, 'CapSize', 0);

% Semantics (蓝色系)
% bar(x3, mean_tongyi, bar_width, 'FaceColor', [2/255, 72/255, 137/255], 'EdgeColor','none');
bar(x3, mean_tongyi, bar_width, 'FaceColor', [2/255, 88/255, 166/255], 'EdgeColor','none');
errorbar(x3, mean_tongyi, SE_tongyi, 'k', 'LineWidth', 0.5, 'CapSize', 0);
bar(x4, mean_yiyi, bar_width, 'FaceColor', [112/255, 166/255, 202/255], 'EdgeColor','none');
errorbar(x4, mean_yiyi, SE_yiyi, 'k', 'LineWidth', 0.5, 'CapSize', 0);

% 显著性标记 - Phonology
line([x1, x2], [height_line, height_line], 'Color', 'k', 'LineWidth', 0.5);
if h_phon == 1
    if p_phon < 0.001, txt = '***'; elseif p_phon < 0.01, txt = '**'; else, txt = '*'; end
    text((x1+x2)/2, height_line + 0.01, txt, 'FontSize', 10, 'HorizontalAlignment', 'center');
else
    text((x1+x2)/2, height_line + 0.06, 'n.s.', 'FontSize', 7, 'HorizontalAlignment', 'center');
end

% 显著性标记 - Semantics
line([x3, x4], [height_line, height_line], 'Color', 'k', 'LineWidth', 0.5);
if h_sem == 1
    if p_sem < 0.001, txt = '***'; elseif p_sem < 0.01, txt = '**'; else, txt = '*'; end
    text((x3+x4)/2, height_line + 0.01, txt, 'FontSize', 10, 'HorizontalAlignment', 'center');
else
    text((x3+x4)/2, height_line + 0.06, 'n.s.', 'FontSize', 7, 'HorizontalAlignment', 'center');
end

% 美化
ylabel('Normalized distance', 'FontSize', 7, 'FontName', 'Arial');
set(gca, 'YTick', 0:0.5:1, 'YLim', [0, 1]); % 留出顶部空间
set(gca, 'XTick', [], 'XTickLabel', [], 'Box', 'off', 'TickDir', 'out', 'LineWidth', 0.5);
set(gca, 'FontSize', 7, 'FontName', 'Arial', 'XColor', 'k', 'YColor', 'k');
xlim([0.45, 3.65]); % 缩减边缘留白

% exportgraphics(gcf, fullfile(save_fig_path,[save_fig_name_2,'.pdf']) ,'Resolution',600);