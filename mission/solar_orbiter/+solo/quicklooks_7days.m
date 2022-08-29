function quicklooks_7days(data,paths,Tint,logoPath)
% Given data in the struct 'data' (see solo.quicklook_main), generates
% plots and saves in the paths specified in the struct 'paths' (see
% solo.quicklook_main). Tint should be a 7-day time interval, e.g.
% irf.tint('2020-06-01T00:00:00.00Z','2020-06-08T00:00:00.00Z');

% Setup figure:
lwidth=1.0;
fsize=18;
legsize=22;
h=irf_plot(9,'newfigure');
fig=gcf;
fig.Position=[1,1,1095,800];
colors = [0 0 0;0 0 1;1 0 0;0 0.5 0;0 1 1 ;1 0 1; 1 1 0];


Units=irf_units;

Me=Units.me; %Electron mass [kg]
epso = Units.eps0; %Permitivitty of free space [Fm^-1]
mp=Units.mp; %proton mass [km]
qe=Units.e; %elementary charge [C]


if ~isempty(data.B)
    irf_plot(h(1),data.B.tlim(Tint),'linewidth',lwidth);
    hold(h(1),'on');
    irf_plot(h(1),data.B.abs.tlim(Tint),'linewidth',lwidth);
end
irf_legend(h(1),{'B_{R}','B_{T}','B_{N}','|B|'},[0.98 0.18],'Fontsize',legsize);
ylabel(h(1),{'B_{RTN}';'(nT)'},'interpreter','tex','fontsize',fsize);
irf_zoom(h(1),'y');

if ~isempty(data.B)
    fci = qe*data.B.abs*10^-9/mp/(2*pi);
    irf_plot(h(2),data.B.abs.tlim(Tint),'linewidth',lwidth);
end
ylabel(h(2),{'|B|';'(nT)'},'interpreter','tex','fontsize',fsize);
h(2).YScale='log';
h(2).YTick=[10,100];
%h(2).YLim=[0.1,200];

% Densities
hold(h(3),'on');
if ~isempty(data.Ne)
    irf_plot(h(3),data.Ne.tlim(Tint),'color',colors(1,:),'linewidth',lwidth);
else
end
if ~isempty(data.Npas)
    irf_plot(h(3),data.Npas.tlim(Tint),'color',colors(2,:),'linewidth',lwidth);
end
ylabel(h(3),{'N';'(cm^{-3})'},'interpreter','tex','fontsize',fsize);
irf_legend(h(3),{'N_{e,RPW} ',' N_{i,PAS}'},[0.98 0.16],'Fontsize',legsize);
h(3).YScale='log';
h(3).YTick=[10,100];
%h(3).YLim=[0.8,200];

if ~isempty(data.Tpas)
    irf_plot(h(4),data.Tpas.tlim(Tint),'color',colors(2,:),'linewidth',lwidth);
end
ylabel(h(4),{'T_i';'(eV)'},'interpreter','tex','fontsize',fsize);
h(4).YScale='log';
h(4).YTick=[1,10,100];
h(4).YLim=[0.5,300];


% y,z PAS velocities
if ~isempty(data.Vpas)
    irf_plot(h(5),data.Vpas.y.tlim(Tint),'color',colors(2,:),'linewidth',lwidth);
    hold(h(5),'on');
    irf_plot(h(5),data.Vpas.z.tlim(Tint),'color',colors(3,:),'linewidth',lwidth);
end
irf_legend(h(5),{'','v_{T}','v_{N}'},[0.98 0.18],'Fontsize',legsize);
%irf_zoom(h(5),'y');
ylabel(h(5),{'v_{T,N}';'(km/s)'},'interpreter','tex','fontsize',fsize);

hold(h(6),'on');
if ~isempty(data.Vrpw)
    irf_plot(h(6),-data.Vrpw,'o','color',colors(1,:));
end
if ~isempty(data.Vpas)
    irf_plot(h(6),data.Vpas.x.tlim(Tint),'color',colors(2,:),'linewidth',lwidth);
