function [dE, dAmp, weight] = caa_sh_xoff(st,dt,flag_amp)
%CAA_SH_XOFF  sunward offset and amplitude correction in the sh/sw
%
% [dE, dAmp, weight] = caa_sh_xoff(st,dt [,flag_amp])
% [dE, dAmp, weight] = caa_sh_xoff(iso_st,iso_et [,flag_amp])
%
% Study sunward offset (X GSE) and amplitude correction
% factor by comparing EFW data with CIS HIA
%
% if FLAG_AMP is zero (default), use default amplitude correction
% factor = 1.1
%
% See also CAA_SH_PLAN, CAA_COROF_DSI

% Copyright 2007, 2014 Yuri Khotyaintsev

STEP = 600; % Averaging window
DEY = 0.5;  % Good Ey correspondence in mV/m
DAMP_DEF = 1.1; % Default amplitude correction factor

dE1 = NaN; dE2 = NaN; dE3 = NaN; dE4 = NaN;
dAmp1 = NaN; dAmp2 = NaN; dAmp3 = NaN; dAmp4 = NaN;
weight = 0;

if nargin<3, flag_amp = 0; end
if flag_amp~=0, flag_amp = 1; end

[st,dt] = irf_stdt(st,dt);
dt = ceil(dt/STEP)*STEP;
t = st:STEP:st+dt; t = t';

Ps1 = caa_get(st,dt,1,'Ps?'); %#ok<NASGU>
Ps2 = caa_get(st,dt,2,'Ps?'); %#ok<NASGU>
Ps3 = caa_get(st,dt,3,'Ps?'); %#ok<NASGU>
Ps4 = caa_get(st,dt,4,'Ps?'); %#ok<NASGU>

% Load spinfits
E1 = []; E2 = []; E3 = []; E4 = [];
for cli=1:4
  old_pwd = pwd;
  dirList = get_dir_list(st,dt,cli);
  if isempty(dirList), cd(old_pwd), continue, end
  
  % Concatenate intervals
  [~,ii] = sort([dirList.st]);
  es_tmp = [];
  for idxDir = ii;
    cd(dirList(idxDir).dir);
    spinFits = get_spin_fits();
    if isempty(spinFits), continue, end
    es_tmp = [es_tmp; spinFits.diEs]; %#ok<AGROW>
  end
  
  if ~isempty(es_tmp)
    es_tmp(isnan(es_tmp(:,2)),:) = []; %#ok<AGROW>
    es_tmp = irf_resamp(es_tmp,t); %#ok<NASGU>
    c_eval('E?=es_tmp;',cli)
  end
  cd(old_pwd)
end
		
diVCEh1 = caa_get(st,dt,1,'diVCEh?');
if ~isempty(diVCEh1)
    diVCEh1(isnan(diVCEh1(:,2)),:)=[];
    CE1=irf_resamp(diVCEh1,t);
else CE1 = [];
end

diVCEh3 = caa_get(st,dt,3,'diVCEh?');
if ~isempty(diVCEh3)
    diVCEh3(isnan(diVCEh3(:,2)),:)=[];
    CE3=irf_resamp(diVCEh3,t);
else CE3 = [];
end

% Plot
h = irf_plot(6);
on = 0; compStr='xy';
for co=1:2
  hca = irf_panel(['RAW E' compStr(co)]);
  if ~isempty(E1), irf_plot(hca,E1(:, [1 1+co]),'k'), on = 1; end
  if on, hold(hca,'on'), end
  if ~isempty(E2), irf_plot(hca,E2(:, [1 1+co]),'r'), on = 1; end
  if on, hold(hca,'on'), end
  if ~isempty(E3), irf_plot(hca,E3(:, [1 1+co]),'g'), on = 1; end
  if on, hold(hca,'on'), end
  if ~isempty(E4), irf_plot(hca,E4(:, [1 1+co]),'b'), on = 1; end
  if on, hold(hca,'on'), end
  if ~isempty(CE1), irf_plot(hca,CE1(:, [1 1+co]),'k+'), on = 1; end
  if on, hold(hca,'on'), end
  if ~isempty(CE3), irf_plot(hca,CE3(:, [1 1+co]),'g+'), on = 1; end
  hold(hca,'off')
  set(hca,'YLimMode','auto', 'XLimMode','auto','XTickLabel','')
  xlabel(hca,'')
  ylabel(hca,['E' compStr(co) ' [mV/m]'])
  if co==1
    title(hca,['SH/SW ' epoch2iso(st,1) ' -- ' epoch2iso(st+dt,1)...
      '  EFW (--), CIS HIA (+)'])
  end
