% rgb2YIQ: 将RGB图像转换为YIQ颜色空间
% 输入：RGB - 原始RGB图像
% 输出：YIQ - 转换后的YIQ图像

function YIQ = rgb2YIQ(RGB)
    % 定义颜色变换矩阵
    transformMatrix = [
        0.299,  0.587,  0.114;
        0.595, -0.274, -0.321;
        0.211, -0.523,  0.312
    ];

    % 获取图像大小
    [M, N, C] = size(RGB);

    % 确保图像为三通道RGB
    assert(C == 3, '输入图像必须是3通道RGB图像');

    % 初始化YIQ图像矩阵
    YIQ = zeros(M, N, C);

    % 循环每个像素，逐个转换颜色
    for i = 1:M
        for j = 1:N
            YIQ(i, j, :) = transformMatrix * double(reshape(RGB(i, j, :), [3, 1]));
        end
    end
end