end
irf_legend(h(6),{'V_{RPW}','V_{PAS}'},[0.98 0.15],'Fontsize',legsize);
%h(6).YLim=[150,950];
ylabel(h(6),{'v_{R}';'(km/s)'},'interpreter','tex','fontsize',fsize);

if ~isempty(data.E)
    irf_plot(h(7),data.E.y,'color',colors(2,:),'linewidth',lwidth)
    hold(h(7),'on');
    %irf_plot(h(7),data.E.z,'color',colors(3,:),'linewidth',lwidth)
end
irf_legend(h(7),{'','E_y'},[0.98 0.15],'Fontsize',legsize);
irf_zoom(h(7),'y');
ylabel(h(7),{'E_{SRF}';'(mV/m)'},'interpreter','tex','fontsize',fsize);

%Ion energy spectrum
if ~isempty(data.ieflux)
    myFile=solo.db_list_files('solo_L2_swa-pas-eflux',Tint);
    iDEF   = struct('t',  data.ieflux.tlim(Tint).time.epochUnix);
    for ii = 1:ceil((myFile(end).stop-myFile(1).start)/3600/24)
        iEnergy = cdfread([myFile(ii).path '/' myFile(ii).name],'variables','Energy');
        iEnergy = iEnergy{1};
        iDEF.p = data.ieflux.data;
          
    end
    iDEF.f = repmat(iEnergy,1,numel(iDEF.t))';
    iDEF.p_label={'dEF','keV/','(cm^2 s sr keV)'};
    irf_spectrogram(h(8),iDEF,'log','donotfitcolorbarlabel');
    % set(h(1),'ytick',[1e1 1e2 1e3]);
    %caxis(h(9),[-1 1])
    hold(h(8),'on');
    if ~isempty(data.B)
        irf_plot(h(8),fci,'k','linewidth',lwidth);
    end
    set(h(8), 'YScale', 'log');
    colormap(h(8),jet)
    ylabel(h(8),'[eV]')

end 

%E-field spectrum (TNR)
if ~isempty(data.Etnr)
    %Electron plasma frequency
    wpe_sc = (sqrt(((data.Ne.tlim(Tint)*1000000)*qe^2)/(Me*epso)));                         
    fpe_sc = (wpe_sc/2/pi)/1000;
    tt = [Tint(1) Tint(1)+24*60*60];
    tp =[];pp=[];
    warning('off', 'fuzzy:general:warnDeprecation_Combine');
    for iii = 1:ceil((myFile(end).stop-myFile(1).start)/3600/24)
        [TNRp] =  solo.read_TNR(tt);
        tt = tt+24*60*60;
        TNR.t = combine(tp,TNRp.t);
        tp = TNR.t;
        TNR.p = combine(pp,TNRp.p);
        pp = TNR.p;
    end
    TNR.f = TNRp.f;
    TNR.p_label = TNRp.p_label;
    irf_spectrogram(h(9),TNR,'log','donotfitcolorbarlabel')
    fpe_sc.units = 'kHz';
    fpe_sc.name = 'f [kHz]';
    hold(h(9),'on');
    irf_plot(h(9),fpe_sc,'r','linewidth',lwidth);
    text(h(9),0.01,0.3,'f_{pe,RPW}','units','normalized','fontsize',18,'Color','r');
    %set(h(9), 'YScale', 'log');
    colormap(h(9),jet)   
   % ylabel(h(9),'f [kHz]')
    set(h(9),'ColorScale','log')
    caxis([.01 10]*10^-12)
    yticks(h(9),[10^1 10^2]);
end




Au=149597871; %Astronomical unit.

if ~isempty(data.solopos.tlim(Tint))
    teststr = ['SolO: ',[' R=',sprintf('%.2f',data.solopos.tlim(Tint).data(1,1)/Au),'Au, '],...
        [' EcLat=',sprintf('%d',round(data.solopos.tlim(Tint).data(1,3)*180/pi)),'\circ, '],...
        [' EcLon=',sprintf('%d',round(data.solopos.tlim(Tint).data(1,2)*180/pi)),'\circ']];
    text1=text(h(9),-0.11,-0.575,teststr,'units','normalized','fontsize',18);


