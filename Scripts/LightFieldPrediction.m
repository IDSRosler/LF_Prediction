%% Criar um objeto de um Light Field 5D LF(s,t,x,y,c)
lf_path = '/home/idsrosler/Documentos/git/CTC_Datasets/Lenslets/Bikes/Bikes/';
L = LightField(lf_path);

%% Light Field Prediction
clc; close all;
disp(' ');
disp('Showing the center sub-aperture image (SAI/View):');
disp('>> imshow(L.getCenterSai());');
imshow(L.getCenterSai());
disp('...press enter to continue...');
pause;
close all;

disp(' ');
disp('Converting the LightField to YCbCr color space:');
disp('>> L.convert2ycbcr;');
L.convertToYCbCr;

disp(' ');
disp('Showing the center sub-aperture image (SAI/View):');
disp('>> imshow(L.getCenterSai());');
imshow(L.getCenterSai());
pause;
close all;

disp(' ');
disp('Showing the center sub-aperture image (SAI/View) in RGB space without converting it back:');
disp('>> imshow(L.getCenterSai(''rgb''));');
imshow(L.getCenterSai('rgb'));
disp('...press enter to continue...');
pause;
close all;

L.convertToRGB;
disp(' ');
disp('Showing the micro image at spacial position x=500 and y=180:');
disp('>> imshow(L.getMI(500,180));');
imshow(L.getMicroImageXY(500,180));
disp('...press enter to continue...');
pause;
figure;

disp(' ');
disp('To identify the position (500,180) at the LightField');
disp('>> imshow(L.getCenterSaiMarked(500,180));');
imshow(L.getCenterSaiMarked(500,180));
disp('...press enter to continue...');
pause;
close all;

disp(' ');
disp('It is also possible to see the LightField as a 2D matrix of micro images:');
disp('>> imshow(L.get2dLf();');
imshow(L.getMatrixMicroImage());
disp('In order to enhance visualization of micro images, zooming in is recommended.');
disp('...press enter to continue...');
pause;
close all;