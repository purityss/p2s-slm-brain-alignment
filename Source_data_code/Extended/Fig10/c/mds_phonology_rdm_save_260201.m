clear all
close all

save_fig_path = 'G:\Research\01 Speech_Comprehension\02 Figure_AI\Fig_sup_update_202604\ED10_part\llasm';
% save_fig_name_1 = 'llasm_mds_pho_pho_2';
save_fig_name_2 = 'llasm_rdm_pho_1';


name = 'llasm';

load(strcat(name, '_pho_avg_token_rdm.mat'));


token = 1  %{1,2}
    data = pho_avg_token_rdm{token};

num_electrodes = length(data); % 电极点数量
num_words = 52;       % 词语数量

%%
% 初始化平均矩阵
mean_rdm = data;
mean_rdm_all = mean_rdm;

% 对称化矩阵：将左下部分对称到右上
for i = 1:num_words
    for j = i+1:num_words
        mean_rdm_all(i, j) = mean_rdm_all(j, i); % 上三角 = 下三角
    end
end

% 确保对角线为 0（余弦距离：完全相似的点应为 0）
mean_rdm_all(1:num_words+1:end) = 0;

distances = mean_rdm_all; 
% 使用 MDS 将距离矩阵降维到3维
% [Y, stress] = mdscale(distances, 3);
% [Y, stress] = mdscale(distances, 2);
[Y, stress] = mdscale(distances, 2, 'Start', 'random');

%% 计算 MDS 解释的方差（基于距离保持度）
% **1. 计算原始余弦距离矩阵**
D_original_full = distances; % 余弦距离矩阵

% **2. 进行 MDS 降维**
% [Y_2D, stress_2D] = mdscale(distances, 2);
[Y_2D, stress] = mdscale(distances, 2, 'Start', 'random');
% [Y_3D, stress_3D] = mdscale(distances, 3);
[Y_3D, stress] = mdscale(distances, 3, 'Start', 'random');

% **3. 计算降维后的余弦距离**
D_2D_cosine = pdist(Y_2D, 'cosine'); % 计算 2D 余弦距离
D_3D_cosine = pdist(Y_3D, 'cosine'); % 计算 3D 余弦距离

% 还原为完整的余弦距离矩阵
D_2D_full = squareform(D_2D_cosine);
D_3D_full = squareform(D_3D_cosine);

% **4. 计算相关性 R²**
R2_2D = corr(D_original_full(:), D_2D_full(:))^2;
R2_3D = corr(D_original_full(:), D_3D_full(:))^2;

% **5. 输出解释方差**
disp(['2D MDS 解释的方差 R² 为: ', num2str(R2_2D, '%.4f')]);
disp(['3D MDS 解释的方差 R² 为: ', num2str(R2_3D, '%.4f')]);

% **6. 判断是否需要第三个维度**
if R2_2D >= 0.9
    disp('✅ 2D MDS 已经很好地解释了数据，无需增加维度。');
else
    disp('⚠️ 2D 可能不足，考虑 3D MDS');
    
    if R2_3D >= 0.9
        disp('✅ 3D MDS 解释力更好，推荐使用 3D。');
    else
        disp('⚠️ 可能需要更高维度');
    end
end


%%
% 假设音频文件存储在 E:\Data\WordVocoder(160916) 文件夹中
folderPath = 'F:\data\01 Project_Speech_Comprehension\WordVocoder(160916)\';
input_texts = ["草莓", "带鱼", "蛋糕", "豆腐", "海带", "红薯", "鸡蛋", "煎饼", "荔枝", ...
    "龙虾", "萝卜", "绿豆", "芒果", "蜜桔", "面包", "蘑菇", "牛肉", "苹果", "软糖", ...
    "薯条", "西瓜", "香肠", "洋葱", "樱桃", "玉米", "猪蹄"];
numWords = numel(input_texts);
durationFirstSyllable = 0.25; % 前250ms

% STFT参数
frameLen = 256; 
frameOverlap = 128;
nfft = 512;

% 元音和辅音频率范围
vowelFreqRange = [200 1200]; % 元音频率范围
consonantFreqRange = [2000 8000]; % 辅音频率范围

% 特征权重（元音和辅音）
vowelWeight = 0.92;
consonantWeight = 0.08;

