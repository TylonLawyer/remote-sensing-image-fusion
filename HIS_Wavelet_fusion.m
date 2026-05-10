% HIS色彩空间与小波融合算法
% 功能：HIS转换与小波融合，用于遥感图像融合
close all
clear all
clc
addpath('evaluation\');

%% 读取图像
Pan = imread('20140714pan.tif');            % 读取全色图像
MS = imread('20140714ms.tif');             % 读取多光谱图像

figure(1)
imshow(Pan);
title('HIS-小波融合：全色图像');

figure(2)
imshow(MS);
title('HIS-小波融合：多光谱图像');

%% RGB转HIS空间
MS_double = double(MS);
Pan_double = double(Pan);
[M, N, ~] = size(MS);
HIS = rgb2his(MS_double);  % 色度、亮度与饱和度分量

H = HIS(:,:,1);
I = HIS(:,:,2);
S = HIS(:,:,3);

%% 对亮度分量与全色波段进行小波分解
wname = 'db4';
[cA_Pan, cH_Pan, cV_Pan, cD_Pan] = dwt2(Pan_double, wname);
[cA_I, cH_I, cV_I, cD_I] = dwt2(I, wname);

%% 融合小波系数
alpha = 0.5;
coef_A = alpha * cA_Pan + (1-alpha) * cA_I;
coef_H = (cH_Pan + cH_I) / 2;
coef_V = (cV_Pan + cV_I) / 2;
coef_D = (cD_Pan + cD_I) / 2;

% 小波重构
I_Fused = idwt2(coef_A, coef_H, coef_V, coef_D, wname);

% 替换亮度分量
HIS(:,:,2) = I_Fused;
Fusion = his2rgb(HIS); % HIS转回RGB
Fusion = uint8(max(min(Fusion, 255), 0));

figure(3)
imshow(Fusion);
title('HIS-小波融合结果');
imwrite(Fusion, 'output\HIS_Wavelet_fusion.jpg');

%% 评价指标计算
PAN = Pan(:,:,1);
[Fu, Fstd, PSNR, RMSE, G, EN, Dk, SF, fp, ERGAS, H_MI, Qnmi, UIQI] = fusion_index(MS, PAN, Fusion);
UIQI_mean = (UIQI(1) + UIQI(2) + UIQI(3)) / 3;
qz = [RMSE(4) G(1,3) Dk(1,4) EN(1,3) max(ERGAS) SF(1,3) fp(1,4) UIQI_mean];

fprintf('\n========== HIS-小波融合算法评价指标 ==========\n');
fprintf('RMSE: %.4f\n梯度: %.4f\nTukeyΛ: %.4f\n信息熵: %.4f\nERGAS: %.4f\n空间频率: %.4f\n相关系数: %.4f\nUIQI: %.4f\n', qz);
fprintf('==========================================\n\n');