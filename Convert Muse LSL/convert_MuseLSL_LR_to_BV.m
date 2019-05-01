%Convert Peer to BrainVision Analyzer
%Created by Chad Williams, M.Sc. student in Dr. Olav Krigolson's
%Neuroeconomics laboratory at the University of Victoria
%www.neuroeconlab.com
%www.chadcwilliams.weebly.com

%%%UPDATE HISTORY%%%
%July 2017 - Created for the app Peer, converted from the script
        %'convert_MUSE_to_BV_2_0'

%% Starting information
clear all; close all; clc; %Clear data

%Directories and pathways
working_dir = uigetdir('','Find the folder with your data'); %Point to where the data is
cd(working_dir); %Change directory to where the data is
addpath(fullfile(fileparts(which('convert_MUSE_to_BV.m')),'./Other Files')); %Add the path for supporting files

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
    current_name = filenames(counter).name;
    %Load data
    EEG = []; %Clear past participant structure
    raw = [];
    raw = eeg_load_xdf(current_name);
    current_name = strtok(current_name,'.'); %Remove filetype for saving
    
    %Insert markers
    markers = []; %Clear markers variable
    for count = 1:length(raw.event)
        markers(1,count) = str2num(raw.event(count).type); %Create variable for markers
        markers(2,count) = raw.event(count).latency; %Add time stamps in datapoints to the markers
    end

    %The structure EEG will be used to convert into BV
    [EEG.data] = raw.data(1:4,:); %Create variable for EEG data
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
    pop_writebva_MuseLSL(EEG, current_name); %This script converts the data
    cd(working_dir); %Change directory to MUSE data location
end

%%
clc;
disp('Complete');