end

% delta Ex
Eref = [];
hca = irf_panel('delta Ex'); on = 0;
if ~isempty(E1) && ~isempty(CE1)
  ii = find( abs(CE1(:,3)-E1(:,3)) < DEY );
  if ~isempty(ii)
    dEx = E1(ii,1:2);
    if flag_amp, dAmp = find_damp(E1(ii,3), CE1(ii,3));
    else dAmp = DAMP_DEF;
    end
    dEx(:,2) = dAmp*E1(ii,2) - CE1(ii,2);
    irf_plot(hca,dEx,'kx'), on = 1;
    dEx1 = mean(dEx(:,2));
    Eref = E1(:,1:3);
    Eref(:,2) = dAmp*Eref(:,2) - dEx1;
    Eref(:,3) = dAmp*Eref(:,3);
  end
end
if ~isempty(E3) && ~isempty(CE3)
  ii = find( abs(CE3(:,3)-E3(:,3)) < DEY );
  if ~isempty(ii)
    dEx = E3(ii,1:2);
    if flag_amp, dAmp = find_damp(E3(ii,3), CE3(ii,3));
    else dAmp = DAMP_DEF;
    end
    dEx(:,2) = dAmp*E3(ii,2) - CE3(ii,2);
    if on, hold(hca,'on'), end
    irf_plot(hca,dEx,'gx')
    dEx3 = mean(dEx(:,2));
    if isempty(Eref)
      Eref = E3(:,1:3);
      Eref(:,2) = dAmp*Eref(:,2) - dEx3;
      Eref(:,3) = dAmp*Eref(:,3);
    else
      Eref(:,2) = ( Eref(:,2) + dAmp*E3(:,2) - dEx3 )/2;
      Eref(:,3) = ( Eref(:,3) + dAmp*E3(:,3) )/2;
      irf_log('proc','using two signals')
    end
  end
end
set(hca,'YLimMode','auto', 'XLimMode','auto','XTickLabel','')
xlabel(hca,'')
ylabel(hca,'dEx [mV/m]')
if on, hold(hca,'off'), end

%Sc Pot
hcp = irf_panel('ScPot'); c_pl_tx(hcp,'Ps?'),ylabel(hcp,'Sc pot [-V]')

