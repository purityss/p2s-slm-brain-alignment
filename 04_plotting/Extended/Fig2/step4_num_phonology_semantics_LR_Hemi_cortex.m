clear
close all

load('brain_hemi_counts_cortex.mat')

save_fig_name = 'prop_LR_hemi_3unit_HG';
% save_fig_name = 'prop_LR_hemi_3unit_Insula';
% save_fig_name = 'prop_LR_hemi_3unit_pmSTG';
% save_fig_name = 'prop_LR_hemi_3unit_MTG';
% save_fig_name = 'prop_LR_hemi_3unit_ITG';
% save_fig_name = 'prop_LR_hemi_3unit_PCC';
% save_fig_name = 'prop_LR_hemi_3unit_Cuneus';
% save_fig_name = 'prop_LR_hemi_3unit_MFG';
% save_fig_name = 'prop_LR_hemi_3unit_IFG';
% save_fig_name = 'prop_LR_hemi_3unit_Sensorimotor';
% save_fig_name = 'prop_LR_hemi_3unit_MTL';
% save_fig_name = 'prop_LR_hemi_3unit_aSTG';
% save_fig_name = 'prop_LR_hemi_3unit_TemporalPole';
% save_fig_name = 'prop_LR_hemi_3unit_IPL';

% Filter out left and right brain data for the HG region
is_HG = strcmp(result_table.Region, 'HG');
% is_HG = strcmp(result_table.Region, 'Insula');
% is_HG = strcmp(result_table.Region, 'pmSTG');
% is_HG = strcmp(result_table.Region, 'MTG');
% is_HG = strcmp(result_table.Region, 'ITG');
% is_HG = strcmp(result_table.Region, 'PCC');
% is_HG = strcmp(result_table.Region, 'Cuneus');
% is_HG = strcmp(result_table.Region, 'MFG');
% is_HG = strcmp(result_table.Region, 'IFG');
% is_HG = strcmp(result_table.Region, 'Sensorimotor');
% is_HG = strcmp(result_table.Region, 'MTL');
% is_HG = strcmp(result_table.Region, 'aSTG');
% is_HG = strcmp(result_table.Region, 'TemporalPole');
% is_HG = strcmp(result_table.Region, 'IPL');

HG_data = result_table(is_HG, :);

% Ensure Left is in the 1st row and Right in the 2nd row (or vice versa)
[~, sort_idx] = sort(HG_data.Hemisphere);  % 'Left' < 'Right' alphabetically sorted
HG_data = HG_data(sort_idx, :);

% Extract proportion data
num = HG_data.TotalContacts;
num_p = HG_data.Phonology;
num_s = HG_data.Semantics;
num_both = HG_data.Both;

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
    
    % Warn if expected frequencies are too small (< 5 in more than 20% of cells), Fisher's exact test or Monte Carlo simulation is recommended
    if sum(expected(:) < 5) > (0.2 * numel(expected))
        warning('More than 20%% of cells have expected frequencies < 5. Fisher''s exact test or Monte Carlo simulation is recommended.');
    end
end

% Assign values to variables
% num      = data_numeric(:, 1);
% num_p    = data_numeric(:, 2);
% num_s    = data_numeric(:, 3);
% num_both = data_numeric(:, 4);

prop_all = num ./ num * 100;
prop_p = num_p ./ num * 100;
prop_s = num_s ./ num * 100;
prop_both = num_both ./ num * 100;

prop(:,1) = prop_p;
prop(:,2) = prop_s;
prop(:,3) = prop_both;

gcf = figure(1);
set(gcf, 'Position', [100, 100, 155, 190]);  % Set reasonable figure proportions
set(gcf, 'Color', 'w');  % Set white background

