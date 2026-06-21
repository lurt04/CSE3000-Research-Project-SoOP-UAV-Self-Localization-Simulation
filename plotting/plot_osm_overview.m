function plot_osm_overview(env, uav_true, results)
% PLOT_OSM_OVERVIEW  Show UAV route and transmitters on an OpenStreetMap tile.
%
%   Downloads a tile from the OpenStreetMap tile server (requires internet),
%   overlays the TX positions and UAV trajectory in lat/lon space.
%
%   If internet is unavailable or the tile download fails, falls back to a
%   clean lat/lon scatter plot without a background map.
%


%% ── Convert ENU trajectory back to lat/lon ──────────────────────────────
T = size(uav_true, 2);
uav_lat = zeros(1, T);
uav_lon = zeros(1, T);
for k = 1:T
    [uav_lat(k), uav_lon(k)] = enu_to_latlon( ...
        uav_true(1,k), uav_true(2,k), env.origin_lat, env.origin_lon);
end

%% ── Compute bounding box with margin ────────────────────────────────────
all_lat = [env.tx_lat, uav_lat];
all_lon = [env.tx_lon, uav_lon];
lat_min = min(all_lat); lat_max = max(all_lat);
lon_min = min(all_lon); lon_max = max(all_lon);
margin_lat = 0.0015;
margin_lon = 0.0020;
lat_min = lat_min - margin_lat;  lat_max = lat_max + margin_lat;
lon_min = lon_min - margin_lon;  lon_max = lon_max + margin_lon;

%% ── Attempt to download OSM tile ────────────────────────────────────────
fig = figure('Name', 'UAV Route - OpenStreetMap Overview', ...
             'Position', [50 50 900 750]);
ax  = axes('Parent', fig);

tile_ok = false;
try
    % Use MATLAB's built-in geoaxes if Mapping Toolbox is available
    delete(ax);
    ga = geoaxes('Parent', fig);
    geolimits(ga, [lat_min lat_max], [lon_min lon_max]);
    geobasemap(ga, 'streets');   % OpenStreetMap-style tiles

    %% Plot on geoaxes
    hold(ga, 'on');

    % True trajectory
    geoplot(ga, uav_lat, uav_lon, '-', ...
        'Color', [0 0.45 0.74], 'LineWidth', 2.5, 'DisplayName', 'True path');

    % Estimated trajectories (if provided)
    if ~isempty(results)
        [est_lat_t, est_lon_t] = enu_arr_to_latlon(results.uav_est_tdoa, env);
        [est_lat_r, est_lon_r] = enu_arr_to_latlon(results.uav_est_rssi,  env);
        [est_lat_f, est_lon_f] = enu_arr_to_latlon(results.uav_est_fused, env);
        geoplot(ga, est_lat_t, est_lon_t, '--', 'Color', [0.5 0.5 0.5],   'LineWidth', 1.5, 'DisplayName', 'EKF TDoA');
        geoplot(ga, est_lat_r, est_lon_r, '--', 'Color', [0.93 0.69 0.13], 'LineWidth', 1.5, 'DisplayName', 'EKF RSSI');
        geoplot(ga, est_lat_f, est_lon_f, '--', 'Color', [0.47 0.67 0.19], 'LineWidth', 1.5, 'DisplayName', 'EKF Fused');
    end

    % Transmitters
    geoplot(ga, env.tx_lat, env.tx_lon, '^', ...
        'MarkerSize', 12, 'MarkerFaceColor', [0.85 0.33 0.10], ...
        'MarkerEdgeColor', 'k', 'DisplayName', 'Base stations');

    % Start / end markers
    geoplot(ga, uav_lat(1),   uav_lon(1),   'go', 'MarkerSize', 10, ...
        'MarkerFaceColor', 'g', 'DisplayName', 'Start');
    geoplot(ga, uav_lat(end), uav_lon(end), 'rs', 'MarkerSize', 10, ...
        'MarkerFaceColor', 'r', 'DisplayName', 'End');

    % TX labels
    for i = 1:env.N_tx
        text(ga, env.tx_lat(i), env.tx_lon(i), sprintf('  TX%d', i), ...
            'FontSize', 9, 'FontWeight', 'bold', 'Color', [0.7 0.1 0]);
    end

    legend(ga, 'Location', 'best');
    title(ga, 'UAV Route - Urban (OpenStreetMap)');
    tile_ok = true;

catch ME
    % Mapping Toolbox unavailable — fall back to plain lat/lon axes
    warning('plot_osm:noMapping', ...
        'Mapping Toolbox unavailable (%s). Plotting without map tile.', ME.message);
    tile_ok = false;
end

if ~tile_ok
    %% ── Fallback: plain axes with lat/lon ────────────────────────────────
    close(fig);
    fig = figure('Name', 'UAV Route — Lat/Lon (no tile)', 'Position', [50 50 900 750]);
    hold on; grid on;

    plot(uav_lon, uav_lat, '-', 'Color', [0 0.45 0.74], 'LineWidth', 2.5, ...
        'DisplayName', 'True path');

    if ~isempty(results)
        [el, eln] = enu_arr_to_latlon(results.uav_est_tdoa, env);
        plot(eln, el, '--', 'Color', [0.5 0.5 0.5],   'LineWidth', 1.5, 'DisplayName', 'EKF TDoA');
        [el, eln] = enu_arr_to_latlon(results.uav_est_rssi, env);
        plot(eln, el, '--', 'Color', [0.93 0.69 0.13], 'LineWidth', 1.5, 'DisplayName', 'EKF RSSI');
        [el, eln] = enu_arr_to_latlon(results.uav_est_fused, env);
        plot(eln, el, '--', 'Color', [0.47 0.67 0.19], 'LineWidth', 1.5, 'DisplayName', 'EKF Fused');
    end

    plot(env.tx_lon, env.tx_lat, '^', 'MarkerSize', 12, ...
        'MarkerFaceColor', [0.85 0.33 0.10], 'MarkerEdgeColor', 'k', ...
        'DisplayName', 'Base stations');
    plot(uav_lon(1),   uav_lat(1),   'go', 'MarkerSize', 10, 'MarkerFaceColor', 'g', 'DisplayName', 'Start');
    plot(uav_lon(end), uav_lat(end), 'rs', 'MarkerSize', 10, 'MarkerFaceColor', 'r', 'DisplayName', 'End');

    for i = 1:env.N_tx
        text(env.tx_lon(i) + 0.0001, env.tx_lat(i), sprintf('TX%d', i), ...
            'FontSize', 9, 'FontWeight', 'bold');
    end

    xlabel('Longitude'); ylabel('Latitude');
    title('UAV Route — TU Delft Campus (Lat/Lon, no tile)');
    legend('Location', 'best');
    axis equal;
end

end

%% ── Helper: convert ENU matrix to lat/lon arrays ─────────────────────────
function [lats, lons] = enu_arr_to_latlon(enu_mat, env)
T = size(enu_mat, 2);
lats = zeros(1, T);
lons = zeros(1, T);
for k = 1:T
    [lats(k), lons(k)] = enu_to_latlon( ...
        enu_mat(1,k), enu_mat(2,k), env.origin_lat, env.origin_lon);
end
end