if ~isempty(Eref)
  weight = length(find(~isnan(Eref(:,2))))/(dt/STEP+1);
  hcx = irf_panel('Ex'); irf_plot(hcx, Eref(:,[1 2]),'o'), hold(hcx,'on')
  hcy = irf_panel('Ey'); irf_plot(hcy, Eref(:,[1 3]),'o'), hold(hcy,'on')
  legx = ''; legy = '';
  if ~isempty(E1)
    ii = find( ~isnan(Eref(:,2)) & ~isnan(E1(:,2)) );
    if ~isempty(ii)
      if flag_amp, dAmp1 = find_damp(E1(ii,3), Eref(ii,3));
      else dAmp1 = DAMP_DEF;
      end
      dE1 = mean(dAmp1*E1(ii,2)-Eref(ii,2))/dAmp1;
      
      irf_plot(hcx, [E1(:,1) dAmp1*E1(:,2)-dE1],'k')
      irf_plot(hcy, [E1(:,1) dAmp1*E1(:,3)],'k')
      legx = num2str(dE1,'dEx1 = %.2f');
      legy = num2str(dAmp1,'dAm1 = %.2f');
    end
  end
  if ~isempty(E2)
    ii = find( ~isnan(Eref(:,2)) & ~isnan(E2(:,2)) );
    if ~isempty(ii)
      if flag_amp, dAmp2 = find_damp(E2(ii,3), Eref(ii,3));
      else dAmp2 = DAMP_DEF;
      end
      dE2 = mean(dAmp2*E2(ii,2)-Eref(ii,2))/dAmp2;
      irf_plot(hcx,[E2(:,1) dAmp2*E2(:,2)-dE2],'r')
      irf_plot(hcy,[E2(:,1) dAmp2*E2(:,3)],'r')
      l = num2str(dE2,'dEx2 = %.2f');
      if isempty(legx), legx = l; else legx = [legx ', ' l]; end
      l = num2str(dAmp2,'dAm2 = %.2f');
      if isempty(legy), legy = l; else legy = [legy ', ' l]; end
    end
  end
  if ~isempty(E3)
    ii = find( ~isnan(Eref(:,2)) & ~isnan(E3(:,2)) );
    if ~isempty(ii)
      if flag_amp, dAmp3 = find_damp(E3(ii,3), Eref(ii,3));
      else dAmp3 = DAMP_DEF;
      end
      dE3 = mean(dAmp3*E3(ii,2)-Eref(ii,2))/dAmp3;
      irf_plot(hcx,[E3(:,1) dAmp3*E3(:,2)-dE3],'g')
      irf_plot(hcy,[E3(:,1) dAmp3*E3(:,3)],'g')
      l = num2str(dE3,'dEx3 = %.2f');
      if isempty(legx), legx = l; else legx = [legx ', ' l]; end
      l = num2str(dAmp3,'dAm3 = %.2f');
      if isempty(legy), legy = l; else legy = [legy ', ' l]; end
    end
  end
  if ~isempty(E4)
    ii = find( ~isnan(Eref(:,2)) & ~isnan(E4(:,2)) );
    if ~isempty(ii)
      if flag_amp, dAmp4 = find_damp(E4(ii,3), Eref(ii,3));
      else dAmp4 = DAMP_DEF;
      end
      dE4 = mean(E4(ii,2)-Eref(ii,2));
      irf_plot(hcx,[E4(:,1) dAmp4*E4(:,2)-dE4],'b')
      irf_plot(hcy,[E4(:,1) dAmp4*E4(:,3)],'b')
      l = num2str(dE4,'dEx4 = %.2f');
      if isempty(legx), legx = l; else legx = [legx ', ' l]; end
      l = num2str(dAmp4,'dAm4 = %.2f');
      if isempty(legy), legy = l; else legy = [legy ', ' l]; end
    end
  end
  if ~isempty(CE1)
    irf_plot(hcx,CE1(:, [1 2]),'k+')
    irf_plot(hcy,CE1(:, [1 3]),'k+')
  end
  if ~isempty(CE3)
    irf_plot(hcx,CE3(:, [1 2]),'g+')
    irf_plot(hcy,CE3(:, [1 3]),'g+')
  end
  hold(hcx,'off'), hold(hcy,'off')
  title(hcx,legx), ylabel(hcx,'Ex [mV/m]')
  if flag_amp, title(hcy,legy), end, ylabel(hcy,'Ey [mV/m]')
end

if ~isempty(Eref)
  title(hcp,sprintf('%d reference points (%d%% data coverage)',...
    length(find(~isnan(Eref(:,2)))), round(weight*100)))
end

irf_zoom(h,'x',st+[0 dt])

