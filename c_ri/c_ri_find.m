function [events_tint]=c_ri_find(run_steps,st_m, et_m, min_angle, min_ampl, period, d2MP, psw)
%
% c_ri_find(run_steps,st_m, et_m, min_angle, min_ampl, period)
% c_ri_find('continue') - continue from the last position
%
%Example
% c_ri_find([1 1 1 1], [2002 02 03 0 0 0], [2002 07 08 0 0 0], 150, 5, 3, 3,2);
% does all steps from [2002 02 03 0 0 0] to [2002 07 08 0 0 0], with
% minum angle at 150 degrees, ,minumum amplitud 5 nT, the period to class to events as one
% is 3 seconds and the maximum distance to MP is 3 Re and the solarwind preassure i
% 2 nPa.
%
%Input:
% st_m -[yyyy | mm | dd | hh | mm | ss] - can be in matrix
% et_m -[yyyy | mm | dd | hh | mm | ss] - can be in matrix
% min_angle -[150|165], must have same number of rows as
%            "st_m"
% min_ampl -[5|10], must have same number of rows as
%            "st_m"
% period - download data and plot time interval event+-period 
% d2MP -distance to MP, in Re
% psw -solarwind preassure, in nPa
% run_steps - [ 0 | 1 | 1 | 1 ]
%       if one element is zero then the step will be jumped
% 		the steps are:
%		1) calculating the MP-crossings
%		2) obtaining angles for potential events and classing as events
%   3) Filtering the events (reducing the numbers), get event data (not ready yet)
% 		   and turn the events into a ascii file and a jpeg figure
%Output:
%  save to mMP variables
% saved to file:
% p_E = './E/';      -the found events
% p_R ='./R/';       -the events in ascii and a figure
%
% Result file, the processed events written to file
% R_F20020302t030000_T20020302t040000.txt
%
% Figure files of the processed events
% F_20020302t033512.jpg
%
%Descrition of the function:
% Finds the times when the satellites are within +-d2MP, downloads the data
% for this period. Then the angles are calculated and if the angles and the
% amplitude are larger than a certian threshold. This time is classed as
% an event. The events are reduced by classing two events as the same events
% if the timedifferance is less than half of period.
%
% Adopted from c_ri_run_all

%--------------------- the beginning --------------------------
if  nargin == 0
   help c_ri_find;return;
end

flag_continue=0;
if  nargin == 1 
  if strcmp(run_steps,'continue')
    disp('loading .c_ri_parameters');
    load '.c_ri_parameters.mat'
    flag_continue=1;
  else
    disp('Using default values');
    %This is where you write the matrix with the timeintervalls
    st_m =[2002 02 02 0 0 0; 2001 02 01 0 0 0];
    et_m =[2002 07 09 0 0 0; 2001 07 08 0 0 0];
    min_angle(1:2) = [150 170];
    min_ampl(1:2) = 5;
    period(1:2) = 3;
    d2MP = 3;
    psw =2;
  end
end

if ~exist('st_m'), error('Start time not defined');end
if ~exist('et_m'), error('End time not defined');end
[r , c] = size(st_m);
if ~exist('min_angle'), min_angle(1:r) = 150;disp(['min_angle not defined, using min_angle=' num2str(min_angle)]);end
if ~exist('min_ampl'), min_ampl(1:r) = 5;disp(['min_ampl not defined, using min_ampl=' num2str(min_ampl)]);end
if ~exist('period'), period(1:r) = 5;disp(['period not defined, using period=' num2str(period)]);end
if ~exist('d2MP'), d2MP = 3;disp(['distance to MP not defined, using d2MP=' num2str(d2MP)]);end
if ~exist('psw'), psw = 3;disp(['SW pressure not defined, using psw=' num2str(psw)]);end

if ~exist('p_E'),  p_E = './E/'; end % path for events
if ~exist('p_R'),  p_R = './R/'; end % path for results

