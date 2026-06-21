function [rssi, toa, rssi_avail, toa_avail]  = generate_measurements_urban(env, x_true, cfg, tx_sites)
% No fallbacks: if raytrace finds no ray for a TX, that TX's rssi(i) and
% toa(i) are left as NaN and tx_avail(i) = false. The caller decides how
% to fold that into the EKF update (see build_tdoa_measurement /
% build_rssi_measurement). x_true is used ONLY to place the
% receiver (rxsite) -- it is never used to synthesize a measurement.

[uav_lat, uav_lon] = enu_to_latlon(x_true(1), x_true(2), ...
                                    env.origin_lat, env.origin_lon);
uav_alt = x_true(3);

rx = rxsite( ...
    'Latitude', uav_lat, ...
    'Longitude', uav_lon, ...
    'AntennaHeight', max(uav_alt, 0.1));

pm = propagationModel('raytracing', ...
    'Method', env.rt_method, ...
    'MaxNumReflections', env.rt_max_reflections, ...
    'MaxNumDiffractions', env.rt_max_diffractions);

toa      = nan(env.N_tx,1);
rssi     = nan(env.N_tx,1);

toa_avail  = false(env.N_tx,1);
rssi_avail = false(env.N_tx,1);

c = cfg.c;

for i = 1:env.N_tx

    try
        rays = raytrace(tx_sites{i}, rx, pm);
    catch ME
        fprintf("TX %d: raytrace ERROR (%s) -- measurement dropped\n", i, ME.message);
        continue;
    end

    if isempty(rays) || isempty(rays{1})
        fprintf("TX %d: no ray found -- measurement dropped\n", i);
        continue;
    end

    ray_list = rays{1};

    %% ── TDoA: first arrival ──────────────────────────────────────────
    d_sorted = sort([ray_list.PropagationDistance]);
    
    if numel(d_sorted) > 1
        distance = d_sorted(1) + 0.3 * (d_sorted(2) - d_sorted(1));
    else
        distance = d_sorted(1);
    end

    toa(i) = distance / c + cfg.noise_std * randn();
    
    toa_avail(i) = true;

    %% ── RSSI: raypl for valid reflection rays ────────

    pl_candidates = [];
    
    for k = 1:numel(ray_list)
    
        ray_k = ray_list(k);

        try  
            pl_k = raypl(ray_k);
    
            if isfinite(pl_k)
                pl_candidates(end+1) = pl_k; %#ok<AGROW>
            end
    
        catch
            % If a ray exists but is unusable, ignore it (no fallback synthesis)
            continue;
        end
    end
    
    % ── No valid propagation at all -> treat like TDoA dropout
    if isempty(pl_candidates)
        fprintf("TX %d: RSSI unavailable (no valid propagation)\n", i);
        continue;
    end
    
    pl_total = -10 * log10(sum(10.^(-pl_candidates / 10)));
    
    rssi(i) = env.rssi_P_tx_dBm ...
            - pl_total ...
            + env.rssi_shadow_std * randn();
    
    rssi_avail(i) = true;
end

end