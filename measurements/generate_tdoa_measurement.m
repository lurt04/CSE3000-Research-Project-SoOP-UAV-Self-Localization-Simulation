function tdoa = generate_tdoa_measurement(env, x_true, cfg)
% GENERATE_TDOA_MEASUREMENT  Simulate noisy TDoA measurements (open-field).
%
%   Computes true Euclidean distances, converts to ToA with additive
%   Gaussian timing noise.


dist = vecnorm(env.tx - x_true', 2, 2);           % N_tx × 1 true distances (m)
toa  = dist / cfg.c + cfg.noise_std * randn(env.N_tx, 1);
tdoa = toa(2:end) - toa(1);

end
