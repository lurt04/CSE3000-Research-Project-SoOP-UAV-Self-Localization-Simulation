function x_next = stateFcn(cfg, x)

dt = cfg.dt;

F = [1 0 0 dt 0  0;
    0 1 0 0  dt 0;
    0 0 1 0  0  dt;
    0 0 0 1  0  0;
    0 0 0 0  1  0;
    0 0 0 0  0  1];

x_next = F * x;

end