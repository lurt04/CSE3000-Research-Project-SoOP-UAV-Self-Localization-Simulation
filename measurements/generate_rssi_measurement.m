function rssi = generate_rssi_measurement(env, x_true)
% GENERATE_RSSI_MEASUREMENT  Simulate noisy RSSI readings (open-field).
%
%   Uses fspl() from the MATLAB Antenna Toolbox, which evaluates the Friis
%   free-space path loss for the given distance and wavelength.
%

lambda = physconst('LightSpeed') / env.rf_frequency_hz;
dist   = vecnorm(env.tx - x_true', 2, 2);   % N_tx × 1 (m)
dist   = max(dist, 1);                        % guard against zero distance

rssi = env.rssi_P_tx_dBm - fspl(dist, lambda) ...
     + env.rssi_shadow_std * randn(env.N_tx, 1);

end
