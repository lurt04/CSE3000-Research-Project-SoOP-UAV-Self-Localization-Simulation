function z = measFcn_fused(x, tx, cfg, env, ref_idx)
z_tdoa = measFcn_tdoa(x, tx, cfg.c, ref_idx);
z_rssi = measFcn_rssi(x, tx, env);
z = [z_tdoa; z_rssi];
end