path_ok='disp([])';
while ~strcmp(path_ok,'c'),
  eval(path_ok);
  disp('=========== Path information =========');
  disp(['found events          > p_E  = ''' p_E ''';']);
  disp(['events ASCII, figures > p_R  = ''' p_R ''';']);
  disp('======================================');
  disp('To change enter new value, e.g. >p_A=[pwd ''/''];  or >p_R=''/share/tmp'';');
  disp('To continue >c');
  path_ok=input('>','s');
  if exist('.c_ri_parameters.mat'),
    try save -append .c_ri_parameters.mat p_E p_R;
    catch disp('Paths changes valid only for this run!');
    end
  else
    try save .c_ri_parameters.mat st_m et_m min_angle min_ampl period d2MP psw run_steps;
    catch disp('Paths changes valid only for this run!');
    end
  end
end

try save -append '.c_ri_parameters.mat' p_E p_R;
catch disp('Input parameters not saved');
end

[i_end,c] = size(st_m);

if flag_continue,
  if exist('time_interval_start'),
    i_start=time_interval_start;
    disp(['Sarting at ' num2str(i_start) '. time interval']);
  end
  if exist('MP_interval_start'),
    j_start=MP_interval_start;
    disp(['Sarting at ' num2str(j_start) '. MP crossing interval']);
  end
end

if ~exist('i_start'),i_start=1;end
if ~exist('j_start'),j_start=1;end

for i = i_start:i_end
  time_interval_start=i;
  try save -append '.c_ri_parameters.mat' time_interval_start;
  catch disp('Could not save time_interval_start');
  end

  disp([num2str(i) '. time interval. ' datestr(st_m(i,:),31) ' -- ' datestr(et_m(i,:),31)]);
  st = st_m(i,:);
  et = et_m(i,:);
  
  %step 1
  if run_steps(1) == 1
    disp('==============  Finding MP crossings ====================');
    [passing_MP,dist_t]=c_ri_auto_event_search(st,et,d2MP,psw);
    disp('Predicted MP crossings');
    if passing_MP == 0, passing_MP=[];dist_t=[]; end % does not finds predicted MP crossings
    for j=1:size(passing_MP,1)
      disp([num2str(j) '. ' datestr(epoch2date(passing_MP(j,1))) ' - ' datestr(epoch2date(passing_MP(j,2)))]);
    end
    save mMP passing_MP dist_t
  end
  
  %step 2
  if run_steps(2) == 1
    if run_steps(1) == 0; load mMP; end
    disp('==============  Finding angles that class as events for MP crossings ====================');
    angles=[];amplitude=[];events=[];
    for j=j_start:size(passing_MP,1)
      MP_interval_start=j;
      try save -append '.c_ri_parameters.mat' MP_interval_start;
      catch disp('Could not save MP_interval_start');
      end
      disp('????????????????????????????????????????????????????????????');
      disp([num2str(j) '. ' datestr(epoch2date(passing_MP(j,1))) ' - ' datestr(epoch2date(passing_MP(j,2)))]);
      disp('????????????????????????????????????????????????????????????');
      [B1,B2,B3,B4]=c_get_bfgm(passing_MP(j,:),1:4);
      if ~isempty(B1)>0,
        c_eval('try Binterp?=av_interp(B?,B1); catch Binterp?=[]; end;',2:4);
        if ~isempty(Binterp2) & ~isempty(Binterp3) & ~isempty(Binterp4),
          [angles_tmp, ampl_tmp] = c_ri_angles_and_ampl(B1,Binterp2,Binterp3,Binterp4);
          if ~isempty(angles_tmp),
            [time_of_events,angles_out,ampl_out] = class_angle_as_event(angles_tmp,ampl_tmp, min_angle, min_ampl,-1) ; % -1 is mode (no idea which)
            if ~isempty(time_of_events), 
              sort_events=1;
              while sort_events
                dt_events=diff(time_of_events(:,1),1,1); % find distance between events
                ind=find(dt_events<period/2); % find which events are closer than period/2 
                if isempty(ind), 
                  sort_events=0;
                else  
                  time_of_events(ind(1),:)=[];
                  angles_out(ind(1),:)=[];
                  ampl_out(ind(1),:)=[]; 
                end
              end
            end
            events=[events;time_of_events];
            angles=[angles;angles_out];
            amplitude=[amplitude;ampl_out];
          end
        end
      end
    end
    save mEvents events angles amplitude;
    disp(['Alltogether found ' num2str(size(events,1)) ' events.']);
  end    
  %step 3
  if run_steps(3) == 1
    if run_steps(2) == 0; load mMP;load mEvents; end
    disp('==============  Plotting data for events ====================');
    if exist('events'),
      if ~isempty(events),
        c_ri_event_picture(events,period,angles,amplitude,p_R)
      end
    end
  end
  j_start=1;
end

