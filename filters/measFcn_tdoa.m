function z = measFcn_tdoa(x, tx, c, ref_idx)
% Output is ALWAYS length N_tx-1 (one entry per non-reference TX, in
% ascending index order). Which physical TX is "the reference" can change
% step to step; the vector LENGTH never does -- this is what keeps the
% extendedKalmanFilter object's measurement dimension constant.

if nargin < 4 || isempty(ref_idx)
    ref_idx = 1;   % backward-compatible default
end

N = size(tx,1);
other_idx = setdiff(1:N, ref_idx);

pos = x(1:3)';
d   = vecnorm(tx - pos, 2, 2);

z = (d(other_idx) - d(ref_idx)) / c;
end