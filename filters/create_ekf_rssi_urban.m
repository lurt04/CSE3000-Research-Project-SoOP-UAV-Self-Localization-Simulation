function ekf = create_ekf_rssi_urban(env, cfg, initial_position)

state0 = [initial_position; 0; 0; 0];

ekf = extendedKalmanFilter( ...
    @(x) stateFcn(cfg, x), ...
    @(x) measFcn_rssi(x, env.tx, env), ...
    state0);

ekf.ProcessNoise = diag([5, 5, 0.5, 1, 1, 0.1]);

ekf.MeasurementNoise = eye(env.N_tx) * env.rssi_shadow_std^2;

end
