function z = measFcn_rssi(x, tx, env)
% MEASFCN_RSSI  Expected RSSI measurements for the EKF correction step.
%
%   Open field:  uses fspl() - identical model to the measurement generator,
%                so the EKF has a consistent prediction.
%   Urban:       uses a log-distance model with calibrated parameters
%                (env.rssi_PL0_dBm, env.rssi_n).  The actual measurements
%                come from the SBR ray tracer; the mismatch is absorbed by
%                the enlarged measurement noise covariance R.
%
%   The EKF never calls ray tracing — it needs a fast, differentiable
%   closed-form prediction that MATLAB can auto-differentiate for the Jacobian.

pos = x(1:3)';
d   = vecnorm(tx - pos, 2, 2);   % N_tx × 1  (m)
d   = max(d, 10);

if isfield(env, 'rssi_PL0_dBm') && isfield(env, 'rssi_n')
    %% Urban: log-distance model
    PL = env.rssi_PL0_dBm + 10 * env.rssi_n * log10(d);

    % small curvature correction 
    PL = PL + 15 ./ d + 0.5 ./ sqrt(d);
    
    z = env.rssi_P_tx_dBm - PL;
else
    %% Open field: free-space path loss (Antenna Toolbox)
    lambda = physconst('LightSpeed') / env.rf_frequency_hz;
    z = env.rssi_P_tx_dBm - fspl(d, lambda);
end

end
