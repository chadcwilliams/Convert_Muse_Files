%Convert MUSE to BrainVision Analyzer
%Created by Chad Williams, M.Sc. student in Dr. Olav Krigolson's
%Neuroeconomics laboratory at the University of Victoria
%www.neuroeconlab.com

%March 2017, V1.3 - A temp file adding MUSELab continuous data with
%markers

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
prompt = {'Continuous (0), segmented (1), or Continuous w/ Markers (2) data?','Enter the prefix of your participant filename','Baseline Offset (data points; mark 0 if continuous)','What is your sampling rate', 'If applicable, What is the size of your segments (ms)', 'Fix oddball data? 1 = yes, 0 = no'};
defaultans = {'1','Participant_','0','500','1000', '0'}; %Default answers
dlg_title = 'MUSE to BV 1.1'; %Title
num_lines = 1; %Lines of input
answer = inputdlg(prompt,dlg_title,num_lines,defaultans);%Record answers

%Determine user input
segmented = str2num(cell2mat(answer(1))); %Determine whether to use continuous or segmented script
prefix = cell2mat(answer(2)); %Determine how many filenames to skip to get to data
offset = str2num(cell2mat(answer(3))); %Determine baseline offset (data points before event)
samprate = str2num(cell2mat(answer(4))); %Determine sampling rate
segsize = str2num(cell2mat(answer(5)))/2;
oddballfix = str2num(cell2mat(answer(6)));

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
        %IXDATA = [EEG{1} EEG{2}]; %Flip data to correct orientation
        EEG = [];
        
        %The structure EEG will be used to convert into BV
        [EEG.data] = IXDATA.raw.eeg.data; %The data
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


%% Continuous with Markers Data
if segmented == 2
    for counter = 1:length(filenames) %Number of participants - if this is incorrect make sure the skipped files was correct (line 38 to 44)
        
        %Load participant data
        current_name = filenames(counter).name; %Name of participant
        IXDATA = []; %Clear past participant data
        EEG = []; %Clear past participant structure
        load(current_name); %Load current participant data
        current_name = strtok(current_name,'.'); %Remove filetype for saving
        EEG = [];
        %IXDATA.m_struct.i_times(2) = IXDATA.raw.eeg.times(end); % For end of rest marker
                
        %The structure EEG will be used to convert into BV
        [EEG.offset] = offset; %How long the baseline is (this offsets markers)
        [EEG.data] = transpose(IXDATA.raw.eeg.data); %The data
        [EEG.srate] = samprate; %The sampling rate
        [EEG.chanlocs] = readlocs('MUSE.locs'); %The electrodes and their locations
        [EEG.nbchan] = 4; %Number of electrodes
        [EEG.xmin] = 0; %A check for latency
        [EEG.event] = []; %The events - this data is continuous so there will be no markers
        [EEG.trials] = length(IXDATA.m_struct.i_times); %Number of trials
        [EEG.pnts] = length(EEG.data); %How many data points
        [EEG.segmented] = segmented;
        
        
%         %Find Marker Times by column
%         for count = 1:length(IXDATA.m_struct.i_times)
%             tempindex = find(IXDATA.raw.eeg.times > IXDATA.m_struct.i_times(count));
%             markertime{count,1} = tempindex(1,1);
%         end
        
        %Adjusts times to seconds from start
        EEG.start_time = IXDATA.raw.eeg.times(1);%When first eeg data came in
        IXDATA.m_struct.i_times = (IXDATA.m_struct.i_times- EEG.start_time)/(1000/samprate); %Markers times in datapoints
        IXDATA.raw.eeg.times = (IXDATA.raw.eeg.times - EEG.start_time)/(1000/samprate); %Datatimes converted to datapoints
        
        %Markers
        for count = 1:length(IXDATA.m_struct.i_times)
            [EEG.event(count).type] = sprintf('S %d', count); %Name of markers
            format long g
            templatency = num2str(round(IXDATA.m_struct.i_times(count)*1000));
            [EEG.event(count).latency] = templatency; %Times of markers
            
        end     
        for count = 1:length(IXDATA.m_struct.i_times)
            [EEG.event(length(IXDATA.m_struct.i_times) + count).type] = sprintf('S 99', count); %Name of markers
            format long g
            templatency = num2str(round((IXDATA.m_struct.i_times(count)*1000)-1500));
            [EEG.event(length(IXDATA.m_struct.i_times) + count).latency] = templatency; %Times of markers
        end 
        
        %Save data as BVA
        cd('BV Data'); %Change directory to new BrainVision data location
        pop_writebva_seg_MUSELABMarkers(EEG, current_name); %This script converts the data
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
        IXDATA = [EEG{1} EEG{2}]; %Compile all of condition 1 and all of condition 2
        %IXDATA(isnan(IXDATA))=[]; %This is to fix Marie_Yoga data
        trial1 = length(EEG{1})/segsize; %Determine number of trials for condition 1
        trial2 = length(EEG{2})/segsize; %Determine number of trials for condition 2
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
        [EEG.trials] = trial1+trial2; %Total number of trials
        [EEG.segmented] = segmented; % To distinguish from MUSELab data
        for count = 1:trial1
            [EEG.event(count).type] = ['S 1']; %Attaches S 1 marker to all of condition 1 trials
        end
        for count = 1:trial2
            [EEG.event(trial1 + count).type] = ['S 2']; %Attaches S 2 marker to all of condition 2 trials
        end
        
        %There is a bug in one of the CA (the one that records 800ms for
        %oddball) where it puts a NaN at the end of each trial. This fixes
        %that.
        if oddballfix == 1
            x = segsize;
            for trial = 1:EEG.trials
                EEG.data(:,x) = EEG.data(:,x-1);
                x = x+segsize;
            end
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

