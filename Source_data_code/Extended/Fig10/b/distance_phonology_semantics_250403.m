clear all
close all

save_fig_path = 'G:\Research\Auditory model\Figure_AI\Sup6_part';
% save_fig_name_1 = 'mds_sample_7';
save_fig_name_2 = 'distance_pho_2';

name = 'qwen2_audio';

load(strcat(name, '_pho_avg_token_rdm.mat'));

token = 2  %{1,2}
    data = pho_avg_token_rdm{token};
    
% 假设我们有一个 20x1 cell，每个元素是一个 52x52 的差异矩阵，代表20个电极点
num_electrodes = length(data); % 电极点数量
num_words = 52;       % 词语数量

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
[Y, stress] = mdscale(distances, 2);

% 假设音频文件存储在 E:\Data\WordVocoder(160916) 文件夹中
folderPath = 'F:\data\WordVocoder(160916)\';
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

% 定义颜色映射：从红到白到蓝
startColor = [200/256, 0, 0];    % 红
endColor = [252/256, 229/256, 228/256];      % 浅粉
numColors = 256;

customColormap = [
    linspace(startColor(1), endColor(1), numColors)', ...
    linspace(startColor(2), endColor(2), numColors)', ...
    linspace(startColor(3), endColor(3), numColors)'
];

% 对Y值进行归一化，用于颜色映射
Y_normalized = (YY - min(YY)) / (max(YY) - min(YY));

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

figure(1); clf;
set(gcf, 'Position', [500, 300, 350, 350]); 
hold on;

% 设置边框颜色（你指定的绿色系）
light_green = [172/255, 225/255, 67/255];
dark_green = [47/255, 169/255, 41/255];

% 绘制前 26 个点（浅绿边框）
for i = 1:26
    scatter(Y(i,1), Y(i,2), 180, ...
        'MarkerFaceColor', word_colors(i, :), ...
        'MarkerEdgeColor', light_green, ...
        'LineWidth', 4);
end

% 绘制后 26 个点（深绿边框）
for i = 27:52
    scatter(Y(i,1), Y(i,2), 180, ...
        'MarkerFaceColor', word_colors(i, :), ...
        'MarkerEdgeColor', dark_green, ...
        'LineWidth', 4);
end

% 图形美化
xlabel('Dimension 1');
ylabel('Dimension 2');
set(gca, 'FontSize', 14, 'TickDir', 'out');
axis equal;
axis off;
set(gcf, 'Color', 'white');
axis equal;

%% Plot Phonology Distance
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
figure(2); clf;
% set(gcf, 'Position', [500, 300, 320, 220]);  % 250 220
set(gcf, 'Position', [500, 300, 90, 110]);  % 原来是 720x600，缩紧一点

% 公共参数
bar_width = 0.52;
bar_spacing = 0.62;
%% ========== 左轴：Phonology ==========
height_phon = 0.95;
yyaxis left;
ax = gca;
ax.YColor = 'k'; %none 'k'

% 数据位置
x1 = 1;
x2 = 1 + bar_spacing;

% 柱状图
% bar(x1, mean_tongyin, bar_width, 'FaceColor', [252/255, 229/255, 228/255], 'EdgeColor', 'none'); hold on;
bar(x1, mean_tongyin, bar_width, 'FaceColor', [194/255, 112/255, 112/255], 'EdgeColor', 'none'); hold on;
errorbar(x1, mean_tongyin, SE_tongyin, 'k', 'LineStyle', '-', 'LineWidth', 0.5, 'CapSize', 0);

% bar(x2, mean_yiyin, bar_width, 'FaceColor', [248/255, 195/255, 193/255], 'EdgeColor', 'none');
bar(x2, mean_yiyin, bar_width, 'FaceColor', [232/255, 202/255, 202/255], 'EdgeColor', 'none');
errorbar(x2, mean_yiyin, SE_yiyin, 'k', 'LineStyle', '-', 'LineWidth', 0.5, 'CapSize', 0);

% 显著性标记
% height_phon = max([mean_tongyin + SE_tongyin, mean_yiyin + SE_yiyin]) + 0.01;
line([x1, x2], [height_phon, height_phon], 'Color', 'k', 'LineWidth', 0.5);
if h == 1
    if p < 0.001
        text((x1+x2)/2, height_phon + 0.003, '***', 'FontSize', 10, 'HorizontalAlignment', 'center');
    elseif p < 0.01
        text((x1+x2)/2, height_phon + 0.003, '**', 'FontSize', 10, 'HorizontalAlignment', 'center');
    elseif p < 0.05
        text((x1+x2)/2, height_phon + 0.003, '*', 'FontSize', 10, 'HorizontalAlignment', 'center');
    end
    else
        text((x1+x2)/2, height_phon + 0.025, 'n.s.', 'FontSize', 8, 'HorizontalAlignment', 'center');
