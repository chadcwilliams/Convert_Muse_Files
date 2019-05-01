%Convert Muse 2 to BrainVision Analyzer
%Created by Chad Williams, PhD student in Dr. Olav Krigolson's
%Theoretical and Applied Neuroscience laboratory at the University of Victoria
%www.krigolsonlab.com
%www.chadcwilliams.com

%%%UPDATE HISTORY%%%
%November 2018 - Created for the new Muse, converted from the script
%'convert_Peer_to_BV'

%% Starting information
clear all; close all; clc; %Clear data

%Directories and pathways
working_dir = uigetdir('','Find the folder with your data'); %Point to where the data is
cd(working_dir); %Change directory to where the data is
addpath(fullfile(fileparts(which('convert_MUSE2_to_BV.m')),'./Other Files')); %Add the path for supporting files

%New data folder check and creation
dircheck = exist(fullfile(working_dir, 'BV Data')); %Check to see if BV Data folder exists
if dircheck ~= 7
    mkdir('BV Data'); %If output folder does not exist, create it
end

%% Finding files
prefix = cell2mat(inputdlg('Enter the prefix of your participant filename','Peer to BV',1,{'Participant_'})); %Input participant file name
filenames = dir(strcat(prefix,'*')); %Create matrix of file names in the directory with the prefix

%% Process Data
for counter = 1:length(filenames) %Number of participants - if this is incorrect make sure the skipped files was correct (line 38 to 44)
    
    disp(strcat('Participant: ', num2str(counter))); %Display what participant is being converted
    
    %Load participant data
    current_name = filenames(counter).name; %Name of participant
    IXDATA = []; %Clear past participant data
    EEG = []; %Clear past participant structure
    
    %Load current participant data
    FID = fopen(current_name); 
    data = textscan(FID,'%s%s%s%s%s%s%s%s','Delimiter',',');
    fclose(FID);
    
    %Find rows that contain raw EEG data
    eeg_rows = find(contains(data{1,2},'/eeg'));
    
    %Find rows that contain marker data
    marker_rows = find(contains(data{1,2},'/annotation'));
    
    %Insert marker labels
    markers = [];
    temp_marks = data{1,3}(marker_rows,1);
    for count = 1:length(temp_marks)
        markers(1,count) = str2num(temp_marks{count,1}(10:end-1)); %Create variable for markers
    end
    
    %Insert marker timepoints 
    for count = 1:length(markers)
        [~, min_row] = min(abs(eeg_rows-marker_rows(count)));
        markers(2,count) = min_row;
    end
    
    %Remove filetype for saving
    current_name = strtok(current_name,'.'); 
    
    %The structure EEG will be used to convert into BV
    [EEG.data] = [str2double(data{1,3}(eeg_rows,1)),str2double(data{1,4}(eeg_rows,1)),str2double(data{1,5}(eeg_rows,1)),str2double(data{1,6}(eeg_rows,1))]'; %The data
    [EEG.srate] = 256; %The sampling rate
    [EEG.chanlocs] = readlocs('MUSE.locs'); %The electrodes and their locations (requires EEGLab Matlab Toolbox)
    [EEG.nbchan] = 4; %Number of electrodes
    [EEG.trials] = length(markers); %Total number of trials
    for markcount = 1:length(markers)
        [EEG.event(markcount).type] = ['S ' num2str(markers(1,markcount))]; %Insert marker names
        [EEG.event(markcount).latency] = num2str(round(markers(2,markcount))); %Add time to structure
    end
    
    %Save data as BVA
    cd('BV Data'); %Change directory to new BrainVision data location
    pop_writebva_Muse2(EEG, current_name); %This script converts the data
    cd(working_dir); %Change directory to MUSE data location
end

%%
clc;
disp('Complete');