else
    teststr=char();
    text1=text(h(9),-0.11,-0.575,teststr,'units','normalized','fontsize',18);

end

% Add Earth longitude as text.
if ~isempty(data.earthpos)
    teststr =['Earth: EcLon=',sprintf('%d',round(data.earthpos.data(1,2)*180/pi)),'\circ'];
    text2=text(h(9),-0.11,-0.925,teststr,'units','normalized','fontsize',18);
else
    teststr=char();
    text2=text(h(9),-0.11,-0.925,teststr,'units','normalized','fontsize',18);
end

xtickangle(h(9),0)
% Add plot information and IRF logo
logopos = h(1).Position;
logopos(1)=logopos(1)+logopos(3)+0.01;
logopos(2)=logopos(2)+0.06;
logopos(3)=0.05;
logopos(4)=logopos(3)*1095/800;
ha2=axes('position',logopos);

if ~isempty(logoPath)
    [x, map]=imread(logoPath);
    image(x)
end
% colormap (map)
set(ha2,'handlevisibility','off','visible','off')
tempdate=datestr(date,2);
currdate=['20',tempdate(7:8),'-',tempdate(1:2),'-',tempdate(4:5)];
infostr = ['Swedish Institute of Space Physics, Uppsala (IRFU), ',currdate];
infostr2 = '. Data available at http://soar.esac.esa.int/';
text(h(1),0,1.2,[infostr,infostr2],'Units','normalized')

% Fix YTicks
for iax=1:9
    cax=h(iax);
    mintick = min(cax.YTick);
    maxtick = max(cax.YTick);
    minlim = cax.YLim(1);
    maxlim = cax.YLim(2);
    
    if maxtick>0
        if maxlim<1.1*maxtick
            newmax = 1.1*maxtick;
        else
            newmax = maxlim;
        end  
    else
        if abs(maxlim)>0.9*abs(maxtick)
            newmax = 0.9*maxtick;
        else
            newmax = maxlim;
        end       
    end
    
    if mintick>0  
        if minlim>0.9*mintick
            newmin = 0.9*mintick;
        else
            newmin = minlim;
        end
    else
        if abs(minlim)<1.1*abs(mintick)
            newmin=1.1*mintick;
        else
            newmin=minlim;
        end
    end
    cax.YLim=[newmin,newmax];
end

yyaxis(h(2),'left');
oldlims2 = h(2).YLim;
oldticks2 = h(2).YTick;
h(2).YScale='log';
h(2).YTick=[1,10,100];
h(2).YLim=[0.8,200];

yyaxis(h(2),'right');
oldlims2_r=h(2).YLim;
oldticks2_r = h(2).YTick;
h(2).YScale='log';
h(2).YTick=[1,10,100];
%h(2).YLim=[0.1,200];

oldlims5 = h(5).YLim;
oldticks5 = h(5).YTick;
h(5).YScale='log';
h(5).YTick=[1,10,100];
h(5).YLim=[0.5,300];

c_eval('h(?).FontSize=18;',1:9);


irf_plot_axis_align(h(1:9));
irf_zoom(h(1:9),'x',Tint);
% irf_zoom(h(1:7),'y');

% Plot complete, print figure.
fig=gcf;
fig.PaperPositionMode='auto';

filesmth = Tint(1);
filesmth = filesmth.utc;
filestr1 = filesmth(1:13);
filestr1([5,8])=[];

filesmth = Tint(end);
filesmth = filesmth.utc;
filestr2 = filesmth(1:13);
filestr2([5,8])=[];
path1=fullfile(paths.path_1w,[filestr1,'_',filestr2,'.png']);
print('-dpng',path1);

h(2).YScale='lin';
h(2).YTick=oldticks2_r;
h(2).YLim=oldlims2_r;
yyaxis(h(2),'left');
h(2).YScale='lin';
h(2).YLim=oldlims2;
h(2).YTick=oldticks2;

h(5).YScale='lin';
h(5).YLim=oldlims5;
h(5).YTick=oldticks5;

close(fig);
