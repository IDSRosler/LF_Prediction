classdef LightField < handle
    %% Private Attributes      
    properties (GetAccess = public, SetAccess = private)
        name; %Light field name
        
        matrix5d; %5D Matrix (s,r,y,x,c) containing visual information. (r,s): angular dimensions (x,y): spatial dimensions c: color channel
        decodeOptions; %Decode Options given by LFToolbox
        modified; %Indicates if the LightField suffered any modification (subsampling, color space conversion, etc.)
        
        lfType; %Type of the Light Field: 'STANFORD' (matrix of cameras), or 'DEC' (Decoded .mat File)
        subSampling; %Color subsampling: '444' (either 'rgb' or 'ycbcr') or '420' (only for 'ycbcr')
                
        colorSpace; %Indicates the LF color space: 'rgb' or 'ycbcr'
        bitDepth; %Data bitdepth ('8', '10', '16' or '64' bits)
        dataType; %Type of matrix5d ('uint8', 'uint16' or 'double')
        
        viewWidth; %Number of horizontal samples per view (SAI)
        viewHeight; %Number of vertical samples per view (SAI)
        numHorViews; %Number of horizontal views (horizontal angular dimension)
        numVerViews; %Number of vertical views (vertical angular dimension)
        
        chViewWidth; %Number of horizontal chroma samples per view (SAI)
        chViewHeight; %Number of vertical chroma samples per view (SAI)
    end
    
    properties (GetAccess = private, SetAccess = private)
        weightChannel; %Weight channel        
    end
    
    %% Public Methods and Constructor
    methods
        % Constructor
        function obj = LightField(path)
            if nargin == 1
                obj.setNameFromPath(path);
                obj.openPPMFile(path);
            else
                p = [uigetdir() '/'];
                obj.setNameFromPath(p);
                obj.openPPMFile(p);
            end
            obj.decodeOptions = '';
            obj.modified = false;
            obj.lfType = 'PPM'; 
            obj.subSampling = '444';
            obj.colorSpace = 'rgb';
            obj.setAuxAttribute();                 
        end
        
        %% Conversors        
        %Converts the LightField to YCbCr Space
        function convertToYCbCr(obj)
            if (strcmp(obj.colorSpace,'ycbcr'))
               return;
            else
                for i=1:obj.numVerViews
                    for j=1:obj.numHorViews
                        RGB = squeeze(obj.matrix5d(i,j,:,:,1:3));
                        YUV = rgb2ycbcr(RGB);
                        obj.matrix5d(i,j,:,:,1:3) = YUV;
                    end
                end
            end
            obj.colorSpace = 'ycbcr';
            obj.modified = true;
            obj.setAuxAttribute();
        end
        
        %Converts the LightField to RGB Space
        function convertToRGB(obj)
            if (strcmp(obj.colorSpace,'rgb'))
               return;
            elseif (~strcmp(obj.subSampling,'444'))
                baseException = MException('LFConvrt:SubSamRGBLF','Trying to convert to RGB a non 4:4:4 YCbCr LightField');
                throw(baseException);
            else
                for i=1:obj.numVerViews
                    for j=1:obj.numHorViews
                        YUV = squeeze(obj.matrix5d(i,j,:,:,1:3));
                        RGB = ycbcr2rgb(YUV);
                        obj.matrix5d(i,j,:,:,1:3) = RGB;
                    end
                end
            end
            obj.colorSpace = 'rgb';
            obj.modified = true;
            obj.setAuxAttribute();
        end
                       
        %SubSample LightField (444->420) Only YCbCr space!
        function subSamp(obj)
           if (~strcmp(obj.colorSpace,'ycbcr')) 
               baseException = MException('LFType:SubSamRGBLF','Trying to subsample a not YCbCr LightField');
               throw(baseException);
           end
           
           if (~strcmp(obj.subSampling,'444'))
              disp('WARNING: LightField was not down sampled!')
              return; 
           end
           
           obj.matrix5d(:,:,1:ceil(obj.viewHeight/2),1:ceil(obj.viewWidth/2),2:3) = obj.matrix5d(:,:,1:2:end,1:2:end,2:3);
           
           obj.matrix5d(:,:,ceil(obj.viewHeight/2)+1:end,1:end,2:3) = 0;
           obj.matrix5d(:,:,1:ceil(obj.viewHeight/2),ceil(obj.viewWidth/2)+1:end,2:3) = 0;           
           
           obj.subSampling = '420';
           obj.modified = true;
           obj.setAuxAttribute();        
        end
        
        %UpSample LightField (420->444)
        function upSamp(obj)
            if ~strcmp(obj.subSampling , '420') || ~strcmp(obj.colorSpace , 'ycbcr')
               disp('WARNING: LightField was not up sampled!')
                return ; 
            end
            
            for i=1:obj.numVerViews
               for j=1:obj.numHorViews
                   
                   [U,V] = obj.getUpSampledChromaChannels(i,j);
                   obj.matrix5d(i,j,:,:,2) = U;
                   obj.matrix5d(i,j,:,:,3) = V;
                   
               end
            end
            obj.subSampling = '444';     
            obj.modified = true;
        end
        
        %Removes chroma information (If LightField is represented in RGB sapce, it is converted to YCbCr)
        function removeChroma(obj)
           if (strcmp(obj.colorSpace,'rgb')) 
               obj.convertToYCbCr();
           end
           
           obj.matrix5d = obj.matrix5d(:,:,:,:,1);
           obj.subSampling = '400';
           obj.modified = true; 
           obj.chViewWidth = 0;
           obj.chViewHeight = 0;
        end
        
        %Converts the Light Field to 8-bit
        function clip2uint8(obj)
            if obj.bitDepth==8
               return;
            elseif obj.bitDepth==10
                obj.matrix5d = uint8(obj.matrix5d/4);
                obj.weightChannel = uint8(obj.weightChannel/4);                
            elseif obj.bitDepth==16
                obj.matrix5d = uint8(obj.matrix5d/256);
                obj.weightChannel = uint8(obj.weightChannel/256);   
            end
            obj.modified = true;
            obj.setAuxAttribute();
        end

        
        
        %% Light Field Projections Getters
        %Returns a given SAI/View
        function I = getView(obj,i,j,colorSpace)
            if (nargin == 3)
                I = obj.getSai(i,j) ;                
            elseif nargin == 4
                I = obj.getSai(i,j,colorSpace);
            end           
        end
        
        %Returns a given SAI/View (s,r,colorSpace)
        function I = getSai(obj,i,j,colorSpace)            
            I = squeeze(obj.matrix5d(i,j,:,:,:));                
            if (nargin == 4)
                if ~strcmp(obj.colorSpace,colorSpace)
                    if strcmp(colorSpace,'rgb')
                        if strcmp(obj.subSampling,'420')                           
                           [U,V] = obj.getUpSampledChromaChannels(i,j);
                           I(:,:,2) = U;
                           I(:,:,3) = V;                           
                        elseif strcmp(obj.subSampling,'400')
                           I(:,:,2:3)  = obj.castTypeLightField(ceil((2^obj.bitDepth)/2));
                        end
                        I = ycbcr2rgb(I);
                    elseif strcmp(colorSpace,'ycbcr')
                        I = rgb2ycbcr(I);
                    end
                end
            end               
           
        end      
        
        %Returns the center given SAI/View (colorSpace) 
        function I = getCenterSai(obj,colorSpace)                       
           i = ceil((1 + obj.numVerViews)/2);
           j = ceil((1 + obj.numHorViews)/2);
           
           if nargin==1
               I = squeeze(obj.matrix5d(i,j,:,:,:));
           else
               I = getSai(obj,i,j,colorSpace);
           end
        end        
        
        %Returns the luma channel of a given sub-aperture image (view). Converts to YCbCr is necessary
        function I = getSaiLuma(obj,i,j)            
            if strcmp(obj.colorSpace,'rgb')
                RGB = squeeze(obj.matrix5d(i,j,:,:,:));
                YUV = rgb2ycbcr(RGB);
                I = YUV(:,:,1);
            elseif strcmp(obj.colorSpace,'ycbcr')
                I = squeeze(obj.matrix5d(i,j,:,:,1));
            else
                baseException = MException('LFClrSpc:Uknwn',['Unknown LightField Color Space ' obj.colorSpace]);
                throw(baseException);
            end
        end
        
        %Returns the luma channel of the central sub-aperture image (view). Converts to YCbCr is necessary
        function I = getCenterSaiLuma(obj)
            i = ceil((1 + obj.numVerViews)/2);
            j = ceil((1 + obj.numHorViews)/2);
            I = obj.getSaiLuma(i,j);
        end
        
        %Returns a given Micro Image (x,y,c)
        function I = getMicroImageXY(obj,x,y,colorSpace)
            if nargin == 3
                I = squeeze(obj.matrix5d(:,:,y,x,:));
            elseif strcmp(colorSpace,obj.colorSpace)
                I = squeeze(obj.matrix5d(:,:,y,x,:));
            elseif strcmp(colorSpace,'rgb')
                Ia = squeeze(obj.matrix5d(:,:,y,x,:));
                I = ycbcr2rgb(Ia);
            elseif strcmp(colorSpace,'ycbcr')
                Ia = squeeze(obj.matrix5d(:,:,y,x,:));
                I = rgb2ycbcr(Ia);
            else
                error(['Undefined colorSpace ' colorSpace]);
            end                                
        end     
        
        %Returns the luma channel of a given Micro Image (x,y)
        function I = getMILuma(obj,x,y)
           Ia = getMicroImageXY(obj,x,y);
           if strcmp(obj.colorSpace,'ycbcr')
               I = squeeze(Ia(:,:,1));
           elseif strcmp(obj.colorSpace,'rgb')
               Ia = rgb2ycbcr(Ia);
               I = squeeze(Ia(:,:,1));
           end
        end
        
        %Returns an Image that groups Micro-Images side-by-side. 2D representation of the Light Field
        function I = getMatrixMicroImage(obj)
            I = obj.castTypeLightField(zeros(obj.viewHeight*obj.numVerViews,obj.viewWidth*obj.numHorViews,3));            
            for i=1:obj.numVerViews
               for j=1:obj.numHorViews
                  I(i:obj.numVerViews:end,j:obj.numHorViews:end,:) = obj.matrix5d(i,j,:,:,:);
               end
            end
        end
        
        %Returns (Center, or not) Sai Marked with straight lines at positions x,y
        function I = getCenterSaiMarked(obj,x,y,colorSpace)
            if nargin == 3
                I = obj.getCenterSai();           
                I = obj.getSaiMarked(I,x,y);
            else
                I = obj.getCenterSai(colorSpace);           
                I = obj.getSaiMarked(I,x,y,colorSpace);
            end   
        end
        
        %Returns a given Sai Marked with straight lines at positions x,y (s,r,x,y,c)
        function I = getSaiMarked(obj,i,j,x,y,colorSpace)
           if nargin==4
               I = i;
               y = x;
               x = j;   
               colorSpace = obj.colorSpace;
           elseif nargin == 5
               I = obj.getSai(i,j);               
               colorSpace = obj.colorSpace;
           elseif nargin == 6
               I = obj.getSai(i,j,colorSpace);               
           else
               error('Function getSaiMarked is defined only to 3, 4 or 5 input arguments.')
           end
                                
           I(y,:,1) = obj.castTypeLightField(2^obj.bitDepth - 1);
           I(:,x,1) = obj.castTypeLightField(2^obj.bitDepth - 1);
           
           if strcmp(colorSpace , 'ycbcr')
               if strcmp(colorSpace , '400')                              
                   return;
               else
                    I(y,:,2:3) = obj.castTypeLightField(ceil((2^obj.bitDepth - 1)/2));
                    I(:,x,2:3) = obj.castTypeLightField(ceil((2^obj.bitDepth - 1)/2));
               end
           elseif strcmp(colorSpace , 'rgb')
               I(y,:,2:3) = obj.castTypeLightField(2^obj.bitDepth - 1);
               I(:,x,2:3) = obj.castTypeLightField(2^obj.bitDepth - 1);
           else
               baseException = MException('LFClrSpc:Uknwn',['Unknown LightField Color Space ' obj.colorSpace]);
               throw(baseException);
           end              
           
        end
        
        %Returns (Center, or not) Sai (Luma Only) Marked with straight lines at positions x,y
        function I = getSaiMarkedLuma(obj,i,j,x,y)
           I = obj.getSaiLuma(i,j);
           
           I(y,:,1) = obj.castTypeLightField(2^obj.bitDepth - 1);
           I(:,x,1) = obj.castTypeLightField(2^obj.bitDepth - 1);
        end     
        
        %Returns the center Sai Marked (luma channel only) with straight lines at positions x,y (s,r,x,y)
        function I = getCenterSaiMarkedLuma(obj,x,y)
           I = obj.getCenterSaiLuma();
           
           I(y,:,1) = obj.castTypeLightField(2^obj.bitDepth - 1);
           I(:,x,1) = obj.castTypeLightField(2^obj.bitDepth - 1);
           
        end
    end
    
    %% Protected Methods
    methods (Access = protected)        
      
        %Make Light Field object by PPM files
        function openPPMFile(obj, path)
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
            obj.matrix5d = LF;
        end
        
        %Define Auxilar Attributes of Light Field
        function setAuxAttribute(obj)            
            obj.viewWidth = size(obj.matrix5d,4);
            obj.viewHeight = size(obj.matrix5d,3);
            obj.numHorViews = size(obj.matrix5d,2);
            obj.numVerViews = size(obj.matrix5d,1);
            
            if strcmp(obj.colorSpace,'rgb')
                obj.chViewWidth = -1;
                obj.chViewHeight = -1;            
            elseif strcmp(obj.colorSpace , 'ycbcr')
                if strcmp(obj.subSampling , '444')
                    obj.chViewWidth = obj.viewWidth;
                    obj.chViewHeight = obj.viewHeight;  
                elseif strcmp(obj.subSampling,'420')
                    obj.chViewWidth = ceil(obj.viewWidth/2);
                    obj.chViewHeight = ceil(obj.viewHeight/2);
                elseif strcmp(obj.subSampling,'400')
                    obj.chViewWidth = 0;
                    obj.chViewHeight = 0;                
                end
            end
            
            obj.dataType = class(obj.matrix5d);
            
            maxSample = max(obj.matrix5d(:));
            if strcmp(obj.dataType,'uint8')
                obj.bitDepth = 8;
            elseif strcmp(obj.dataType,'uint16') && maxSample <= 2^10
                obj.bitDepth = 10;
            elseif strcmp(obj.dataType,'uint16') && maxSample <= 2^16
                obj.bitDepth = 16;
            elseif strcmp(obj.dataType,'double') && maxSample <= 1
                obj.bitDepth = 64;
            else
                baseException = MException('LFDtType:UknwLFDataType',['Unknown Data of LightField Type ' class(obj.matrix5d)]);
                throw(baseException);
            end            
        end
        
        %Get U and V upsampled channels of the subsampled LightField (s,r)
        function [U,V] = getUpSampledChromaChannels(obj,i,j)            
            xOff = mod(obj.viewWidth,2);
            yOff = mod(obj.viewHeight,2);
            U = obj.castTypeLightField(zeros(obj.viewHeight+yOff,obj.viewWidth+xOff));
            V = obj.castTypeLightField(zeros(obj.viewHeight+yOff,obj.viewWidth+xOff));
                   
            U(1:2:end,1:2:end) = obj.matrix5d(i,j,1:obj.chViewHeight,1:obj.chViewWidth,2);
            V(1:2:end,1:2:end) = obj.matrix5d(i,j,1:obj.chViewHeight,1:obj.chViewWidth,3);
                   
            U(2:2:end,1:2:end) = obj.matrix5d(i,j,1:obj.chViewHeight,1:obj.chViewWidth,2);
            V(2:2:end,1:2:end) = obj.matrix5d(i,j,1:obj.chViewHeight,1:obj.chViewWidth,3);
                   
            U(1:2:end,2:2:end) = obj.matrix5d(i,j,1:obj.chViewHeight,1:obj.chViewWidth,2);
            V(1:2:end,2:2:end) = obj.matrix5d(i,j,1:obj.chViewHeight,1:obj.chViewWidth,3);
                   
            U(2:2:end,2:2:end) = obj.matrix5d(i,j,1:obj.chViewHeight,1:obj.chViewWidth,2);
            V(2:2:end,2:2:end) = obj.matrix5d(i,j,1:obj.chViewHeight,1:obj.chViewWidth,3);
            
            U = U(1:obj.viewHeight,1:obj.viewWidth);
            V = V(1:obj.viewHeight,1:obj.viewWidth);
        end
        
        %Returns applies a cast in matrix I according to the object data type, and returns the O matrix
        function O = castTypeLightField(obj,I)
            if strcmp(obj.dataType,'uint8') && obj.bitDepth == 8
                O = uint8(I);
            elseif strcmp(obj.dataType,'uint16') && (obj.bitDepth == 10 || obj.bitDepth == 16)
                O = uint16(I);
            elseif strcmp(obj.dataType,'double') && obj.bitDepth == 64
                O = double(I);
            else
                baseException = MException('LFDtType:UknwLFDataType',['Unknown Data of LightField Type ' class(obj.matrix5d)]);
                throw(baseException);
            end
        end      
        
        %Set the name of the light field according to the file name
        function setNameFromPath(obj,path)
            C = strsplit(path,{'/','\'});
            obj.name = C{end}(1:end-4);            
            obj.name = strrep(obj.name,'&','n');
        end
                
    end
    
    
    %% Static Method
    methods (Static)        
              
    end
end

