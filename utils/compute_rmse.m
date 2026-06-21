function [rmse3d, rmse2d, rmse1d_z] = compute_rmse(uav_est, uav_true)
% COMPUTE_RMSE  Compute 3-D, 2-D (horizontal), and vertical RMSE.


err3d    = vecnorm(uav_est - uav_true, 2, 1);               % Euclidean 3-D error
err2d    = vecnorm(uav_est(1:2,:) - uav_true(1:2,:), 2, 1); % Horizontal error
err1d_z  = abs(uav_est(3,:) - uav_true(3,:));               % Vertical error

rmse3d   = sqrt(mean(err3d.^2));
rmse2d   = sqrt(mean(err2d.^2));
rmse1d_z = sqrt(mean(err1d_z.^2));

end
