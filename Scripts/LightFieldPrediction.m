%% Criar um objeto de um Light Field 5D LF(s,t,x,y,c)
lf_path = '/home/idsrosler/Documentos/git/CTC_Datasets/Lenslets/Bikes/Bikes/';
L = LightField(lf_path);

%% Light Field Prediction
clc; close all;

% disp('Exibindo LF no seu formaro Lenslet: ');
lenslet = L.getLensletFormat;
% imshow(lenslet);
% disp('...press enter to continue...');
% pause;
% close all;

[rows, columns, c] = size(lenslet);

blockSizeR = 15 * 15; % Linhas no bloco (15 MIs de 15 pixels cada)
blockSizeC = 15 * 15; % Colunas no bloco (15 MIs de 15 pixels cada)

wholeBlockRows = floor(rows / blockSizeR);
blockVectorR = [blockSizeR * ones(1, wholeBlockRows), rem(rows, blockSizeR)];
 
wholeBlockCols = floor(columns / blockSizeC);
blockVectorC = [blockSizeC * ones(1, wholeBlockCols), rem(columns, blockSizeC)];

ca = mat2cell(lenslet, blockVectorR, blockVectorC, c); % Divide o LF em blocos 15x15

blockA = ca{1,2};
blockAR = ca{1,3};
blockL = ca{2,1};

block = zeros(15*15, 15*15);

figure('NumberTitle','on');
figure(1); 
subplot(2,3,2); imshow(blockA); title('Above');
subplot(2,3,3); imshow(blockAR); title('Above-Rigth');
subplot(2,3,4); imshow(blockL); title('Left');
subplot(2,3,5); imshow(block); title('Block to be predict');

figure('NumberTitle','on');
figure(2);
imshow(blockA(end-15:end,:,:)); title('Above Last Row');

figure('NumberTitle','on');
figure(3);
imshow(blockL(:,end-15:end,:)); title('Left Last Column');