% 初始化特征矩阵
dummyAudio = rand(1, round(durationFirstSyllable * 16000)); % 模拟音频
stepSize = frameLen - frameOverlap;
numFrames = floor((length(dummyAudio) - frameOverlap) / stepSize);

% 频率索引计算
f = (0:(nfft/2)) * (16000 / nfft); % 频率轴
vowelFreqIdx = (f >= vowelFreqRange(1) & f <= vowelFreqRange(2));
consonantFreqIdx = (f >= consonantFreqRange(1) & f <= consonantFreqRange(2));

% 动态计算特征维度
numVowelFreqs = sum(vowelFreqIdx); % 元音频率数量
numConsonantFreqs = sum(consonantFreqIdx); % 辅音频率数量
numEnergyFrames = numFrames - 1; % 能量变化率的帧数
totalFeatures = (numVowelFreqs + numConsonantFreqs) * 2 + numEnergyFrames; % 平均频谱+标准差+能量变化率

features = zeros(numWords, totalFeatures);

for i = 1:numWords
    % 读取音频文件
    audioFile = fullfile(folderPath, [char(input_texts(i)) '.wav']);
    [audio, fs] = audioread(audioFile);
    
    % 截取前250ms音频
    numSamples = round(durationFirstSyllable * fs);
    audioSegment = audio(1:numSamples);
    
    % 手动实现 STFT
    numFrames = floor((length(audioSegment) - frameOverlap) / stepSize);
    stftMatrix = zeros(nfft, numFrames);
    window = hamming(frameLen, 'periodic');
    
    for j = 1:numFrames
        startIdx = (j-1) * stepSize + 1;
        endIdx = startIdx + frameLen - 1;
        frame = audioSegment(startIdx:endIdx) .* window; % 加窗
        fftResult = fft(frame, nfft); % FFT
        stftMatrix(:, j) = fftResult;
    end
    
    % 提取正频部分
    f = (0:(nfft/2)) * (fs / nfft);
    stftMatrix = stftMatrix(1:nfft/2+1, :);
    magnitude = abs(stftMatrix); % 幅值谱
    
    % 提取元音特征
    vowelMagnitude = magnitude(vowelFreqIdx, :);
    vowelMeanSpectrum = mean(vowelMagnitude, 2); % 平均频谱
    vowelStdSpectrum = std(vowelMagnitude, 0, 2); % 标准差频谱
    
    % 提取辅音特征
    consonantMagnitude = magnitude(consonantFreqIdx, :);
    consonantMeanSpectrum = mean(consonantMagnitude, 2); % 平均频谱
    consonantStdSpectrum = std(consonantMagnitude, 0, 2); % 标准差频谱
    
    % 提取能量变化率
    frameEnergy = sum(consonantMagnitude.^2, 1); % 短时能量
    energyDerivative = diff(frameEnergy); % 能量变化率
    
    % 融合元音和辅音特征
    combinedFeatures = [
        vowelWeight * vowelMeanSpectrum', vowelWeight * vowelStdSpectrum', ...
        consonantWeight * consonantMeanSpectrum', consonantWeight * consonantStdSpectrum', ...
        consonantWeight * energyDerivative
    ];
    
    % 赋值到特征矩阵
    features(i, :) = combinedFeatures;
end

% 计算相似性矩阵
Distances = pdist(features, 'euclidean');
similarityMatrix = squareform(Distances);

% 使用MDS降维到1维
YY = mdscale(similarityMatrix, 1);

% 定义颜色映射：从粉到浅粉
% startColor = [200/256, 0, 0];    % 红
% endColor = [252/256, 229/256, 228/256];      % 浅粉
startColor = [180/255, 0, 0];    % 红
endColor = [252/255, 229/255, 228/255];      % 浅粉
numColors = 256;

% 生成颜色映射
customColormap = [
    linspace(startColor(1), endColor(1), numColors)', ...
    linspace(startColor(2), endColor(2), numColors)', ...
    linspace(startColor(3), endColor(3), numColors)'
];

% 对Y值进行归一化，用于颜色映射
Y_normalized = (YY - min(YY)) / (max(YY) - min(YY));

% 绘制渐变colorbar
figure(1);clf;
hold on;
for i = 1:numWords
    % 将归一化的Y值映射到颜色索引
    colorIdx = round(Y_normalized(i) * (numColors - 1)) + 1;
    % 绘制每个词语对应的颜色标记
    plot(i, 1, 'o', 'MarkerFaceColor', customColormap(colorIdx, :), ...
        'MarkerEdgeColor', customColormap(colorIdx, :), 'MarkerSize', 10);
