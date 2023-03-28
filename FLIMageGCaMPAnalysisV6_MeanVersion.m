%% Code for analyzing GCaMP data exported from FLIMage

%% READ ME
% To use this code you will need to have csv files that you exported from
% FLIMage. 
    % To obtain these files: open the .flim file in FLIMage and have
    % it calculate (should happen automatically if the box is checked or you
    % can push the button). Make sure you have the ROI(s) you want to use drawn
    % and created (you have to right click after you draw it an click create
    % ROI) as well as the background ROI drawn and created (draw it, then
    % right click and select as background ROI). Then after it calculates,
    % in that same box there is a save option at the bottom, save as a CSV.
    % If you took multiple files under the same name, you will need to
    % rename the file otherwise it will just overwrite the previous one.
    
% For each file you want to analyze you will need to know the frame rate
% (which is a function of the number of pixels)

% In this version of the code, you can only analyze things together that
% will share the same parameters (ie, frame rate, time you want to use for
% the baseline etc.).

% In this version of the code you can only run files that have a single ROI
% selected

% Note this code rounds down to the nearest whole frame to calculate the
% baseline and uses the mean to calculate the dF/F

% Note this code averages before calculating dF/F

% Version 2 contains bug fixes
% Version 3 contains bug fixes for a single spreadsheet and allows the user
% to specify a Fo value they pre-calculated
% Version 4 contains a simple multi-ROI mode (can only run one spreadsheet
% at a time) and an averaging bug fix
% Version 5 allows the user to specify different pre-calculated Fo values to
% the different spreadsheets and/or ROIs selected
% Version 6 has a critical bug fix in the baseline calculation

%% Ask the user if they are running multi-ROI mode
multi_ROI = input('Do you have multiple ROIs? (enter 1 for yes, 0 for no) ');

%% Ask the user to select the files to be analyzed
if multi_ROI == 1
    [fileNames, pathNames] = uigetfile('*.csv',...
        'Select only ONE file you want to analyze',...
        'Multiselect', 'off');
   % Next couple lines are for determining how many ROIs you have
   currentFolder = pwd; % Find out what folder we are in now so we can navigate back to it later
   cd(pathNames) % Go to where your spreadsheet is
   sheetData = xlsread(fileNames);
   numROI = sheetData(1,1);
   cd(currentFolder)
else
    [fileNames, pathNames] = uigetfile('*.csv',...
        'Select the files you want to analyze',...
        'Multiselect', 'on');
end

%% Find out how many sheets we are working with
if isa(fileNames, 'char') == 1
    singleSheet = 1;
else
    singleSheet = 0;
end

%% Ask the user if they have a dF/F value they want to use
disp('--------------------------------------------------------------------')
multi_Fo = 0; % turn off multi-Fo mode by default
dFF_YN = input('Do you have a Fo value you want to specify? (enter 1 for yes, 0 for no) ');
if dFF_YN == 1
    if singleSheet == 1 && multi_ROI == 0
        fo = input('What is the Fo value? ');
    else
        multi_Fo = input('Do you want to use the same Fo for all data (0) or different Fo values (1)?');
        if multi_Fo == 0
            fo = input('What is the Fo value? ');
        elseif multi_Fo == 1 && multi_ROI == 1
            disp('Please provide the Fo values in order:')
            for x = 1:numROI
                y = ['What is the Fo value for ROI number ' num2str(x) '? '];
                fo(x) = input(y);
            end
        elseif multi_Fo == 1 && multi_ROI == 0
            disp('Please provide the Fo values in order:')
            for x = 1:length(fileNames)
                y = ['What is the Fo value for spreadsheet number ' num2str(x) '? '];
                fo(x) = input(y);
            end
        else
            error('Something went wrong with the Fo specification')
        end
    end
end
disp('--------------------------------------------------------------------')

%% Ask the user what the frame rate is
if dFF_YN == 0
    disp('--------------------------------------------------------------------')
    disp('                     Frame rate lookup table                        ')
    disp('64 x 64 pixels = 0.128')
    disp('128 x 128 pixels = 0.256')
    disp('--------------------------------------------------------------------')
    frameRate = input('What is the frame rate of your data?  ');
end

%% Ask the user how long they want the baseline to be
if dFF_YN == 0
    disp('--------------------------------------------------------------------')
    baselineTime = input('How many seconds do you want to use for your baseline?  ');
    time2frame = floor(baselineTime./frameRate);
    disp(['The number of frames used for a baseline will be: ', num2str(time2frame)]);
    disp('--------------------------------------------------------------------')
end

%% Ask the user if they want to average
disp('--------------------------------------------------------------------')
avgYN = input('Do you want to average? (enter 1 for yes, 0 for no) ');
if avgYN == 1
    frames2avg = input('How many frames do you want to average together?');
end
disp('--------------------------------------------------------------------')

%% Ask the user if they want to run fastmode (no column headings)
if isa(fileNames, 'char') == 0
    disp('--------------------------------------------------------------------')
    disp('Fast mode omits the step where you manually assign column headers');
    fastYN = input('Do you want to run in fast mode? (enter 1 for yes, 0 for no) ');
    disp('--------------------------------------------------------------------')
else 
    fastYN = 1; % Automatically runs in fast mode if there is just one spreadsheet
end 


