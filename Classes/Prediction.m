classdef Prediction < handle
    %% Private Attributes  
    properties
        predictedLF; % Predicted Light Field
        predictedLFC; % Predicted Light Field into blocks 15x15
    end
  
    %% Public Methods and Constructor
    methods
        %Constructor
        function obj = Prediction(rows, columns, color)
            obj.predictedLF = zeros(rows, columns, color);
            
            blockSizeR = 15 * 15; % Linhas no bloco (15 MIs de 15 pixels cada)
            blockSizeC = 15 * 15; % Colunas no bloco (15 MIs de 15 pixels cada)
            
            wholeBlockRows = floor(rows / blockSizeR);
            blockR = [blockSizeR * ones(1, wholeBlockRows), rem(rows, blockSizeR)];

            wholeBlockCols = floor(columns / blockSizeC);
            blockC = [blockSizeC * ones(1, wholeBlockCols), rem(columns, blockSizeC)];

            obj.predictedLFC = mat2cell(obj.predictedLF, blockR, blockC, color); % Divide o LF em blocos 15x15
        end
        
        % Predict block
        function PredictBlock(obj, block, i, j)
            obj.predictedLFC{i,j} = block;
        end
        
        % Get predicted Light Field
        function LF = GetPredictedLF(obj)
           LF = cell2mat(obj.predictedLFC);
        end
    end
    
    %% Protected Methods
    methods (Access = protected)  
        % Get above reference
        function A = AboveReference(obj, i, j)
            if i-1 > 0
                A = obj.predictedLFC{i-1, j};
            else
                A = -1;
            end
        end
        
        % Get above-rigth reference
        function AR = AboveRightReference(obj, i, j)
            if i-1 > 0 && j+1 < size(obj.predictedLFC,2)
                AR = obj.predictedLFC{i-1, j+1};
            else
                AR = -1;
            end
        end
        
        % Get left reference
        function L = LeftReference(obj, i, j)
            if j-1 > 0
                L = obj.predictedLFC{i, j-1};
            else
                L = -1;
            end
        end
    end
end

