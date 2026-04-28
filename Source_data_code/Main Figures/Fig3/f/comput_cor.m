clear all
close all

load('model_matrix.mat')

%% --- Data Sorting: Order by model performance descending ---
% 1. Define original model names
labels_all = { ...
    'XLSR-53-ch', 'Whisper-large-v3', 'LLaSM', 'SALMONN', ...
    'Qwen-Audio', 'Qwen-Audio-Chat', 'Qwen2-Audio', 'Qwen2-Audio-Instruct', ...
    'GLM-4-Voice', 'Freeze-Omni', 'MiniCPM-o 2.6', 'Qwen2.5-Omni'};

% 2. Calculate the total performance score of the first two columns and get the descending sort index
total_score = sum(model_matrix(:, 1:2), 2);
[~, sort_idx] = sort(total_score, 'descend');

% 3. Rearrange matrix and labels based on the index
model_matrix = model_matrix(sort_idx, :);
labels_all = labels_all(sort_idx);

%% ---------------------------------------
num_rows = size(model_matrix, 2);  
num_pairs = nchoosek(num_rows, 2);  

% Initialize results
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

%% Extract plotting data
x = model_matrix(:,1);  % Performance column
y = model_matrix(:,7);  % Target alignment index column

valid_idx = ~isnan(x) & ~isnan(y);
x = x(valid_idx);
y = y(valid_idx);

%% Generate colors (Colors mapped to the sorted descending models)
custom_cmap = [68 1 84; 59 82 139; 33 145 140; 94 201 98; 253 231 37]/255;
n_models = size(model_matrix, 1);
t = linspace(0, 1, n_models).^0.7;   
colors_all = interp1(linspace(0, 1, size(custom_cmap,1)), ...
                     custom_cmap, t, 'pchip');  
colors = colors_all(valid_idx, :);
labels = labels_all(valid_idx);

%% Linear Fitting
p = polyfit(x, y, 1);
x_fit = linspace(min(x), max(x), 100)';
y_fit = polyval(p, x_fit);

% Calculate Confidence Intervals
X = [ones(length(x), 1), x];
b = X \ y;
y_hat = X * b;
residuals = y - y_hat;
df = length(x) - 2;
s_err = sqrt(sum(residuals.^2) / df);
CI = tinv(0.975, df) * s_err * sqrt(1/length(x) + (x_fit - mean(x)).^2 / sum((x - mean(x)).^2));

y_upper = y_fit + CI;
y_lower = y_fit - CI;

%% Plotting
figure;
set(gcf, 'Position', [100, 100, 150, 200]);

% Shaded area (Confidence Interval)
fill([x_fit; flipud(x_fit)], [y_upper; flipud(y_lower)], [0.8 0.8 0.8], ...
     'EdgeColor', 'none', 'FaceAlpha', 0.5); 
hold on;

% Fit line
plot(x_fit, y_fit, 'k-', 'LineWidth', 1);

% Scatter plot: Colors mapped by sorted model performance
scatter(x, y, 12, colors, 'filled');  

% Maintain legend object handles
hs = gobjects(numel(x),1);
for k = 1:numel(x)
    hs(k) = scatter(x(k), y(k), 28, colors(k,:), 'filled'); hold on
end

% Calculate correlation and add text annotation
[r, pval] = corr(x, y, 'Type', 'Pearson');

if pval < 0.001
    stars = '***';
elseif pval < 0.01
    stars = '**';
elseif pval < 0.05
    stars = '*';
else
    stars = ''; 
end

text(min(x) + 0.02, max(y) - 0.02, sprintf('\\it r = %.2f%s', r, stars), ...
    'FontSize', 6, 'FontAngle', 'italic');

% Aesthetics and Axis Limits
xlim([0, 100]); 
ylim([-0.2, 1]); 
set(gca, 'FontSize', 6, 'Box', 'off', 'FontName', 'Arial', 'TickDir', 'out', ...
    'LineWidth', 0.5, 'XColor', 'k', 'YColor', 'k');