%% Compile data into a table

currentFolder = pwd; % Find out what folder we are in now so we can navigate back to it later
cd(pathNames) % Go to where your spreadsheet is

% Find the spreadsheet and access the information:
if multi_ROI == 1
   sheetData = xlsread(fileNames);
   numROI = sheetData(1,1);
   sheetData = transpose(sheetData);
   disp('-------------------------------------------------------------')
   disp('Rows taken as data:')
   for x = 1:numROI
       loc = (18 + x + (numROI*14)); % for monitoring
       disp(loc)
       tempNew = sheetData(:,loc);
       tempStore{x} = tempNew;
   end
   singleSheet = 0;
else
    if singleSheet == 1 % Bug fix for if there's only one file name
        sheetData = xlsread(fileNames);
        
        cd(currentFolder) % Return to the original folder
        
        % Extract the data and store it in a cell array
        % We are using a cell array here because our data might be different
        % lengths
        sheetData = transpose(sheetData); % We need to transpose it so the data is in column form
        tempNew = sheetData(:,33); % Because we took the transpose it is now the 34th column that has the data
        tempStore{1} = tempNew;
        
    else
        
        for x = 1:length(fileNames) % For each spreadsheet
            cd(pathNames) % Go to where your spreadsheet is
            sheetData = xlsread(fileNames{x}); % Extract the numeric data from the file
            cd(currentFolder) % Return to the original folder
            
            % Extract the data and store it in a cell array
            % We are using a cell array here because our data might be different
            % lengths
            sheetData = transpose(sheetData); % We need to transpose it so the data is in column form
            tempNew = sheetData(:,33); % Because we took the transpose it is now the 34th column that has the data
            tempStore{x} = tempNew;
        end
        
        
        if fastYN == 0
            % Get the column label:
            % Prompt the user to provide a variable name for the sheet:
            disp(fileNames{x})
            headers{x} = input('What do you want to name the column header for this data? (put in single quotes) ');
        end
    end
end

%% Data processing
% This is where noise removal could happen ina future version

% Remove the random zeros at the end of the data set
for x = 1:length(tempStore)
    thisData = tempStore{x}; % Take data from the cell array
    while thisData(length(thisData)) == 0 % While the last element is 0
        thisData(end)=[]; % Remove the last element
    end
    tempStore{x} = thisData; % Replace with the trimmed data set
end

% Compile all the data into one array
if singleSheet == 0 % Bug fix for one spreadsheet
    tempRaw = padcat(tempStore{:});
else
    tempRaw = cell2mat(tempStore);
end
        
% Create the table
compiledRaw = array2table(tempRaw);
if fastYN == 0
    compiledRaw.Properties.VariableNames = headers;
end 
    
%% Take the dF/F

% Calculate and store the dF/F values 
if dFF_YN == 0
    disp('These are the Fo values calculated:') % To make things pretty on the user end
end
% The operations can't be performed in a table so we need everything to be
% an array
tempRaw = table2array(compiledRaw); % Convert our raw data into an array
tempDFF = zeros(size(tempRaw)); % Set up another array to store our dF/F values

if multi_Fo == 0
    for jColumns = 1:width(compiledRaw) % For as many columns are in the table
        if dFF_YN == 0
            fo = mean(tempRaw(1:time2frame,jColumns)); % The Fo is the mean of the baseline frames
            disp(fo); % Show the dF/F
        end
        for iRows = 1:height(compiledRaw) % For as many frames as there are
            tempDFF(iRows,jColumns)=(((tempRaw(iRows,jColumns)-fo))/fo); % Calculate the dF/F and store it in a matrix
        end
    end
elseif multi_Fo == 1 
    for jColumns = 1:width(compiledRaw) % For as many columns are in the table
        for iRows = 1:height(compiledRaw) % For as many frames as there are
            tempDFF(iRows,jColumns)=(((tempRaw(iRows,jColumns)-fo(jColumns)))/fo(jColumns)); % Calculate the dF/F and store it in a matrix
        end
    end
end

% Compile into a table
compiledDFF = array2table(tempDFF); % data
if fastYN == 0
compiledDFF.Properties.VariableNames = headers; % headers
end

%% Averaging

if avgYN == 1
    % The number of frames to average over is saved as frames2avg
    % THE CODE WILL CHOP OFF THE FRAMES THAT ARE EXTRA AT THE END
    tempAVG = nan((floor(size(tempDFF,1)/frames2avg)), size(tempDFF,2));
    for iRows= 1:size(tempAVG, 1)
        lower=(1+(frames2avg*(iRows-1)));
        upper=(iRows*frames2avg);
        for jColumns = 1:size(tempDFF,2)
            tempAVG(iRows,jColumns)=nanmean(tempDFF(lower:upper, jColumns));
        end
    end
    
    % Make the table with headers
    compiledAVG = array2table(tempAVG); % data
    if fastYN == 0
        compiledAVG.Properties.VariableNames = headers; % headers
    end
end

%% Export tables 

cd(pathNames);
write(compiledRaw, 'compiledRaw.xlsx')
write(compiledDFF, 'compiledDFF.xlsx')
if avgYN == 1
    write(compiledAVG, 'compiledAVG.xlsx')
end
cd(currentFolder)

%% EYYYY You're done!

disp('Done!')



