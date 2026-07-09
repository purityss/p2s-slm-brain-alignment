clear all
close all

name = 'qwen2_audio';

% --- Load Data ---
% Load data file containing two token RDMs (a 1x2 cell array)
load(strcat(name, '_pho_avg_token_rdm.mat')); 

% Load sorted normalization factor
load('Y_normalized.mat')
if length(Y_normalized) ~= 26
    error('Y_normalized length must be 26, but got %d', length(Y_normalized));
end

% --- Set Parameters ---
target_tokens = [1, 2]; % Corresponds to Token 1 and Token 2 in the data
num_time_points = length(target_tokens);
Y_storage = cell(num_time_points, 1); 

% --- Visual Parameters (fine-tuned for 2 points) ---
time_spacing = 1.5;  
x_compression = 0.4; 

% --- Pre-calculate reorder sequence (based on Y_normalized) ---
Y_normalized_52 = [Y_normalized; Y_normalized]; 
[~, sortedIdx1] = sort(Y_normalized_52(1:26));
[~, sortedIdx2] = sort(Y_normalized_52(27:52));
newOrder = [sortedIdx1; sortedIdx2 + 26];

% =========================================================================
% Step 1: Calculate MDS and force normalization in a loop
% =========================================================================
for t_idx = 1:num_time_points
    token_idx = target_tokens(t_idx);
    
    % Get data for the corresponding Token (52x52 matrix)
    mean_rdm = pho_avg_token_rdm{token_idx};
    
    % --- Data Symmetrization ---
    mean_rdm_all = mean_rdm;
    num_words = 52;
    for i = 1:num_words
        for j = i+1:num_words
            mean_rdm_all(i, j) = mean_rdm_all(j, i); % Upper triangle = lower triangle
        end
    end
    mean_rdm_all(1:num_words+1:end) = 0; % Zero the diagonal
    
    % --- RDM Reordering ---
    similarityMatrix = mean_rdm_all;
    reorderedRDM = NaN(52, 52);
    for i = 2:52
        for j = 1:i-1
            original_value = similarityMatrix(i, j);
            new_i = find(newOrder == i);
            new_j = find(newOrder == j);
            
            % Fill lower triangle
            if new_i > new_j
                reorderedRDM(new_i, new_j) = original_value;
            else
                reorderedRDM(new_j, new_i) = original_value;
            end
        end
    end
    
    % Prepare MDS input matrix (symmetrized and reordered)
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
    
    % Handle residual NaNs (if any)
    if any(isnan(distances_for_mds(:)))
         max_dist = max(distances_for_mds(~isnan(distances_for_mds)));
         distances_for_mds(isnan(distances_for_mds)) = max_dist;
    end
    
    % --- MDS Calculation ---
    try
        [Y_curr, ~] = mdscale(distances_for_mds, 2, 'Criterion', 'stress');
        
        % --- Force uniform size (Normalization) ---
        Y_curr = Y_curr - mean(Y_curr); % Decentralize
        max_radius = max(sqrt(sum(Y_curr.^2, 2))); % Calculate max radius
        Y_curr = Y_curr / max_radius; % Scale to radius 1
        
        Y_storage{t_idx} = Y_curr;
    catch ME
        error('MDS failed for token %d: %s', token_idx, ME.message);
    end
end

% =========================================================================
% Step 2: Chain alignment (Procrustes Analysis, disable scaling)
% =========================================================================
for t = 2:num_time_points
    % Align Token 2 to Token 1
    [d, Y_aligned] = procrustes(Y_storage{t-1}, Y_storage{t}, 'Scaling', false);
    Y_storage{t} = Y_aligned; 
    fprintf('Token %d aligned to Token %d (Error: %.4f)\n', target_tokens(t), target_tokens(t-1), d);
end

% =========================================================================
% Step 3: Draw flow chart
% =========================================================================
gcf = figure(200); clf;
set(gcf, 'Position', [100, 100, 200, 350]); % Adjust canvas size to fit 2 points
hold on;

% --- Style Definitions ---
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

% Pre-calculate drawing coordinates
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
            
            % Draw special points
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
            % Normal points
            scatter(cx, cy, normal_marker_size, base_color, 'filled', 'MarkerEdgeColor', 'none'); 
        end
    end
end

% =========================================================================
% Add a new loop here to draw black ellipses last
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