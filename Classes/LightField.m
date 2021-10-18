classdef LightField < handle
    % This class contains a set of attributes and methods in the
    % endeavor to facilitate light fields handling targeting encoding
    % applications
    
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
        
        %% Constructor
        function obj = LightField(arg1,arg2,arg3,arg4,arg5,arg6)
            %Light Field Constructor (from 1 up to 6 arguments) (click to see more)
            %If nargin == 1
                %Arg1 must be an LightField object
            %If nargin == 2
                %Arg1 is the path of the to-be-opened LightField 
                %Arg2 is the Light Field type
            %If nargin == 3
                %Arg1 is the path of the to-be-opened LightField 
                %Arg2 is the Light Field type
                %Arg3 is the opening options
            %If nargin == 6
                %Arg1 is the LF name
                %Arg2 is the matrix5d
                %Arg3 is the decoded options
                %Arg4 is the LF type'
                %Arg5 is the sub-sampling information
                %Arg6 is color space
            
                        
            if (nargin == 1 || (strcmp(arg2,'none') && strcmp(arg3,'none'))) %Checks if the LightField has been created from other LightField
               if (isa(arg1,'LightField')) 
                   obj.matrix5d = arg1.matrix5d; 
                   obj.decodeOptions = arg1.decodeOptions; 
                   obj.modified = arg1.modified; 

                   obj.lfType = arg1.lfType; 
                   obj.subSampling = arg1.subSampling; 

                   obj.colorSpace = arg1.colorSpace; 
                   obj.bitDepth = arg1.bitDepth; 
                   obj.dataType = arg1.dataType; 

                   obj.viewWidth = arg1.viewWidth;
                   obj.viewHeight = arg1.viewHeight;
                   obj.numHorViews = arg1.numHorViews;
                   obj.numVerViews = arg1.numVerViews;

                   obj.chViewWidth = arg1.chViewWidth;
                   obj.chViewHeight = arg1.chViewHeight;   
                   
                   obj.weightChannel = arg1.getWeightChannel();
                   obj.name = arg1.name;
               else
                   baseException = MException('LFConst:Argin','For one parameter, LightField constructor must receive an LightField object');
                   throw(baseException);
               end
               
            elseif (nargin < 6)
                if (nargin < 3)
                    arg3 = 'none';
                end

                switch arg2
                    case 'STANFORD'
                        obj.openStanford(arg1); 
                    case 'DEC'
                        obj.openDecFile(arg1);
                    case 'TGEORGIEV'
                        obj.openTGFile(arg1); 
                    case 'none'

                    otherwise
                        baseException = MException('LFConst:UknwLFType',['Unknown LightField Type ' arg2]);
                        throw(baseException);
                end
                obj.lfType = arg2;
                obj.subSampling = '444';
                obj.setNameFromPath(arg1);
                if ~strcmp(arg3,'none') %If there is construction options, it is interpreted here
                    pattern = '\s*([a-zA-Z]+)\s*=\s*([a-zA-Z]+|\d)+\s*';
                    optCell = regexp(arg3,pattern,'tokens');
                    for i=1:size(optCell,2)
                        obj.interpretOption(arg2,optCell{i}(1),optCell{i}(2));
                    end
                end
                obj.modified = false;            
            else
                obj.name = arg1;
                
                obj.matrix5d = arg2;
                obj.decodeOptions = arg3; %Decode Options given by LFToolbox
                obj.modified = false;
                
                obj.lfType = arg4; 
                obj.subSampling = arg5;
                
                obj.colorSpace = arg6;
                
            end
            obj.setAuxAttribute();                 
        end
        
        %% Conversors        
        %Converts the LightField to YCbCr Space
        function convert2ycbcr(obj)
            %Converts the LightField to YCbCr Space
           obj.convertToYCbCr();
        end
        function convertToYCbCr(obj)
            %Converts the LightField to YCbCr Space
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
        function convert2rgb(obj)
            %Converts the LightField to RGB Space
           obj.convertToRGB();
        end
        function convertToRGB(obj)
            %Converts the LightField to RGB Space
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
            %SubSample LightField (444->420) Only YCbCr space!
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
        function downSamp(obj)
            %SubSample LightField (444->420) Only YCbCr space!
           obj.subSamp(); 
        end
        
        %UpSample LightField (420->444)
        function upSamp(obj)
            %UpSample LightField (420->444)
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
            %Removes chroma information (If LightField is represented in RGB sapce, it is converted to YCbCr)
           if (strcmp(obj.colorSpace,'rgb')) 
               obj.convert2ycbcr();
           end
           
           obj.matrix5d = obj.matrix5d(:,:,:,:,1);
           obj.subSampling = '400';
           obj.modified = true; 
           obj.chViewWidth = 0;
           obj.chViewHeight = 0;
        end
        
        %Converts the Light Field to 8-bit
        function clip2uint8(obj)
            %Converts the Light Field to 8-bit
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
            %Returns a given SAI/View (s,r,colorSpace)
            if (nargin == 3)
                I = obj.getSai(i,j) ;                
            elseif nargin == 4
                I = obj.getSai(i,j,colorSpace);
            end           
        end
        function I = getSai(obj,i,j,colorSpace)
            %Returns a given SAI/View (s,r,colorSpace)
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
        %Returns center SAI
        function I = getCenterView(obj,colorSpace)
            %Returns the center given SAI/View (colorSpace)            
            if nargin==1
                I = obj.getCenterSai();
            else
                I = obj.getCenterSai(colorSpace);
            end
            
        end        
        function I = getCenterSai(obj,colorSpace)
            %Returns the center given SAI/View (colorSpace)            
           i = ceil((1 + obj.numVerViews)/2);
           j = ceil((1 + obj.numHorViews)/2);
           
           if nargin==1
               I = squeeze(obj.matrix5d(i,j,:,:,:));
           else
               I = getSai(obj,i,j,colorSpace);
           end
        end        
        %Returns the luma channel of a given sub-aperture image (view). Converts
        %to YCbCr is necessary
        function I = getViewLuma(obj,i,j)
            %Returns the luma channel of a given sub-aperture image (view). Converts to YCbCr is necessary
           I = obj.getSaiLuma(i,j);
        end
        function I = getSaiLuma(obj,i,j)
            %Returns the luma channel of a given sub-aperture image (view). Converts to YCbCr is necessary
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
        %Returns Luma Channel of Center Sub-aperture image
        function I = getCenterViewLuma(obj)
            %Returns the luma channel of the central sub-aperture image (view). Converts
        %to YCbCr is necessary
            I = obj.getCenterSaiLuma();
        end
        function I = getCenterSaiLuma(obj)
            %Returns the luma channel of the central sub-aperture image (view). Converts
        %to YCbCr is necessary
            i = ceil((1 + obj.numVerViews)/2);
            j = ceil((1 + obj.numHorViews)/2);
            I = obj.getSaiLuma(i,j);
        end
                
        %Returns a given Micro Image (x,y,c)
        function I = getMI(obj,x,y,colorSpace)
            %Returns a given Micro Image (x,y,c)
            if nargin == 3
                I = getMicroImageXY(obj,x,y);
            else
                I = getMicroImageXY(obj,x,y,colorSpace);
            end
        end
        %Returns a given Micro Image (x,y,c)
        function I = getMicroImageXY(obj,x,y,colorSpace)
            %Returns a given Micro Image (x,y,c)
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
        function I = getMILuma(obj,x,y)
            %Returns the luma channel of a given Micro Image (x,y)
           Ia = getMicroImageXY(obj,x,y);
           if strcmp(obj.colorSpace,'ycbcr')
               I = squeeze(Ia(:,:,1));
           else strcmp(obj.colorSpace,'rgb');
               Ia = rgb2ycbcr(Ia);
               I = squeeze(Ia(:,:,1));
           end
        end
        
        %Returns an Image that groups Micro-Images side-by-side. 2D
        %representation of the Light Field
        function I = getMatrixMicroImage(obj)
            %Returns an Image that groups Micro-Images side-by-side. 2D
        %representation of the Light Field
            I = obj.castTypeLightField(zeros(obj.viewHeight*obj.numVerViews,obj.viewWidth*obj.numHorViews,3));            
            for i=1:obj.numVerViews
               for j=1:obj.numHorViews
                  I(i:obj.numVerViews:end,j:obj.numHorViews:end,:) = obj.matrix5d(i,j,:,:,:);
               end
            end
        end        
        function I = get2dLf(obj)
            %Returns an Image that groups Micro-Images side-by-side. 2D
        %representation of the Light Field
            I = obj.getMatrixMicroImage();
        end
        
        %Returns the Weight Channel (Reliability of each pixel)
        function M = getWeightChannel(obj)
            %Returns the Weight Channel (Reliability of each pixel)
           if strcmp(obj.lfType,'STANFORD')
               M = zeros(obj.numVerViews,obj.numHorViews,obj.viewWidth,obj.viewHeight);        
               if obj.bitDepth == 8
                   M = uint8(M + 2^8-1);
               elseif obj.bitDepth == 10
                   M = uint16(M + 2^10-1);
               elseif obj.bitDepth == 16
                   M = uint16(M + 2^16-1);
               else
                   M = double(M + 1);
               end
           else
               M = obj.weightChannel;
           end
        end
        
        %Returns (Center, or not) Sai Marked with straight lines at positions x,y
        function I = getCenterSaiMarked(obj,x,y,colorSpace)
           %Returns the CenterSai Marked with straight lines at positions
           %x,y (x,y,c)
            if nargin == 3
                I = obj.getCenterSai();           
                I = obj.getSaiMarked(I,x,y);
            else
                I = obj.getCenterSai(colorSpace);           
                I = obj.getSaiMarked(I,x,y,colorSpace);
            end
            
           
        end
        function I = getSaiMarked(obj,i,j,x,y,colorSpace)
           %Returns a given Sai Marked with straight lines at positions
           %x,y (s,r,x,y,c)
           if nargin==4 %With three (four considering obj) args, the function parameters are (I,x,y)
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
            %Returns a given Sai Marked (luma channel only) with straight lines at positions
            %x,y (s,r,x,y)
           I = obj.getSaiLuma(i,j);
           
           I(y,:,1) = obj.castTypeLightField(2^obj.bitDepth - 1);
           I(:,x,1) = obj.castTypeLightField(2^obj.bitDepth - 1);
        end        
        function I = getCenterSaiMarkedLuma(obj,x,y)
            %Returns the center Sai Marked (luma channel only) with straight lines at positions
            %x,y (s,r,x,y)
           I = obj.getCenterSaiLuma();
           
           I(y,:,1) = obj.castTypeLightField(2^obj.bitDepth - 1);
           I(:,x,1) = obj.castTypeLightField(2^obj.bitDepth - 1);
           
        end
        
        %% Auxiliary Methods
        %Check if There are  in the LightField object obj
        function assert(obj)
            %Check if there are any inconsistency in the LightField object obj
            if (size(obj.matrix5d,1) ~= obj.numVerViews) || (size(obj.matrix5d,2) ~= obj.numHorViews) || (size(obj.matrix5d,3) ~= obj.viewHeight) || (size(obj.matrix5d,4) ~= obj.viewWidth)                
                error('Size Inconsistency'); 
            else
                disp('Size Consistency: OK'); 
            end
            
            if strcmp(obj.lfType,'STANFORD') && size(obj.weightChannel,1) ~= 0
                error('Weight Channel Error for Stanford DataSet');
            elseif strcmp(obj.lfType,'DEC') 
                if (size(obj.weightChannel,1) ~= obj.numVerViews) || (size(obj.weightChannel,2) ~= obj.numHorViews) || (size(obj.weightChannel,3) ~= obj.viewHeight) || (size(obj.weightChannel,4) ~= obj.viewWidth)
                    error('Weight Channel Error for Decoded DataSet');
                end
            else
                disp('Weight Channel: OK'); 
            end
               
            if strcmp(obj.colorSpace,'rgb')
                if ~strcmp(obj.subSampling,'444')
                    error('RGB is not 4:4:4');
                end
                if obj.chViewWidth ~= -1 || obj.chViewHeight ~= -1
                    error('RGB must not have chroma channels');
                end
            elseif strcmp(obj.colorSpace,'ycbcr')
                if strcmp(obj.subSampling,'444')
                    if (obj.chViewHeight ~= obj.viewHeight || obj.chViewWidth ~= obj.viewWidth)
                        error('Chroma size does not match luma dimensions');
                    end
                elseif strcmp(obj.subSampling,'420')
                   if (obj.chViewHeight ~= ceil(obj.viewHeight/2) || obj.chViewWidth ~= ceil(obj.viewWidth/2))
                        error('Chroma size does not match luma dimensions in 4:2:0 subsampling');
                    end                 
                elseif strcmp(obj.subSampling,'400')
                    if (obj.chViewHeight ~= 0 || obj.chViewWidth ~= 0)
                        error('Chroma size does not match luma dimensions in 4:0:0 subsampling');
                    end                 
                else
                    error(['Unknown LightField Subsampling: ' obj.subSampling]);
                end
            end
            disp('Color Space and SubSampling: OK');
            
            if(obj.bitDepth == 8)
                if (~strcmp(obj.dataType,'uint8'))
                    error('Inconsistency between bitDepth and dataType'); 
                end
                
                if (max(max(max(max(max(obj.matrix5d)))))>=2^obj.bitDepth)
                    error('Inconsistency between bitDepth and max sample'); 
                end
                
            elseif(obj.bitDepth == 10)
                if (~strcmp(obj.dataType,'uint16'))
                    error('Inconsistency between bitDepth and dataType'); 
                end
                
                if (max(max(max(max(max(obj.matrix5d)))))>=2^obj.bitDepth)
                    error('Inconsistency between bitDepth and max sample'); 
                end
                
            elseif (obj.bitDepth == 16)
                if (~strcmp(obj.dataType,'uint16'))
                    error('Inconsistency between bitDepth and dataType'); 
                end
                
                if (max(max(max(max(max(obj.matrix5d)))))>=2^obj.bitDepth)
                    error('Inconsistency between bitDepth and max sample'); 
                end
                
            elseif (obj.bitDepth == 64)
                if (~strcmp(obj.dataType,'double'))
                    error('Inconsistency between bitDepth and dataType'); 
                end
                
                if (max(max(max(max(max(obj.matrix5d)))))>1)
                    error('Inconsistency between dataType and max sample'); 
                end
                
            else
                error(['Unknown LightField bitDepth: ' int2str(obj.bitDepth)]);
            end
            disp('BitDepth and DataType: OK');
                
        end
        
        %Performs 8-bit clipping, conversion to YCbCr and SubSampling
        function videoFriendly(obj)
            %Performs 8-bit clipping, conversion to YCbCr and SubSampling
           obj.clip2uint8();
           obj.convert2ycbcr();
           obj.subSamp();
        end
        
        %Inserts black pixels (or zoh) in odd dimensions to make then even
        function adjustOddDimensions(obj,approach)
            %Inserts black pixels (or zoh) in odd dimensions to make then
            %even (Not recommended for use.. Use redimSaiDivByN instead)
            if mod(obj.viewWidth,2) == 0 && mod(obj.viewHeight,2) == 0
                return;
            end
            
            if nargin == 1
                approach = 'zeros';
            end
            
            offH = mod(obj.viewHeight,2);
            offW = mod(obj.viewWidth,2);
            
            if strcmp(obj.subSampling,'400')
                ch = 1;
            else
                ch = 3;
            end
            
            M = obj.castTypeLightField(zeros(obj.numVerViews,obj.numHorViews,obj.viewHeight+offH,obj.viewWidth+offW,ch));
            
            for i=1:obj.numVerViews
                for j=1:obj.numHorViews
                    M(i,j,1:obj.viewHeight,1:obj.viewWidth,:) = obj.matrix5d(i,j,:,:,:);
                    
                    if strcmp(approach,'zoh')
                        M(i,j,obj.viewHeight+offH,:,:) = M(i,j,obj.viewHeight,:,:);
                        M(i,j,:,obj.viewWidth+offW,:) = M(i,j,:,obj.viewWidth,:);
                    end
                    
                end
            end
            
            obj.matrix5d = M;
            obj.viewHeight = obj.viewHeight + offH;
            obj.viewWidth = obj.viewWidth + offW;
            
            if strcmp(obj.subSampling,'444')
                obj.chViewWidth = obj.viewWidth;
                obj.chViewHeight = obj.viewHeight;
            elseif strcmp(obj.subSampling,'420')
                obj.chViewWidth = obj.viewWidth/2;
                obj.chViewHeight = obj.viewHeight/2;
            elseif strcmp(obj.subSampling,'400')
                obj.chViewWidth = 0;
                obj.chViewHeight = 0;
            else
                error(['Unexpected sub-sampling: ' obj.subSampling]);
            end
            
            
            
        end
                
        function adjustDimensionsVideoEncoder(obj,approach)
            %Adjust the dimensions of SAI to be divided by eight in
            %accordance with HEVC encoder. (not recommended, used redimSaiDivByN instead.)
            %Args: (approach) --> approach can be "zeros" or "zoh"
            if mod(obj.viewWidth,8) == 0 && mod(obj.viewHeight,8) == 0
                return;
            end
            
            if nargin == 1
                approach = 'zeros';            
            end
            
            if strcmp(obj.subSampling,'420')
                obj.upSamp;
                was420 = true;
            else
                was420 = false;
            end
            
            if strcmp(obj.colorSpace,'ycbcr')
                obj.convert2rgb;
                wasycbcr = true;
            else
                wasycbcr = false;
            end
            
            
            offH = mod(8 - mod(obj.viewHeight,8),8);
            offW = mod(8 - mod(obj.viewWidth,8),8);
            
            if strcmp(obj.subSampling,'400')
                ch = 1;
            else
                ch = 3;
            end
            
            M = obj.castTypeLightField(zeros(obj.numVerViews,obj.numHorViews,obj.viewHeight+offH,obj.viewWidth+offW,ch));
            
            for i=1:obj.numVerViews
                for j=1:obj.numHorViews
                    M(i,j,1:obj.viewHeight,1:obj.viewWidth,:) = obj.matrix5d(i,j,:,:,:);
                    
                    if strcmp(approach,'zoh')
                        
                        for k = 1:offH
                            M(i,j,obj.viewHeight+k,:,:) = M(i,j,obj.viewHeight,:,:);
                        end
                        for k = 1:offW
                            M(i,j,:,obj.viewWidth+k,:) = M(i,j,:,obj.viewWidth,:);
                        end                        
                        
                    end
                    
                end
            end
            
            obj.matrix5d = M;
            obj.viewHeight = obj.viewHeight + offH;
            obj.viewWidth = obj.viewWidth + offW;
            
            if strcmp(obj.subSampling,'444')
                obj.chViewWidth = obj.viewWidth;
                obj.chViewHeight = obj.viewHeight;
            elseif strcmp(obj.subSampling,'420')
                obj.chViewWidth = obj.viewWidth/2;
                obj.chViewHeight = obj.viewHeight/2;
            elseif strcmp(obj.subSampling,'400')
                obj.chViewWidth = 0;
                obj.chViewHeight = 0;
            else
                error(['Unexpected sub-sampling: ' obj.subSampling]);
            end
            
            if wasycbcr
                obj.convert2ycbcr;
            end
            
            if was420
                obj.downSamp;
            end
            
        end
        
        %Redimension SAI proportions in a "divisible by N" fashion (height
        %and width divisible by N). 
        function redimSaiDivByN(obj,N,approach)
            %Redimension SAI proportions in a "divisible by N" fashion
            %(height and width divisible by N). Arguments: Arg1: N; Arg2:
            %approach (zeros or zoh)
            if mod(obj.viewWidth,N) == 0 && mod(obj.viewHeight,N) == 0
                return;
            end
            
            if nargin == 2
                approach = 'zeros';            
            end
            
            if strcmp(obj.subSampling,'420')
                obj.upSamp;
                was420 = true;
            else
                was420 = false;
            end
            
            if strcmp(obj.colorSpace,'ycbcr')
                obj.convert2rgb;
                wasycbcr = true;
            else
                wasycbcr = false;
            end
            
            
            offH = mod(N - mod(obj.viewHeight,N),N);
            offW = mod(N - mod(obj.viewWidth,N),N);
            
            if strcmp(obj.subSampling,'400')
                ch = 1;
            else
                ch = 3;
            end
            
            M = obj.castTypeLightField(zeros(obj.numVerViews,obj.numHorViews,obj.viewHeight+offH,obj.viewWidth+offW,ch));
            
            for i=1:obj.numVerViews
                for j=1:obj.numHorViews
                    M(i,j,1:obj.viewHeight,1:obj.viewWidth,:) = obj.matrix5d(i,j,:,:,:);
                    
                    if strcmp(approach,'zoh')
                        
                        for k = 1:offH
                            M(i,j,obj.viewHeight+k,:,:) = M(i,j,obj.viewHeight,:,:);
                        end
                        for k = 1:offW
                            M(i,j,:,obj.viewWidth+k,:) = M(i,j,:,obj.viewWidth,:);
                        end                        
                        
                    end
                    
                end
            end
            
            obj.matrix5d = M;
            obj.viewHeight = obj.viewHeight + offH;
            obj.viewWidth = obj.viewWidth + offW;
            
            if strcmp(obj.subSampling,'444')
                obj.chViewWidth = obj.viewWidth;
                obj.chViewHeight = obj.viewHeight;
            elseif strcmp(obj.subSampling,'420')
                obj.chViewWidth = obj.viewWidth/2;
                obj.chViewHeight = obj.viewHeight/2;
            elseif strcmp(obj.subSampling,'400')
                obj.chViewWidth = 0;
                obj.chViewHeight = 0;
            else
                error(['Unexpected sub-sampling: ' obj.subSampling]);
            end
            
            if wasycbcr
                obj.convert2ycbcr;
            end
            
            if was420
                obj.downSamp;
            end
            obj.setAuxAttribute();
            
        end
        
        function cropSai(obj,newWidth,newHeight)
            %Reduces the LF SAIs dimensions according to the arguments
            %newWidth (arg1) and newHeight (arg2)
            if newWidth > obj.viewWidth;
                error ('New Width must be smaller than LF width!');
            end
            
            if newHeight > obj.viewHeight;
                error ('New Width must be smaller than LF height!');
            end
            
            obj.matrix5d = obj.matrix5d(:,:,1:newHeight,1:newWidth,:);
            obj.setAuxAttribute();            
        end
    end
    
    %% Protected Methods
    methods (Access = protected)
        
        % Open Stanford DataSet LightField
        function openStanford(obj, path)
            % Open Stanford DataSet LightField
            [obj.matrix5d, obj.decodeOptions] = LFReadGantryArray(path);                        
            obj.weightChannel = [];               
            obj.colorSpace = 'rgb';                        
        end
        
        % Open Decoded .Mat LightField (EPFL, Smart DataSets)
        function openDecFile(obj, path)
            % Open Decoded .Mat LightField (EPFL, Smart DataSets)
            load(path);
            obj.matrix5d = squeeze(LF(:,:,:,:,1:3));
            if (size(LF,5) == 4)                
                obj.weightChannel = squeeze(LF(:,:,:,:,4));
            else
                baseException = MException('LFNumDim:DecLFHsnt4CC',['Decoded .mat LightField does not have wight color channel  ' class(obj.matrix5d)]);
                throw(baseException);  
            end
            obj.colorSpace = 'rgb';
            obj.decodeOptions = DecodeOptions;
        end
        
        % Open LightField http://www.tgeorgiev.net/Gallery/
        function openTGFile(obj, path)
            % Open LightField http://www.tgeorgiev.net/Gallery/. NOT
            % IMPLEMENTED YED!
            disp('WARNING: TGEORGIEV cannot be opened yet!')
