function uav_true = urban_trajectory_chicago(cfg, env)
% URBAN_TRAJECTORY_CHICAGO  UAV path over Chicago Loop in local ENU metres.
%
%   The UAV follows a road-aligned route through downtown Chicago.
%   The path is defined by several lat/lon waypoints and is interpolated
%   in local ENU. Altitude varies slightly to mimic realistic flight.
%
%   All positions are expressed in local ENU (m) relative to env.origin.
%   Output: 3×T matrix [East; North; Altitude_AGL].

T = cfg.T;
t = linspace(0, 1, T);   % normalised time [0,1]

%% ── Road-aligned waypoints for Chicago Loop ────────────────────────────
waypoints = [
    41.8807765130121, -87.62772757521203;
    41.88074099268571, -87.63227835618414;
    41.882003214599095, -87.63235972432628;
    41.88202552011342, -87.6308745868409;
    41.88447724924336, -87.63094566854383;
    41.88452887120226, -87.62793220010303;
];

num_waypoints = size(waypoints, 1);

e_wp = zeros(num_waypoints, 1);
n_wp = zeros(num_waypoints, 1);
for idx = 1:num_waypoints
    [e_wp(idx), n_wp(idx)] = latlon_to_enu(waypoints(idx,1), waypoints(idx,2), ...
                                           env.origin_lat, env.origin_lon);
end

%% ── Piecewise linear route interpolation ──────────────────────────────
segment_distances = sqrt(diff(e_wp).^2 + diff(n_wp).^2);
cumulative_dist = [0; cumsum(segment_distances)];
route_s = linspace(0, cumulative_dist(end), T);

e_path = interp1(cumulative_dist, e_wp, route_s, 'linear');
n_path = interp1(cumulative_dist, n_wp, route_s, 'linear');

%% ── Altitude profile: small variation around 30 m AGL ─────────────────
alt_base = 40;          % m AGL
alt_amp  = 10;           % m amplitude
alt_wave = alt_base + alt_amp * sin(2*pi * 2 * t + pi/6);

%% ── Assemble trajectory ─────────────────────────────────────────────────
uav_true = [e_path; n_path; alt_wave];

end
