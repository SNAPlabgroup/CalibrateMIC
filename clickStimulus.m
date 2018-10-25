function y = clickStimulus(N)
% function y = clickStimulus (N)
% Generates a 1 sample click with a total buffer duration of N samples
nsampsclick = 1; %WBMEMRipsi uses 5 sample clicks
initbuff =  2;
y = zeros(1, N);
y(initbuff + (1:nsampsclick)) = 0.95;
y = y(:); % Just in case