function results = run_monte_carlo(cfg, env, uav_true, fig)
% RUN_MONTE_CARLO  Run MC_runs independent EKF trials and collect RMSE statistics.
%
%   Three parallel EKFs are evaluated each run:
%     1. TDoA-only
%     2. RSSI-only
%     3. Fused TDoA + RSSI
%
%   For each filter, three RMSE metrics are recorded per run:
%     rmse3d   - overall 3-D error
%     rmse2d   - horizontal (XY) error
%     rmse_z   - vertical (Z) error
%   This allows diagnosing whether height determination is the dominant
%   source of localization error.

rmse3d_tdoa  = zeros(cfg.MC_runs, 1);
rmse3d_rssi  = zeros(cfg.MC_runs, 1);
rmse3d_fused = zeros(cfg.MC_runs, 1);

rmse2d_tdoa  = zeros(cfg.MC_runs, 1);
rmse2d_rssi  = zeros(cfg.MC_runs, 1);
rmse2d_fused = zeros(cfg.MC_runs, 1);

rmsez_tdoa   = zeros(cfg.MC_runs, 1);
rmsez_rssi   = zeros(cfg.MC_runs, 1);
rmsez_fused  = zeros(cfg.MC_runs, 1);

figure(fig);
hold on;

h_tdoa = []; h_rssi = []; h_fused = [];

for mc = 1:cfg.MC_runs

    uav_est_tdoa  = zeros(3, cfg.T);
    uav_est_rssi  = zeros(3, cfg.T);
    uav_est_fused = zeros(3, cfg.T);

    init_pos = uav_true(:,1) + 10 * randn(3,1);

    ekf_tdoa  = create_ekf_tdoa(env, cfg, init_pos);
    ekf_rssi  = create_ekf_rssi(env, cfg, init_pos);
    ekf_fused = create_ekf_fused(env, cfg, init_pos);

    for k = 1:cfg.T

        x_true = uav_true(:,k);

        tdoa    = generate_tdoa_measurement(env, x_true, cfg);
        rssi    = generate_rssi_measurement(env, x_true);
        z_fused = [tdoa; rssi];

        predict(ekf_tdoa);  correct(ekf_tdoa,  tdoa');
        predict(ekf_rssi);  correct(ekf_rssi,  rssi');
        predict(ekf_fused); correct(ekf_fused, z_fused');

        uav_est_tdoa(:,k)  = ekf_tdoa.State(1:3);
        uav_est_rssi(:,k)  = ekf_rssi.State(1:3);
        uav_est_fused(:,k) = ekf_fused.State(1:3);

    end

    [rmse3d_tdoa(mc),  rmse2d_tdoa(mc),  rmsez_tdoa(mc)]  = compute_rmse(uav_est_tdoa,  uav_true);
    [rmse3d_rssi(mc),  rmse2d_rssi(mc),  rmsez_rssi(mc)]  = compute_rmse(uav_est_rssi,  uav_true);
    [rmse3d_fused(mc), rmse2d_fused(mc), rmsez_fused(mc)] = compute_rmse(uav_est_fused, uav_true);

    h1 = plot3(uav_est_tdoa(1,:),  uav_est_tdoa(2,:),  uav_est_tdoa(3,:),  '--', 'Color', [0.5 0.5 0.5],   'HandleVisibility','off');
    h2 = plot3(uav_est_rssi(1,:),  uav_est_rssi(2,:),  uav_est_rssi(3,:),  '--', 'Color', [0.93 0.69 0.13], 'HandleVisibility','off');
    h3 = plot3(uav_est_fused(1,:), uav_est_fused(2,:), uav_est_fused(3,:), '--', 'Color', [0.47 0.67 0.19], 'HandleVisibility','off');

    if mc == 1
        h1.HandleVisibility = 'on'; h_tdoa  = h1;
        h2.HandleVisibility = 'on'; h_rssi  = h2;
        h3.HandleVisibility = 'on'; h_fused = h3;
    end

end

legend('True trajectory', 'Transmitters', 'EKF TDoA', 'EKF RSSI', 'EKF Fused');

%% Pack results
results.rmse3d_tdoa  = rmse3d_tdoa;
results.rmse3d_rssi  = rmse3d_rssi;
results.rmse3d_fused = rmse3d_fused;

results.rmse2d_tdoa  = rmse2d_tdoa;
results.rmse2d_rssi  = rmse2d_rssi;
results.rmse2d_fused = rmse2d_fused;

results.rmsez_tdoa   = rmsez_tdoa;
results.rmsez_rssi   = rmsez_rssi;
results.rmsez_fused  = rmsez_fused;

end
