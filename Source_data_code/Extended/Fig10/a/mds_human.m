clear all
close all

% --- Setup Paths and Load Data ---
data_path = './';
% Load normalization factors
load('Y_normalized.mat')
if length(Y_normalized) ~= 26
    error('Y_normalized length must be 26, but got %d', length(Y_normalized));
end

% --- Target Time Windows ---
target_times = [4, 8]; % Time points for MDS snapshots
num_time_points = length(target_times);
Y_storage = cell(num_time_points, 1); 

% --- Layout Settings ---
time_spacing = 1.5;  % Spacing between time snapshots
x_compression = 0.4; % Horizontal compression factor for MDS space

% =========================================================================
% Step 1: Compute MDS and Force Normalization
% =========================================================================
for t_idx = 1:num_time_points
    target_t = target_times(t_idx);
    file_name = sprintf('time%d_rdm.mat', target_t);
    subject_file = fullfile(data_path, file_name);
    
    if ~exist(subject_file, 'file')
        error('File %s not found!', subject_file);
    end
    load(subject_file); 
    
    % --- Data Processing ---
    data = rdm_data_all;
    num_words = 52;
    mean_rdm = nanmean(cat(3, data{:,3}), 3);
    
    % Symmetrize RDM
    mean_rdm_all = mean_rdm;
    for i = 1:num_words
        for j = i+1:num_words
            mean_rdm_all(i, j) = mean_rdm_all(j, i);
        end
    end
    mean_rdm_all(1:num_words+1:end) = 0;
    
    similarityMatrix = mean_rdm;
    
    % Reorder based on Y_normalized (Twin word pairs)
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
    
    % Handle missing values
    if any(isnan(distances_for_mds(:)))
         max_dist = max(distances_for_mds(~isnan(distances_for_mds)));
         distances_for_mds(isnan(distances_for_mds)) = max_dist;
    end
    
    try
        % Run Multi-dimensional Scaling
        [Y_curr, ~] = mdscale(distances_for_mds, 2, 'Criterion', 'stress');
        
        % Force standard size/center for comparison
        Y_curr = Y_curr - mean(Y_curr); 
        max_radius = max(sqrt(sum(Y_curr.^2, 2))); 
        Y_curr = Y_curr / max_radius; 
        
        Y_storage{t_idx} = Y_curr;
    catch ME
        error('MDS failed for time %d', target_t);
    end
end

% =========================================================================
% Step 2: Chain Alignment and Forced Orientation
% =========================================================================
idx_green = 1:26;
idx_yellow = 27:52;

for t = 1:num_time_points 
    % 1. Procrustes alignment to maintain temporal continuity
    if t > 1
        [~, Y_aligned] = procrustes(Y_storage{t-1}, Y_storage{t}, 'Scaling', false, 'Reflection', true);
        Y_storage{t} = Y_aligned;
    end
    
    % 2. Force Vertical Separation (Orientation Anchor)
    Y_curr = Y_storage{t};
    centroid_green = mean(Y_curr(idx_green, :));
    centroid_yellow = mean(Y_curr(idx_yellow, :));
    
    % Vector from Yellow to Green category
    diff_vec = centroid_green - centroid_yellow; 
    current_angle = atan2(diff_vec(2), diff_vec(1));
    
    % Rotate to make Green category appear vertically above Yellow category
    target_angle = pi/2; 
    theta = target_angle - current_angle;
    R = [cos(theta), -sin(theta); sin(theta), cos(theta)];
    Y_storage{t} = Y_curr * R;
end

% =========================================================================
% Step 3: Visualization (Flow Diagram)
% =========================================================================
fig = figure(200); clf;
set(fig, 'Position', [100, 100, 200, 350], 'Color', 'w');
hold on;

% Aesthetic parameters
color_light_blue = [0, 173, 181]/255; % Category A
color_dark_blue = [240/255, 167/255, 58/255]; % Category B
normal_marker_size = 10; 
special_marker_size = 50;

% Highlight specific words
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

% Pre-calculate plotting coordinates
final_X = zeros(num_words, num_time_points);
final_Y = zeros(num_words, num_time_points);
for t = 1:num_time_points
    Y_curr = Y_storage{t};
    center_offset = (t-1) * time_spacing;
    final_X(:, t) = Y_curr(:, 1) * x_compression + center_offset;
    final_Y(:, t) = Y_curr(:, 2);
end

% --- Draw connecting lines (Flow path) ---
for i = 1:num_words
    orig_idx = newOrder(i);
    base_color = color_light_blue;
    if ~ismember(orig_idx, 1:26), base_color = color_dark_blue; end
    plot(final_X(i, :), final_Y(i, :), '-', 'Color', [base_color, 0.4], 'LineWidth', 1);
end

% --- Draw data points ---
for t = 1:num_time_points
    for i = 1:num_words
        cx = final_X(i, t);
        cy = final_Y(i, t);
        
        orig_idx = newOrder(i);
        base_color = color_light_blue;
        if ~ismember(orig_idx, 1:26), base_color = color_dark_blue; end
        
        is_special = ismember(i, special_indices_new);
        
        if is_special
            spec_idx_in_list = find(special_indices_new == i);
            shape = specific_markers{spec_idx_in_list, 2};
            
            if strcmp(shape, 'o')
                scatter(cx, cy, special_marker_size, base_color, 'filled', 'MarkerEdgeColor', 'none'); 
            else
                scatter(cx, cy, special_marker_size, shape, 'MarkerEdgeColor', base_color, 'MarkerFaceColor', base_color);
            end
        else
            scatter(cx, cy, normal_marker_size, base_color, 'filled', 'MarkerEdgeColor', 'none');
        end
    end
end

% --- Draw enclosing boundary ellipses ---
for t = 1:num_time_points
    center_offset = (t-1) * time_spacing;
    ellipse_w = 2.35 * x_compression; 
    ellipse_h = 2.35;                 
    rectangle('Position', [center_offset - ellipse_w/2, -ellipse_h/2, ellipse_w, ellipse_h], ...
              'Curvature', [1 1], 'EdgeColor', 'k', 'LineWidth', 0.5);
end

axis equal; 
axis off;