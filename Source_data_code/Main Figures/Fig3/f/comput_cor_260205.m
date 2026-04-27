clear all
close all

save_fig_path = 'G:\Research\01 Speech_Comprehension\02 Figure_AI\Fig_sup_update_202601\Fig3_part';
save_fig_name = 'tem_both_align_1';
% save_fig_name = 'tem_both_align_2';

load('model_matrix.mat')

%% --- 修改部分：根据模型性能降序排列数据 ---
% 1. 定义原始模型名称
labels_all = { ...
    'XLSR-53-ch', 'Whisper-large-v3', 'LLaSM', 'SALMONN', ...
    'Qwen-Audio', 'Qwen-Audio-Chat', 'Qwen2-Audio', 'Qwen2-Audio-Instruct', ...
    'GLM-4-Voice', 'Freeze-Omni', 'MiniCPM-o 2.6', 'Qwen2.5-Omni'};

% 2. 计算前两列的总性能分并获取降序索引
total_score = sum(model_matrix(:, 1:2), 2);
[~, sort_idx] = sort(total_score, 'descend');

% 3. 根据索引重排矩阵和标签
model_matrix = model_matrix(sort_idx, :);
labels_all = labels_all(sort_idx);
%% ---------------------------------------

num_rows = size(model_matrix, 2);  
num_pairs = nchoosek(num_rows, 2);  

% 初始化结果
corr_values = zeros(num_pairs, 1);        
pair_indices = zeros(num_pairs, 2);       
k = 1;
for i = 1:num_rows-1
    for j = i+1:num_rows
        r = corrcoef(model_matrix(:,i), model_matrix(:,j));  
        corr_values(k) = r(1,2);         
        pair_indices(k, :) = [i, j];     
        k = k + 1;
    end
end

%% 提取绘图数据
x = model_matrix(:,1);  % 性能列
y = model_matrix(:,7);  % 目标对齐指标列
valid_idx = ~isnan(x) & ~isnan(y);
x = x(valid_idx);
y = y(valid_idx);

%% 生成颜色（此时 colors 的顺序已经对应了降序后的模型）
custom_cmap = [68 1 84; 59 82 139; 33 145 140; 94 201 98; 253 231 37]/255;
n_models = size(model_matrix, 1);
t = linspace(0,1,n_models).^0.7;   
colors_all = interp1(linspace(0,1,size(custom_cmap,1)), ...
                     custom_cmap, t, 'pchip');  
colors = colors_all(valid_idx, :);
labels = labels_all(valid_idx);

%% 线性拟合
p = polyfit(x, y, 1);
x_fit = linspace(min(x), max(x), 100)';
y_fit = polyval(p, x_fit);

% 计算置信区间
X = [ones(length(x), 1), x];
b = X \ y;
y_hat = X * b;
residuals = y - y_hat;
df = length(x) - 2;
s_err = sqrt(sum(residuals.^2) / df);
CI = tinv(0.975, df) * s_err * sqrt(1/length(x) + (x_fit - mean(x)).^2 / sum((x - mean(x)).^2));
y_upper = y_fit + CI;
y_lower = y_fit - CI;

%% 绘图
figure;
set(gcf, 'Position', [100, 100, 150, 200]);

% 阴影部分（置信区间）
fill([x_fit; flipud(x_fit)], [y_upper; flipud(y_lower)], [0.8 0.8 0.8], ...
     'EdgeColor', 'none', 'FaceAlpha', 0.5); 
hold on;

% 拟合线
plot(x_fit, y_fit, 'k-', 'LineWidth', 1);

% 散点：颜色按排序后的模型性能映射
scatter(x, y, 12, colors, 'filled');  

% 维持图例对象句柄
hs = gobjects(numel(x),1);
for k = 1:numel(x)
    hs(k) = scatter(x(k), y(k), 28, colors(k,:), 'filled'); hold on
end

% 计算相关性并添加标注
[r, pval] = corr(x, y, 'Type', 'Pearson');
if pval < 0.001, stars = '***';
elseif pval < 0.01, stars = '**';
elseif pval < 0.05, stars = '*';
else, stars = ''; end

text(min(x) + 0.02, max(y) - 0.02, sprintf('\\it r = %.2f%s', r, stars), ...
    'FontSize', 6, 'FontAngle', 'italic');

% 图形美化设置
xlim([0,100]); ylim([-0.2,1]); 
set(gca, 'FontSize', 6, 'Box', 'off', 'FontName', 'Arial', 'TickDir', 'out', ...
    'LineWidth', 0.5, 'XColor', 'k', 'YColor', 'k');

% --- 添加图例代码 ---
% 建议加在 set(gca, 'FontSize'...) 之后，exportgraphics 之前
% lgn = legend(hs, labels, 'Location', 'northeastoutside', 'Box', 'off', 'FontSize', 5);
% lgn.ItemTokenSize = [10, 10]; % 缩地图例图标尺寸以适应小图

% exportgraphics(gcf, fullfile(save_fig_path,[save_fig_name,'.pdf']) ,'Resolution',600);