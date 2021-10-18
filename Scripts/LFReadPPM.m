function [LF, lf_name] = LFReadPPM()
    path = [uigetdir() '/'];
    lf_name = strsplit(path, {'/'});
    lf_name = cell2mat(lf_name(end - 1));
    disp(['LF: ' lf_name]);
    files = dir([path '*.ppm']);
    vals = strsplit(files(end).name, {'_', '.'});
    nviews = [str2double(vals(1, 1)), str2double(vals(1, 2))] + 1;
    u = nviews(1,1);
    v = nviews(1,2);
    disp(['nViews: ' num2str(nviews)]);
    index = 1;
    for i=1:u
        for j=1:v
            img = imread([path files(index).name]);
            index = index + 1;
            LF(i,j,:,:,1:3) = img;
        end                
    end
end

