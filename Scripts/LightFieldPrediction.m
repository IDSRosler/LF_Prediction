%% Ler Light Field no formato .ppm
[LF, lf_name] = LFReadPPM();
%% Criar um objeto de um Light Field 5D LF(x,y,s,t,c)
L = LightField(lf_name, LF, '', 'PPM', '444', 'rgb');
%% Teste
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
L.convert2ycbcr;

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

L.convert2rgb;
disp(' ');
disp('Showing the micro image at spacial position x=500 and y=180:');
disp('>> imshow(L.getMI(500,180));');
imshow(L.getMI(500,180));
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
imshow(L.get2dLf());
disp('In order to enhance visualization of micro images, zooming in is recommended.');
disp('...press enter to continue...');
pause;
close all;