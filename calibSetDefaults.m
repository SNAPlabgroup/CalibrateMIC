function calib = calibSetDefaults(card)

%set default parameters 

calib.Attenuation = 12;
% pick whatever has good SNR but it does not distort
calib.Vref  = 1; 
calib.BufferSize = 2048;
calib.SamplingRate = card.Fs * 1e-3; %kHz
calib.Averages = 16384;
calib.ThrowAway = 32;
calib.doFilt = 0;
calib.RZ6ADdelay = card.ADdelay; % Samples


