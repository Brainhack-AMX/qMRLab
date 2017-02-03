classdef BrowserSet < handle
    % BrowserSet - manage the file browser interface
    %   P.Beliveau 2017 - setup
    %   * manage the standard set of interface items in the browser
    %   * Properties: 
    %       uicontrols:     - NameText 
    %                       - BrowserButton 
    %                       - FileBox 
    %                       - ViewButton
    %       vars: - NameID: identifies the method
    %             - FullFile: the path and file name displayed 
    %                           and chosen by user

    
    properties
        NameText;
        BrowseBtn;      
        FileBox;        
        ViewBtn;        
        
        BrowseBtnOn;    
        ViewBtnOn;      
        
        NameID;         % Method
        FullFile;       
        
        Data;           
    end
    
    methods
        %------------------------------------------------------------------
        % -- CONSTRUCTOR
        function obj = BrowserSet(varargin)
            
            if nargin>0
                % parse the input arguments
                parent = varargin{1};
                handles = varargin{2};
                Name = varargin{3};
                Location = varargin{4};
                obj.BrowseBtnOn = varargin{5};
                obj.ViewBtnOn = varargin{6};
                
                obj.NameID = Name;

                Position = [Location, 0.1, 0.1];
                obj.NameText = uicontrol(parent, 'Style', 'Text', 'units', 'normalized', 'fontunits', 'normalized', ...
                    'String', obj.NameID, 'HorizontalAlignment', 'left', 'Position', Position,'FontSize', 0.6);

                if obj.BrowseBtnOn == 1
                    Location = Location + [0.1, 0];
                    Position = [Location, 0.1, 0.1];
                    obj.BrowseBtn = uicontrol(parent, 'Style', 'pushbutton', 'units', 'normalized', 'fontunits', 'normalized', ...
                    'String', 'Browse', 'Position', Position, 'FontSize', 0.6, ...
                    'Callback', {@(src, event)BrowserSet.BrowseBtn_callback(obj, src, event, handles{1,1})});
                end 

                Location = Location + [0.11, 0];
                Position = [Location, 0.65, 0.1];
                obj.FileBox = uicontrol(parent, 'Style', 'edit','units', 'normalized', 'fontunits', 'normalized', 'Position', Position,'FontSize', 0.6);

                if obj.ViewBtnOn == 1 
                    Location = Location + [0.66, 0];
                    Position = [Location, 0.1, 0.1];
                    obj.ViewBtn = uicontrol(parent, 'style', 'pushbutton','units', 'normalized', 'fontunits', 'normalized', ...
                        'String', 'View', 'Position', Position, 'FontSize', 0.6, ...
                        'Callback', {@(src, event)BrowserSet.ViewBtn_callback(obj, src, event, handles{1,1})});            end
            end % testing varargin
        end % constructor end
        
        %------------------------------------------------------------------
        % -- DESCTRUCTOR
        function delete(obj)
        end % destructor end
    end
    
    methods
        %------------------------------------------------------------------
        % -- VISIBLE
        %       Visibility should be set to 'on' or 'off'
        function Visible(obj, Visibility)
            set(obj.NameText, 'Visible', Visibility);
            set(obj.BrowseBtn, 'Visible', Visibility);
            set(obj.FileBox, 'Visible', Visibility);
            set(obj.ViewBtn, 'Visible', Visibility);
        end
        
        
    end
    
    methods
        
        %------------------------------------------------------------------
        % -- DATA LOAD
        %   load data from file and make accessible to qMTLab fct
        function DataLoad(obj, handles)
            obj.Data = [];
            obj.FullFile = get(obj.FileBox, 'String');
            [pathstr,name,ext] = fileparts(obj.FullFile);
            if strcmp(ext,'.mat');
                Data = load(obj.FullFile);                
                DataLoaded = get(obj.NameText, 'String');
                obj.Data = Data.(name);                
            elseif strcmp(ext,'.nii') || strcmp(ext,'.gz');
                nii = load_nii(obj.FullFile);
                obj.Data = nii.img;
            elseif strcmp(ext,'.tiff') || strcmp(ext,'.tif');
                TiffInfo = imfinfo(obj.FullFile);
                NbIm = numel(TiffInfo);
                if NbIm == 1
                    File = imread(obj.FullFile);
                else
                    for ImNo = 1:NbIm;
                        File(:,:,ImNo) = imread(obj.FullFile, ImNo);%, 'Info', info);            
                    end
                end
                obj.Data = File
            end            
            setappdata(0, obj.NameID{1,1}, obj.Data);            
        end
        
        %------------------------------------------------------------------
        % -- setPath
        % search for filenames that match the NameText
        function setPath(obj, Path, fileList, handles)           
            
            % clear previous file paths
            set(obj.FileBox, 'String', '');
            DataName = get(obj.NameText, 'String');
            %Check for files and set fields automatically
            for i = 1:length(fileList)
                if strfind(fileList{i}(1:end-4), DataName)
                    obj.FullFile = fullfile(Path,fileList{i});                    
                    set(obj.FileBox, 'String', obj.FullFile);
                    obj.DataLoad(handles);
                end
            end
            
        end
    end
    
    methods(Static)
        %------------------------------------------------------------------
        % -- BROWSE BUTTONS
        %------------------------------------------------------------------
        function BrowseBtn_callback(obj,src, event, handles)
            obj.FullFile = get(obj.FileBox, 'String');
            if isequal(obj.FullFile, 0) || (isempty(obj.FullFile))
                [FileName,PathName] = uigetfile({'*.nii';'*.mat'},'Select B1map file');          
            else
                [FileName,PathName] = uigetfile({'*.nii';'*.mat'},'Select B1map file',obj.FullFile);               
            end
            obj.FullFile = fullfile(PathName,FileName);
            set(obj.FileBox,'String',obj.FullFile);
            
            DataLoad(obj, handles);            
        end
        
        %------------------------------------------------------------------
        % -- VIEW BUTTONS
        %------------------------------------------------------------------
        function ViewBtn_callback(obj,src, event, handles)
            obj.DataLoad(handles);
            obj.Data = getappdata(0, obj.NameID{1,1});
            if isempty(obj.Data), errordlg('empty data'); return; end
            
            if ~strcmp(obj.NameID, 'MTSAT') && strcmp(obj.NameID{1,1}, 'MTdata')
                n = ndims(obj.Data);
                Data.(obj.NameID{1,1}) = mean(double(obj.Data), n);
            else
                Data.(obj.NameID{1,1}) = double(obj.Data);
            end
            
            
            Data.fields = {obj.NameID{1,1}};
            handles.CurrentData = Data;
            guidata(src,handles);
            DrawPlot(handles);
        end
        
        
    end
    
end
