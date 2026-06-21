function cfg = default_config()
% DEFAULT_CONFIG  Simulation-wide parameters shared across all environments.
%
%   Environment-specific parameters (transmitter layout, power, path-loss
%   exponent, RSSI noise, timing noise) live in the individual environment
%   files and are applied as overrides in main.m.

%% Physical constants
cfg.c = physconst('LightSpeed');    % m/s  (exact CODATA value)

%% Simulation timing (overridden per environment in main.m)
cfg.T  = 200;   % Number of time steps
cfg.dt = 1;     % Time step (s)

%% Monte Carlo (1 = single run; urban environments override to 1)
cfg.MC_runs = 50;

%% TDoA timing noise — open-field default
%   sigma_d = c * noise_std ≈ 3 m equivalent range noise at 10 ns.
%   Urban environments override this via env.noise_std (larger, NLOS spread).
cfg.noise_std = 10e-9;   % s

end
