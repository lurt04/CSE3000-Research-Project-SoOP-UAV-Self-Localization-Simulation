function env = open_field_environment()
% OPEN_FIELD_ENVIRONMENT  Large open-field UAV tracking scenario.
%
%   Flat, rural, open-sky conditions — free-space propagation.
%   Propagation: fspl() from the MATLAB Antenna Toolbox (Friis model).
%
%   RF parameters represent a rural Dutch macro tower (LTE Band 20 / 800 MHz
%   equivalent modelled at 2.4 GHz for simulation convenience):
%     Tx power    : +63 dBm  (rough average effective radiated power, NL rural tower)
%     Frequency   : 2.4 GHz
%     Shadow fading: sigma = 6 dB  (IEEE 802.16m Evaluation Methodology Document, LOS open terrain)
%
%   NLOS and multipath are not modelled in this environment.

env.type = 'open_field';

%% Area and transmitter layout
env.area_size = 10000;   % m
env.N_tx      = 6;

xy     = env.area_size * rand(env.N_tx, 2);   % random XY (m)
z      = 15 + 45 * rand(env.N_tx, 1);         % mast height: 15–60 m AGL
env.tx = [xy, z];                             % N_tx × 3

%% RF parameters
env.rf_frequency_hz = 2.4e9;         % Hz  (used by fspl and EKF measFcn)
env.rssi_P_tx_dBm   = 63;            % dBm - rough average power of Dutch rural towers

%% Shadow fading (log-normal, IEEE 802.16m Evaluation Methodology Document LOS open Rural Macrocell)
%   Added on top of the deterministic fspl() path loss.
%   This is NOT part of fspl - fspl is purely geometric; fading is physical.
env.rssi_shadow_std = 6;            % dB

end
