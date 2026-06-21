% MAIN  UAV Localisation Simulation - Open Field & Urban (TU Delft Campus)
%
%   Switch the environment by changing ENVIRONMENT below.
%
%   open_field : Monte Carlo, Cartesian ENU, free-space path loss.
%   urban      : Single run, lat/lon -> ENU, ray-traced measurements (OSM).
%
%   REQUIREMENTS
%     - MATLAB Antenna Toolbox  (fspl, pathloss, siteviewer, txsite, rxsite)
%     - map.osm in the working directory (for urban ray tracing).
%       Export from openstreetmap.org, bounding box approx:
%         51.993 – 52.005 N,  4.368 – 4.382 E  (TU Delft campus)
%     - Mapping Toolbox (optional, for OSM tile background in overview plot)

clear; close all; clc;
addpath(genpath(pwd));
rng(42);

%% ─────────────────────────── SELECT ENVIRONMENT ────────────────────────────────────────────────────
ENVIRONMENT = 'urban_chicago';      % 'open_field'  |  'urban_tu_delft' | 'urban_chicago'
%% ──────────────────────────────────────────────────────────────────────────────────────────────────

%% ── Load shared config ───────────────────────────────────────────────────
cfg = default_config();

%% ── Environment-specific overrides ──────────────────────────────────────
switch lower(ENVIRONMENT)

    case 'open_field'
        env     = open_field_environment();
        cfg.T   = 200;
        cfg.dt  = 1;
        cfg.MC_runs = 50;

    case 'urban_tu_delft'
        env     = urban_environment_tu_delft();
        cfg.T   = 30;     % fewer steps; ray tracing per step is expensive
        cfg.dt  = 2;      % s
        cfg.MC_runs = 1;
        cfg.noise_std = env.noise_std;   
        
    case 'urban_chicago'
        env     = urban_environment_chicago();
        cfg.T   = 30;
        cfg.dt  = 2;
        cfg.MC_runs = 1;
        cfg.noise_std = env.noise_std;
    otherwise
        error('Unknown environment ''%s''. Use ''open_field'' or ''urban''.', ENVIRONMENT);
end

fprintf('Environment : %s\n', upper(env.type));
fprintf('Time steps  : %d  (dt = %.1f s)\n', cfg.T, cfg.dt);

%% ── Generate UAV trajectory ──────────────────────────────────────────────
switch lower(ENVIRONMENT)
    case 'open_field'
        uav_true = sinusoidal_trajectory(cfg, env);
    case 'urban_tu_delft'
        uav_true = urban_trajectory_tu_delft(cfg, env);
    case 'urban_chicago'
        uav_true = urban_trajectory_chicago(cfg, env);
end

%% ── Plot initial environment / trajectory ────────────────────────────────
fig = plot_environment(env, uav_true);

%% ── Run simulation ───────────────────────────────────────────────────────
switch lower(ENVIRONMENT)

    case 'open_field'
        results = run_monte_carlo(cfg, env, uav_true, fig);

        fprintf('\n--- Monte Carlo Results (%d runs) | %s ---\n', cfg.MC_runs, env.type);
        fprintf('\n  %-10s  %8s  %8s  %8s\n', 'Filter', '3-D RMSE', '2-D RMSE', 'Z RMSE');
        fprintf('  %s\n', repmat('-', 1, 42));
        print_row('TDoA',  results.rmse3d_tdoa,  results.rmse2d_tdoa,  results.rmsez_tdoa);
        print_row('RSSI',  results.rmse3d_rssi,  results.rmse2d_rssi,  results.rmsez_rssi);
        print_row('Fused', results.rmse3d_fused, results.rmse2d_fused, results.rmsez_fused);

        fprintf('\n  Z-RMSE / 2D-RMSE ratios (>1 = height dominates):\n');
        fprintf('    TDoA  : %.2f\n', mean(results.rmsez_tdoa)  / mean(results.rmse2d_tdoa));
        fprintf('    RSSI  : %.2f\n', mean(results.rmsez_rssi)  / mean(results.rmse2d_rssi));
        fprintf('    Fused : %.2f\n', mean(results.rmsez_fused) / mean(results.rmse2d_fused));

        plot_results(results);

    case {'urban_tu_delft', 'urban_chicago'}
        results = run_urban_simulation(cfg, env, uav_true);

        fprintf('\n--- Urban Ray-Tracing Results (1 run) | %s ---\n', env.type);
        fprintf('\n  %-10s  %8s  %8s  %8s\n', 'Filter', '3-D RMSE', '2-D RMSE', 'Z RMSE');
        fprintf('  %s\n', repmat('-', 1, 42));
        fprintf('  %-10s  %7.2f m  %7.2f m  %7.2f m\n', 'TDoA',  ...
            results.rmse3d_tdoa,  results.rmse2d_tdoa,  results.rmsez_tdoa);
        fprintf('  %-10s  %7.2f m  %7.2f m  %7.2f m\n', 'RSSI',  ...
            results.rmse3d_rssi,  results.rmse2d_rssi,  results.rmsez_rssi);
        fprintf('  %-10s  %7.2f m  %7.2f m  %7.2f m\n', 'Fused', ...
            results.rmse3d_fused, results.rmse2d_fused, results.rmsez_fused);

        %% Add estimated tracks to the environment plot
        figure(fig);
        hold on;
        plot3(results.uav_est_tdoa(1,:),  results.uav_est_tdoa(2,:),  results.uav_est_tdoa(3,:),  ...
              '--', 'Color', [0.5 0.5 0.5],   'LineWidth', 1.5, 'DisplayName', 'EKF TDoA');
        plot3(results.uav_est_rssi(1,:),  results.uav_est_rssi(2,:),  results.uav_est_rssi(3,:),  ...
              '--', 'Color', [0.93 0.69 0.13], 'LineWidth', 1.5, 'DisplayName', 'EKF RSSI');
        plot3(results.uav_est_fused(1,:), results.uav_est_fused(2,:), results.uav_est_fused(3,:), ...
              '--', 'Color', [0.3 0.3 0.9], 'LineWidth', 1.5, 'DisplayName', 'EKF Fused');
        legend('Location', 'best');

        %% Detailed result plots
        plot_urban_results(results, env, uav_true);

        %% OpenStreetMap overview (requires Mapping Toolbox for tile background)
        plot_osm_overview(env, uav_true, results);
end

%% ─────────────────────────────────────────────────────────────────────────
function print_row(name, r3d, r2d, rz)
fprintf('  %-10s  %7.2f m  %7.2f m  %7.2f m\n', name, mean(r3d), mean(r2d), mean(rz));
end
