function ekf = create_ekf_tdoa(env, cfg, initial_position)

state0 = [initial_position; 0;0;0];

ekf = extendedKalmanFilter( ...
    @(x) stateFcn(cfg, x), ...
    @(x) measFcn_tdoa(x, env.tx, cfg.c, 1), ...
    state0);

ekf.ProcessNoise = diag([5 5 5 1 1 1]);

ekf.MeasurementNoise = eye(env.N_tx-1) * cfg.noise_std^2;

end