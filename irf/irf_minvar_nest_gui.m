function status = irf_minvar_nest_gui(x,column)
%IRF_MINVAR_NEST_GUI interactively do a nested minimum variance analysis
%
%Click on 'Click cs center' to define the center of the current sheet. The nested
%analysis starts from this center point and does minimum variance on this point
%and the two surrounding. Each larger member of a nest is generated by adding
%one data point at each end of the preceeding segment until the end of the
%interval selected is reached. If the normal vector and normal field component are strictly
%time-stationary, the results from all different nested segments should be the
%same. The average of the normal field component can be calculated by clicking
%'Calculate avg' and selecting the nest limits when the normal vector is
%most stationary. Error estimates are calculated according to 8.3.1 in Analysis
%Methods for multispacecraft data.
%
% IRF_MINVAR_NEST_GUI(X,COLUMN)
%  X - vector to use, [x(:,column(1)) x(:,column(2)) x(:,column(3))]
%  COLUMN - which columns to use, if not given use 2,3,4
%
% You can access the results through variable 'ud' that is defined as global
% ud.v - eigenvectors (ud.v(1,:), ..), also ud.v1, ud.v2. ud.v3
%ud.bn_avg - The average magnetic field in the normal direction throughout the
%interval selected [ud.bn_avg(1)] and the average error estimate of Bn
%[ud.bn_avg(2)]
%
% See also IRF_MINVAR_NEST, IRF_MINVAR
%
% $Id$

global ud
persistent tlim message t0;
%persistent ud tlim;

if isempty(message) % run only the first time during the session
  message='You can anytime access all the results from the variable "ud".';
  disp(message);
end

if      nargin < 1, help irf_minvar_nest_gui;return;
elseif  (nargin==1 && ischar(x)), action=x;%disp(['action=' action]);
elseif  isnumeric(x)
  if size(x,2)<3, disp('Vector has too few components');return;end
  if nargin < 2
    if size(x,2)==3, column=[1 2 3];end
    if size(x,2)>3, column=[2 3 4];end
  end
  action='initialize';
end

