classdef Prediction < handle
    %% Private Attributes  
    properties
        predictedLF; % Predicted Light Field
        predictedLFC; % Predicted Light Field into blocks 15x15
        mode; % predict mode used to block (0:vertical|1:horizontal|2:DC|-1:block-copy)
    end
  
    %% Public Methods and Constructor
    methods
        %Constructor
        function obj = Prediction(rows, columns, color, blockSizeR, blockSizeC)
            obj.predictedLF = uint16(zeros(rows, columns, color));
            
            wholeBlockRows = floor(rows / blockSizeR);
            blockR = [blockSizeR * ones(1, wholeBlockRows), rem(rows, blockSizeR)];

            wholeBlockCols = floor(columns / blockSizeC);
            blockC = [blockSizeC * ones(1, wholeBlockCols), rem(columns, blockSizeC)];

            obj.predictedLFC = mat2cell(obj.predictedLF, blockR, blockC, color); % Divide o LF em blocos 15x15
        end
        
        % Predict block
        function [blockMSE, predMode] = PredictBlock(obj, block, i, j)
            mseBlock = 99999999999999999999;
            if i == 1 || j == 1
                blockP = block; 
                mse = MSE(block, blockP);
                if mse < mseBlock
                   mseBlock = mse;
                   obj.mode = -1;
                end
            else
                refA = obj.AboveReference(i,j);
                refL = obj.LeftReference(i,j);
                
                for m = 0:2
                   switch m
                       case 0
                           if refA ~= -1
                             blockP = obj.VerticalPrediction(refA, i, j); % vertical mode
                           end
                       case 1
                           if refL ~= -1
                             blockP = obj.HorizontalPrediction(refL, i, j); % horizontal mode
                           end
                       case 2
                           if refA ~= -1
                               if refL ~= -1
                                 blockP = obj.DCPrediction(refA, refL, i, j); % DC mode
                               end
                           end
                   end
                   mse = MSE(block, blockP);
                    if mse < mseBlock
                       mseBlock = mse;
                       obj.mode = m;
                    end
                end
                
                switch obj.mode
                   case 0
                       blockP = obj.VerticalPrediction(refA, i, j); % vertical mode
                   case 1
                       blockP = obj.HorizontalPrediction(refL, i, j); % horizontal mode
                   case 2
                       blockP = obj.DCPrediction(refA, refL, i, j); % DC mode
                end
            end
            obj.predictedLFC{i,j} = blockP;
            blockMSE = mseBlock;
            predMode = obj.mode;
        end
        
        % Get predicted Light Field
        function LF = GetPredictedLF(obj)
           LF = cell2mat(obj.predictedLFC);
        end
    end
    
    %% Protected Methods
    methods (Access = protected)  
        %% Reference Geters
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
        %% Predictors      
        % Vertical prediction
        function block = VerticalPrediction(obj, refA, i, j)
            row_MI = refA(end-14:end, :, :);
            x = floor(size(obj.predictedLFC{i,j}, 1)/15);
            block = repmat(row_MI, [x, 1]); % replica a matriz de MIs no bloco a ser predito
        end
        
        % Horizontal prediction
        function block = HorizontalPrediction(obj, refL, i, j)
            col_MI = refL(:,end-14:end, :);
            y = floor(size(obj.predictedLFC{i,j}, 2)/15);
            block = repmat(col_MI, [1, y]); % replica a matriz de MIs no bloco a ser predito
        end
        
        % DC prediction
        function block = DCPrediction(obj, refA, refL, i, j)
            row_MI = refA(end-14:end, :, :);
            col_MI = refL(:,end-14:end, :);
            col_MI = permute(col_MI, [2, 1, 3]); % transforma uma coluna de MIs em uma linhas de MIs
            ry  = size(row_MI, 2);
            cx = size(col_MI, 2);
            if ry < cx % verifica se a referência de cima é menor que a referência a esquerda para poder calcular a média e não ocorrer problemas de indexação
                me = floor((row_MI + col_MI(:, 1:ry, :))./2);
            elseif ry > cx % verifica se a referência de cima é maior que a referência a esquerda para poder calcular a média e não ocorrer problemas de indexação
                me = uint16(zeros(15, ry, 3));
                me(:, 1:cx, :) = floor((row_MI(:, 1:cx, :) + col_MI)./2);
                me(:, cx+1:ry, :) = row_MI(:, cx+1:ry, :);
            else
                me = floor((row_MI + col_MI)./2);
            end
            x = floor(size(obj.predictedLFC{i,j}, 1)/15);
            block = repmat(me, [x, 1]); % replica a matriz de MIs no bloco a ser predito
        end
    end
end

