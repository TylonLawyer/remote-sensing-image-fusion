% HSV色彩空间与小波融合算法
% 功能：基于HSV色彩空间和小波变换实现图像融合
% 输入：MS为多光谱图像，Pan为全色图像
close all
clear all
clc
addpath('evaluation\');

%% 读取图像
Pan = imread('20140714pan.tif');          % 全色图像
MS = imread('20140714ms.tif');           % 多光谱图像

figure(1)
imshow(Pan);
title('HSV-小波融合：全色图像');

figure(2)
imshow(MS);
title('HSV-小波融合：多光谱图像');

%% RGB转HSV
MS_double = double(MS);
Pan_double = double(Pan);
[M, N, ~] = size(MS_double);

MS_HSV = rgb2hsv(MS_double);   % 使用MATLAB内置函数完成HSV变换
H = MS_HSV(:,:,1);
S = MS_HSV(:,:,2);
V = MS_HSV(:,:,3);  % 提取亮度分量

%% 小波变换
wtype = 'db4';  % 小波基函数
level = 1;      % 分解层数
[cA_Pan, cH_Pan, cV_Pan, cD_Pan] = dwt2(Pan_double, wtype);
[cA_V, cH_V, cV_V, cD_V] = dwt2(V, wtype);

%% 小波系数融合
alpha = 0.7;  % 融合权重
cA_Fusion = alpha * cA_Pan + (1-alpha) * cA_V;
cH_Fusion = alpha * cH_Pan + (1-alpha) * cH_V;
cV_Fusion = alpha * cV_Pan + (1-alpha) * cV_V;
cD_Fusion = alpha * cD_Pan + (1-alpha) * cD_V;

% 小波重构
V_Fusion = idwt2(cA_Fusion, cH_Fusion, cV_Fusion, cD_Fusion, wtype);

% 确保尺寸匹配
V_Fusion = V_Fusion(1:M, 1:N);

%% HSV反变换
MS_HSV_Fusion(:,:,1) = H;
MS_HSV_Fusion(:,:,2) = S;
MS_HSV_Fusion(:,:,3) = V_Fusion;
Fusion_rgb = hsv2rgb(MS_HSV_Fusion);  % MATLAB内置函数

% 数据归一化和转换
Fusion_rgb = max(Fusion_rgb, 0);
Fusion_rgb = min(Fusion_rgb, 255);
Fusion = uint8(round(Fusion_rgb));

figure(3)
imshow(Fusion);
title('HSV-小波融合结果');
imwrite(Fusion, 'output\HSV_Wavelet_fusion.jpg');

%% 评价指标计算
PAN = Pan(:,:,1);
[Fu, Fstd, PSNR, RMSE, G, EN, Dk, SF, fp, ERGAS, H_MI, Qnmi, UIQI] = fusion_index(MS, PAN, Fusion);
UIQI_mean = (UIQI(1) + UIQI(2) + UIQI(3)) / 3;
qz = [RMSE(4) G(1,3) Dk(1,4) EN(1,3) max(ERGAS) SF(1,3) fp(1,4) UIQI_mean];

fprintf('\n========== HSV-小波融合算法评价指标 ==========\n');
fprintf('RMSE: %.4f\n梯度: %.4f\nTukeyΛ: %.4f\n信息熵: %.4f\nERGAS: %.4f\n空间频率: %.4f\n相关系数: %.4f\nUIQI: %.4f\n', qz);
fprintf('==========================================\n\n');