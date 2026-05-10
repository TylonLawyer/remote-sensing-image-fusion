% Brovey融合算法
% 功能：基于Brovey变换进行图像融合，突显亮度与色彩平衡
close all
clear all
clc
addpath('evaluation\');

%% 读取图像
Pan = imread('20140714pan.tif');          % 全色图像
MS = imread('20140714ms.tif');           % 多光谱图像

figure(1)
imshow(Pan);
title('Brovey融合：全色图像');

figure(2)
imshow(MS);
title('Brovey融合：多光谱图像');

%% 预处理图像
MS_double = double(MS);
Pan_double = double(Pan);

MS_R = MS_double(:,:,1);
MS_G = MS_double(:,:,2);
MS_B = MS_double(:,:,3);

% 多光谱图像的平均值 (避免除以零时出现问题)
MS_mean = max((MS_R + MS_G + MS_B) / 3, 1e-6);

% Brovey融合
Fusion(:,:,1) = MS_R .* Pan_double ./ MS_mean;
Fusion(:,:,2) = MS_G .* Pan_double ./ MS_mean;
Fusion(:,:,3) = MS_B .* Pan_double ./ MS_mean;

% 数据归一化
Fusion = max(Fusion, 0);
Fusion = min(Fusion, 255);
Fusion = uint8(Fusion);

figure(3)
imshow(Fusion);
title('Brovey融合结果');
imwrite(Fusion, 'output\Brovey_fusion.jpg');

%% 评价指标计算
PAN = Pan(:,:,1);
[Fu, Fstd, PSNR, RMSE, G, EN, Dk, SF, fp, ERGAS, H_MI, Qnmi, UIQI] = fusion_index(MS, PAN, Fusion);
UIQI_mean = (UIQI(1) + UIQI(2) + UIQI(3)) / 3;
qz = [RMSE(4) G(1,3) Dk(1,4) EN(1,3) max(ERGAS) SF(1,3) fp(1,4) UIQI_mean];

fprintf('\n========== Brovey融合算法评价指标 ==========\n');
fprintf('RMSE: %.4f\n梯度: %.4f\nTukeyΛ: %.4f\n信息熵: %.4f\nERGAS: %.4f\n空间频率: %.4f\n相关系数: %.4f\nUIQI: %.4f\n', qz);
fprintf('==========================================\n\n');