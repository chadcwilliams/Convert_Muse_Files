%Convert MUSE to BrainVision Analyzer
%Created by Chad Williams, M.Sc. student in Dr. Olav Krigolson's
%Neuroeconomics laboratory at the University of Victoria
%www.neuroeconlab.com
%www.chadcwilliams.weebly.com

%%%UPDATE HISTORY%%%
%June 2017, v2.0 - Adapted to new data structure
                %- Removed the fix for oddball data
                %- Changed offset to ask for seconds, not datapoints
%January 2017, v1.1 - Added a parameter to account for different sized
                      %segments, and a parameter to fix the oddball data
                      %(as the current CA has a bug).
%October 2016, v1.0

%% Starting information
clear all; close all; clc; %Clear data

%Directories and pathways
working_dir = uigetdir('','Find folder with your data'); %Point to where the data is
cd(working_dir); %Change directory to where the data is
addpath(fullfile(fileparts(which('convert_MUSE_to_BV.m')),'./Other Files')); %Add the path for supporting files

%New data folder check and creation
dircheck = exist(fullfile(working_dir, 'BV Data')); %Check to see if BV Data folder exists
addnum = 0; %If folder did exist, assume user knows that
if dircheck ~= 7
    mkdir('BV Data'); %If output folder does not exist, create it
    addnum = 1; %If folder did not exist, assume user did not know we will create it
end

%% User input
%Prompt questions
prompt = {'Continuous (0) or segmented (1) data?','Enter the prefix of your participant filename','Baseline Offset (In milliseconds; mark 0 if continuous)','What is your sampling rate', 'If applicable, What is the size of your segments (ms)'};
defaultans = {'1','Participant_','200','500','1000'}; %Default answers
dlg_title = 'MUSE to BV 2.0'; %Title
num_lines = 1; %Lines of input
answer = inputdlg(prompt,dlg_title,num_lines,defaultans);%Record answers

%Determine user input
segmented = str2num(cell2mat(answer(1))); %Determine whether to use continuous or segmented script
prefix = cell2mat(answer(2)); %Determine how many filenames to skip to get to data
samprate = str2num(cell2mat(answer(4))); %Determine sampling rate
offset = str2num(cell2mat(answer(3)))*(samprate/1000); %Determine baseline offset (data points before event)
segsize = str2num(cell2mat(answer(5)))/2; %Determine length of each segment

%Create a list of participant names
filenames = dir(strcat(prefix,'*')); %Create matrix of file names in the directory

%% Continuous Data
if segmented == 0
    for counter = 1:length(filenames) %Number of participants - if this is incorrect make sure the skipped files was correct (line 38 to 44)
        
        %Load participant data
        current_name = filenames(counter).name; %Name of participant
        IXDATA = []; %Clear past participant data
        EEG = []; %Clear past participant structure
        load(current_name); %Load current participant data
        current_name = strtok(current_name,'.'); %Remove filetype for saving
        IXDATA = [EEG{1} EEG{2}]; %Flip data to correct orientation
        EEG = [];
        
        %The structure EEG will be used to convert into BV
        [EEG.data] = IXDATA; %The data
        [EEG.srate] = samprate; %The sampling rate
        [EEG.chanlocs] = readlocs('MUSE.locs'); %The electrodes and their locations
        [EEG.nbchan] = 4; %Number of electrodes
        [EEG.event] = []; %The events - this data is continuous so there will be no markers
        [EEG.pnts] = length(EEG.data); %How many data points
        [EEG.trials] = 1; %Number of trials
        
        %Center data and transform into microvolts
        means = mean(EEG.data,2); %Determine means of each data point
        for row = 1:size(means,1)
            EEG.data(row,:) = EEG.data(row,:) - means(row); %Center data
        end
        EEG.data(:,:) =  EEG.data(:,:)*1.64498; %Convert to microvolts
        
        %Save data as BVA
        cd('BV Data'); %Change directory to new BrainVision data location
        pop_writebva(EEG, current_name); %This script converts the data
        cd(working_dir); %Change directory to MUSE data location
    end
end

%% Segmented Data

if segmented == 1
    for counter = 1:length(filenames) %Number of participants - if this is incorrect make sure the skipped files was correct (line 38 to 44)
        
        %Load data
        current_name = filenames(counter).name; %Name of participant
        IXDATA = []; %Clear past participant data
        EEG = []; %Clear past participant structure
        load(current_name); %Load current participant data
        %[EEG{1}] = check_data(EEG{1}); % check for old format files (we used to collect MUSE with a different structure)
        %[EEG{2}] = check_data(EEG{2}); % check for old format files (we used to collect MUSE with a different structure)
        IXDATA = ALLEEG; %Compile all of condition 1 and all of condition 2
        trial1 = length(find(markers==1)); %Determine number of trials for condition 1
        trial2 = length(find(markers==2)); %Determine number of trials for condition 2
        EEG = []; %Clear structure
        current_name = strtok(current_name,'.'); %Remove filetype for saving
        
        %The structure EEG will be used to convert into BV
        [EEG.offset] = offset; %How long the baseline is (this offsets markers)
        [EEG.data] = IXDATA; %The data
        [EEG.srate] = samprate; %The sampling rate
        [EEG.chanlocs] = readlocs('MUSE.locs'); %The electrodes and their locations
        [EEG.nbchan] = 4; %Number of electrodes
        [EEG.xmin] = 0; %A check for latency
        [EEG.pnts] = segsize; %Data points in a trial
        [EEG.trials] = length(markers); %Total number of trials
        for markcount = 1:length(markers)
           [EEG.event(markcount).type] = ['S ' num2str(markers(markcount))]; %Insert marker files
        end
                
        %Center data and transform into microvolts
        means = mean(EEG.data,2); %Determine means of each data point
        for row = 1:size(means,1)
            EEG.data(row,:) = EEG.data(row,:) - means(row); %Center data
        end
        EEG.data(:,:) =  EEG.data(:,:)*1.64498; %Convert to microvolts
        
        %Save data as BVA
        cd('BV Data'); %Change directory to new BrainVision data location
        pop_writebva_seg(EEG, current_name); %This script converts the data
        cd(working_dir); %Change directory to MUSE data location
    end
end

%%
clc;
disp('Complete');

