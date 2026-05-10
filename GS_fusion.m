% GS (Gram-Schmidt) 融合算法实现
% 方法说明：
% 1) 计算多光谱图像的亮度分量 I = (R+G+B)/3
% 2) 使用 Gram-Schmidt 风格的正交化：对每个波段计算 alpha = cov(band,I)/var(I)，并得到残差 s_band = band - alpha*I
% 3) 将全色图像 PAN 匹配到亮度分量的均值/方差（线性配准）：PAN_m = (PAN-mean(PAN))*(std(I)/std(PAN)) + mean(I)
% 4) 用 PAN_m 替换亮度分量，然后通过逆变换重建各波段：band_fused = s_band + alpha * PAN_m
% 该方法能较好地保留光谱信息的同时注入全色的空间细节

close all
clearvars -except -global
clc
addpath('evaluation\');

%% 读取图像
Pan = imread('20140714pan.tif');
MS  = imread('20140714ms.tif');

figure(1); imshow(Pan); title('PAN (全色)');
figure(2); imshow(MS);  title('MS (多光谱)');

% 转为double以便计算
Pan_d = double(Pan(:,:,1)); % PAN为灰度或单通道，这里取第一通道
MS_d  = double(MS);
[M, N, C] = size(MS_d);
if C < 3
    error('MS图像不是三波段图像，GS融合需要三通道多光谱图像');
end

% 如果PAN尺寸与MS不一致，则重采样PAN到MS尺寸
[Mp, Np, Cp] = size(Pan);
if Mp ~= M || Np ~= N
    Pan_d = imresize(Pan_d, [M, N], 'bilinear');
end

% 提取波段
R = MS_d(:,:,1);
G = MS_d(:,:,2);
B = MS_d(:,:,3);

%% 计算亮度分量 I
I = (R + G + B) / 3;

% 计算方差与协方差（用于alpha）
varI = var(I(:));
if varI == 0
    varI = eps;
end

alphaR = sum((R(:)-mean(R(:))).*(I(:)-mean(I(:)))) / (numel(I)-1) / varI;
alphaG = sum((G(:)-mean(G(:))).*(I(:)-mean(I(:)))) / (numel(I)-1) / varI;
alphaB = sum((B(:)-mean(B(:))).*(I(:)-mean(I(:)))) / (numel(I)-1) / varI;

% 计算残差分量 s_band
sR = R - alphaR .* I;
sG = G - alphaG .* I;
sB = B - alphaB .* I;

%% 将PAN匹配到I的统计量（均值/方差）
meanPAN = mean(Pan_d(:));
stdPAN  = std(Pan_d(:));
meanI   = mean(I(:));
stdI    = std(I(:));
if stdPAN == 0
    stdPAN = eps;
end
PAN_matched = (Pan_d - meanPAN) * (stdI / stdPAN) + meanI;

%% 用PAN_matched替换亮度分量，然后逆变换得到融合波段
R_fused = sR + alphaR .* PAN_matched;
G_fused = sG + alphaG .* PAN_matched;
B_fused = sB + alphaB .* PAN_matched;

% 剪裁并转换为uint8
R_fused = uint8(min(max(R_fused, 0), 255));
G_fused = uint8(min(max(G_fused, 0), 255));
B_fused = uint8(min(max(B_fused, 0), 255));

Fusion = cat(3, R_fused, G_fused, B_fused);

figure(3); imshow(Fusion); title('GS融合结果');
imwrite(Fusion, 'output\GS_fusion.jpg');

%% 评价指标
PAN_gray = Pan_d; % PAN灰度图
[Fu, Fstd, PSNR, RMSE, G, EN, Dk, SF, fp, ERGAS, H_MI, Qnmi, UIQI] = fusion_index(MS, PAN_gray, Fusion);
UIQI_mean = mean(UIQI(1:3));
qz = [RMSE(4), G(1,3), Dk(1,4), EN(1,3), max(ERGAS), SF(1,3), fp(1,4), UIQI_mean];

fprintf('\n========== GS (Gram-Schmidt) 融合评价指标 ==========\n');
fprintf('RMSE: %.4f  梯度: %.4f  Dk: %.4f  熵: %.4f  ERGAS: %.4f  SF: %.4f  相关: %.4f  UIQI: %.4f\n', qz);
fprintf('====================================================\n');
