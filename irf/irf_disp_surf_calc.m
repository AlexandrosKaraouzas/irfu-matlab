function [wfinal,extraparam]=irf_disp_surf_calc(kc_x_max,kc_z_max,m_i,wp_e)
%IRF_DISP_SURF_CALC    Calculate the cold plasma dispersion surfaces
%
%  [W,EXTRAPAR] = IRF_DISP_SURFCALC(K_PERP_MAX,K_PAR_MAX,M_I,WP_E)
%  calculates the cold plasma dispersion surfaces according to
%  equation 2.64 in Plasma Waves by Swanson (2nd ed.), and puts
%  them in the matrix W. Additional parameters that are needed in
%  IRF_DISP_SURF is returned as EXTRAPARAM.
%
%  This function is essential for IRF_DISP_SURF to work.
%
%  K_PERP_MAX = max value of k_perpendicular*c/w_c
%  K_PAR_MAX = max value of k_parallel*c/w_c
%  M_I = ion mass in terms of electron masses
%  WP_E = electron plasma frequency in terms of electron gyro frequency  
%
% $Id$

%  By Anders Tjulin, last update 25/3-2003.
  
  % First get rid of those annoying "division by zero"-warnings
    
  warning off
  
  % Make vectors of the wave numbers
  
  kc_z=linspace(0.000001,kc_z_max,35);
  kc_x=linspace(0.000001,kc_x_max,35);
  
  % Turn those vectors into matrices
  
  [KCX,KCZ]=meshgrid(kc_x,kc_z);

  % Find some of the numbers that appear later in the calculations

  kc=sqrt(KCX.*KCX+KCZ.*KCZ); % Absolute value of k
  theta=atan2(KCX,KCZ); % The angle between k and B
  
  wci=1/m_i; % The ion gyro frequency
  wp_i=wp_e/sqrt(m_i); % The ion plasma frequency
  wp=sqrt(wp_e*wp_e+wp_i*wp_i); % The total plasma frequency
  
  % To speed up the program somewhat introduce these
  
  kc2=kc.*kc;
  kc4=kc2.*kc2;
  wci2=wci*wci;
  wp2=wp*wp;
  wextra=wp2+wci;
  wextra2=wextra*wextra;
  cos2theta=cos(theta).*cos(theta);
  

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % For every k_perp and k_par, turn the dispersion relation into a
  % polynomial equation and solve it.  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % The polynomial coefficients are calculated
  
  polkoeff8=-(2*kc2+1+wci2+3*wp2);
  polkoeff6=(kc4+(2*kc2+wp2)*(1+wci2+2*wp2)+wextra2);
  polkoeff4=-(kc4*(1+wci2+wp2)+2*kc2*wextra2+kc2*wp2*(1+wci2-wci).*(1+cos2theta)+wp2*wextra2);
  polkoeff2=(kc4.*(wp2*(1+wci2-wci)*cos2theta+wci*wextra)+kc2*wp2* ...
	     wci*wextra.*(1+cos2theta));
  polkoeff0=-kc4*wci2*wp2.*cos2theta;
  
  % For each k, solve the equation
  
  for kz=1:length(kc_z)
    for kx=1:length(kc_x)
      disppolynomial=[1, 0, polkoeff8(kz,kx), 0, polkoeff6(kz,kx), 0, ...
		      polkoeff4(kz,kx), 0, polkoeff2(kz,kx), 0, ...
		      polkoeff0(kz,kx)];
%      wtemp=roots(disppolynomial); 
      wtemp=real(roots(disppolynomial)); % theoretically should be real (A. Tjulin)
      wfinal(:,kz,kx)=sort(wtemp); % We need to sort the answers to
                                   % get nice surfaces.
    end
  end
  

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Now we have solved the dispersion relation. Let us find some other
  % interesting parameters in this context.  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  % The elements of the dielectric tensor, using Swansons notation
  
  dielS=1-wp_e*wp_e./(wfinal.*wfinal-1)-wp_i*wp_i./(wfinal.*wfinal-wci2);
  dielD=-wp_e*wp_e./(wfinal.*(wfinal.*wfinal-1))+wci*wp_i*wp_i./(wfinal.*(wfinal.*wfinal-wci2));
  dielP=1-(wp_e*wp_e+wp_i*wp_i)./(wfinal.*wfinal);
  
  % The rest of this function is not cleaned yet. The calculations
  % could probably be much shorter!
  
  for temp=1:10
    KC2(temp,:,:)=kc2;
    THETA(temp,:,:)=theta;
    KX(temp,:,:)=KCX;
    KZ(temp,:,:)=KCZ;
  end
  
  n2=KC2./(wfinal.*wfinal);
  
  dielxx=dielS-n2.*cos(THETA).*cos(THETA);
  dielxy=-i*dielD;
  dielxz=n2.*cos(THETA).*sin(THETA);
  dielyy=dielS-n2;
  dielzz=dielP-n2.*sin(THETA).*sin(THETA);
  
  Ex=-dielzz./dielxz;
  Ey=dielxy./dielyy.*Ex;
  Ez=1;
  Eperp=sqrt(Ex.*conj(Ex)+Ey.*conj(Ey));
  Etot=sqrt(Ex.*conj(Ex)+Ey.*conj(Ey)+1);
  EparK=(KX.*Ex+KZ.*Ez)./sqrt(KC2);
  Epolar=-2*imag(Ex.*conj(Ey))./(Eperp.*Eperp);
  
  Bx=-KZ.*Ey./wfinal;
  By=(KZ.*Ex-KX.*Ez)./wfinal;
  Bz=KX.*Ey./wfinal;
  Btot=sqrt(Bx.*conj(Bx)+By.*conj(By)+Bz.*conj(Bz));
  
  temp=length(kc_x);
  dk_x=kc_x(2);dk_z=kc_z(2);
  dw_x=diff(wfinal,1,3); dw_z=diff(wfinal,1,2);
  dw_x(1,temp,temp)=0; dw_z(1,temp,temp)=0;
  v_x=dw_x/dk_x; v_z=dw_z/dk_z;
  
  extraparam(2,:,:,:)=Btot./Etot; % Degree of electromagnetism
  extraparam(3,:,:,:)=abs(EparK)./Etot; % Degree of longitudinality
  extraparam(4,:,:,:)=Ez./Etot; % Degree of parallelity
  extraparam(5,:,:,:)=sqrt(v_x.*v_x+v_z.*v_z); % Value of the group vel.
  extraparam(6,:,:,:)=Epolar; % Ellipticity
  warning on
