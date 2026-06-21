function results = run_urban_simulation(cfg, env, uav_true)
% RUN_URBAN_SIMULATION  Single-run EKF simulation for the urban environment.
%
%   Ray tracing is computationally expensive, so this is a single
%   deterministic run (no Monte Carlo).  Three EKF variants:
%     1. TDoA-only   (urban-tuned: small Z process noise)
%     2. RSSI-only   (urban-tuned)
%     3. Fused TDoA + RSSI (urban-tuned)
%
%   siteviewer and txsite objects are built once and reused.
%   EKF operates in local ENU meters; ray tracing uses lat/lon internally.

fprintf('Urban simulation: building siteviewer with OSM map...\n');
map_file = 'urban OSM map';

%% ── Build siteviewer ─────────────────────────────────────────────────────

try
    switch (lower(env.type))
        case 'urban_tu_delft'
            map_file = 'map.osm';
        case 'urban_chicago'
            map_file = 'chicago.osm';
        otherwise
            error('urban_sim:invalidEnv', ...
                'Unsupported environment type: %s', env.type);
    end

    sv = siteviewer('Buildings', map_file);

catch ME
    warning('urban_sim:noMap', ...
        'Could not load %s (%s). Continuing without building map.', ...
        map_file, ME.message);

    sv = siteviewer();
end

%% ── Build txsite objects ────────────────────────────────────────────────
fprintf('Creating %d transmitter sites...\n', env.N_tx);

tx_sites = cell(env.N_tx, 1);

for i = 1:env.N_tx
    tx_sites{i} = txsite( ...
        'Latitude',             env.tx_lat(i), ...
        'Longitude',            env.tx_lon(i), ...
        'AntennaHeight',        env.tx_hagl(i), ...
        'TransmitterFrequency', env.tx_freq, ...
        'TransmitterPower',     10^((env.rssi_P_tx_dBm - 30)/10));
end

%% ── Storage ──────────────────────────────────────────────────────────────
T = cfg.T;

uav_est_tdoa  = zeros(3, T);
uav_est_rssi  = zeros(3, T);
uav_est_fused = zeros(3, T);

%% ── Initial state ────────────────────────────────────────────────────────
init_noise = [5*randn(2,1); 2*randn(1)];
init_pos   = uav_true(:,1) + init_noise;

ekf_tdoa  = create_ekf_tdoa_urban(env, cfg, init_pos);
ekf_rssi  = create_ekf_rssi_urban(env, cfg, init_pos);
ekf_fused = create_ekf_fused_urban(env, cfg, init_pos);

%% ── Precompute noise settings ────────────────────────────────────────────
tdoa_gate_sigma = get_env_field(env, 'tdoa_gate_sigma', 3);
tdoa_outlier_std_multiplier = get_env_field(env, ...
    'tdoa_outlier_std_multiplier', 10);



%% ── Simulation loop ──────────────────────────────────────────────────────
fprintf('Running %d time steps...\n', T);

HUGE_R = 1e8;  % >>> any real RSSI/TDoA variance in this sim -- effectively "infinite"

for k = 1:T

    fprintf('  Step %d / %d\n', k, T);
    x_true = uav_true(:, k);

    [rssi_raw, toa_raw, rssi_avail, toa_avail] = generate_measurements_urban(env, x_true, cfg, tx_sites);

    predict(ekf_tdoa);
    predict(ekf_rssi);
    predict(ekf_fused);
    constrain_ekf_state(ekf_tdoa, env);
    constrain_ekf_state(ekf_rssi, env);
    constrain_ekf_state(ekf_fused, env);

    %% ── TDoA block ──────────────────────────────────────────────────
    [tdoa_z, R_tdoa_diag, ref_idx] = build_tdoa_measurement( ...
        toa_raw, toa_avail, ekf_tdoa.State, env, cfg, ...
        tdoa_gate_sigma, tdoa_outlier_std_multiplier, HUGE_R);

    ekf_tdoa.MeasurementNoise = diag(R_tdoa_diag);
    correct(ekf_tdoa, tdoa_z, ref_idx);

    %% ── RSSI block ──────────────────────────────────────────────────
    [rssi_z, R_rssi_diag] = build_rssi_measurement(rssi_raw, rssi_avail, env.rssi_shadow_std, HUGE_R); 

    ekf_rssi.MeasurementNoise = diag(R_rssi_diag); correct(ekf_rssi, rssi_z);

    %% ── Fused block ─────────────────────────────────────────────────
    [rssi_z_f, ~] = build_rssi_measurement(rssi_raw, rssi_avail, env.rssi_shadow_std, HUGE_R);

    R_rssi_diag_f = rssi_covariance_model(rssi_avail, ekf_fused.State, env.tx, env); 

    [tdoa_z_f, R_tdoa_diag_f, ref_idx_f] = build_tdoa_measurement( ... 
            toa_raw, toa_avail, ekf_fused.State, env, cfg, ... 
            tdoa_gate_sigma, tdoa_outlier_std_multiplier, HUGE_R);

    z_fused = [tdoa_z_f; rssi_z_f];

    % --- modality weights ---
    w_tdoa = 1.0;
    w_rssi = 0.4;
    
    R_fused = diag([ ...
        w_tdoa * R_tdoa_diag_f; ...
        w_rssi * R_rssi_diag_f ]);
    
    ekf_fused.MeasurementNoise = R_fused;
    
    correct(ekf_fused, z_fused, ref_idx_f);

    constrain_ekf_state(ekf_tdoa, env);
    constrain_ekf_state(ekf_rssi, env);
    constrain_ekf_state(ekf_fused, env);

    uav_est_tdoa(:,k)  = ekf_tdoa.State(1:3);
    uav_est_rssi(:,k)  = ekf_rssi.State(1:3);
    uav_est_fused(:,k) = ekf_fused.State(1:3);

