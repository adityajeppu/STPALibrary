% analyse_loss.m -->
% MOOSE : Matlab Tool for STPA Evaluation
% This program is used to generate a report of the losses
% and the associated hazards or sub hazards based on a
% simulink model designed using stpa library blocks
% 1. Run this file
% 2. Select the simulink stpa file (eg. stpa_test_model.mdl)
% 3. Check the stpa_lh.txt file for the summary of losses and hazards
%
% NOTE : The stpa model should have only two levels of hazards i.e.
%        Losses --> Hazards --> Sub-Hazards. The loss blocks should not
%        include inports but only outports.
%
% The report file can be opened in word and table can be generated using
% 'text to table' delimited by '|'
%
% For STPA refer http://psas.scripts.mit.edu/home/get_file.php?name=STPA_handbook.pdf

% Copyright(C) Aditya Y Jeppu, adi.jeppu28@gmail.com


clear all
clc
filename = uigetfile;
open_system(filename);
allBlks = find_system(gcs, 'MaskType', 'loss');
% Get all the loss blocks in the model

%Begin diary
if exist('stpa_lh.txt','file')
    delete stpa_lh.txt;
end
diary stpa_lh.txt;

% Display the header
dtime = datetime('now');
disp('MOOSE : Matlab Tool for STPA Evaluation')
disp(' ')
disp(['Report created on : ' datestr(dtime)])
disp(' ')

% display details of losses
for i = 1:size(allBlks,1)
    d{i}=get_param(allBlks{i},'Name');
end
disp('Table 1: The Losses identified are')
disp('Loss | Description');
for i = 1:size(allBlks,1)
    d{i}=get_param(allBlks{i},'Name');
    s=get_param(allBlks{i}, 'DES');
    s=strrep(s,'\n','');
    disp([get_param(allBlks{i}, 'NAMEFORBLOCK') ' | ' s])
end
disp(' ')

% For every loss identfy the hazard blocks attached to it
temp = [];
for i= 1:size(allBlks,1)
    a=get_param(allBlks{i},'PortConnectivity');
    % find if many destination blocks
    for m = 1:size(a, 1)
        dstblk = a(m).DstBlock;
        temp = [temp dstblk];
    end
end
temp=unique(temp); % remove duplicates

disp('Table 2: The Hazards identified are')
for i = 1:length(temp)
    c=get_param(temp(i),'PortConnectivity');
    A='';
    for j = 1:length(c)
        if ~isempty((c(j).SrcBlock))
            A=[A get_param(c(j).SrcBlock, 'NAMEFORBLOCK')];
            A=[A ', '];
        end
        
    end
    
    P{i}=A(1:end-2);  % Get all losses attached to first level hazard
end
disp('Loss | Hazard | Sub Hazard | Description | Constraint');
for i = 1:length(temp)
    iprint = 0;
    c=get_param(temp(i),'PortConnectivity');
    for m = 1:length(c)
        if ~isempty((c(m).DstBlock))
            for k = 1:length(c(m).DstBlock)
                s1=get_param(c(m).DstBlock(k), 'DES');
                s1=strrep(s1,'\n','');
                disp([ '| | ' get_param(c(m).DstBlock(k), 'NAMEFORBLOCK') '|' s1])
            end
        else
            if iprint == 0
                iprint = 1;
                s1=get_param(temp(i), 'DES');
                s1=strrep(s1,'\n','');
                disp([ P{i} '|' get_param(temp(i), 'NAMEFORBLOCK') '| | ' s1 ' |'])
            end
        end
    end
    
end


% close diary
diary off;
