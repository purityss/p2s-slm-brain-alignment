clear all
close all
clf

load('contacts_all_resp_sub17.mat')
y = contacts_all_resp;

% Set a more reasonable figure proportion
set(gcf, 'Position', [100, 100, 400, 260]);  

% Bottom bar graph
% Plot stacked bar chart and set bar width
barHandle = bar(y, 'stacked', 'BarWidth', 0.6);

% Define colors
green_color = [145, 172, 91] / 255;
white_color = [1 1 1];

% Set the color of each column: the first column is green, the others are white
for i = 1:length(barHandle)
    if i == 1
        barHandle(i).FaceColor = green_color;
    else
        barHandle(i).FaceColor = white_color;
    end
end

xticks([1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17]);

ylabel('The number of contacts', 'FontSize', 8, 'FontName', 'Arial', 'Color', 'k');
xlabel('Subjects label',  'FontSize', 8, 'FontName', 'Arial', 'Color', 'k');
set(gca, 'FontSize', 8, 'FontName', 'Arial', 'TickDir', 'out', 'LineWidth', 0.5, 'XColor', 'k', 'YColor', 'k');
box off;