end
colormap(customColormap);
colorbar; % 显示colorbar
% title('Gradient Colorbar Based on Combined Features (Vowel + Consonant)');
title('Vowel + Consonant');
% xlabel('Word Index');
set(gca, 'ytick', []); % 隐藏y轴刻度
set(gca, 'xtick', 1:numWords, 'xticklabel', input_texts); % 显示词语索引
xtickangle(45); % 旋转词语标签
set(gcf, 'Color', 'white');
hold off;

% 应用自定义颜色映射
colormap(customColormap);

% 初始化词语的颜色矩阵
word_colors = zeros(num_words, 3);

% 将1-26号词语和27-52号词语设置为相同的颜色
for i = 1:26
    % 获取每个词语的颜色
    colorIdx = round(Y_normalized(i) * (numColors - 1)) + 1;  % 映射到颜色索引
%     colorIdx = round(Y_expanded_normalized(i) * (numColors - 1)) + 1;  % 映射到颜色索引
    word_colors(i, :) = customColormap(colorIdx, :);           % 设置1-26号词语的颜色
    word_colors(i+26, :) = customColormap(colorIdx, :);        % 设置27-52号词语的颜色
end
    
% 可视化降维结果，降为2维
figure(2);clf
% set(gcf, 'Position', [500, 300, 370, 370]); 
set(gcf, 'Position', [500, 300, 102, 100]); 
hold on;

% % 绘制所有52个点
% scatter(Y(:,1), Y(:,2), 150, word_colors, 'filled'); % 点的大小设置为150

% 绘制1-26号点，并为它们设置标签
for i = 1:26
    scatter(Y(i,1), Y(i,2), 20, word_colors(i, :), 'filled'); % 绘制1-26号点
end

% 绘制27-52号点，但不添加标签
for i = 27:52
    scatter(Y(i,1), Y(i,2), 20, word_colors(i, :), 'filled'); % 绘制27-52号点
end

% 为前26个点设置图例标签（1到26）
legend_labels = arrayfun(@(x) num2str(x), 1:26, 'UniformOutput', false); % 生成1到26的标签
% legend(legend_labels, 'Location', 'bestoutside');  % 仅为前26个点生成图例

% 标题和标签
xlabel('Dimension 1');
ylabel('Dimension 2');
set(gca, 'FontSize', 8, 'FontName', 'Arial', 'TickDir', 'out', 'LineWidth', 0.5, 'XColor', 'k', 'YColor', 'k', 'XTick', [], 'YTick', []);    
axis equal;
set(gcf, 'Color', 'w');
xlim padded
ylim padded
% exportgraphics(gcf, fullfile(save_fig_path,[save_fig_name_1,'.pdf']) ,'Resolution',600);

