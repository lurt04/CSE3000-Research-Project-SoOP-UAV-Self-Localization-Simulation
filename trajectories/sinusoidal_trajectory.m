function uav_true = sinusoidal_trajectory(cfg, env)

t = 1:cfg.T;

uav_true = zeros(3,cfg.T);

uav_true(1,:) = linspace(env.area_size / 20, (env.area_size - (env.area_size / 20)), cfg.T);

uav_true(2,:) = (env.area_size / 2) + (1/4 * env.area_size) *sin(2*pi*t/cfg.T);

uav_true(3,:) = env.area_size / 10 + ((1/4 * env.area_size)/10) *sin(4*pi*t/cfg.T);

end