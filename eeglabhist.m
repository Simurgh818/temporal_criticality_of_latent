% EEGLAB history file generated on the 12-Mar-2025
% ------------------------------------------------

EEG.etc.eeglabvers = '2020.0'; % this tracks which version of EEGLAB is being used, you may ignore it
EEG = eeg_checkset( EEG );
EEG = eeg_checkset( EEG );
EEG = eeg_checkset( EEG );
EEG = eeg_checkset( EEG );
EEG= pop_overwritevent( EEG, 'codelabel');% Script: 30-Sep-2024 22:42:16
EEG= pop_editeventlist( EEG , 'AlphanumericCleaning', 'on', 'BoundaryNumeric', { -99}, 'BoundaryString', { 'boundary' }, 'List', 'C:\Users\Aya Rezeika\sciebo2\ARE\PhD\mark001\binsP1.txt', 'SendEL2', 'EEG', 'UpdateEEG', 'codelabel' );% Script: 30-Sep-2024 22:42:16
EEG.setname='eventlists BLAAvgBOS2';
EEG = eeg_checkset( EEG );
EEG = eeg_checkset( EEG );
EEG = eeg_checkset( EEG );
EEG = eeg_checkset( EEG );
EEG.setname='ICAremovedBLAS2';
EEG = eeg_checkset( EEG );
EEG = pop_epochbin( EEG , [-500.03000.0],'none');% Script: 30-Sep-2024 22:44:56
EEG.setname='binepochs filtered ICArej BLAAvgBOS2';
EEG = eeg_checkset( EEG );
EEG.etc.eeglabvers = 'dev'; % this tracks which version of EEGLAB is being used, you may ignore it
pop_topoplot(EEG, 0, [1:28] ,'binepochs filtered ICArej BLAAvgBOS2',[5 6] ,0,'electrodes','on');
