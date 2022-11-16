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
% baseline and uses the median to calculate the dF/F

% Note this code averages before calculating dF/F

%% Ask the user to select the files to be analyzed
[fileNames, pathNames] = uigetfile('*.csv',...
    'Select the files you want to analyze',...
    'Multiselect', 'on');

%% Ask the user what the frame rate is
disp('--------------------------------------------------------------------')
disp('                     Frame rate lookup table                        ')
disp('64 x 64 pixels = 0.128')
disp('128 x 128 pixels = 0.256')
disp('--------------------------------------------------------------------')
frameRate = input('What is the frame rate of your data?  ');

%% Ask the user how long they want the baseline to be
disp('--------------------------------------------------------------------')
baselineTime = input('How many seconds do you want to use for your baseline?  ');
time2frame = floor(baselineTime./frameRate);
disp(['The number of frames used for a baseline will be: ', num2str(time2frame)]);
disp('--------------------------------------------------------------------')

%% Ask the user if they want to average
disp('--------------------------------------------------------------------')
avgYN = input('Do you want to average? (enter 1 for yes, 0 for no) ');
if avgYN == 1
    frame2avg = input('How many frames do you want to average together?');
end
disp('--------------------------------------------------------------------')

%% Ask the user if they want to run fastmode (no column headings)
disp('--------------------------------------------------------------------')
disp('Fast mode omits the step where you manually assign column headers');
fastYN = input('Do you want to run in fast mode? (enter 1 for yes, 0 for no) ');
disp('--------------------------------------------------------------------')

%% Compile data into a table 

currentFolder = pwd; % Find out what folder we are in now so we can navigate back to it later

for x = 1:length(fileNames) % For each spreadsheet
    
    % Find the spreadsheet and access the information:
    cd(pathNames) % Go to where your spreadsheet is
    sheetData = xlsread(fileNames{x}); % Extract the numeric data from the file
    cd(currentFolder) % Return to the original folder
    
    % Extract the data and add it to our table:
    % Row 34 of the spreadsheet (!ASSUMES 1 ROI) has the background
    % subtracted data = row 33 of data
    sheetData = transpose(sheetData); % We need to transpose it so the data is in column form
    tempNew = sheetData(:,33); % Because we took the transpose it is now the 34th column that has the data
    if x == 1 % If this is the first spreadsheet then...
        tempRaw = tempNew; % put the data in the first column.
    else % Otherwise...
        % You can only concatenate a matrix and a column vector if they are
        % the same length
        tempData = nan(length(tempRaw),1); % Find out the length of the current matrix
        tempData(1:length(tempNew))= tempNew; % Add NaNs to make the vector the same size as the matrix
        tempRaw = [tempRaw tempData];
    end
    % Now convert data into a table
    compiledRaw = array2table(tempRaw);
    if fastYN == 0    
    % Get the column label:
    % Prompt the user to provide a variable name for the sheet:
    disp(fileNames{x})
    headers{x} = input('What do you want to name the column header for this data? (put in single quotes) ');
%     % Use a try loop to add variable name to the header in case the user
%     % makes a mistake
%     try
%         compiledRaw.Properties.VariableNames{x} = fileVarName;
%         flag = 0;
%     catch
%         disp('Something was wrong with the variable name, try again.');
%         fileVarName = input('What do you want to name the column header for this data? (no symbols allowed, put in quotes) ');
%     end
%     
    % Add the headings to the table
    compiledRaw.Properties.VariableNames = headers;
    end
end




%% Take the dF/F

% Calculate and store the dF/F values 
disp('These are the dF/F values calculated:') % To make things pretty on the user end
% The operations can't be performed in a table so we need everything to be
% an array
tempRaw = table2array(compiledRaw); % Convert our raw data into an array
tempDFF = zeros(size(tempRaw)); % Set up another array to store our dF/F values
for jColumns = 1:width(compiledRaw) % For as many columns are in the table
    fo = median(tempRaw(1:2,jColumns)); % The Fo is the median of the baseline frames
    disp(fo); % Show the dF/F
    for iRows = 1:height(compiledRaw) % For as many frames as there are
        tempDFF(iRows,jColumns)=(((tempRaw(iRows,jColumns)-fo))/fo); % Calculate the dF/F and store it in a matrix
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



