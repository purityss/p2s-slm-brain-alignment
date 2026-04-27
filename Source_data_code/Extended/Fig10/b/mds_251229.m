clear all
close all

% --- 路径与文件设置 ---
save_fig_path = 'G:\Research\01 Speech_Comprehension\02 Figure_AI\Fig_sup_update_202604\ED10_part\qwen2_audio';
save_fig_name = 'qwen2_audio_mds_flow_pho';
name = 'qwen2_audio';

% --- 加载数据 ---
% 加载包含两个 token RDM 的数据文件
load(strcat(name, '_pho_avg_token_rdm.mat')); 
% 变量名应该是 pho_avg_token_rdm，是一个 1x2 的 cell

% 加载排序归一化因子
load('Y_normalized.mat')
if length(Y_normalized) ~= 26
    error('Y_normalized length must be 26, but got %d', length(Y_normalized));
end

% --- 设置参数 ---
target_tokens = [1, 2]; % 对应数据中的 Token 1 和 Token 2
num_time_points = length(target_tokens);
Y_storage = cell(num_time_points, 1); 

% --- 视觉参数 (针对 2 个点进行微调) ---
time_spacing = 1.5;  
x_compression = 0.4; 

% --- 预计算重排顺序 (基于 Y_normalized) ---
Y_normalized_52 = [Y_normalized; Y_normalized]; 
[~, sortedIdx1] = sort(Y_normalized_52(1:26));
[~, sortedIdx2] = sort(Y_normalized_52(27:52));
newOrder = [sortedIdx1; sortedIdx2 + 26];

% =========================================================================
% 第一步：循环计算 MDS 并强制归一化
% =========================================================================
for t_idx = 1:num_time_points
    token_idx = target_tokens(t_idx);
    
    % 获取对应 Token 的数据 (52x52 矩阵)
    % 根据你的第一段代码逻辑：data = pho_avg_token_rdm{token};
    mean_rdm = pho_avg_token_rdm{token_idx};
    
    % --- 数据对称化处理 ---
    mean_rdm_all = mean_rdm;
    num_words = 52;
    for i = 1:num_words
        for j = i+1:num_words
            mean_rdm_all(i, j) = mean_rdm_all(j, i); % 上三角 = 下三角
        end
    end
    mean_rdm_all(1:num_words+1:end) = 0; % 对角线置零
    
    % --- RDM 重排 (Reordering) ---
    similarityMatrix = mean_rdm_all;
    reorderedRDM = NaN(52, 52);
    for i = 2:52
        for j = 1:i-1
            original_value = similarityMatrix(i, j);
            new_i = find(newOrder == i);
            new_j = find(newOrder == j);
            
            % 填充下三角
            if new_i > new_j
                reorderedRDM(new_i, new_j) = original_value;
            else
                reorderedRDM(new_j, new_i) = original_value;
            end
        end
    end
    
    % 准备 MDS 输入矩阵 (对称化重排后的矩阵)
    distances_for_mds = reorderedRDM;
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
    
    % 处理残留 NaN (如果有)
    if any(isnan(distances_for_mds(:)))
         max_dist = max(distances_for_mds(~isnan(distances_for_mds)));
         distances_for_mds(isnan(distances_for_mds)) = max_dist;
    end
    
    % --- MDS 计算 ---
    try
        [Y_curr, ~] = mdscale(distances_for_mds, 2, 'Criterion', 'stress');
        
        % --- 强制尺寸统一 (Normalization) ---
        Y_curr = Y_curr - mean(Y_curr); % 去中心化
        max_radius = max(sqrt(sum(Y_curr.^2, 2))); % 计算最大半径
        Y_curr = Y_curr / max_radius; % 缩放至半径为 1
        
        Y_storage{t_idx} = Y_curr;
    catch ME
        error('MDS failed for token %d: %s', token_idx, ME.message);
    end
end

% =========================================================================
% 第二步：链式对齐 (Procrustes Analysis, 禁止缩放)
% =========================================================================
for t = 2:num_time_points
    % 将 Token 2 对齐到 Token 1
    [d, Y_aligned] = procrustes(Y_storage{t-1}, Y_storage{t}, 'Scaling', false);
    Y_storage{t} = Y_aligned; 
    fprintf('Token %d aligned to Token %d (Error: %.4f)\n', target_tokens(t), target_tokens(t-1), d);
end

% =========================================================================
% 第三步：绘制流图
% =========================================================================
gcf = figure(200); clf;
set(gcf, 'Position', [100, 100, 200, 350]); % 调整画布大小适应 2 个点
hold on;

% --- 样式定义 ---
% color_light_blue = [58/255, 191/255, 153/255]; 
color_light_blue = [0, 173, 181]/255;
color_dark_blue = [240/255, 167/255, 58/255]; 
normal_marker_size = 10; 
special_marker_size = 50;

specific_markers = {
    4,  's', 'light'; 
    30, 's', 'dark';  
    20, 'o', 'light'; 
    46, 'o', 'dark';  
    25, 'd', 'light'; 
    51, 'd', 'dark'
};
special_indices_orig = cell2mat(specific_markers(:, 1));
special_indices_new = arrayfun(@(x) find(newOrder == x), special_indices_orig);

% 预计算绘图坐标
final_X = zeros(num_words, num_time_points);
final_Y = zeros(num_words, num_time_points);

for t = 1:num_time_points
    Y_curr = Y_storage{t};
    center_offset = (t-1) * time_spacing;
    
    final_X(:, t) = Y_curr(:, 1) * x_compression + center_offset;
    final_Y(:, t) = Y_curr(:, 2);
    
    % % --- 绘制背景实线椭圆 ---
    % ellipse_w = 2.2 * x_compression; 
    % ellipse_h = 2.2;                 
    % rectangle('Position', [center_offset - ellipse_w/2, -ellipse_h/2, ellipse_w, ellipse_h], ...
    %           'Curvature', [1 1], ...
    %           'EdgeColor', 'k', ...   
    %           'LineStyle', '-', ...   
    %           'LineWidth', 0.5);      
    % 
    % 标签
    % text(center_offset, 1.3, sprintf('Token %d', target_tokens(t)), ...
         % 'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold');
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
            
            % 特殊点绘制
            if strcmp(shape, 'o')
                scatter(cx, cy, special_marker_size, base_color, 'filled', ...
                    'MarkerEdgeColor', 'none'); 
            elseif strcmp(shape, 'x')
                scatter(cx, cy, special_marker_size, shape, 'MarkerEdgeColor', base_color, 'LineWidth', 2);
            else
                scatter(cx, cy, special_marker_size, shape, ...
                    'MarkerEdgeColor', base_color, ... 
                    'MarkerFaceColor', base_color);
            end
        else
            % 普通点
            scatter(cx, cy, normal_marker_size, base_color, 'filled', 'MarkerEdgeColor', 'none'); %, 'MarkerFaceAlpha', 0.8
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
exportgraphics(gcf, fullfile(save_fig_path,[save_fig_name, '.pdf']), 'Resolution', 600);