clear all
close all
save_fig_path = 'G:\Research\01 Speech_Comprehension\02 Figure_AI\Fig_sup_update_202604\ED10_part';
save_fig_name = 'human_mds_sem'; 
data_path = 'F:\code\Matlab work\code_for_SEEG_data\code_for_all_subjects\selective_contacts_step_rdm_not_control\all_sub_selective_contacts\MDS_RDM\sem_rdm_all_time\save\';

% 加载归一化因子
load('Y_normalized.mat')
if length(Y_normalized) ~= 26
    error('Y_normalized length must be 26, but got %d', length(Y_normalized));
end

% --- 设置目标时间窗 ---
target_times = [4, 8]; %4 6 8 10
num_time_points = length(target_times);
Y_storage = cell(num_time_points, 1); 

% --- 【关键调整 1：缩短间距】 ---
% 之前是 2.5，现在改为 1.6，让每张图靠得更近
time_spacing = 1.5;  
x_compression = 0.4; 

% =========================================================================
% 第一步：计算 MDS 并强制归一化
% =========================================================================
for t_idx = 1:num_time_points
    target_t = target_times(t_idx);
    file_name = sprintf('time%d_rdm.mat', target_t);
    subject_file = fullfile(data_path, file_name);
    
    if ~exist(subject_file, 'file')
        error('File %s not found!', subject_file);
    end
    load(subject_file); 
    
    % --- 数据处理 ---
    data = rdm_data_all;
    num_words = 52;
    mean_rdm = nanmean(cat(3, data{:,3}), 3);
    mean_rdm_all = mean_rdm;
    for i = 1:num_words
        for j = i+1:num_words
            mean_rdm_all(i, j) = mean_rdm_all(j, i);
        end
    end
    mean_rdm_all(1:num_words+1:end) = 0;
    
    similarityMatrix = mean_rdm;
    Y_normalized_52 = [Y_normalized; Y_normalized];
    [~, sortedIdx1] = sort(Y_normalized_52(1:26));
    [~, sortedIdx2] = sort(Y_normalized_52(27:52));
    newOrder = [sortedIdx1; sortedIdx2 + 26];
    
    reorderedRDM = NaN(52, 52);
    for i = 2:52
        for j = 1:i-1
            original_value = similarityMatrix(i, j);
            new_i = find(newOrder == i);
            new_j = find(newOrder == j);
            if new_i > new_j
                reorderedRDM(new_i, new_j) = original_value;
            else
                reorderedRDM(new_j, new_i) = original_value;
            end
        end
    end
    reorderedRDM_all = reorderedRDM;
    distances_for_mds = reorderedRDM_all;
    for i = 1:num_words
        for j = i+1:num_words
            if isnan(distances_for_mds(i, j))
                distances_for_mds(i, j) = distances_for_mds(j, i);
            elseif isnan(distances_for_mds(j, i))
                distances_for_mds(j, i) = distances_for_mds(i, j);
            end
        end
    end
    distances_for_mds(1:num_words+1:end) = 0;
    if any(isnan(distances_for_mds(:)))
         max_dist = max(distances_for_mds(~isnan(distances_for_mds)));
         distances_for_mds(isnan(distances_for_mds)) = max_dist;
    end
    
    try
        [Y_curr, ~] = mdscale(distances_for_mds, 2, 'Criterion', 'stress');
        
        % 强制尺寸统一 (Normalization)
        Y_curr = Y_curr - mean(Y_curr); 
        max_radius = max(sqrt(sum(Y_curr.^2, 2))); 
        Y_curr = Y_curr / max_radius; 
        
        Y_storage{t_idx} = Y_curr;
    catch ME
        error('MDS failed for time %d', target_t);
    end
end

% =========================================================================
% 第二步：链式对齐 (修改版：强制一致的垂直分布)
% =========================================================================
% 定义两类索引
idx_green = 1:26;
idx_yellow = 27:52;