switch action
  case 'initialize'
    % X is used for minimum variance estimates
    tlim = [];
    evalin('base','clear ud; global ud;');
    
    if min(column)==1, time_vector=1:size(x,1);
    elseif min(column)>1, time_vector=x(:,1);
    end
    
    X=[time_vector x(:,column)];X=irf_abs(X);
    ud={}; % structure to pass all information to manager function
    ud.X=X;
    ud.from = 1; % first click with mouse is 'from', second is 'to'
    ud.cancel = 0;
    tlim = [min(X(:,1)) max(X(:,1))];
    ud.tlim_mva=tlim+[-1 1]; % default tlim_mva includes all interval, add 1s to help later in program
    
    dgh=figure;clf;irf_figmenu;
    h(1)=subplot(4,1,1);
    irf_plot(X);axis tight;
    uf=get(dgh,'userdata');
    if isfield(uf,'t_start_epoch'), t0=uf.t_start_epoch;else, t0=0; end
    ud.h=h;
    
    set(gcf,    'windowbuttondownfcn', 'irf_minvar_nest_gui(''ax'')');zoom off;
    irf_pl_info(['irf\_minvar\_gui() ' char(datetime("now","Format","dd-MMM-uuuu HH:mm:ss"))]); % add information to the plot
    set(ud.h(1),'layer','top');
    ax=axis;grid on;
    ud.patch_mvar_intervals=patch([tlim(1) tlim(2) tlim(2) tlim(1)]-t0,[ax(3) ax(3) ax(4) ax(4)],[-1 -1 -1 -1],'y');
    
    h(2)=subplot(4,2,3);
    
    h(3)=subplot(4,2,4);
    
    h(4)=subplot(4,2,5);
    
    h(5)=subplot(4,2,6);
    
    ud.h=h;
    
    xp=0.2;yp=0.20;
    ud.centretext=uicontrol('style', 'text', 'string', 'Centre:','units','normalized', 'position', [xp yp 0.1 0.04],'backgroundcolor','white');
    ud.centreh = uicontrol('style', 'edit', ...
      'string', epoch2iso(tlim(1),1), ...
      'callback', 'irf_minvar_nest_gui(''csc'')', ...
      'backgroundcolor','white','units','normalized','position', [xp+0.11 yp 0.25 0.05]);
    
    
    xp=0.2;yp=0.15;
    ud.fromtext=uicontrol('style', 'text', 'string', 'From:','units','normalized', 'position', [xp yp 0.1 0.04],'backgroundcolor','red');
    ud.fromh = uicontrol('style', 'edit', ...
      'string', epoch2iso(tlim(1),1), ...
      'callback', 'irf_minvar_nest_gui(''from'')', ...
      'backgroundcolor','white','units','normalized','position', [xp+0.11 yp 0.25 0.05]);
    
    yp=0.10;
    ud.totext=uicontrol('style', 'text', 'string', 'To:','units','normalized', 'position', [xp yp 0.1 0.04],'backgroundcolor','white');
    ud.toh=uicontrol('style', 'edit', ...
      'string', epoch2iso(tlim(2),1), ...
      'callback', 'irf_minvar_nest_gui(''from'')','backgroundcolor','white','units','normalized', 'position', [xp+0.11 yp 0.25 0.05]);
    
    
    xp=0.1;yp=0.05;
    uch1 = uicontrol('style', 'text', 'string', 'Low pass filter f/Fs = ','units','normalized','position', [xp yp 0.2 0.04],'backgroundcolor','white');
    ud.filter = uicontrol('style', 'edit', ...
      'string', '1', ...
      'backgroundcolor','white','units','normalized','position', [xp+0.21 yp 0.1 0.05]);
    
    uimenu('label','&Recalculate','accelerator','r','callback','irf_minvar_nest_gui(''mva'')');
    uimenu('label','&Pick cs centre','accelerator','r','callback','irf_minvar_nest_gui(''csc'')');
    uimenu('label','&Calculate avg','accelerator','r','callback','irf_minvar_nest_gui(''avg'')');
    
    subplot(4,2,8);axis off;
    ud.result_text=text(0.3,0.8,'result','FontSize',14);
    
  case 'csc'
    title('Click on the current sheet center');
    uf=get(gcf,'userdata');
    if isfield(uf,'t_start_epoch'), t0=uf.t_start_epoch;else, t0=0; end
    temp=ginput(1);
    ud.csc=temp(1)+t0;
    p(1)=ud.csc;
    set(ud.centreh, 'string', epoch2iso(p(1),1));
    return
    
  case 'avg'
    axes(ud.h(2));
    title('Click the averaging limits');
    set(ud.h(2),'layer','top');
    grid on;
    avglim=ginput(2);
    ax=axis;
    ud.patch_avg_intervals=patch([avglim(1,1) avglim(2,1) avglim(2,1) avglim(1,1)],[ax(3) ax(3) ax(4) ax(4)],[-1 -1 -1 -1],'g');
    axes(ud.h(3));
    set(ud.h(3),'layer','top');
    grid on;
    ax=axis;
    ud.patch_avg_intervals=patch([avglim(1,1) avglim(2,1) avglim(2,1) avglim(1,1)],[ax(3) ax(3) ax(4) ax(4)],[-1 -1 -1 -1],'g');
    axes(ud.h(4));
    set(ud.h(4),'layer','top');
    grid on;
    ax=axis;
    ud.patch_avg_intervals=patch([avglim(1,1) avglim(2,1) avglim(2,1) avglim(1,1)],[ax(3) ax(3) ax(4) ax(4)],[-1 -1 -1 -1],'g');
    axes(ud.h(5));
    set(ud.h(5),'layer','top');
    grid on;
    ax=axis;
    ud.patch_avg_intervals=patch([avglim(1,1) avglim(2,1) avglim(2,1) avglim(1,1)],[ax(3) ax(3) ax(4) ax(4)],[-1 -1 -1 -1],'g');
    axes(ud.AX(2));
    set(ud.AX(2),'layer','top');
    ind_lim=find(ud.bn(:,1) < avglim(2,1) & ud.bn(:,1) > avglim(1,1));
    ud.bn_avg=mean(ud.bn(ind_lim,2:3));
    ud.v1=mean(ud.v1_nest(ind_lim,2:4));
    ud.v2=mean(ud.v2_nest(ind_lim,2:4));
    ud.v3=mean(ud.v3_nest(ind_lim,2:4));
    ud.l2_l3_abs=mean(ud.l2_l3_ratio(ind_lim,2));
    v=[ud.v1; ud.v2; ud.v3];
    ud.v=v;
    v1_str=['v1=[' num2str(ud.v1,'%6.2f') '] \newline'];
    v2_str=['v2=[' num2str(ud.v2,'%6.2f') '] \newline'];
    v3_str=['v3=[' num2str(ud.v3,'%6.2f') '] \newline'];
    bn_str=['B_n=' num2str(ud.bn_avg(1),'%6.2f') '\pm' num2str(ud.bn_avg(2),'%6.2f') '\newline'];
    l2_l3_str=['<L2/L3> =' num2str(ud.l2_l3_abs,'%6.2f') '\newline'];
    %['<L2/L3> =' num2str(ud.l2_l3_abs),'%6.2f') '\newline'];
    err_str=['|\Delta B_n|/|B_n| =' num2str(abs(ud.bn_avg(2))/abs(ud.bn_avg(1)),'%6.2f') '\newline'];
    v_str=[v1_str v2_str v3_str];
    set(ud.result_text,'string',[v_str bn_str err_str l2_l3_str],'verticalalignment','top');
    
    return
    
  case 'ax'
    tlim = get(ud.patch_mvar_intervals, 'xdata'); tlim=tlim(:)';tlim(3:4)=[];
    uf=get(gcf,'userdata');
    if isfield(uf,'t_start_epoch'), t0=uf.t_start_epoch;else, t0=0; end
    tlim=tlim+t0;
    p = get(gca, 'currentpoint')+t0;
    tlim_interval=get(gca,'xlim')+t0;
    if ud.from
      tlim(1) = max(tlim_interval(1), p(1));
      tlim(2) = max(p(1),tlim(2));
      set(ud.fromtext,'backgroundcolor','w');
      set(ud.totext,'backgroundcolor','r');
      ud.from = 0;
    else
      tlim(2) = min(tlim_interval(2), p(1));
      tlim(1) = min(tlim(1), p(1));
      set(ud.totext,'backgroundcolor','w');
      set(ud.fromtext,'backgroundcolor','r');
      ud.from = 1;
    end
    set(ud.fromh, 'string', epoch2iso(tlim(1),1));
    set(ud.toh, 'string', epoch2iso(tlim(2),1));
    set(ud.patch_mvar_intervals,'xdata',[tlim(1) tlim(2) tlim(2) tlim(1)]-t0);
    irf_minvar_nest_gui('update_mva_axis');
    
  case 'from'
    tlim(1) = iso2epoch(get(ud.fromh,'string'));
    tlim(2) = iso2epoch(get(ud.toh,'string'));
    set(ud.patch_mvar_intervals,'xdata',[tlim(1) tlim(2) tlim(2) tlim(1)]-t0);
    irf_minvar_nest_gui('update_mva_axis');
    
    
  case 'mva'
    ud.tlim_mva=tlim;
    X = ud.X;
    if eval(get(ud.filter,'string'))<1
      Fs = 1/(X(2,1)-X(1,1));
      flim = Fs*eval(get(ud.filter,'string'));
      X = irf_tlim(X, tlim + [-20/Fs 20/Fs]);
      X = irf_filt(X,0,flim,Fs,5);
    else
      disp('f/Fs must be <1!!!')
      set(ud.filter,'string','1')
    end
    [ud.bn, ud.l2_l3_ratio, ud.v1_nest, ud.v2_nest, ud.v3_nest]=irf_minvar_nest(X,ud.csc,tlim);
    irf_minvar_nest_gui('update_mva_axis');
    
  case 'update_mva_axis'
    if tlim==ud.tlim_mva % plot first time after 'mva'
      axes(ud.h(2));
      plot(ud.v3_nest(:,1),ud.v3_nest(:,2));
      xlabel('Nest size (M)');ylabel('n_X');
      axes(ud.h(3));
      plot(ud.v3_nest(:,1),ud.v3_nest(:,3));
      xlabel('Nest size (M)');ylabel('n_Y');
      axes(ud.h(4));
      plot(ud.v3_nest(:,1),ud.v3_nest(:,4));
      xlabel('Nest size (M)');ylabel('n_Z');
      axes(ud.h(5));
      ud.l2_l3_ratio(1,2)=NaN;
      [ud.AX,H1,H2]=plotyy(ud.bn(:,1),ud.bn(:,2),ud.l2_l3_ratio(:,1),ud.l2_l3_ratio(:,2))
      hold on
      errorbar(ud.bn(:,1),ud.bn(:,2),ud.bn(:,3),'Color','b');
      hold off
      xlabel('Nest size (M)');
      set(get(ud.AX(1),'Ylabel'),'String','B_n [nT]')
      set(get(ud.AX(2),'Ylabel'),'String','L2/L3')
    end
    
end
