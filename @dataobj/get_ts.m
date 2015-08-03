function res = get_ts(dobj,var_s)
%GET_TS(dobj, var_s)  get a variable in as TSeries object
%
% Output:
%			empty, if variable does not exist
%			otherwise TSeries object
%
%  See also: TSeries

% ----------------------------------------------------------------------------
% "THE BEER-WARE LICENSE" (Revision 42):
% <yuri@irfu.se> wrote this file.  As long as you retain this notice you
% can do whatever you want with this stuff. If we meet some day, and you think
% this stuff is worth it, you can buy me a beer in return.   Yuri Khotyaintsev
% ----------------------------------------------------------------------------

data = get_variable(dobj,var_s);
if isempty(data), % no such variable, return empty
	res=[];
	return;
end
fillv = getfillval(dobj,var_s);
if ~ischar(fillv), data.data(data.data==fillv) = NaN;
else irf.log('warning','fill value is character: discarding')
end

if strcmpi(data.DEPEND_0.type,'tt2000')
  Time = EpochTT(data.DEPEND_0.data);
else
  Time = EpochUnix(data.DEPEND_0.data);
end

tensorOrder = length(data.variance(3:end));
repres = [];
switch tensorOrder
  case 0 % scalar
  case 1 % vector
    if data.dim(1)==2,
      repres = {'x','y'};
    elseif data.dim(1)==3
      repres = {'x','y','z'};
    end
  case 2 % tensor
  otherwise
    error('TensorOrder>2 not supported')
end

if isempty(repres)
  res = TSeries(Time,data.data,'TensorOrder',tensorOrder);
else
  res = TSeries(Time,data.data,'TensorOrder',tensorOrder,...
    'repres',repres);
end
res.name = data.name;
res.units = data.UNITS;
ud = data; ud = rmfield(ud,'DEPEND_0'); ud = rmfield(ud,'data');
ud = rmfield(ud,'nrec'); ud = rmfield(ud,'dim'); ud = rmfield(ud,'name');
ud = rmfield(ud,'variance');
if isfield(ud,'COORDINATE_SYSTEM')
  res.coordinateSystem = ud.COORDINATE_SYSTEM;
  ud = rmfield(ud,'COORDINATE_SYSTEM');
end
res.userData = ud;