% Set colors for each group of bars
% colors = [249/256, 196/256, 194/256;   % Color for group 1 (RGB)
%           156/256, 196/256, 226/256    % Color for group 2 (RGB)
%           0.751, 0.691, 0.857];   %0.716, 0.659, 0.816; 0.791, 0.766, 0.820; 0.791, 0.727, 0.902; 0.712, 0.655, 0.812; 0.751, 0.691, 0.857; 0.728, 0.669, 0.830
%           %198/256, 197/256, 196/256 ]; % Color for group 3 (RGB)
colors = [231/256, 126/256, 121/256;   % Color for group 1 (RGB)
          112/256, 166/256, 202/256;   % Color for group 2 (RGB)
          158/256, 137/256, 193/256];  

% Position parameters setup
group_centers = [1, 2];      % Centers for the two groups (Left, Right)
bar_width = 0.2;  % Narrower bar width
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

x_pos = [1, 2];
% y_pos = [48, 48];
height = 45;

if p < 0.001
    text((x_pos(1) + x_pos(2))/2, height + 0.5, '***', 'FontSize', 15, 'HorizontalAlignment', 'center');
    line([x_pos(1), x_pos(2)],[height,height], 'Color', 'k', 'LineStyle', '-','LineWidth',0.5);
elseif p < 0.01
    text((x_pos(1) + x_pos(2))/2, height + 0.5, '**', 'FontSize', 15, 'HorizontalAlignment', 'center');
    line([x_pos(1), x_pos(2)],[height,height], 'Color', 'k', 'LineStyle', '-','LineWidth',0.5);
elseif p < 0.05
    text((x_pos(1) + x_pos(2))/2, height + 0.5, '*', 'FontSize', 15, 'HorizontalAlignment', 'center');   
    line([x_pos(1), x_pos(2)],[height,height], 'Color', 'k', 'LineStyle', '-','LineWidth',0.5);
end     

xlim([0.45, 2.55]);
xticks(group_centers);
xticklabels({'Left', 'Right'});

% for k = 1:length(b)
%     b(k).FaceColor = 'flat'; % Allow each bar to have a different color
%     b(k).CData = repmat(colors(k, :), size(prop, 1), 1); % Set color
%     b(k).EdgeColor = 'none'; % Set edge color to none
% end 

ylim([0 50]);
yticks(0:10:50);

set(gca, 'FontSize', 8, 'FontName', 'Arial', 'TickDir', 'out', 'LineWidth', 0.5, 'XColor', 'k', 'YColor', 'k');

ylabel('Proportion of contacts (%)', 'FontSize', 8, 'FontName', 'Arial', 'Color', 'k');

xlabel('HG', 'FontSize', 8, 'FontName', 'Arial', 'Color', 'k');
% xlabel('Insula', 'FontSize', 8, 'FontName', 'Arial', 'Color', 'k');
% xlabel('pmSTG', 'FontSize', 8, 'FontName', 'Arial', 'Color', 'k');
% xlabel('MTG', 'FontSize', 8, 'FontName', 'Arial', 'Color', 'k');
% xlabel('ITG', 'FontSize', 8, 'FontName', 'Arial', 'Color', 'k');
% xlabel('PCC', 'FontSize', 8, 'FontName', 'Arial', 'Color', 'k');
% xlabel('Cuneus', 'FontSize', 8, 'FontName', 'Arial', 'Color', 'k');
% xlabel('MFG', 'FontSize', 8, 'FontName', 'Arial', 'Color', 'k');
% xlabel('IFG', 'FontSize', 8, 'FontName', 'Arial', 'Color', 'k');
% xlabel('Sensorimotor', 'FontSize', 8, 'FontName', 'Arial', 'Color', 'k');
% xlabel('MTL', 'FontSize', 8, 'FontName', 'Arial', 'Color', 'k');
% xlabel('aSTG', 'FontSize', 8, 'FontName', 'Arial', 'Color', 'k');
% xlabel('Temporal Pole', 'FontSize', 8, 'FontName', 'Arial', 'Color', 'k');
% xlabel('IPL', 'FontSize', 8, 'FontName', 'Arial', 'Color', 'k');

box off; 