end

% ylabel('Phonology Distance','FontSize',16);
ylim([0 1]); yticks(0:1:1);


%% plot Semantics Distance
rdm = mean_rdm;
elements_tongyi = [];  %同义（只有不同音）
elements_yiyi = [];   %不同义（不同音+同音）
            for x = 2:26
                for y = 1:(x-1)
                    elements_tongyi = [elements_tongyi, rdm(x, y)];
                end
            end
            for x = 28:52
                for y = 27:(x-1)
                    elements_tongyi = [elements_tongyi, rdm(x, y)];
                end
            end
            for x = 27:52
                for y = 1:26
                    elements_yiyi = [elements_yiyi, rdm(x, y)];
                end
            end           
% 计算平均值
mean_tongyi = mean(elements_tongyi);
SE_tongyi = std(elements_tongyi)/(length(elements_tongyi))^0.5;
mean_yiyi = mean(elements_yiyi);
SE_yiyi = std(elements_yiyi)/(length(elements_yiyi))^0.5;

% Step 3: 双样本t检验
[h, p, ci, stats]  = ttest2(elements_tongyi, elements_yiyi);
% 检查显著性
if h == 1
    fprintf('组内和组间距离有显著差异，p值为 %f\n', p);
else
    fprintf('组内和组间距离无显著差异，p值为 %f\n', p);
end

%% ========== 右轴：Semantics ==========
height_sem = 0.95;
yyaxis right;
ax.YColor = 'k'; %k none

x3 = 2 + bar_spacing;
x4 = x3 + bar_spacing;

% bar(x3, mean_tongyi, bar_width, 'FaceColor', [201/255, 223/255, 239/255], 'EdgeColor','none');
bar(x3, mean_tongyi, bar_width, 'FaceColor', [70/255, 138/255, 184/255], 'EdgeColor','none');
errorbar(x3, mean_tongyi, SE_tongyi, 'k', 'LineStyle', '-', 'LineWidth', 0.5, 'CapSize', 0);

% bar(x4, mean_yiyi, bar_width, 'FaceColor', [155/255, 195/255, 225/255], 'EdgeColor','none');
bar(x4, mean_yiyi, bar_width, 'FaceColor', [166/255, 199/255, 222/255], 'EdgeColor','none');
errorbar(x4, mean_yiyi, SE_yiyi, 'k', 'LineStyle', '-', 'LineWidth', 0.5, 'CapSize', 0);

% 显著性标记（右轴）
% height_sem = max([mean_tongyi + SE_tongyi, mean_yiyi + SE_yiyi]) + 0.02;
line([x3, x4], [height_sem, height_sem], 'Color', 'k', 'LineWidth', 0.5);
if h == 1
    if p < 0.001
        text((x3+x4)/2, height_sem + 0.003, '***', 'FontSize', 10, 'HorizontalAlignment', 'center');
    elseif p < 0.01
        text((x3+x4)/2, height_sem + 0.003, '**', 'FontSize', 10, 'HorizontalAlignment', 'center');
    elseif p < 0.05
        text((x3+x4)/2, height_sem + 0.003, '*', 'FontSize', 10, 'HorizontalAlignment', 'center');
    end
    else
        text((x3+x4)/2, height_sem + 0.025, 'n.s.', 'FontSize', 8, 'HorizontalAlignment', 'center');
end

% ylabel('Semantics Distance','FontSize',16);
ylim([0 1]); yticks(0:1:1);

%% ========== 美化图表 ==========
xticks([x1, x2, x3, x4]);
% xticklabels({'Similar Phonology', 'Different Phonology', 'Similar Semantics', 'Different Semantics'});
% xticklabels({'Sim-Phon', 'Diff-Phon', 'Sim-Sem', 'Diff-Sem'});
% xtickangle(90);  % 标签竖着显示（90度）
% xtickangle(45);  % 可选 90 或 45，看你喜欢

set(gca, 'TickDir', 'out');
set(gca, 'FontSize', 14);
% title('Phonology vs Semantics Distance','FontSize',18,'FontWeight','bold');
box off;
xlim([0.52, 3.72]);  % 根据你的 x 位置做微调

set(gca, 'XTick', []);        % 去掉横坐标刻度位置
set(gca, 'XTickLabel', []);   % 去掉横坐标标签文字
set(gca, 'FontSize', 8, 'FontName', 'Arial', 'TickDir', 'out', 'LineWidth', 0.5, 'YColor', 'k','XColor', 'k');
exportgraphics(gcf, fullfile(save_fig_path,[save_fig_name_2,'.pdf']) ,'Resolution',600);


