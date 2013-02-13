function [mindist,nvec] = magnetopause_normal(pos_Re_gsm, IMF_Bz_nT, swp_nPa, modelflag) 

% MODEL.MAGNETOPAUSE_NORMAL the distance and normal vector to the magnetopause 
% Shue et al., 1997 model is assumed.
%	
% [mindist,nvec] = MODEL.MAGNETOPAUSE_NORMAL(pos_Re_gsm, IMF_Bz_nT, swp_nPa)
%
% Input:
%		pos_Re_gsm - GSM position in Re (if more than 3 values assumes that 1st is time)
%		IMF_Bz_nT  - IMF Bz in nT
%		swp_nPa    - Solar wind dynamic pressure in nPa
%       modelflag  - Set to 1 to use the 1998 model, otherwise the 1997 
%                    model is used.
%
% Output: 
%       mindist - minimum distance to the magnetopause, in Re. Positive 
%       value if spacecraft is inside the magnetopause, negative if 
%       outside the magnetopause.
%       nvec    - normal vector to the magnetopause (pointing away from
%       Earth).

% $Id$

% TODO: vectorize, so that input can be vectors

if nargin == 0,
	help model.magnetopause_normal;
elseif nargin==3, modelflag=0;
elseif nargin ~=4
	irf_log('fcal','Wrong number of input parameters, see help.');
	return;
end    
    
if modelflag==1, shueex=1;else shueex =0;end

if(shueex == 1)
    alpha = (0.58 -0.007*IMF_Bz_nT)*(1.0 +0.024*log(swp_nPa));
    r0 = (10.22 + 1.29*tanh(0.184*(IMF_Bz_nT + 8.14)))*swp_nPa^(-1.0/6.6);
    display ('Shue et al., 1998 model used.')  
else    
    alpha = ( 0.58 -0.01*IMF_Bz_nT)*( 1.0 +0.01*swp_nPa);

    if IMF_Bz_nT>=0, r0 = (11.4 +0.013*IMF_Bz_nT)*swp_nPa^(-1.0/6.6);
    else             r0 = (11.4 +0.140*IMF_Bz_nT)*swp_nPa^(-1.0/6.6);
    end
    display ('Shue et al., 1997 model used.')
end

%SC pos
x1 = pos_Re_gsm(1);
y1 = pos_Re_gsm(2);
z1 = pos_Re_gsm(3);

x0 = x1;
y0 = sqrt(y1^2+z1^2);

theta = -pi/1.2:0.00001:pi/1.2;

d2 = r0^2*(2./(1+cos(theta))).^(2*alpha) - 2*r0*(2./(1+cos(theta))).^(alpha).*(x0*cos(theta) + y0*sin(theta)) + x0^2 + y0^2;

[minval,minpos] = min(d2);

thetamin = theta(minpos);
mindist = sqrt(minval);

%calculate the direction to the spacecraft normal to the magnetopause
xn = r0*(2/(1+cos(thetamin)))^alpha * cos(thetamin) - x1;
phi = atan2(z1,y1);
yn = cos(phi)*(r0*(2/(1+cos(thetamin)))^alpha * sin(thetamin)) - y1;
zn = sin(phi)*(r0*(2/(1+cos(thetamin)))^alpha * sin(thetamin)) - z1;

%disttest = sqrt(xn^2+yn^2+zn^2)

nvec = [xn yn zn]/mindist;

%if statement to ensure normal is pointing away from Earth
if (sqrt(x0^2+y0^2) > r0*(2/(1+cos(thetamin)))^alpha) 
    nvec = -nvec;
    mindist = -mindist;
end 
