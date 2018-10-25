function h = flatFPLfilter(calib, card2volts, nfilt)
% Function to generate a filter to provide a flat FPL in the ear
% that was just calibrated. If phase doesn't matter for you, you can apply
% this with filtfilt. This has an additional delay of nfilt/2 samples.
%
% INPUTS:
%   calib - The structure from ear calibration
%   card2volts - The scaling between MATLAB values and D/A voltage
%   nfilt - filter length
%
% RETURNS:
%   h - filter which will yield a 1 Pa RMS FPL for matlab RMS 1 white noise
%       (the filter itself will give a 1 Pa pe-FPL click)
% Important Note:
%   (1) If you only care about flatness in a certain frequency range,
%   make Pfor = 1 for all other frequencies before using this function.
%   (2) The probe mic calibration, including phase is important for this
%   to work well for transient sounds

if ~exist('card2volts', 'var')
    card2volts = 5.0;
end

if ~exist('nfilt', 'var')
    nfilt = 256;
end


% In general, this is more stable
A = 1./calib.Pfor;
f = calib.freq *2 / (calib.SamplingRate*1000);
win = dpss(nfilt + 1, 1, 1);
win = win/max(win);
h = fir2(nfilt, f, A, win) / card2volts;


