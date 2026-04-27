clear all
close all
clf

save_fig_path = 'G:\Research\Auditory model\Figure_AI\Sup0_part';
save_fig_name = 'prop_rsep';

% load('contacts_all_resp_sub15.mat')
load('contacts_all_resp_sub17.mat')

y = contacts_all_resp;

set(gcf, 'Position', [100, 100, 400, 260]);  % 更合理比例

% Bottom bar graph
% ax2 = nexttile;
% bar(ax2,y,'stacked')

% 绘制堆叠柱状图，设置柱宽
barHandle = bar(y, 'stacked', 'BarWidth', 0.6);

% 定义颜色
green_color = [145, 172, 91] / 255;
white_color = [1 1 1];

% 设置每列颜色，第1列绿色，其它白色
for i = 1:length(barHandle)
    if i == 1
        barHandle(i).FaceColor = green_color;
    else
        barHandle(i).FaceColor = white_color;
    end
end

xticks([1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17]);
%xticklabels({'LMT', 'YHP','LL','LR','ZRH','LJ','ZJP'});
% xticklabels({'P462', 'P450','P445','P434','P474','P466','P463','P430','P469','P468','P451','P465','P454','P480','P481','P443','P455'});
ylabel('The number of contacts', 'FontSize', 8, 'FontName', 'Arial', 'Color', 'k');
xlabel('Subjects label',  'FontSize', 8, 'FontName', 'Arial', 'Color', 'k');
set(gca, 'FontSize', 8, 'FontName', 'Arial', 'TickDir', 'out', 'LineWidth', 0.5, 'XColor', 'k', 'YColor', 'k');
box off; 
exportgraphics(gcf, fullfile(save_fig_path,[save_fig_name,'.pdf']) ,'Resolution',600);