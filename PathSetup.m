function PathSetup()

    % Set LFToolbox Path
    disp('Setting LFToolbox path');
    cd LFToolbox-master
    LFMatlabPathSetup
    cd ../..

    %% Set Project Pathes
    disp('Setting pathes of this project');
    path = fileparts(mfilename('fullpath'));

    addpath(path);

    addpath(fullfile(path,'Classes'));
    addpath(fullfile(path,'Scripts'));
end