%             obj.aux = imread(path);
%             A = rgb2ycbcr(obj.aux);
%             A = squeeze(A(:,:,1));
%             varMin = max(max(A))/5;
%             bestSad = 255;
%             for offY = 10:40
%                 h = waitbar(offY/51);
%                 for offX = 10:40
%                     for bHeight = 70:90
%                         for bWidth = bHeight-5:bHeight+5
%                             
%                             if (std2(A(offY:offY+bHeight-1,offX:offX+bWidth-1))<12.75)
%                                 break;
%                             end
%                             
%                            sad = sum(sum(abs(A(offY:offY+bHeight-1,offX:offX+bWidth-1)-A(offY+bHeight:offY+2*bHeight-1,offX+bWidth:offX+2*bWidth-1)))) ... %Diagonal
%                                + sum(sum(abs(A(offY:offY+bHeight-1,offX:offX+bWidth-1)-A(offY+bHeight:offY+2*bHeight-1,offX:offX+bWidth-1)))) ...  %Below
%                                + sum(sum(abs(A(offY:offY+bHeight-1,offX:offX+bWidth-1)-A(offY:offY+bHeight-1,offX+bWidth:offX+2*bWidth-1)))); %Right
%                            sad = sad / (bHeight*bWidth);
%                            
%                            varL = sum(sum(abs(A(offY:offY+bHeight-1,offX)-A(offY:offY+bHeight-1,offX-1)))); 
%                            varR = sum(sum(abs(A(offY:offY+bHeight-1,offX+bWidth-1)-A(offY:offY+bHeight-1,offX+bWidth))));
%                            varU = sum(sum(abs(A(offY,offX:offX+bWidth-1)-A(offY-1,offX:offX+bWidth-1)))); %Border Above
%                            varD = sum(sum(abs(A(offY+bHeight-1,offX:offX+bWidth-1)-A(offY+bHeight,offX:offX+bWidth-1)))); %Border Below
%                            
%                            var = min([varL, varR, varU, varD]);
%                            
%                            
%                            
%                            if (sad < bestSad && var > varMin)
%                                disp(sad);
%                                bestOffY = offY;
%                                bestOffX = offX;
%                                bestWidth = bWidth;
%                                bestHeight = bHeight;
%                                bestSad = sad;
%                            end
%                         end
%                     end
%                 end
%             end
%             
% %             bestVar = 0;
% %             for offY = 2:50
% %                 h = waitbar(offY/51);
% %                 for offX = 2:50
% %                     for bHeight = 5:200
% %                         for bWidth = round(bHeight/1.5):round(1.5*bHeight)
% %                            var = sum(sum(abs(A(offY:offY+bHeight-1,offX)-A(offY:offY+bHeight-1,offX-1)))) ... Left Border                              
% %                                + sum(sum(abs(A(offY:offY+bHeight-1,offX+bWidth-1)-A(offY:offY+bHeight-1,offX+bWidth)))) ... Right Border                               
% %                                + sum(sum(abs(A(offY,offX:offX+bWidth-1)-A(offY-1,offX:offX+bWidth-1)))); %Border Above
% %                                + sum(sum(abs(A(offY+bHeight-1,offX:offX+bWidth-1)-A(offY+bHeight,offX:offX+bWidth-1)))); %Border Below
% %                                
% %                            var = var / (2*bHeight+2*bWidth);
% %                            if (var > bestVar)
% %                                bestOffY = offY;
% %                                bestOffX = offX;
% %                                bestWidth = bWidth;
% %                                bestHeight = bHeight;
% %                                bestVar = var;
% %                            end
% %                         end
% %                     end
% %                 end
% %             end
%             delete(h);
%             A(bestOffY:bestOffY+bestHeight-1,bestOffX) = 255;
%             A(bestOffY:bestOffY+bestHeight-1,bestOffX+bestWidth-1) = 255;
%             A(bestOffY,bestOffX:bestOffX+bestWidth-1) = 255;
%             A(bestOffY+bestHeight-1,bestOffX:bestOffX+bestWidth-1) = 255;
%             imshow(A);
%             
%             obj.weightChannel = [];               
%             obj.colorSpace = 'rgb';
        end
        
        %Define Auxilar Attributes of Light Field
        function setAuxAttribute(obj)            
            %Define Auxilar Attributes of Light Field
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
        
        function O = castTypeLightField(obj,I)
            %Returns applies a cast in matrix I according to the object
            %data type, and returns the O matrix
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
        
        function interpretOption(obj,type,key,value)
            %Interpret options along with the construction process
            disp('WARNING: function/method interpretOption probably not full implemented yet!')
            
            if strcmp('numViews',key) || strcmp('angDim',key) || strcmp('angDims',key)
                numViews = regexp(value,'(\d+)x(\d+)','tokens');
                obj.redimLightField(str2double(numViews{1}{1}{2}),str2double(numViews{1}{1}{1}));
                        
            elseif strcmp('lfName',key) || strcmp('name',key) || strcmp('lfname',key)
                obj.name = value{1};            
            
            else
                baseException = MException('LFOptKey:Uknwn',['Unknown Option Key ' key]);
                throw(baseException);
            end
                
            
        end        
        
        function redimLightField(obj,numVertViews,numHorViews)
            %Angular redimension over the light field
            stVert = floor((size(obj.matrix5d,1)-numVertViews)/2);
            endVert = floor((size(obj.matrix5d,1)-numVertViews)/2+numVertViews-1);
            
            stHor = floor((size(obj.matrix5d,2)-numHorViews)/2);
            endHor = floor((size(obj.matrix5d,2)-numHorViews)/2+numHorViews-1);
            
            obj.matrix5d = obj.matrix5d(stVert:endVert,stHor:endHor,:,:,:);
        end
        
        function [U,V] = getUpSampledChromaChannels(obj,i,j)
            %Get U and V upsampled channels of the subsampled LightField (s,r)
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
        
        function setNameFromPath(obj,path)
            %Set the name of the light field according to the file name
            C = strsplit(path,{'/','\'});
            if strcmp(obj.lfType,'STANFORD')
                if strcmp(C{end},'')
                    obj.name = C{end-2};                
                else
                    obj.name = C{end-1};
                end
            else
                obj.name = C{end}(1:end-4);
            end            
            obj.name = strrep(obj.name,'&','n');
        end
                
    end
    
    
    %% Static Method
    methods (Static)        
              
    end
end

