function [ax cb] = c_caa_plot_distribution_function(varargin)
% C_CAA_PLOT_DISTRIBUTION_FUNCTION Plot particle distribution.
%
%   [ax ax_cb] = C_CAA_PLOT_DSITRIBUTION_FUNTION(ax,'tint',tint,plot_type,...
%           data_structure,'pitchangle',pitchangles)
%       ax - axis handle, can be given, or not
%       ax_cb - colorbar handle if plot_type is 'polar'
%       tint - time interval or single time in epoch
%       plot_type - 'polar' or 'cross-section' [0 90 180]
%       data_structure - obtained from c_caa_distribution_data.m, 'polar'
%           supports up to two data_structure, 'cross-section' one at the
%           moment
%       pitchangle - pitch angles to plot if 'cross-section' is chosen, 
%           [0 90 180] is default
%
%   Examples:
%       data_structure = c_caa_distribution_data('C3_CP_PEA_3DXPH_PSD');
%       h=C_CAA_PLOT_DISTRIBUTION_FUNCTION('tint',tint,'polar',data_structure);
%
% See also c_caa_distribution_data.m

% Check for axes
[ax,args,nargs] = axescheck(varargin{:});
original_args=args;
original_nargs=nargs;

% Default values
emin=[];
plot_type='polar';
pitch_angles=[0 90 180];

% Read input
n_toplot=0;
while length(args)>0
    if isstruct(args{1})
        n_toplot=n_toplot+1;
        to_plot{n_toplot}=args{1};  
        args=args(2:end);
    elseif isstr(args{1})   
        switch lower(args{1})
            case 'tint'            
                tint=args{2};
                args=args(3:end);            
            case 'polar'
                plot_type='polar';
                args=args(2:end);           
            case 'cross-section'
                plot_type='cross-section';
                args=args(2:end);
            case 'emin'            
                emin=args{2};
                args=args(3:end);
            case 'pitchangle'
                pitch_angles=args{2};
                args=args(3:end);
            otherwise % additional input
                eval([args{1},'=args{2};'])
                args=args(2:end);
        end
    else
        args=args(2:end);
    end
end

% Return if not enough input is given.
% Reduce products if too much input is given.
if isempty(tint)
    disp('No time interval was given!')
    return;
end
switch n_toplot
    case 0
        disp('No particle product was given!')
        return;
    case 1
    case 2
        if strcmp(plot_type,'cross-section')
            disp('Cross-section distributions are only plotted for single products.')
            disp('Plotting first product given.')
            to_plot=toplot(1);
        end
    otherwise
        switch plot_type
            case 'polar'
                disp('Polar distributions are plotted for at most two products.')
                disp('Plotting two first products given.')
                to_plot=to_plot(1:2);
                n_toplot=2;
            case 'cross-section'
                disp('Cross-section distributions are only plotted for single products.')
                disp('Plotting first product given.')
                to_plot=to_plot(1);
                n_toplot=1;
        end
end

% take out time interval
for k=1:n_toplot
    if length(tint)==2; % start and stop interval
        [~,ind_t{k}]=irf_tlim(to_plot{k}.t,tint);
    elseif length(tint)==1; % only one time, take closest energy sweep
        [tt,ind_t{k}]=irf_tlim(to_plot{k}.t,[tint-1 tint+1]);
        ind_min=find(abs((tt-tint))==min(abs((tt-tint))));
        ind_t={ind_t{1}(ind_min)};   
    end
end

% If no axes is given, initialize figure.
if isempty(ax) 
    ax=irf_plot(1);
end

