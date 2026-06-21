function uav_true = urban_trajectory_tu_delft(cfg, env)
% URBAN_TRAJECTORY  UAV path over TU Delft campus in local ENU metres.
%
%   The UAV starts at 51.99729 N, 4.37583 E and flies toward
%   52.00344 N, 4.37120 E in a wave-like pattern - sinusoidal lateral
%   (East) excursions superimposed on the main North track, plus gentle
%   altitude oscillation.
%
%   All positions are expressed in local ENU (m) relative to env.origin.
%   Output: 3×T matrix [East; North; Altitude_AGL].

T = cfg.T;
t = linspace(0, 1, T);   % normalised time [0,1]

%% ── Convert start / end lat-lon to ENU (m) ──────────────────────────────
lat_start =  51.99728852309749;  lon_start = 4.375825099135653;
lat_end   =  52.00344324089038;  lon_end   = 4.371195848849639;

[e_start, n_start] = latlon_to_enu(lat_start, lon_start, ...
                                    env.origin_lat, env.origin_lon);
[e_end,   n_end  ] = latlon_to_enu(lat_end,   lon_end,   ...
                                    env.origin_lat, env.origin_lon);

%% ── Main straight-line path (start → end) ───────────────────────────────
e_line = e_start + t * (e_end - e_start);
n_line = n_start + t * (n_end - n_start);

%% ── Lateral wave (perpendicular to flight direction) ────────────────────
%   The wave oscillates in the East component, perpendicular to the
%   primarily-North track.
lateral_amp  = 45;      % m — half-width of the wave
num_cycles   = 3;       % full wave cycles along the route
lateral_wave = lateral_amp * sin(2*pi * num_cycles * t);

%% ── Altitude profile: 35–50 m AGL, gentle oscillation ──────────────────
alt_base = 42;          % m AGL
alt_amp  = 8;           % m amplitude
alt_wave = alt_base + alt_amp * sin(2*pi * 2.5 * t);   % 2.5 cycles

%% ── Assemble trajectory ──────────────────────────────────────────────────
e_path = e_line + lateral_wave;
n_path = n_line;

uav_true = [e_path; n_path; alt_wave];

end
