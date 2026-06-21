function env = urban_environment_chicago()
% URBAN_ENVIRONMENT_CHICAGO  Chicago downtown urban scenario with OSM ray tracing.
%
%   Uses MATLAB's siteviewer + raytracing propagation model (SBR method)
%   for realistic building-aware propagation.  NLOS and multipath are
%   captured implicitly by the ray tracer
%
%   Four transmitters in the Chicago Loop area (lat/lon).
%   The UAV trajectory is defined in lat/lon/altitude, converted to local
%   ENU (East-North-Up) meters for the EKF state vector.
%
%   No Monte Carlo: ray tracing is too expensive for repeated runs.

env.type = 'urban_chicago';

%% ── Reference origin (WGS-84) ──────────────────────────────────────────
%   ENU origin at TX1.  All positions expressed relative to this.
env.origin_lat =  41.88382;
env.origin_lon = -87.63025;
env.origin_alt =   0;

%% ── Transmitter sites (lat, lon, height AGL in m) ───────────────────────
%% Source: https://www.celltowermaps.com/cell-towers/near/city-state/chicago/il
%% LOS TX2 at 164m
env.tx_lat  = [41.88382,  41.87975,  41.88083,  41.87836, 41.88336, 41.88583, 41.88333, 41.88597];
env.tx_lon  = [-87.63025, -87.63144, -87.62852, -87.62788, -87.63561, -87.62666, -87.62638, -87.63316];
env.tx_hagl = [  183,          164,        86,         88  , 76, 6, 44, 107];

%% NLOS TX2 at 44m
%env.tx_lat  = [41.88382,  41.87930,  41.88083,  41.87836, 41.88336, 41.88583, 41.88333, 41.88597];
%env.tx_lon  = [-87.63025, -87.63288, -87.62852, -87.62788, -87.63561, -87.62666, -87.62638, -87.63316];
%env.tx_hagl = [  183,          44,        86,         88  , 76, 6, 44, 107];

%% 20 Transmitters distributed over UAV trajectory
%env.tx_lat  = [41.88382,  41.87975,  41.88083,  41.87836, 41.88336, 41.88583, 41.88333, 41.88597, 41.88058, 41.88083, 41.88113, 41.88086, 41.88227, 41.88316, 41.88427, 41.88500, 41.88405, 41.88127, 41.88305, 41.88444];
%env.tx_lon  = [-87.63025, -87.63144, -87.62852, -87.62788, -87.63561, -87.62666, -87.62638, -87.63316, -87.62783, -87.62852, -87.62975, -87.63283, -87.63202, -87.63102, -87.63069, -87.62883, -87.62830, -87.63105, -87.62972, -87.62916];
%env.tx_hagl = [  183,          164,        86,         88  , 76,        6,          44,         107,        35,     87,         282,        75, 161, 125, 198, 89, 114, 126, 182, 10];

env.tx_freq = 2.4e9;   % Hz 

env.N_tx = numel(env.tx_lat);

%% ── Convert TX lat/lon → local ENU (m) ──────────────────────────────────
env.tx = zeros(env.N_tx, 3);
for i = 1:env.N_tx
    [e, n] = latlon_to_enu(env.tx_lat(i), env.tx_lon(i), ...
                            env.origin_lat, env.origin_lon);
    env.tx(i,:) = [e, n, env.tx_hagl(i)];
end

%% ── RF parameters ───────────────────────────────────────────────────────
env.rf_frequency_hz = env.tx_freq; 
env.rssi_P_tx_dBm   = 43; % 20 Watt power.

%% ── Ray-tracing model settings ──────────────────────────────────────────
env.rt_method           = 'sbr';
env.rt_max_reflections  = 16;
env.rt_max_diffractions = 1;

%% ── Noise parameters ────────────────────────────────────────────────────
%   noise_std      : hardware TDoA timing noise std (s) - used in measurement
%                    generation only (generate_measurements_urban)
%   nlos_spread_s  : EKF R inflation (s) - must cover both hardware noise AND
%                    the systematic LOS/NLOS model mismatch between
%                    measFcn_tdoa (Euclidean prediction) and the ray-traced
%                    measurement.   
%   rssi_shadow_std: RSSI shadow fading std (dB)
env.noise_std      = 20e-9;    % s  - hardware timing noise
env.nlos_spread_s  = 100e-9;   % s  - EKF R: covers NLOS model mismatch
env.rssi_shadow_std = 10;      % dB - EKF 

%% ── EKF internal measurement model (log-distance) ───────────────────────
%   Used ONLY for EKF prediction — never for measurement generation.
%   The mismatch between this model and the ray-traced truth is absorbed by R.
env.rssi_PL0_dBm = 40;   % dB (free-space reference at d = 1 m, 2.4 GHz) 
env.rssi_n       = 3.8;  % path-loss exponent (urban)

%% ── Area size (m) — loose bounding box of the 4 TXs ────────────────────
%% Map / flight bounds
% Keep EKF estimates inside the Chicago OSM export. Without this physical
% constraint, a biased TDoA update can jump outside the map and the plotted
% error becomes an artifact of the filter leaving the simulated area.
env.map_lat_min =  41.87680;
env.map_lat_max =  41.88440;
env.map_lon_min = -87.63600;
env.map_lon_max = -87.62550;

[e_min, n_min] = latlon_to_enu(env.map_lat_min, env.map_lon_min, ...
                               env.origin_lat, env.origin_lon);
[e_max, n_max] = latlon_to_enu(env.map_lat_max, env.map_lon_max, ...
                               env.origin_lat, env.origin_lon);
env.bounds_enu = [min(e_min, e_max), max(e_min, e_max); ...
                  min(n_min, n_max), max(n_min, n_max); ...
                  1, 160];

% TDoA innovation gate for dense urban NLOS. Outlier TDoA components are
% not discarded; their EKF variance is inflated for that update.
env.tdoa_gate_sigma = 3;
env.tdoa_outlier_std_multiplier = 5;

env.area_size = max(env.bounds_enu(1,2) - env.bounds_enu(1,1), ...
                    env.bounds_enu(2,2) - env.bounds_enu(2,1));


end