% Plot
switch plot_type
    case 'polar'
        if n_toplot==1; % Mirror plot if only one product is given
            to_plot{2}=to_plot{1};
            ind_t{2}=ind_t{1};
        end
        for k=1:2
            % Put energy in log eV
            rlog{k} = log10(double(to_plot{k}.en_pol))';
            % Pitch angles, turn so that pitch angle 0 is on top
            theta{k} = double(to_plot{k}.f_pol)+90;                    
        end                    
        if isempty(emin) || log10(emin)>min(min(rlog{:})); % Take out r0
            r0log = min(min([rlog{1};rlog{2}]));
        else
            r0log = log10(emin);
        end            
        for k=1:2 % Create surf grids  
            r{k} = tocolumn(rlog{k}-r0log);
            X{k} = r{k}*cosd(theta{k});
            Y{k} = r{k}*sind(theta{k});
            C{k} = squeeze(nanmean(log10(to_plot{k}.p(ind_t{k},:,:)),1))';
        end        
        
        % Plot data
        surf(ax,X{1},Y{1},X{1}*0,C{1}); hold(ax,'on');
        surf(ax,-flipdim(X{2},2),Y{2},X{2}*0,C{2});         
        view(ax,2); 
        axis(ax,'equal','tight'); 
        shading(ax,'flat');
        grid(ax,'off');
        cb=colorbar('peer',ax);
        ylabel(cb,to_plot{1}.p_label)
        
        if 1 % Energy ticks
            xticks=log10([1e-1 1e0 1e1 1e2 1e3 1e4 1e5 1e6 1e7]*1e-3)-r0log;            
            xticks=xticks(find(xticks>0));
            xticks=xticks(find(xticks<max([max(r{1}) max(r{2})])));
            xticklabels=cell(size(xticks));
            for k=1:length(xticklabels)
                xticklabels{k}=num2str(10.^(xticks(k)+r0log)*1e-3);
            end         
            xticks=[-flipdim(xticks,2) 0 xticks];
            xticklabels=[flipdim(xticklabels,2) num2str(1e-3*10^r0log,'%.3f') xticklabels];
            yticks=xticks;
            yticklabels=xticklabels; 
            set(ax,'xtick',xticks,'xticklabel',xticklabels,'TickDir','in',...
                'XMinorTick','off','ytick',yticks,'yticklabel',yticklabels)  
            xlabel(ax,'Energy  [keV]'); ylabel(ax,'Energy  [keV]')
        end
        if 1 % Pitch angle labels
            rmax=max([max(r{1}) max(r{2})]);
            text(0-0.2,rmax-0.5,0,'0^o')
            text(0-0.2,-rmax+0.5,0,'180^o')
            text(-0.2-rmax+0.5,0,0,'90^o')
            text(-0.2+rmax-0.5,0,0,'90^o')
        end               
        
    case 'cross-section' 
        k=1; % only one product supported
        % Pick out angles
        n_pa=length(pitch_angles);
        for p=1:n_pa
            diff_pa=abs(to_plot{k}.f_cs-pitch_angles(p));
            ind_pa{k,p}=find(diff_pa==min(diff_pa));
            pa_toplot{k,p}=squeeze(nanmean(to_plot{k}.p(ind_t{k},ind_pa{p},:),1));
            pa_legends{k,p}=num2str(pitch_angles(p),'%.0f');
            disp(['Plotting average of bins: ',num2str(to_plot{k}.f_cs(ind_pa{k,p}))])
        end
        if ~isempty(to_plot{k}.p_bg)                
            PAbg=squeeze(nanmean(nanmean(to_plot{k}.p_bg(ind_t{k},:,:),1),2)); % One common zero-count level for all levels
        else
            PAbg=NaN(size(to_plot{k}.en_cs));
        end
        pa_legends{end+1}='Bg';

        % Plotting data, making string to adapt to varying pitch angles
        plt_str='loglog(ax';
        for p=1:n_pa; eval(['plt_str=[plt_str,'',to_plot{1}.en_cs,pa_toplot{',num2str(p),'}''];']); end
        plt_str=[plt_str,',to_plot{1}.en_cs,PAbg,''--'');'];
        eval(plt_str);
        set(ax,'xlim',[to_plot{1}.en_cs(1)*0.8 to_plot{1}.en_cs(end)*1.2])
        % irf_legend(ax,{'0','90','180','-- Zero count'},[0.94 0.94])
        % irf_legend gets too big for box if box is small
        legend(ax,pa_legends,'edgecolor','w') 
        ylabel(ax,to_plot{k}.p_label)
        xlabel(ax,'Energy  [eV]')
        grid(ax,'off');   
        cb=[];        
end

% Title
switch length(tint) % First line is time
    case 1 % Only one time
        t1str=datestr(epoch2date(to_plot{k}.t(ind_t{:})),'dd-mmm-yyyy  HH:MM:SS.FFF');        
        titleStr{1}=[t1str,' UT'];
    case 2 % Time interval
        t1str=datestr(epoch2date(tint(1)),'dd-mmm-yyyy  HH:MM:SS.FFF');
        t2str=datestr(epoch2date(tint(2)),'HH:MM:SS.FFF');
        %t1str=datestr(epoch2date(to_plot{1}.t(ind_t{1}(1))),'dd-mmm-yyyy  HH:MM:SS.FFF');
        %t2str=datestr(epoch2date(to_plot{1}.t(ind_t{1}(end))),'HH:MM:SS.FFF');
        titleStr{1}=[t1str,'-',t2str,' UT'];
end
switch n_toplot % Second line is the product plotted
    case 1 % Only one product
        titleStr{2}=[to_plot{1}.product,to_plot{1}.detector];
    case 2 % Two products    
        titleStr{2}=['Left: ',to_plot{1}.product,to_plot{1}.detector];            
        titleStr{3}=['Right: ', to_plot{2}.product,to_plot{1}.detector];                   
end
for k=1:(n_toplot+1) titleStr{k}(strfind(titleStr{k},'_'))=' '; end
title(ax,titleStr);
end

function m = nanmean(x,dim)
%NANMEAN Mean value, ignoring NaNs.
%   M = NANMEAN(X) returns the sample mean of X, treating NaNs as missing
%   values.  For vector input, M is the mean value of the non-NaN elements
%   in X.  For matrix input, M is a row vector containing the mean value of
%   non-NaN elements in each column.  For N-D arrays, NANMEAN operates
%   along the first non-singleton dimension.
%
%   NANMEAN(X,DIM) takes the mean along dimension DIM of X.
%
%   See also MEAN, NANMEDIAN, NANSTD, NANVAR, NANMIN, NANMAX, NANSUM.

%   Copyright 1993-2004 The MathWorks, Inc.
%   Revision: 1.1.8.1   Date: 2010/03/16 00:15:50 

% Find NaNs and set them to zero
nans = isnan(x);
x(nans) = 0;

if nargin == 1 % let sum deal with figuring out which dimension to use
    % Count up non-NaNs.
    n = sum(~nans);
    n(n==0) = NaN; % prevent divideByZero warnings
    % Sum up non-NaNs, and divide by the number of non-NaNs.
    m = sum(x) ./ n;
else
    % Count up non-NaNs.
    n = sum(~nans,dim);
    n(n==0) = NaN; % prevent divideByZero warnings
    % Sum up non-NaNs, and divide by the number of non-NaNs.
    m = sum(x,dim) ./ n;
end
end