% Return
dE = [dE1 dE2 dE3 dE4];
dAmp = [dAmp1 dAmp2 dAmp3 dAmp4];


  function spinFits = get_spin_fits()
    spinFits = caa_sfit_load(cli);
    
    if ~isempty(spinFits)
      
      if spinFits.flagLX
        probe_numeric = spinFits.probePair;
      else
        E_info = c_load('diESPEC?p1234_info', cli, 'var');    % Load info; need list of probe pairs!
        if isempty(E_info) || ~isfield(E_info, 'probe')
          irf_log('load','Could not load probe pair info!')
          probe_numeric = spinFits.probePair;
        else probe_numeric=str2double(E_info.probe);
        end
      end
      % Remove saturation due to too high bias current
      if probe_numeric<50, probepair_list=probe_numeric;
      else probepair_list=[12 32 34];end
      for probepair=probepair_list
        [ok,hbias,msg] = c_load(irf_ssub('HBIASSA?p!',cli,probepair));
        if ok
          % Special trick for C2 after April 2011
          if ~isempty(hbias) && cli==2
            hbias(hbias(:,1)==iso2epoch('2011-04-30T06:00:00.00Z'),:)=[];
          end
          if ~isempty(hbias)
            irf_log('proc','blanking HB saturation')
            spinFits.diEs = caa_rm_blankt(spinFits.diEs,hbias);
          end
        else irf_log('load',msg)
        end
        clear ok hbias msg
      end
      
      % Remove saturation
      if probe_numeric<50, probepair_list=[mod(probe_numeric,10),fix(probe_numeric/10)];
      else probepair_list=[1 2 3 4];end
      for probe=probepair_list
        [ok,hbias,msg] = c_load(irf_ssub('PROBESA?p!',cli,probe));
        if ok
          if ~isempty(hbias)
            irf_log('proc','blanking probe saturation')
            spinFits.diEs = caa_rm_blankt(spinFits.diEs,hbias);
          end
        else irf_log('load',msg)
        end
        clear ok hbias msg
      end
      
      % Remove whisper pulses
      [ok,whip,msg] = c_load('WHIP?',cli);
      if ok
        if ~isempty(whip)
          irf_log('proc','blanking Whisper pulses')
          spinFits.diEs = caa_rm_blankt(spinFits.diEs,whip);
        end
      else irf_log('load',msg)
      end
      clear ok whip msg
      
      % Remove ns_ops intervals
      ns_ops = c_ctl('get', cli, 'ns_ops');
      if isempty(ns_ops)
        c_ctl('load_ns_ops', [c_ctl('get', 5, 'data_path') '/caa-control'])
        ns_ops = c_ctl('get', cli, 'ns_ops');
      end
      if ~isempty(ns_ops)
        ns_ops_intervals = [caa_get_ns_ops_int(spinFits.diEs(1,1), spinFits.diEs(end,1)-spinFits.diEs(1,1), ns_ops, 'bad_data')' ...
          caa_get_ns_ops_int(spinFits.diEs(1,1), spinFits.diEs(end,1)-spinFits.diEs(1,1), ns_ops, 'bad_tm')']';
        if ~isempty(ns_ops_intervals)
          ns_ops_intervals(:,1)=ns_ops_intervals(:,1)-4;
          ns_ops_intervals(:,2)=ns_ops_intervals(:,2)+4;
          irf_log('proc', 'blanking NS_OPS')
          spinFits.diEs = caa_rm_blankt(spinFits.diEs,ns_ops_intervals);
        end
        clear ns_ops ns_ops_intervals
      end
      
      % Delta offsets
      Del_caa = c_efw_delta_off(spinFits.diEs(1,1),cli);
      if ~isempty(Del_caa)
        [ok,Delauto] = c_load('D?p12p34',cli);
        if ~ok || isempty(Delauto)
          irf_log('load',irf_ssub('Cannot load/empty D?p12p34',cli))
        else
          spinFits.diEs = caa_corof_delta(spinFits.diEs,spinFits.probePair,Delauto,'undo');
          spinFits.diEs = caa_corof_delta(spinFits.diEs,spinFits.probePair,Del_caa,'apply');
        end
      end
    end
  end

end

function dirList = get_dir_list(st,dt,cl_id)
DP = '/data/caa/l1';
SPLIT_INT = 3; % 3 hour subintervals
t = fromepoch(st);
t0 = toepoch([t(1) t(2) t(3) fix(t(4)/SPLIT_INT)*SPLIT_INT 0 0]);
t = fromepoch(st+dt);
t1 = toepoch([t(1) t(2) t(3) fix(t(4)/SPLIT_INT)*SPLIT_INT 0 0]);
if t1>=st+dt, t1 = t1 - SPLIT_INT*3600; end

dirList = [];
for t=t0:SPLIT_INT*3600:t1
  y = fromepoch(t);
  main_int = [DP '/' num2str(y(1)) '/' irf_fname(t) '/C' num2str(cl_id)];
  if ~exist(main_int,'dir'), continue, end
  
  cd(main_int)
  d = dir('*_*');
  if isempty(d), continue, end
  good_dir = {};
  for j=1:length(d)
    if ~d(j).isdir, continue, end
    if caa_is_valid_dirname(d(j).name), good_dir = [good_dir {d(j).name}]; end %#ok<AGROW>
  end
  if isempty(good_dir), continue, end
  
  for j=1:length(good_dir)
    subdir = [main_int '/' good_dir{j}];
    cd(subdir)
    [st_t,dt_tmp] = caa_read_interval();
    if isempty(st_t), continue, end
    st_tmp = iso2epoch(st_t);
    if (st_tmp+dt_tmp <= st) || (st_tmp >= st+dt), continue, end % subinterval starts before/after the interval
    [ok,tm] = c_load('mTMode?',cl_id);
    if ~ok, continue, end
    ttt.st = st_tmp;
    ttt.dt = dt_tmp;
    ttt.mode = tm(1);
    ttt.dir = subdir;
    dirList = [dirList, ttt]; %#ok<AGROW>
  end
  clear good_dir
end
end

function res = find_damp(Ey,CEy)
% find amlitude correction factor by searching for 
% minimum( std( ECISy -dAMP*Ey ) )

damp = 1:0.025:1.4;
dstd = damp;
for i=1:length(damp), dstd(i)=std(CEy - damp(i)*Ey); end
res = damp(dstd==min(dstd));
end