%% Plot Distance
% Step 1: 计算组内和组间距离
rdm = mean_rdm;
elements_tongyin = []; %同音(只有不同义）
elements_yiyin = [];  %不同音（不同义+同义）
            for x = 27:52
                for y = 1:26
                    if x == y + 26
                        elements_tongyin = [elements_tongyin, rdm(x, y)];
                    end
                end
            end
            for x = 2:52
                for y = 1:x-1
                    if x ~= y + 26
                        elements_yiyin = [elements_yiyin, rdm(x, y)];
                    end
                end
            end
            
% 计算平均值
mean_tongyin = mean(elements_tongyin);
SE_tongyin = std(elements_tongyin)/(length(elements_tongyin))^0.5;
mean_yiyin = mean(elements_yiyin);
SE_yiyin = std(elements_yiyin)/(length(elements_yiyin))^0.5;

% Step 3: 进行双样本t检验
[h, p, ci, stats] = ttest2(elements_tongyin, elements_yiyin);
if h == 1
    fprintf('组内和组间距离有显著差异，p值为 %f\n', p);
else
    fprintf('组内和组间距离无显著差异，p值为 %f\n', p);
end

% Step 4: 绘制柱状图
figure(3);clc
set(gcf, 'Position', [500, 200, 620, 660]); 
bar_width = 0.4; % 设置柱的宽度
bar_spacing = 0.25; % 设置两个柱之间的间距
% height = 0.07;
height = 0.58;

% 绘制第一个柱：组内距离
bar(1, mean_tongyin, 'FaceColor', [252/255, 229/255, 228/255], 'EdgeColor', 'none', 'BarWidth', bar_width);
hold on;
errorbar(1, mean_tongyin, SE_tongyin, 'k', 'LineStyle', '-', 'LineWidth', 2, "CapSize", 30);

% 绘制第二个柱：组间距离
bar(1 + bar_spacing + bar_width, mean_yiyin, 'FaceColor', [248/255, 195/255, 193/255], 'EdgeColor', 'none', 'BarWidth', bar_width);
errorbar(1 + bar_spacing + bar_width, mean_yiyin, SE_yiyin, 'k', 'LineStyle', '-', 'LineWidth', 2, "CapSize", 30);

% 调整 x 轴范围以适应新的位置
xlim([0.5, 1.5 + bar_spacing + bar_width]);

% 添加显著性标记
x_pos = [1, 1 + bar_spacing + bar_width];
y_pos = [mean_tongyin + 2 * SE_tongyin, mean_yiyin + 2 * SE_yiyin];

if h == 1 && p < 0.001
    text((2 + bar_spacing + bar_width)/2, height + 0.001, '***', 'FontSize', 30, 'HorizontalAlignment', 'center');
    line([x_pos(1), x_pos(1)], [y_pos(1), height], 'Color', 'k', 'LineStyle', '-','LineWidth',2);
    line([x_pos(2), x_pos(2)], [y_pos(2), height], 'Color', 'k', 'LineStyle', '-','LineWidth',2);
    line([1, 1 + bar_spacing + bar_width],[height,height], 'Color', 'k', 'LineStyle', '-','LineWidth',2);
elseif h == 1 && p < 0.01
    text((2 + bar_spacing + bar_width)/2, height + 0.01, '**', 'FontSize', 30, 'HorizontalAlignment', 'center');
    line([x_pos(1), x_pos(1)], [y_pos(1), height], 'Color', 'k', 'LineStyle', '-','LineWidth',2);
    line([x_pos(2), x_pos(2)], [y_pos(2), height], 'Color', 'k', 'LineStyle', '-','LineWidth',2);
    line([1, 1 + bar_spacing + bar_width],[height,height], 'Color', 'k', 'LineStyle', '-','LineWidth',2);
elseif h == 1 && p < 0.05
    text((2 + bar_spacing + bar_width)/2, height + 0.01, '*', 'FontSize', 30, 'HorizontalAlignment', 'center');   
    line([x_pos(1), x_pos(1)], [y_pos(1), height], 'Color', 'k', 'LineStyle', '-','LineWidth',2);
    line([x_pos(2), x_pos(2)], [y_pos(2), height], 'Color', 'k', 'LineStyle', '-','LineWidth',2);
    line([1, 1 + bar_spacing + bar_width],[height,height], 'Color', 'k', 'LineStyle', '-','LineWidth',2);
else
    text((2 + bar_spacing + bar_width)/2, height + 0.02, 'n.s.', 'FontSize', 20, 'HorizontalAlignment', 'center');   
    line([x_pos(1), x_pos(1)], [y_pos(1), height], 'Color', 'k', 'LineStyle', '-','LineWidth',2);
    line([x_pos(2), x_pos(2)], [y_pos(2), height], 'Color', 'k', 'LineStyle', '-','LineWidth',2);
    line([1, 1 + bar_spacing + bar_width],[height,height], 'Color', 'k', 'LineStyle', '-','LineWidth',2);
end     

% 美化图表
xticks([1, 1 + bar_spacing + bar_width]);
xticklabels({'Similar Phonology', 'Different Phonology'});
% ylim([0, 0.1]);
% yticks(0:0.05:0.1);
ylim([0, 0.6]);
yticks(0:0.1:0.6);

set(gca, 'TickDir', 'out');
set(gca, 'FontSize', 16);
ylabel('Mean Euclidean Distance','FontSize',18);
title('Similar Phonology v.s. Different Phonology','FontSize',20,'FontWeight','bold');
box off;
hold off;

%% 平均化 rdm 并绘制对称热图
% 绘制对称平均差异矩阵的热图
figure(4); clf;
set(gcf, 'Position', [300, 300, 420, 400]); 
% 使用 imagesc 绘制热图
h = imagesc(mean_rdm); % 绘制热图
% colorbar; % 显示颜色条
colormap jet; % 使用蓝-绿-黄色配色方案
% title('Symmetric Average Phonology RDM');
xlabel('Words');
ylabel('Words');
set(gca, 'FontSize', 16);
set(gca, 'TickDir', 'out');
box off;

% 设置 NaN 的透明度
% 将 NaN 值的区域设置为透明
set(h, 'AlphaData', ~isnan(mean_rdm)); 

% **隐藏横纵坐标轴**
set(gca, 'XColor', 'none', 'YColor', 'none'); 
% **隐藏刻度**
set(gca, 'XTick', [], 'YTick', []); 
% **去掉轴标签**
xlabel('');
ylabel('');
% **去掉边框**
axis off; 

%%  把词语重新sort
similarityMatrix = mean_rdm;
% 确保 Y_normalized 维度正确
if length(Y_normalized) ~= 26
    error('Y_normalized 长度应为 26，但得到的是 %d，请检查 MDS 计算是否正确', length(Y_normalized));
end

% **复制 Y_normalized，使其变为 52×1**
Y_normalized_52 = [Y_normalized; Y_normalized]; 

% **获取新顺序**
[~, sortedIdx1] = sort(Y_normalized_52(1:26));  %升序，从小到大
[~, sortedIdx2] = sort(Y_normalized_52(27:52)); 
% [~, sortedIdx1] = sort(Y_normalized_52(1:26), 'descend');   %降序，从大到小
% [~, sortedIdx2] = sort(Y_normalized_52(27:52), 'descend'); 
newOrder = [sortedIdx1; sortedIdx2 + 26];

% **创建一个新 RDM**
reorderedRDM = NaN(52, 52); % 先填充 NaN

% **遍历原 `RDM` 的下三角部分**
for i = 2:52
    for j = 1:i-1  % 只操作下三角部分 (i > j)
        % 获取原来的 `RDM(i, j)`
        original_value = similarityMatrix(i, j);
        
        % 获取 `i, j` 在新排序中的索引
        new_i = find(newOrder == i);
        new_j = find(newOrder == j);
        
        % 确保 `new_i > new_j`，才能放到下三角
        if new_i > new_j
            reorderedRDM(new_i, new_j) = original_value;
        else
            reorderedRDM(new_j, new_i) = original_value;
        end
    end
end

reorderedRDM_all = reorderedRDM;
% 
% % 对称化矩阵：将左下部分对称到右上
% for i = 1:num_words
%     for j = i+1:num_words
%         reorderedRDM_all(i, j) = reorderedRDM_all(j, i); % 上三角 = 下三角
%     end
% end

% 绘制对称平均差异矩阵的热图
figure(5); clf;
set(gcf, 'Position', [300, 300, 102, 100]); 
% set(gcf, 'Position', [300, 300, 420, 400]); 
h = imagesc(reorderedRDM_all); % 绘制热图
% colorbar; % 显示颜色条
% colormap jet; % 使用蓝-绿-黄色配色方案
% colormap(parula);         % MATLAB 默认
% 1. 定义颜色节点 (从下往上提取颜色)
color1 = [50, 28, 90] / 255;   % 深蓝色 (底部)
color2 = [40, 100, 120] / 255;  % 紫色
color3 = [45, 175, 120] / 255;   % 粉红/珊瑚色
color4 = [170, 215, 60] / 255;  % 橙色
color5 = [252, 245, 65] / 255;  % 亮黄色 (顶部)
% 2. 组合控制点
control_colors = [color1; color2; color3; color4; color5];
% 3. 生成 256 级的平滑渐变
n = 256;
x = linspace(1, 5, size(control_colors, 1)); % 5个原始颜色节点的位置
xi = linspace(1, 5, n);                     % 插值后的 256 个位置
custom_map = interp1(x, control_colors, xi);
% 应用 colormap
colormap(custom_map);

set(h, 'AlphaData', ~isnan(reorderedRDM_all)); 
set(gca, 'FontSize', 16);
set(gca, 'TickDir', 'out');
box off;

% **隐藏横纵坐标轴**
set(gca, 'XColor', 'none', 'YColor', 'none'); 
% **隐藏刻度**
set(gca, 'XTick', [], 'YTick', []); 
% **去掉轴标签**
xlabel('');
ylabel('');
% **去掉边框**
axis off;

exportgraphics(gcf, fullfile(save_fig_path,[save_fig_name_2,'.pdf']) ,'Resolution',600);
