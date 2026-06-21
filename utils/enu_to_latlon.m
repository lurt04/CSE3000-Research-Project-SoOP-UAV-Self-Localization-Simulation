function [lat, lon] = enu_to_latlon(e, n, lat0, lon0)
% ENU_TO_LATLON  Convert local ENU (m) back to WGS-84 lat/lon.
%
%   Inverse of latlon_to_enu.

R_earth = 6378137;

lat = lat0 + rad2deg(n / R_earth);
lon = lon0 + rad2deg(e / (R_earth * cos(deg2rad(lat0))));

end
