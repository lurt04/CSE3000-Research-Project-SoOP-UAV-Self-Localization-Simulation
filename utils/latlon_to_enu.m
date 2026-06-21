function [e, n] = latlon_to_enu(lat, lon, lat0, lon0)
% LATLON_TO_ENU  Convert WGS-84 lat/lon to local East-North (m).
%
%   Uses the flat-Earth (equirectangular) approximation
%
%   Inputs
%     lat, lon   : target position (degrees)
%     lat0, lon0 : reference origin (degrees)
%
%   Outputs
%     e : east  offset (m)
%     n : north offset (m)

R_earth = 6378137;   % WGS-84 equatorial radius (m)

dlat = deg2rad(lat  - lat0);
dlon = deg2rad(lon  - lon0);
lat0_rad = deg2rad(lat0);

n = R_earth * dlat;
e = R_earth * cos(lat0_rad) * dlon;

end