for t = 1:num_time_points 
    
    % 1. 先做普通的 Procrustes 对齐 (T 对齐到 T-1)
    if t > 1
        % 使用 'reflection', true 允许镜像翻转，有助于找最佳匹配
        [d, Y_aligned] = procrustes(Y_storage{t-1}, Y_storage{t}, 'Scaling', false, 'Reflection', true);
        Y_storage{t} = Y_aligned;
    end
    
    % 2. 【核心修改】针对所有时间点，强制最大化垂直分离，且固定方向
    if ismember(target_times(t), [4, 6, 8, 9]) % 修正了原本错误的 || 写法
        Y_curr = Y_storage{t};
        
        % 计算两类质心
        centroid_green = mean(Y_curr(idx_green, :));
        centroid_yellow = mean(Y_curr(idx_yellow, :));
        
        % --- 【关键修改点】 ---
        % 我们定义向量为：绿色质心 - 黄色质心
        % 含义：这是一个从“黄”指向“绿”的箭头
        diff_vec = centroid_green - centroid_yellow; 
        
        % 计算该向量目前的角度
        current_angle = atan2(diff_vec(2), diff_vec(1));
        
        % 我们要让这个箭头指向正上方 (pi/2)
        % 结果：绿色(箭头尖)在上，黄色(箭头尾)在下
        target_angle = pi/2; 
        
        % 计算旋转角
        theta = target_angle - current_angle;
        
        % 构建旋转矩阵
        R = [cos(theta), -sin(theta); sin(theta), cos(theta)];
        
        % 应用旋转
        Y_rotated = Y_curr * R;
        
        % --- 【保险措施】 ---
        % 旋转后，理论上 Green Y > Yellow Y。
        % 但为了防止 Procrustes 在 X 轴方向产生镜像（左右颠倒），
        % 如果你希望保持时间连续性(流场线的顺滑)，
        % 可以在这里检查 X 轴的相关性。如果不需要极度严格的流场连贯，下面的代码已足够。
        
        % 更新存储
        Y_storage{t} = Y_rotated;
        
        fprintf('Time %d: 已强制旋转。绿色质心Y: %.2f, 黄色质心Y: %.2f (绿应大于黄)\n', ...
            target_times(t), mean(Y_rotated(idx_green,2)), mean(Y_rotated(idx_yellow,2)));
    end
end

% =========================================================================
% 第三步：绘制流图
% =========================================================================
gcf = figure(200); clf;
set(gcf, 'Position', [100, 100, 200, 350]); 
hold on;

% --- 样式 ---
% color_light_blue = [58/255, 191/255, 153/255];  %绿
color_light_blue = [0, 173, 181]/255;
color_dark_blue = [240/255, 167/255, 58/255];   %黄
normal_marker_size = 10; 
special_marker_size = 50;

specific_markers = {
    4,  's', 'light'; 
    30, 's', 'dark';  
    20, 'o', 'light'; 
    46, 'o', 'dark';  
    25, 'd', 'light'; 
    51, 'd', 'dark'; 
};

special_indices_orig = cell2mat(specific_markers(:, 1));
special_indices_new = arrayfun(@(x) find(newOrder == x), special_indices_orig);

% 预计算坐标
final_X = zeros(num_words, num_time_points);
final_Y = zeros(num_words, num_time_points);

for t = 1:num_time_points
    Y_curr = Y_storage{t};
    center_offset = (t-1) * time_spacing;

    final_X(:, t) = Y_curr(:, 1) * x_compression + center_offset;
    final_Y(:, t) = Y_curr(:, 2);

    % % --- 【关键调整 2：黑色实线椭圆】 ---
    % ellipse_w = 2.2 * x_compression; 
    % ellipse_h = 2.2;                 
    % rectangle('Position', [center_offset - ellipse_w/2, -ellipse_h/2, ellipse_w, ellipse_h], ...
    %           'Curvature', [1 1], ...
    %           'EdgeColor', 'k', ...   % 改为黑色
    %           'LineStyle', '-', ...   % 改为实线
    %           'LineWidth', 0.5);      % 线宽设为0.5，显得精致（可按需改为1）

    % 时间标签
    % text(center_offset, 1.3, sprintf('Time %d', target_times(t)), ...
    %      'HorizontalAlignment', 'center', 'FontSize', 8, 'FontWeight', 'bold');
end

% --- 绘制连接线 ---
for i = 1:num_words
    orig_idx = newOrder(i);
    is_light = ismember(orig_idx, 1:26);
    if is_light
        base_color = color_light_blue;
    else
        base_color = color_dark_blue;
    end
    plot(final_X(i, :), final_Y(i, :), '-', 'Color', [base_color, 0.4], 'LineWidth', 1);
end

% --- 绘制散点 ---
for t = 1:num_time_points
    for i = 1:num_words
        cx = final_X(i, t);
        cy = final_Y(i, t);
        
        orig_idx = newOrder(i);
        is_light = ismember(orig_idx, 1:26);
        if is_light
            base_color = color_light_blue;
        else
            base_color = color_dark_blue;
        end
        
        is_special = ismember(i, special_indices_new);
        
        if is_special
            spec_idx_in_list = find(special_indices_new == i);
            shape = specific_markers{spec_idx_in_list, 2};
            
            % --- 【关键调整 3：去掉特殊圆点的黑边框】 ---
            if strcmp(shape, 'o')
                % 之前是 'MarkerEdgeColor', 'k' -> 现在改为 'none'
                scatter(cx, cy, special_marker_size, base_color, 'filled', ...
                    'MarkerEdgeColor', 'none'); % 保持半透明度一致
            elseif strcmp(shape, 'x')
                scatter(cx, cy, special_marker_size, shape, 'MarkerEdgeColor', base_color, 'LineWidth', 2);
            else
                % 方块和菱形
                scatter(cx, cy, special_marker_size, shape, ...
                    'MarkerEdgeColor', base_color, ... % 边框同色，相当于无边框
                    'MarkerFaceColor', base_color);
            end
        else
            % 普通点，本来就是 none
            scatter(cx, cy, normal_marker_size, base_color, 'filled', 'MarkerEdgeColor', 'none');  %'MarkerFaceAlpha', 0.8
        end
    end
