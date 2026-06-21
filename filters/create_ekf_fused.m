function ekf = create_ekf_fused(env, cfg, initial_position)

state0 = [initial_position; 0; 0; 0];

ekf = extendedKalmanFilter( ...
    @(x) stateFcn(cfg, x), ...
    @(x) measFcn_fused(x, env.tx, cfg, env, 1), ...
    state0);

ekf.ProcessNoise = diag([5 5 5 1 1 1]);

R_tdoa = eye(env.N_tx - 1) * cfg.noise_std^2;
R_rssi = eye(env.N_tx)     * env.rssi_shadow_std^2;

ekf.MeasurementNoise = blkdiag(R_tdoa, R_rssi);

end
