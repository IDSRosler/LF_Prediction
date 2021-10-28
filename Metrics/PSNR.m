function [Y_PSNR, U_PSNR, V_PSNR, YUV_PSNR]= PSNR(ref,rec,n)

    ref_YCbCr = rgb2ycbcr(ref);
    rec_YCbCr = rgb2ycbcr(rec);

    Y1 = ref_YCbCr(:,:,1);
    U1 = ref_YCbCr(:,:,2);
    V1 = ref_YCbCr(:,:,3);
    
    Y2 = rec_YCbCr(:,:,1);
    U2 = rec_YCbCr(:,:,2);
    V2 = rec_YCbCr(:,:,3);
    
    % Objective metrics
    Y_MSE = MSE(Y1,Y2);
    U_MSE = MSE(U1,U2);
    V_MSE = MSE(V1,V2);

    Y_PSNR  = 10*log10((2^n-1)*(2^n-1)/Y_MSE);
    U_PSNR  = 10*log10((2^n-1)*(2^n-1)/U_MSE);
    V_PSNR  = 10*log10((2^n-1)*(2^n-1)/V_MSE);

    YUV_PSNR = (6*Y_PSNR+U_PSNR+V_PSNR)/8;
end