end

% =========================================================================
% 【修改位置】：在此处添加一个新循环，最后绘制黑色椭圆
% =========================================================================
for t = 1:num_time_points
    center_offset = (t-1) * time_spacing;
    
    ellipse_w = 2.35 * x_compression; 
    ellipse_h = 2.35;                 
    rectangle('Position', [center_offset - ellipse_w/2, -ellipse_h/2, ellipse_w, ellipse_h], ...
              'Curvature', [1 1], ...
              'EdgeColor', 'k', ...   % 黑色
              'LineStyle', '-', ...   % 实线
              'LineWidth', 0.5);      % 线宽
end

axis equal; 
axis off; 
set(gcf, 'Color', 'w');
exportgraphics(gcf, fullfile(save_fig_path,[save_fig_name, '.pdf']), 'Resolution', 1200);


%% 统计绘图：基于距离差异的聚类指数 (Clustering Index)
%{
% 目的：计算 (类间距离 - 类内距离)，值越高代表聚类越明显

figure('Color', 'w', 'Position', [100, 100, 900, 250]); 
tiledlayout(1, 4, 'TileSpacing', 'compact', 'Padding', 'compact');

% --- 1. 预先构建逻辑掩膜 (Masks) ---
% 这些掩膜用于从距离矩阵中提取我们需要的部分

% A. 语义掩膜 (Semantic Masks)
% 假设前26个是一类，后26个是一类
mask_sem_within = false(52);
mask_sem_within(1:26, 1:26) = true;
mask_sem_within(27:52, 27:52) = true;
mask_sem_within(logical(eye(52))) = false; % 去除对角线

mask_sem_between = ~mask_sem_within; % 取反即为类间
mask_sem_between(logical(eye(52))) = false;

% B. 语音掩膜 (Phonological Masks)
% 假设 original index i 和 i+26 是一对
orig_pairs = eye(52);
for k = 1:26
    orig_pairs(k, k+26) = 1;
    orig_pairs(k+26, k) = 1;
end
% 根据 MDS 的 newOrder 重排掩膜
reordered_pairs = orig_pairs(newOrder, newOrder);

mask_phon_within = (reordered_pairs == 1); % 只有互为双子星的位置是 true
mask_phon_between = ~mask_phon_within;
mask_phon_between(logical(eye(52))) = false;

% --- 2. 循环计算 ---
results_mean = zeros(length(target_times), 2); % 存储均值 [Phon, Sem]
results_sem  = zeros(length(target_times), 2); % 存储标准误 (用于误差棒)

for t_idx = 1:length(target_times)
    target_t = target_times(t_idx);
    
    % 获取坐标并计算欧氏距离矩阵
    coords = Y_storage{t_idx};
    dist_mat = squareform(pdist(coords)); % 52x52 距离矩阵
    
    % --- 计算语音指数 ---
    d_phon_within  = dist_mat(mask_phon_within);
    d_phon_between = dist_mat(mask_phon_between);
    % 指数 = 类间 - 类内 (距离越远越好 - 距离越近越好)
    % 这里我们为了统一度量，计算差值。
    % 也可以直接画两根柱子对比，但画差值更直观展示"强度"
    phon_index_val = mean(d_phon_between) - mean(d_phon_within);
    
    % --- 计算语义指数 ---
    d_sem_within  = dist_mat(mask_sem_within);
    d_sem_between = dist_mat(mask_sem_between);
    sem_index_val = mean(d_sem_between) - mean(d_sem_within);
    
    % --- 绘图 ---
    nexttile;
    hold on;
    
    % 准备数据
    y_data = [phon_index_val, sem_index_val];
    
    % 绘制柱状图
    b = bar(1:2, y_data, 0.6);
    b.FaceColor = 'flat';
    b.CData(2,:) = [50, 100, 200]/255; % 语义-蓝
    b.CData(1,:) = [200, 50, 50]/255;  % 语音-红
    b.EdgeColor = 'none';
    b.FaceAlpha = 0.8;
    
    % 装饰
    title(sprintf('Time %d', target_t), 'FontSize', 11);
    set(gca, 'XTick', 1:2, 'XTickLabel', {'Phon', 'Sem'});
    ylabel('\Delta Distance'); 
    
    % 统一Y轴范围 (重要！让不同时间点可比)
    % 你可能需要根据实际数据调整这个范围，例如 [-0.05, 0.2]
    ylim([-0.02, 0.6]); 
    yline(0, '-', 'Color', [0.5 0.5 0.5]); % 0基准线
    box off;
    
    % 显示数值
    text(1, y_data(1), sprintf('%.3f', y_data(1)), 'Vert', 'bottom', 'Horiz', 'center', 'FontSize',8);
    text(2, y_data(2), sprintf('%.3f', y_data(2)), 'Vert', 'bottom', 'Horiz', 'center', 'FontSize',8);
end

sgtitle('Clustering Strength: Between-Class minus Within-Class Distance');
%}