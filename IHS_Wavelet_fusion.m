% IHS色彩空间与小波融合算法
% 功能：使用IHS色彩空间变换并结合小波变换进行图像融合
% 输入：MS - 多光谱图像, PAN - 全色图像
% 输出：Fusion - 融合后的图像

close all
clear all
clc
addpath('evaluation\');

%% 读取图像
Pan = imread('20140714pan.tif');          % 全色图像
MS = imread('20140714ms.tif');            % 多光谱图像

figure(1)
imshow(Pan);
title('IHS-小波融合：全色图像');

figure(2)
imshow(MS);
title('IHS-小波融合：多光谱图像');

%% RGB转IHS
MS_double = double(MS);
[M, N, C] = size(MS_double);

% RGB到IHS的转换
MS_IHS = rgb2ihs(MS_double);
I = MS_IHS(:,:,1);  % 强度分量
H = MS_IHS(:,:,2);  % 色调分量
S = MS_IHS(:,:,3);  % 饱和度分量

Pan_double = double(Pan);

%% 小波变换
% 对全色图像和强度分量进行小波分解
wtype = 'db4';  % 小波基函数
level = 1;      % 分解层数

[cA_Pan, cH_Pan, cV_Pan, cD_Pan] = dwt2(Pan_double, wtype);
[cA_I, cH_I, cV_I, cD_I] = dwt2(I, wtype);

%% 小波系数融合
% 使用加权平均法融合细节系数，使用全色图像的逼近系数
alpha = 0.7;  % 权重参数
cA_Fusion = alpha * cA_Pan + (1-alpha) * cA_I;
cH_Fusion = alpha * cH_Pan + (1-alpha) * cH_I;
cV_Fusion = alpha * cV_Pan + (1-alpha) * cV_I;
cD_Fusion = alpha * cD_Pan + (1-alpha) * cD_I;

% 小波重构
I_Fusion = idwt2(cA_Fusion, cH_Fusion, cV_Fusion, cD_Fusion, wtype);

% 确保尺寸匹配
I_Fusion = I_Fusion(1:M, 1:N);

%% IHS反变换
MS_IHS_Fusion(:,:,1) = I_Fusion;
MS_IHS_Fusion(:,:,2) = H;
MS_IHS_Fusion(:,:,3) = S;

Fusion_rgb = ihs2rgb(MS_IHS_Fusion);

% 数据归一化和转换
Fusion_rgb = max(Fusion_rgb, 0);
Fusion_rgb = min(Fusion_rgb, 255);
Fusion = uint8(round(Fusion_rgb));

figure(3)
imshow(Fusion);
title('IHS-小波融合结果');
imwrite(Fusion, 'output\IHS_Wavelet_fusion.jpg');

%% 评价指标计算
PAN = Pan(:,:,1);
[Fu, Fstd, PSNR, RMSE, G, EN, Dk, SF, fp, ERGAS, H_MI, Qnmi, UIQI] = fusion_index(MS, PAN, Fusion);
UIQI_mean = (UIQI(1) + UIQI(2) + UIQI(3)) / 3;
qz = [RMSE(4) G(1,3) Dk(1,4) EN(1,3) max(ERGAS) SF(1,3) fp(1,4) UIQI_mean];

fprintf('\n========== IHS-小波融合算法评价指标 ==========\n');
fprintf('RMSE: %.4f\n梯度: %.4f\nTukeyΛ: %.4f\n信息熵: %.4f\nERGAS: %.4f\n空间频率: %.4f\n相关系数: %.4f\nUIQI: %.4f\n', qz);
fprintf('==========================================\n\n');
