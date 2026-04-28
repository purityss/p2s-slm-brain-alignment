clear all
close all

% Set data paths to current directory
data_path = './';

% Load normalization factor
load('Y_normalized.mat')
if length(Y_normalized) ~= 26
    error('Y_normalized length must be 26, but got %d', length(Y_normalized));
end

% --- Set target time windows ---
target_times = [4, 8]; 
num_time_points = length(target_times);
Y_storage = cell(num_time_points, 1); 

% --- [Key Adjustment 1: Shorten spacing] ---
% Changed to 1.5 to make each plot closer
time_spacing = 1.5;  
x_compression = 0.4; 

% =========================================================================
% Step 1: Calculate MDS and force normalization
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
        
        % Force uniform size (Normalization)
        Y_curr = Y_curr - mean(Y_curr); 
        max_radius = max(sqrt(sum(Y_curr.^2, 2))); 
        Y_curr = Y_curr / max_radius; 
        
        Y_storage{t_idx} = Y_curr;
    catch ME
        error('MDS failed for time %d', target_t);
    end
end

% =========================================================================
% Step 2: Chain alignment (Disable scaling)
% =========================================================================
for t = 2:num_time_points
    [d, Y_aligned] = procrustes(Y_storage{t-1}, Y_storage{t}, 'Scaling', false);
    Y_storage{t} = Y_aligned; 
end

% =========================================================================
% Step 3: Draw flow chart
% =========================================================================
gcf = figure(200); clf;
set(gcf, 'Position', [100, 100, 200, 350]); 
hold on;

% --- Style ---
color_light_blue = [58/255, 191/255, 153/255];  % Green
color_dark_blue = [240/255, 167/255, 58/255];   % Yellow
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

% Pre-calculate coordinates
final_X = zeros(num_words, num_time_points);
final_Y = zeros(num_words, num_time_points);
for t = 1:num_time_points
    Y_curr = Y_storage{t};
    center_offset = (t-1) * time_spacing;
    final_X(:, t) = Y_curr(:, 1) * x_compression + center_offset;
    final_Y(:, t) = Y_curr(:, 2);
end

% --- Draw connection lines ---
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

% --- Draw scatter points ---
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
            
            % --- [Key Adjustment 3: Remove black border for special circular points] ---
            if strcmp(shape, 'o')
                scatter(cx, cy, special_marker_size, base_color, 'filled', ...
                    'MarkerEdgeColor', 'none'); % Maintain consistent translucency
            elseif strcmp(shape, 'x')
                scatter(cx, cy, special_marker_size, shape, 'MarkerEdgeColor', base_color, 'LineWidth', 2);
            else
                % Squares and diamonds
                scatter(cx, cy, special_marker_size, shape, ...
                    'MarkerEdgeColor', base_color, ... % Border same color, equivalent to no border
                    'MarkerFaceColor', base_color);
            end
        else
            % Normal points
            scatter(cx, cy, normal_marker_size, base_color, 'filled', 'MarkerEdgeColor', 'none');
        end
    end
end

% =========================================================================
% [Modification]: Add a new loop here to draw black ellipses last
% =========================================================================
for t = 1:num_time_points
    center_offset = (t-1) * time_spacing;
    
    ellipse_w = 2.35 * x_compression; 
    ellipse_h = 2.35;                 
    rectangle('Position', [center_offset - ellipse_w/2, -ellipse_h/2, ellipse_w, ellipse_h], ...
              'Curvature', [1 1], ...
              'EdgeColor', 'k', ...   % Black
              'LineStyle', '-', ...   % Solid line
              'LineWidth', 0.5);      % Line width
end

axis equal; 
axis off; 
set(gcf, 'Color', 'w');