% Wavelet融合算法
% 功能：基于小波变换进行图像融合，处理全色图像和多光谱图像
close all
clear all
clc
addpath('evaluation\');

%% 读取图像
Pan = imread('20140714pan.tif');           % 全色图像
MS = imread('20140714ms.tif');            % 多光谱图像

figure(1)
imshow(Pan);
title('Wavelet融合：全色图像');

figure(2)
imshow(MS);
title('Wavelet融合：多光谱图像');

%% 小波变换
MS_double = double(MS);
Pan_double = double(Pan);
[M, N, ~] = size(MS_double);

wtype = 'db4';   % 小波基类型
decLevel = 1;    % 分解层数

% 对全色图像和多光谱分量分别进行分解
[cA_Pan, cH_Pan, cV_Pan, cD_Pan] = dwt2(Pan_double, wtype);
[cA_MS_R, cH_MS_R, cV_MS_R, cD_MS_R] = dwt2(MS_double(:,:,1), wtype);
[cA_MS_G, cH_MS_G, cV_MS_G, cD_MS_G] = dwt2(MS_double(:,:,2), wtype);
[cA_MS_B, cH_MS_B, cV_MS_B, cD_MS_B] = dwt2(MS_double(:,:,3), wtype);

%% 融合小波系数
alpha = 0.75;  % 融合系数

fused_cA = alpha * cA_Pan + (1-alpha) * ((cA_MS_R + cA_MS_G + cA_MS_B) / 3);
fused_cH = (cH_Pan + cH_MS_R + cH_MS_G + cH_MS_B) / 4;
fused_cV = (cV_Pan + cV_MS_R + cV_MS_G + cV_MS_B) / 4;
fused_cD = (cD_Pan + cD_MS_R + cD_MS_G + cD_MS_B) / 4;

%% 重构融合图像
Fusion_R = idwt2(fused_cA, fused_cH, fused_cV, fused_cD, wtype);
Fusion_G = idwt2(fused_cA, fused_cH, fused_cV, fused_cD, wtype);
Fusion_B = idwt2(fused_cA, fused_cH, fused_cV, fused_cD, wtype);

Fusion = cat(3, Fusion_R, Fusion_G, Fusion_B);
Fusion = uint8(Fusion(1:M, 1:N, :));  % 确保尺寸一致

figure(3)
imshow(Fusion);
title('Wavelet融合结果');
imwrite(Fusion, 'output\Wavelet_fusion.jpg');

%% 评价指标计算
PAN = Pan(:,:,1);
[Fu, Fstd, PSNR, RMSE, G, EN, Dk, SF, fp, ERGAS, H_MI, Qnmi, UIQI] = fusion_index(MS, PAN, Fusion);
UIQI_mean = (UIQI(1) + UIQI(2) + UIQI(3)) / 3;
qz = [RMSE(4) G(1,3) Dk(1,4) EN(1,3) max(ERGAS) SF(1,3) fp(1,4) UIQI_mean];

fprintf('\n========== Wavelet融合算法评价指标 ==========\n');
fprintf('RMSE: %.4f\n梯度: %.4f\nTukeyΛ: %.4f\n信息熵: %.4f\nERGAS: %.4f\n空间频率: %.4f\n相关系数: %.4f\nUIQI: %.4f\n', qz);
fprintf('==========================================\n\n');