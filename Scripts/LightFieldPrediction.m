%% Criar um objeto de um Light Field 5D LF(s,t,x,y,c)
lf_path = '/home/idsrosler/Documentos/git/CTC_Datasets/Lenslets/Bikes/Bikes/';
L = LightField(lf_path);

%% Light Field Prediction
clc; close all;

lenslet = L.getLensletFormat;
[rows, columns, c] = size(lenslet);

prediction = Prediction(rows, columns, c);

blockSizeR = 15 * 15; % Linhas no bloco (15 MIs de 15 pixels cada)
blockSizeC = 15 * 15; % Colunas no bloco (15 MIs de 15 pixels cada)

wholeBlockRows = floor(rows / blockSizeR);
blockR = [blockSizeR * ones(1, wholeBlockRows), rem(rows, blockSizeR)];
 
wholeBlockCols = floor(columns / blockSizeC);
blockC = [blockSizeC * ones(1, wholeBlockCols), rem(columns, blockSizeC)];

ca = mat2cell(lenslet, blockR, blockC, c); % Divide o LF em blocos 15x15
[r, c] = size(ca);

for i = 1:r
    for j = 1:c
        block = ca{i,j};
        prediction.PredictBlock(block, i, j);
        disp(strcat('block = {x: ', int2str(i), ', y: ', int2str(j),'}'));
    end
end

predictedLF = prediction.GetPredictedLF();

[y_psnr, u_psnr, v_psnr, yuv_psnr] = PSNR(lenslet, predictedLF, L.bitDepth);

disp(' ');
disp('******************************');
disp('Métricas de qualidade');
disp('******************************');
disp(strcat('Y_PSNR: ', num2str(y_psnr)));
disp(strcat('U_PSNR: ', num2str(u_psnr)));
disp(strcat('V_PSNR: ', num2str(v_psnr)));
disp(strcat('YUV_PSNR: ', num2str(yuv_psnr)));

% figure(1); imshow(lenslet); title('Original LF');
% figure(2); imshow(predictedLF); title('Predicted LF');
