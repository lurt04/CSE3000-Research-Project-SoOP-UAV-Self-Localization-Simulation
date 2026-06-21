function constrained = constrain_ekf_state(ekf, env)
% CONSTRAIN_EKF_STATE  Project an EKF state into environment bounds.
%
%   The EKF itself is unconstrained. Urban simulations have a finite OSM
%   map and a plausible flight altitude range, so correction steps are
%   projected back into that volume. If a position component is clipped,
%   the corresponding velocity is reset to avoid repeated boundary escapes.

constrained = false;

if ~isfield(env, 'bounds_enu') || isempty(env.bounds_enu)
    return;
end

state = ekf.State;
bounds = env.bounds_enu;

for dim = 1:3
    before = state(dim);
    state(dim) = min(max(state(dim), bounds(dim, 1)), bounds(dim, 2));

    if state(dim) ~= before
        state(dim + 3) = 0;
        constrained = true;
    end
end

ekf.State = state;

end