end

%% ── RMSE ────────────────────────────────────────────────────────────────
[rmse3d_tdoa,  rmse2d_tdoa,  rmsez_tdoa]  = compute_rmse(uav_est_tdoa,  uav_true);
[rmse3d_rssi,  rmse2d_rssi,  rmsez_rssi]  = compute_rmse(uav_est_rssi,  uav_true);
[rmse3d_fused, rmse2d_fused, rmsez_fused] = compute_rmse(uav_est_fused, uav_true);

%% ── Pack results ────────────────────────────────────────────────────────
results.uav_est_tdoa  = uav_est_tdoa;
results.uav_est_rssi  = uav_est_rssi;
results.uav_est_fused = uav_est_fused;

results.rmse3d_tdoa  = rmse3d_tdoa;
results.rmse2d_tdoa  = rmse2d_tdoa;

results.rmse3d_rssi  = rmse3d_rssi;
results.rmse2d_rssi  = rmse2d_rssi;

results.rmse3d_fused = rmse3d_fused;
results.rmse2d_fused = rmse2d_fused;

results.rmsez_tdoa   = rmsez_tdoa;
results.rmsez_rssi   = rmsez_rssi;
results.rmsez_fused  = rmsez_fused;

results.sv       = sv;
results.tx_sites = tx_sites;

end


function value = get_env_field(env, field_name, default_value)
if isfield(env, field_name)
    value = env.(field_name);
else
    value = default_value;
end
end

function [tdoa_z, R_diag, ref_idx] = build_tdoa_measurement( ...
    toa_raw, toa_avail, ekf_state, env, cfg, gate_sigma, outlier_mult, huge_r)
% Fixed-length (N_tx-1) TDoA vector. Missing TX -> placeholder 0 with
% R = huge_r (zero Kalman weight). Reference TX chosen dynamically as
% whichever TX actually has a ray this step.

N = env.N_tx;
avail_idx = find(toa_avail);

tdoa_z = zeros(N-1, 1);
R_diag = huge_r * ones(N-1, 1);

if numel(avail_idx) < 2
    ref_idx = 1;          % nobody usable; everything stays nulled
    return;
end

ref_idx   = avail_idx(1);
other_idx = setdiff(1:N, ref_idx);   % always length N-1, fixed order

for s = 1:numel(other_idx)
    j = other_idx(s);
    if toa_avail(j)
        tdoa_z(s) = toa_raw(j) - toa_raw(ref_idx);
        R_diag(s) = env.nlos_spread_s^2;
    end
end

% Outlier gating only applies to genuinely-populated entries
predicted = measFcn_tdoa(ekf_state, env.tx, cfg.c, ref_idx);
residual  = abs(tdoa_z - predicted);
is_real   = R_diag < huge_r;
sigma     = sqrt(R_diag);
outlier   = is_real & (residual > gate_sigma * sigma);
R_diag(outlier) = (sigma(outlier) * outlier_mult).^2;

end

function [rssi_z, R_diag] = build_rssi_measurement(rssi_raw, rssi_avail, sigma_base, huge_r)
missing         = ~rssi_avail;
rssi_z          = rssi_raw;
rssi_z(missing) = 0;
R_diag          = sigma_base^2 * ones(size(rssi_raw));
R_diag(missing) = huge_r;
end

function R_diag = rssi_covariance_model(rssi_avail, x_pred, tx, env)
pos = x_pred(1:3)';
d = vecnorm(tx - pos, 2, 2);
d = max(d, 10);

R_diag = zeros(size(d));

sigma_los  = env.rssi_shadow_std;    
sigma_nlos = 2.5 * env.rssi_shadow_std;  % heavier tail in NLOS

for i = 1:numel(d)

    if ~rssi_avail(i)
        R_diag(i) = 1e8;
        continue;
    end

    % simple LOS probability surrogate
    p_los = exp(-d(i) / 300);  

    sigma_eff = sqrt( ...
        p_los  * sigma_los^2 + ...
        (1 - p_los) * sigma_nlos^2);

    R_diag(i) = sigma_eff^2;
end
end