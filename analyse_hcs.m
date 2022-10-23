% analyse_loss.m -->
% MOOSE : Matlab Tool for STPA Evaluation
% This program is used to generate a report of the unsafe control actions
% and the associated hazards along with the responsible blocks that may
% cause these actions.
% There is also an ability for the user to add requirements for the
% specific UCA(s).
% 1. Run this file
% 2. Select the simulink stpa file (eg. stpa_test_model.mdl)
% 3. Check the stpa_hcs.txt file for the summary of losses and hazards
%
% The report file can be opened in word and table can be generated using
% 'text to table' delimited by '|'
%
% For STPA refer http://psas.scripts.mit.edu/home/get_file.php?name=STPA_handbook.pdf

% Copyright(C) Aditya Y Jeppu, adi.jeppu28@gmail.com
% Modified by Ravi Kiran on 9/15/2021
%   - Sort based on position of block
% Modified by Ravi Kiran on 9/15/2021
%   - Sort based on position of block

clear all
clc
filename = uigetfile;
open_system(filename);

%Begin diary
if exist('stpa_hcs.txt','file')
    delete stpa_hcs.txt;
end
diary stpa_hcs.txt;

dtime = datetime('now');
disp('MOOSE : Matlab Tool for STPA Evaluation')
disp(' ')
disp(['Report created on : ' datestr(dtime)])
disp(' ')
reqlist = {};
% get the control_action blocks
allBlks = find_system(gcs, 'MaskType', 'control_action');

for i = 1:size(allBlks,1)
    d{i}=get_param(allBlks{i},'Name');
end

% get the source block of the control action block and check if it is not a
% control_action block. If it is then make c at index as 'none' or make c
% at index as 'Name' of block.
for i = 1:size(allBlks,1)
    a=get_param(allBlks{i},'PortConnectivity');
    b=get_param(a(1).SrcBlock,'MaskType');
    
    if strcmp(b,'control_action')
        get_param(a(1).SrcBlock,'Name');
        c{i} = 'none';
    else
        name = get_param(a(1).SrcBlock,'NAMEFORBLOCK');
        c{i}=name;
    end
    
end

index = find(strcmp(c, 'none'));  % get the indices for CA blocks not connected to control

% get the name of control_action blocks that are connected to same block
% type
while ~isempty(index)
    for i = 1:length(index)
        a=get_param(allBlks{index(i)},'PortConnectivity');
        b=get_param(a(1).SrcBlock,'Name');
        iix=find(strcmp(d, b));
        ii = find(index==iix);
        if isempty(ii)
            c{index(i)}=c{iix}  ;
        end
    end
    index = find(strcmp(c, 'none'));
end

posD={};
% sort the list of such blocks to be in hierarchical order
% based on their positions
% Find the position of the block
for i=1:length(c)
    blkDet=find_system(bdroot,'NAMEFORBLOCK',c{i});
    posD{i}=get_param(blkDet{1},'Position');
end
posSort={};
% Convert into single matrix
posMat=cell2mat(posD');
% Sort based on position: Priority is top left and then bottom right
[sortPos, s2]=sortrows(posMat,[2 3]);
[a1,a2,a3] = unique(c(s2)); % get the unique from the sorted list
uc=c(s2(sort(a2))); % get the sorted list in order
ic = 1;
count = 1;

% display the result.
disp(['Responsibility  |Not providing causes hazard |Providing causes hazard |' ...
    'Too early, too late, out of order |Stopped too soon, applied too long '])
for i = 1:length(s2)
    if (ic <= length(uc))
        if strcmp(c{s2(i)},uc{ic})
            ic = ic+1;
            disp(['Responsible Block : ' c{s2(i)} '| | | |']);
            rb = c{s2(i)} ;
        end
    end
    b=get_param(allBlks{s2(i)},'DES');
    b=strrep(b,'\n','');
    b1=get_param(allBlks{s2(i)},'UCA1');
    b2=get_param(allBlks{s2(i)},'UCA2');
    b3=get_param(allBlks{s2(i)},'UCA3');
    b4=get_param(allBlks{s2(i)},'UCA4');
    disp([b '|' b1 ' | ' b2 ' | ' b3 ' | ' b4]);
    list = {rb, b, b1, b2, b3, b4};
    reqlist{count} = list;
    count = count + 1;
end
disp(' ')
disp('Make a table and provide constraints for the UCA(s)')
count = 1;

dict = {'NP', 'P', 'TE', 'S'};

% display all the UCAs to write requirements for
disp('Responsible Block | Responsibility | UCA Number | UCA | Constraints')
for fl = 1:(length(s2))
    a = reqlist{fl};
    for fl2 = 3:6
        if ~isempty(a{fl2})
            disp([a{1} ' | ' a{2} '| ' num2str(count) ' | ' dict{fl2-2} ': ' a{fl2} ' | '])
            count = count + 1;
        end
    end
end


% handle=get_param(gcs,'handle');
%
% print(handle,'-dsvg',gcs);

diary off;