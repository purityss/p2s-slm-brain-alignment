clear all
close all
clc

%% 1. Data Loading and Pre-processing
% Find all matching files in the current directory
load('Y_normalized.mat')
subject_files_pattern = 'time*_rdm.mat'; 
subject_files = dir(subject_files_pattern);

% Iterate through subject files
for step = 1:length(subject_files)
    % Load the file directly from the current folder
    subject_file = subject_files(step).name;
    load(subject_file); % Load 'rdm_data_all'
    
    data = rdm_data_all; 
    num_words = 52; 
    
    %% 2. Calculate Mean RDM
    % Assuming 'data' is a cell array where the 3rd column contains 52x52 RDM matrices
    % 'cat(3, data{:,3})' stacks all matrices into a 3D array
    % 'nanmean(..., 3)' calculates the mean across the 3rd dimension (electrodes)
    mean_rdm = nanmean(cat(3, data{:,3}), 3);
    
    % Symmetrize the matrix: copy the lower triangle to the upper triangle
    for i = 1:num_words
        for j = i+1:num_words
            mean_rdm(i, j) = mean_rdm(j, i);
        end
    end
    
    % Ensure the diagonal is zero (Self-similarity should be 0 in distance metrics)
    mean_rdm(1:num_words+1:end) = 0;
    
    %% 3. Reorder RDM based on MDS Results
    % Note: 'Y_normalized' should be a 26x1 vector representing the MDS 1D sorting
    % Ensure it is already loaded in your workspace before running this script
    
    % Duplicate the 1D sorting result to cover 52 items (26 words x 2 categories)
    Y_normalized_52 = [Y_normalized; Y_normalized]; 
    
    % Generate the new sorting order
    [~, sortedIdx1] = sort(Y_normalized_52(1:26));  % Ascending
    [~, sortedIdx2] = sort(Y_normalized_52(27:52)); 
    newOrder = [sortedIdx1; sortedIdx2 + 26];
    
    % Create a reordered RDM filled with NaNs
    reorderedRDM = NaN(52, 52); 
    
    % Map original values to the reordered lower triangle
    for i = 2:52
        for j = 1:i-1 
            original_value = mean_rdm(i, j);
            
            new_i = find(newOrder == i);
            new_j = find(newOrder == j);
            
            if new_i > new_j
                reorderedRDM(new_i, new_j) = original_value;
            else
                reorderedRDM(new_j, new_i) = original_value;
            end
        end
    end
    
    %% 4. Plotting the RDM
    figure_handle = figure(step); clf;
    set(gcf, 'Position', [300, 300, 125, 120], 'Color', 'w'); 
    
    h = imagesc(reorderedRDM); 
    
    % Define custom color gradient nodes
    color1 = [50, 28, 90] / 255;    % Dark Blue
    color2 = [40, 100, 120] / 255;  % Teal
    color3 = [45, 175, 120] / 255;  % Green
    color4 = [170, 215, 60] / 255;  % Lime
    color5 = [252, 245, 65] / 255;  % Yellow
    
    control_colors = [color1; color2; color3; color4; color5];
    custom_map = interp1(linspace(1, 5, 5), control_colors, linspace(1, 5, 256));
    colormap(custom_map);
    
    % Transparency: Only show the lower triangle (NaN values are transparent)
    set(h, 'AlphaData', ~isnan(reorderedRDM)); 
    
    % Aesthetics settings
    set(gca, 'FontSize', 10, 'TickDir', 'out', 'Box', 'off');
    set(gca, 'XColor', 'none', 'YColor', 'none', 'XTick', [], 'YTick', []); 
    axis off;
end