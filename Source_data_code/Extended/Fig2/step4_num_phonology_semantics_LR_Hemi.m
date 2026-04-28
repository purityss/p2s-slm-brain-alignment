clear
close all

load('brain_hemi_counts_2.mat')

data_numeric = cell2mat(brain_hemisphere_counts(:, 2:5));

% Assign values to variables
num      = data_numeric(:, 1);
num_p    = data_numeric(:, 2);
num_s    = data_numeric(:, 3);
num_both = data_numeric(:, 4);

% Build a 2x3 contingency table (Rows: Left/Right, Columns: Phonology/Semantics/Both)
tbl = [num_p(1), num_s(1), num_both(1); 
       num_p(2), num_s(2), num_both(2)];

% Perform Chi-square test of independence
[chi2, p, df] = chi2test_independence(tbl);

% Display results
fprintf('Chi-square test results (Distribution differences of the 3 types of contacts across hemispheres):\n');
fprintf('χ²(%.f) = %.3f, p = %.4f\n', df, chi2, p);

if p < 0.05
    fprintf('** Significant difference in the proportional distribution across hemispheres (p < 0.05) **\n');
else
    fprintf('No significant difference in the proportional distribution across hemispheres (p > 0.05)\n');
end

% Calculate proportions
prop_p = num_p ./ num * 100;
prop_s = num_s ./ num * 100;
prop_both = num_both ./ num * 100;

prop(:,1) = prop_p;
prop(:,2) = prop_s;
prop(:,3) = prop_both;

gcf = figure(1);
set(gcf, 'Position', [100, 100, 180, 213]);  % Set reasonable figure proportions
set(gcf, 'Color', 'w');  % Set white background

% Set colors for each group of bars (RGB)
colors = [231/256, 126/256, 121/256;   % Color for group 1 (Phonology)
          112/256, 166/256, 202/256;   % Color for group 2 (Semantics)
          158/256, 137/256, 193/256];  % Color for group 3 (Both)
          
% Position parameters setup
group_centers = [1, 2];      % Centers for the two groups (Left, Right)
bar_width = 0.2;             % Narrower bar width
offsets = [-0.24, 0, 0.24];  % Increased spacing between bars within a group

hold on

% Draw bars
for i = 1:3  % Three types: phonology, semantics, both
    x = group_centers + offsets(i);
    y = prop(:, i);
    bar(x, y, bar_width, ...
        'FaceColor', colors(i,:), ...
        'EdgeColor', 'none');
end

xlim([0.35, 2.65]);
xticks(group_centers);
xticklabels({'Left', 'Right'});

ylim([0 50]);
yticks(0:10:50);

% Format axes
set(gca, ...
    'FontSize', 8, ...
    'FontName', 'Arial', ...
    'TickDir', 'out', ...
    'LineWidth', 0.5, ...
    'XColor', 'k', ...
    'YColor', 'k');

ylabel('Proportion of contacts (%)', ...
    'FontSize', 8, ...
    'FontName', 'Arial', ...
    'Color', 'k');

xlabel('Hemisphere', ...
    'FontSize', 8, ...
    'FontName', 'Arial', ...
    'Color', 'k');

box off; 

%% Chi-square test of independence function (applicable to any R x C table)
function [chi2, p, df] = chi2test_independence(tbl)
    % Calculate expected frequencies
    row_totals = sum(tbl, 2);
    col_totals = sum(tbl, 1);
    n = sum(tbl(:));
    expected = (row_totals * col_totals) / n;
    
    % Calculate Chi-square statistic
    chi2 = sum((tbl(:) - expected(:)).^2 ./ expected(:), 'omitnan');
    
    % Calculate degrees of freedom (df = (rows-1)*(cols-1))
    df = (size(tbl, 1)-1) * (size(tbl, 2)-1);
    
    % Calculate p-value
    p = 1 - chi2cdf(chi2, df);
    
    % Warn if expected frequencies are too small (< 5 in more than 20% of cells)
    if sum(expected(:) < 5) > (0.2 * numel(expected))
        warning('More than 20%% of cells have expected frequencies < 5. Fisher''s exact test or Monte Carlo simulation is recommended.');
    end
end