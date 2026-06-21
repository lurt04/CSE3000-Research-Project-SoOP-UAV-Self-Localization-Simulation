function fig = plot_environment(env, uav_true)
% PLOT_ENVIRONMENT  Plot the UAV true trajectory and transmitter positions.
%
%   Works for both open-field (Cartesian ENU) and urban (ENU from lat/lon).

fig = figure('Name','Trajectory','Position',[100 100 900 700]);

hold on;
grid on;
axis equal;
axis vis3d;

plot3(uav_true(1,:), uav_true(2,:), uav_true(3,:), ...
    'Color',     [0 0.45 0.74], ...
    'LineWidth', 2, ...
    'DisplayName', 'True trajectory');

plot3(env.tx(:,1), env.tx(:,2), env.tx(:,3), ...
    '^', ...
    'MarkerSize',      12, ...
    'MarkerFaceColor', [0.85 0.33 0.10], ...
    'MarkerEdgeColor', 'k', ...
    'LineStyle',       'none', ...
    'DisplayName',     'Transmitters');

for i = 1:size(env.tx, 1)
    text(env.tx(i,1) + 15, env.tx(i,2) + 15, env.tx(i,3), ...
        sprintf('TX%d', i), 'FontSize', 10);
end

xlabel('East (m)');
ylabel('North (m)');
zlabel('Altitude (m)');
title(sprintf('UAV Trajectory - %s', upper(env.type)));
legend('Location', 'best');
view(45, 30);
rotate3d on;

end
