function plot_results(results)
% PLOT_RESULTS  Compare RMSE distributions across all three EKF variants.
%
%   Figure 1 — RMSE by filter (histogram + box plot)
%   Figure 2 — 3-D vs 2-D vs vertical RMSE breakdown
%               This reveals whether height determination is the dominant
%               source of localization error.

colors = struct( ...
    'tdoa',  [0.50 0.50 0.50], ...
    'rssi',  [0.93 0.69 0.13], ...
    'fused', [0.47 0.67 0.19]);

%% -----------------------------------------------------------------------
%% Figure 1: filter comparison (3-D RMSE only — same as before)
%% -----------------------------------------------------------------------
figure('Name','Filter Comparison - 3-D RMSE','Position',[100 100 900 400]);

subplot(1,2,1);
hold on;
histogram(results.rmse3d_tdoa,  'FaceColor', colors.tdoa,  'FaceAlpha', 0.6, 'EdgeColor', 'none');
histogram(results.rmse3d_rssi,  'FaceColor', colors.rssi,  'FaceAlpha', 0.6, 'EdgeColor', 'none');
histogram(results.rmse3d_fused, 'FaceColor', colors.fused, 'FaceAlpha', 0.6, 'EdgeColor', 'none');
xlabel('3-D RMSE (m)');
ylabel('Count');
title('3-D Localization Error Distribution');
legend('TDoA','RSSI','Fused','Location','best');
grid on;

subplot(1,2,2);
data3d  = [results.rmse3d_tdoa, results.rmse3d_rssi, results.rmse3d_fused];
labels  = {'TDoA','RSSI','Fused'};
boxplot(data3d, labels, 'Colors', [colors.tdoa; colors.rssi; colors.fused]);
ylabel('3-D RMSE (m)');
title('3-D RMSE Box Plot');
grid on;

%% -----------------------------------------------------------------------
%% Figure 2: 3-D vs 2-D vs vertical breakdown (per filter)
%% -----------------------------------------------------------------------
figure('Name','RMSE Breakdown — 3D / 2D / Vertical','Position',[100 560 1200 500]);

filter_names = {'TDoA', 'RSSI', 'Fused'};
rmse3d_mean  = [mean(results.rmse3d_tdoa),  mean(results.rmse3d_rssi),  mean(results.rmse3d_fused)];
rmse2d_mean  = [mean(results.rmse2d_tdoa),  mean(results.rmse2d_rssi),  mean(results.rmse2d_fused)];
rmsez_mean   = [mean(results.rmsez_tdoa),   mean(results.rmsez_rssi),   mean(results.rmsez_fused)];

rmse3d_std   = [std(results.rmse3d_tdoa),   std(results.rmse3d_rssi),   std(results.rmse3d_fused)];
rmse2d_std   = [std(results.rmse2d_tdoa),   std(results.rmse2d_rssi),   std(results.rmse2d_fused)];
rmsez_std    = [std(results.rmsez_tdoa),    std(results.rmsez_rssi),    std(results.rmsez_fused)];

subplot(1,3,1);
bar_grouped(filter_names, rmse3d_mean, rmse2d_mean, rmsez_mean, ...
            rmse3d_std,   rmse2d_std,  rmsez_std, '3-D RMSE (m)', ...
            '3-D vs 2-D vs Z RMSE per Filter');

subplot(1,3,2);
% Ratio: vertical / horizontal - >1 means height is worse than XY
ratio_tdoa  = results.rmsez_tdoa  ./ results.rmse2d_tdoa;
ratio_rssi  = results.rmsez_rssi  ./ results.rmse2d_rssi;
ratio_fused = results.rmsez_fused ./ results.rmse2d_fused;
data_ratio  = [ratio_tdoa, ratio_rssi, ratio_fused];
boxplot(data_ratio, filter_names);
yline(1, '--k', 'Z = XY', 'LabelHorizontalAlignment','right');
ylabel('Z-RMSE / 2D-RMSE');
title('Vertical vs Horizontal Error Ratio');
grid on;

subplot(1,3,3);
% Cumulative distribution of 2D RMSE across runs
hold on;
plot_ecdf(results.rmse2d_tdoa,  colors.tdoa,  'TDoA 2-D');
plot_ecdf(results.rmse2d_rssi,  colors.rssi,  'RSSI 2-D');
plot_ecdf(results.rmse2d_fused, colors.fused, 'Fused 2-D');
xlabel('2-D RMSE (m)');
ylabel('CDF');
title('CDF of 2-D Horizontal RMSE');
legend('Location','southeast');
grid on;

end


%% -----------------------------------------------------------------------
%% Local helper: grouped bar chart with error bars
%% -----------------------------------------------------------------------
function bar_grouped(names, v3d, v2d, vz, e3d, e2d, ez, ylbl, ttl)

x  = 1:numel(names);
bw = 0.25;

b1 = bar(x - bw, v3d, bw, 'FaceColor', [0.2 0.4 0.8]); hold on;
b2 = bar(x,      v2d, bw, 'FaceColor', [0.2 0.7 0.4]);
b3 = bar(x + bw, vz,  bw, 'FaceColor', [0.9 0.4 0.2]);

errorbar(x - bw, v3d, e3d, '.k', 'LineWidth', 1.2);
errorbar(x,      v2d, e2d, '.k', 'LineWidth', 1.2);
errorbar(x + bw, vz,  ez,  '.k', 'LineWidth', 1.2);

set(gca, 'XTick', x, 'XTickLabel', names);
ylabel(ylbl);
title(ttl);
legend([b1 b2 b3], {'3-D','2-D (XY)','Z (height)'}, 'Location','best');
grid on;

end


%% -----------------------------------------------------------------------
%% Local helper: empirical CDF line
%% -----------------------------------------------------------------------
function plot_ecdf(data, col, lbl)
sorted = sort(data);
n      = numel(sorted);
p      = (1:n) / n;
plot(sorted, p, 'Color', col, 'LineWidth', 2, 'DisplayName', lbl);
end
