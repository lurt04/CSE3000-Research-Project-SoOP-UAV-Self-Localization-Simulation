function env = urban_environment_tu_delft()
% URBAN_ENVIRONMENT_TU_DELFT  TU Delft campus urban scenario with OSM ray tracing.
%
%   Uses MATLAB's siteviewer + raytracing propagation model (SBR method)
%   for realistic building-aware propagation.  NLOS and multipath are
%   captured implicitly by the ray tracer
%
%   Four transmitters on/around the TU Delft campus (lat/lon).
%   The UAV trajectory is defined in lat/lon/altitude, converted to local
%   ENU (East-North-Up) metres for the EKF state vector.
%
%   No Monte Carlo: ray tracing is too expensive for repeated runs.

env.type = 'urban_tu_delft';

%% ── Reference origin (WGS-84) ──────────────────────────────────────────
%   ENU origin at TX1.  All positions expressed relative to this.
env.origin_lat =  52.0021;
env.origin_lon =   4.3730;
env.origin_alt =   0;

%% ── Transmitter sites (lat, lon, height AGL in m) ───────────────────────
%% Handpicked sites
env.tx_lat  = [52.00275,  52.00194,  52.00018,  51.99785];
env.tx_lon  = [ 4.37107,   4.37847,   4.37242,   4.37933];
env.tx_hagl = [  21,        41,        28,         42   ];

%% Real transmitter sites from https://antennekaart.nl/kaart/5g
%env.tx_lat  = [52.00275,  52.00194,  52.00018,  51.99785, 51.99870, 51.99029, 51.99788];
%env.tx_lon  = [ 4.37107,   4.37847,   4.37242,   4.37933, 4.36788, 4.37517, 4.38251];
%env.tx_hagl = [  21,        41,        28,         42   ,   28,       4,        30];


env.tx_freq = 2.4e9;   % Hz 

env.N_tx = numel(env.tx_lat);

%% ── Convert TX lat/lon to local ENU (m) ──────────────────────────────────
env.tx = zeros(env.N_tx, 3);
for i = 1:env.N_tx
    [e, n] = latlon_to_enu(env.tx_lat(i), env.tx_lon(i), ...
                            env.origin_lat, env.origin_lon);
    env.tx(i,:) = [e, n, env.tx_hagl(i)];
end

%% ── RF parameters ───────────────────────────────────────────────────────
env.rf_frequency_hz = env.tx_freq;   
env.rssi_P_tx_dBm   = 43; % 20 Watt

%% ── Ray-tracing model settings ──────────────────────────────────────────
env.rt_method           = 'sbr';
env.rt_max_reflections  = 2;
env.rt_max_diffractions = 1;

%% ── Noise parameters ────────────────────────────────────────────────────
%   noise_std      : hardware TDoA timing noise std (s) - used in measurement
%                    generation only (generate_tdoa_measurement_urban)
%   nlos_spread_s  : EKF R inflation (s) - covers hardware noise AND the
%                    systematic LOS/NLOS model mismatch. 
%   rssi_shadow_std: RSSI shadow fading std (dB)
env.noise_std      = 20e-9;    % s  - hardware timing noise
env.nlos_spread_s  = 100e-9;   % s  - EKF R: covers NLOS model mismatch
env.rssi_shadow_std = 10;       % dB - EKF

%% ── EKF internal measurement model (log-distance) ───────────────────────
%   Used ONLY for EKF prediction — never for measurement generation.
%   The mismatch between this model and the ray-traced truth is absorbed by R.
env.rssi_PL0_dBm = 40;   % dB  (free-space reference at d = 1 m, 2.4 GHz)
env.rssi_n       = 3.2;  % path-loss exponent (urban campus)

env.tdoa_gate_sigma = 3;
env.tdoa_outlier_std_multiplier = 5;

%% ── Area size (m) — loose bounding box of the 4 TXs ────────────────────
env.area_size = 800;

end
