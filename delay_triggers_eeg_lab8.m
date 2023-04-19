%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    MIDE EL DELAY DE LOS TRIGGERS Y ESTIMULOS EN EL REGISTRO DE EEG %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Notas:

% 09/02/2023. Fátima Álvarez(UAM): este script mide el retraso que tarda en
% presentarse un estímulo en relación al trigger enviado por el ordenador
% de estimulación. Para ello necesitamos:
    % archivo .bdf con la medida de la célula fotoeléctrica
    % archivo .mat con el archivo de conducta

%% Requisitos antes de correr el script:
% % Si corres es script en versiones recientes de Matlab, asegurar disponer
% % de las siguientes toolbox_
%     % Image Processing Toolbox (images)
%     % Optimization Toolbox (optim)
%     % Signal Processing Toolbox (signal)
%     % Statistics and Machine Learning Toolbox (stats)

% restoredefaultpath % --> si no se ha hecho esto ya, correr esta parte para que funcione
% addpath C:\Psicofis\fieldtrip-20230128; % add ultimate version with subfolders
%  ft_defaults % restore default values
% addpath('C:\') % add folder with analysis script

clear all; close all; clc

%% Define ================================================================
ruta_comun='C:\Users\FA.5052232\OneDrive - UAM\PhD\2022_DATOS\datos_emotxt22\delay_emotxt\'; % ruta datos
sujeto_eeg= 's222222'; % meter el registro en el que se ha usado la célula fotoeléctrica
direc_eeg=[sujeto_eeg,'\'];
ruta_eeg=[ruta_comun, direc_eeg];
cd(ruta_eeg)
 

%% Read EEG data =========================================================

eegfile= ls(sprintf('txt_%s.bdf',sujeto_eeg (2:end))); 

% Define channels
cfg=[];
cfg.dataset=eegfile;
cfg.channel={'all' '-EXG6' '-EXG7' '-EXG8' '-Status'};
cfg.reref = 'yes';
cfg.refchannel = 'EXG5';
data=ft_preprocessing(cfg);

% Read triggers
event= ft_read_event(eegfile);
event = event(find(strcmp({event.type},'STATUS')));
    for evento=1:length(event)
        triggers(evento,1)=event(evento).sample;
        triggers(evento,2)=event(evento).value;
    end

% find first trigger// it is adding 512 to the pre-established values
elemento= find (triggers(:,2)==512); % trigger 0, value 512
triggers(elemento, :)=[]; % removal of discrepant elements
  
elemento= find (triggers(:,2)==768); % find photoelectric cell trigger
triggers(elemento, :)=[]; 

celula= data.trial{1,1}(70,:); % cell is channel 70
time = data.time{1,1};


%% Delay calculation:

% Matrix when rows are essays and columns are:
% 1: time point
% 2: trigger value
% 3: delay in milliseconds

triggers_temp = [triggers zeros(size(triggers,1),1)];

% For each timepoint in triggers
    for tp=1:size(triggers,1)

        % Timepoint index:
        TP_index = triggers(tp,1);

        % Diff_Vector
        if tp<size(triggers,1)
            Diff_Vect = diff(celula(TP_index+1:triggers(tp+1,1))); % corrects mistaken delays (0 value)
        else
            Diff_Vect = diff(celula(TP_index+1:end)); % corrects mistaken delays (0 value)
        end

        % Find index of beginning of signal:
        ind_big_diffs = find(Diff_Vect>250); % sentitivity range: 100-500
        ind_real_trigger = ind_big_diffs(1)-1; % pick previous time point (before stimulus onset)

        % Obtain time value for trigger delay:
        delay_value = time(TP_index + ind_real_trigger) - time(TP_index);

        % Save in variable
        triggers_temp(tp,3) = delay_value*1000;
        triggers_temp(tp,4) = ind_real_trigger;
    end

%% Find extreme delays  
bajos= find (triggers_temp(:,3)<= 5)
altos= find (triggers_temp(:,3)>=17)

%% Plot an essay to check the measure
close all
ensayo = 20; % essay
ini= triggers_temp (ensayo, 1);
real= ini+triggers_temp (ensayo, 4);

figure
plot(celula, 'color',[0 0 0], 'LineWidth',2);
hold on
xline(ini,'-g', 'LineWidth',1);xline(real,'-r', 'LineWidth',1);
xlim([ini-10 real+10]);

%% **  A PARTIR DE AQUÍ CADA EXPERIMENTO ES DIFERENTE:

%% behavior data:
cd(ruta_eeg)
fichconducta=['Output_', sujeto_eeg]; load (fichconducta)
    
%% statistical analysis table:
pto= triggers_temp(:,1); % previous variables
trigger= triggers_temp(:,2); 
delay= triggers_temp(:,3);
id= e(:,1); txt= e(:,2); % behaviour variables
stat_data= table(pto, trigger ,delay, id, txt);

summary (stat_data); mean (triggers_temp(:, 3))

%% Export exportar archivo para análisis:

save stat_data.csv;
[success,message]=xlswrite([ruta_eeg '\delay.xlsx'],triggers_temp);   
   