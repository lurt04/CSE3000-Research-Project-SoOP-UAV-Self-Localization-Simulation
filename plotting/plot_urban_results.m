function plot_urban_results(results, env, uav_true)
% PLOT_URBAN_RESULTS  Visualise single-run urban EKF results.
%
%   Figure 1 — ENU trajectory (3-D)
%   Figure 2 — Position error over time (per filter)
%   Figure 3 — RMSE bar chart (3D / 2D / Z)

T = size(uav_true, 2);

colors = struct( ...
    'true',  [0.00 0.45 0.74], ...
    'tdoa',  [0.50 0.50 0.50], ...
    'rssi',  [0.93 0.69 0.13], ...
    'fused', [0.47 0.67 0.19]);

%% ── Figure 1: 3-D trajectory ─────────────────────────────────────────────
figure('Name','Urban EKF - Trajectories (ENU)','Position',[50 50 900 700]);
hold on; grid on; axis vis3d;

plot3(uav_true(1,:), uav_true(2,:), uav_true(3,:), ...
      'Color', colors.true, 'LineWidth', 2.5, 'DisplayName', 'True path');

plot3(results.uav_est_tdoa(1,:),  results.uav_est_tdoa(2,:),  results.uav_est_tdoa(3,:), ...
      '--', 'Color', colors.tdoa,  'LineWidth', 1.5, 'DisplayName', 'EKF TDoA');
plot3(results.uav_est_rssi(1,:),  results.uav_est_rssi(2,:),  results.uav_est_rssi(3,:), ...
      '--', 'Color', colors.rssi,  'LineWidth', 1.5, 'DisplayName', 'EKF RSSI');
plot3(results.uav_est_fused(1,:), results.uav_est_fused(2,:), results.uav_est_fused(3,:), ...
      '--', 'Color', colors.fused, 'LineWidth', 1.5, 'DisplayName', 'EKF Fused');

% Plot TX positions
plot3(env.tx(:,1), env.tx(:,2), env.tx(:,3), ...
      '^', 'MarkerSize', 12, 'MarkerFaceColor', [0.85 0.33 0.10], ...
      'MarkerEdgeColor', 'k', 'DisplayName', 'Base stations');

for i = 1:env.N_tx
    text(env.tx(i,1)+10, env.tx(i,2)+10, env.tx(i,3), ...
         sprintf('TX%d', i), 'FontSize', 10);
end

legend('Location', 'best');
xlabel('East (m)'); ylabel('North (m)'); zlabel('Altitude (m)');
title('Urban UAV Tracking');
view(45, 30);
rotate3d on;

%% ── Figure 2: position error over time ───────────────────────────────────
err3d_tdoa  = vecnorm(results.uav_est_tdoa  - uav_true, 2, 1);
err3d_rssi  = vecnorm(results.uav_est_rssi  - uav_true, 2, 1);
err3d_fused = vecnorm(results.uav_est_fused - uav_true, 2, 1);

figure('Name','Urban EKF — 3-D Error Over Time','Position',[50 600 900 350]);
hold on; grid on;
plot(err3d_tdoa,  'Color', colors.tdoa,  'LineWidth', 1.5, 'DisplayName', 'TDoA');
plot(err3d_rssi,  'Color', colors.rssi,  'LineWidth', 1.5, 'DisplayName', 'RSSI');
plot(err3d_fused, 'Color', colors.fused, 'LineWidth', 2.0, 'DisplayName', 'Fused');
xlabel('Time step'); ylabel('3-D Position Error (m)');
title('Urban EKF: 3-D Error Over Time (Ray-Traced Measurements)');
legend('Location', 'best');

%% ── Figure 3: RMSE bar chart ─────────────────────────────────────────────
figure('Name','Urban EKF - RMSE Summary','Position',[1000 50 700 450]);

filter_names = {'TDoA', 'RSSI', 'Fused'};
v3d = [results.rmse3d_tdoa, results.rmse3d_rssi, results.rmse3d_fused];
v2d = [results.rmse2d_tdoa, results.rmse2d_rssi, results.rmse2d_fused];
vz  = [results.rmsez_tdoa,  results.rmsez_rssi,  results.rmsez_fused];

x  = 1:3;
bw = 0.25;
bar(x - bw, v3d, bw, 'FaceColor', [0.2 0.4 0.8]); hold on;
bar(x,      v2d, bw, 'FaceColor', [0.2 0.7 0.4]);
bar(x + bw, vz,  bw, 'FaceColor', [0.9 0.4 0.2]);

set(gca, 'XTick', x, 'XTickLabel', filter_names);
ylabel('RMSE (m)');
title('Urban EKF RMSE - 3D / 2D / Vertical (Ray-Traced Measurements)');
legend({'3-D','2-D (XY)','Z (height)'}, 'Location', 'best');
grid on;

end
