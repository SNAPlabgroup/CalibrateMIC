%% Play chirp and use calibration to verify FPL
[FileName,PathName,FilterIndex] = uigetfile(strcat('Calib_Ph*', date, '*.mat'),...
    'Please pick DRIVE PROBE CALIBRATION file to use');
probefile = fullfile(PathName, FileName);
load(probefile);

% Initializing TDT
fig_num=99;
GB_ch=1;
FS_tag = 3;


[f1RZ,RZ,~]=load_play_circuit(FS_tag,fig_num,GB_ch);
Fs = calib.SamplingRate * 1000;
driver = calib.driver;

%% Generate chirp and filter using calib.Pfor

vo_unfilt = chirpStimulus(16384, 0.9);
calib.BufferSize = numel(vo_unfilt);
Nf = 2047;
delay = 1024;
pad = zeros(delay, 1);
invPfor = mean(abs(calib.Pfor))./abs(calib.Pfor);
freqNyq = calib.freq * 2e-3 / calib.SamplingRate;
invPfor(freqNyq < 250 * 2e-3/calib.SamplingRate) = ...
    invPfor(find(freqNyq < 250 * 2e-3/calib.SamplingRate, 1, 'last'));
invPfor(freqNyq > 20e3 * 2e-3/calib.SamplingRate) = ...
    invPfor(find(freqNyq > 20e3 * 2e-3/calib.SamplingRate, 1, 'first'));
b = fir2(Nf, freqNyq, invPfor);

plotFilter = 1;
if plotFilter
    figure;
    semilogx(calib.freq / 1000, db(mean(abs(calib.Pfor))./abs(calib.Pfor))); %#ok<UNRCH>
    hold on;
    [H,f] = freqz(b, 1, numel(calib.Pfor));
    semilogx(f * calib.SamplingRate / (2 * pi), db(abs(H)));
end
vo = filter(b, 1, [vo_unfilt; pad]);
vo = scaleSound(vo((delay+1):end));

%% Load compensated chirp
%vo = vo_unfilt;
buffdata = zeros(2, numel(vo));
buffdata(driver, :) = vo; % The other source plays nothing

% Check for clipping and load to buffer
if(any(abs(buffdata(driver, :)) > 1))
    error('What did you do!? Sound is clipping!! Cannot Continue!!\n');
end
%Load the 2ch variable data into the RZ6:
playrecTrigger = 1;
RZ6ADdelay = 97; % Samples
resplength = numel(vo) + RZ6ADdelay; % How many samples to read from OAE buffer

invoke(RZ, 'SetTagVal', 'nsamps', resplength);
invoke(RZ, 'WriteTagVEX', 'datainL', 0, 'F32', buffdata(1, :));
invoke(RZ, 'WriteTagVEX', 'datainR', 0, 'F32', buffdata(2, :));

%% Set attenuation and play
%calib.vo = vo;
calib.vinsA = zeros(calib.Averages, calib.BufferSize);
calib.vinsB = zeros(calib.Averages, calib.BufferSize);
drop = calib.Attenuation; %dB
invoke(RZ, 'SetTagVal', 'attA', drop);
invoke(RZ, 'SetTagVal', 'attB', drop);


for n = 1: (calib.Averages + calib.ThrowAway)
    %Start playing from the buffer:
    invoke(RZ, 'SoftTrg', playrecTrigger);
    currindex = invoke(RZ, 'GetTagVal', 'indexin');
    while(currindex < resplength)
        currindex=invoke(RZ, 'GetTagVal', 'indexin');
    end
    
    vinA = invoke(RZ, 'ReadTagVex', 'dataoutA', 0, resplength,...
        'F32','F64',1);
    vinB = invoke(RZ, 'ReadTagVex', 'dataoutB', 0, resplength,...
        'F32','F64',1);
    %Accumluate the time waveform - no artifact rejection
    if (n > calib.ThrowAway)
        calib.vinsA(n-calib.ThrowAway, :) = vinA((RZ6ADdelay + 1):end);
        calib.vinsB(n-calib.ThrowAway, :) = vinB((RZ6ADdelay + 1):end);
    end
    
    % Get ready for next trial
    invoke(RZ, 'SoftTrg', 8); % Reste OAE index

    fprintf(1, 'Done with # %d / %d trials \n', n, (calib.Averages + calib.ThrowAway));
end



%% Compute the average and convert to right units
energy = squeeze(sum(calib.vinsA.^2, 2));
good = energy < median(energy) + 2*mad(energy);
vavgA = mean(calib.vinsA(good, :), 1);
VavgA = rfft(vavgA);
energy = squeeze(sum(calib.vinsB.^2, 2));
good = energy < median(energy) + 2*mad(energy);
vavgB = mean(calib.vinsB(good, :), 1);
VavgB = rfft(vavgB);


% Note: Nexus setting is 316 mV/Pa, mic sensitivity on Nexus = 1.131 mV/Pa
mic_sens_B = 0.316;
mic_sens_A = 0.05 * db2mag(36);
mic_gain = 1;

P_ref = 20e-6;

DR_onesided = 1;

mic_output_V_A = VavgA / (DR_onesided * mic_gain);
mic_output_V_B = VavgB / (DR_onesided * mic_gain);

output_Pa_A = mic_output_V_A/mic_sens_A;
output_Pa_B = mic_output_V_B/mic_sens_B;
freq = 1000*linspace(0,calib.SamplingRate/2,length(VavgA))';
calib.freq = freq;
Pavg = output_Pa_A / P_ref; % peak in 20 uPa units
calib.EarCanalH =  Pavg;
calib.EarDrumH =  output_Pa_B / P_ref;

close_play_circuit(f1RZ, RZ);
%% Plot data
lim = [250, 24000];
figure(1);
hold on;
ax(1) = subplot(2, 1, 1);
semilogx(calib.freq, db(abs(calib.EarCanalH)), 'linew', 2);
ylabel('Response magnitude (dB SPL)', 'FontSize', 16);
ax(2) = subplot(2, 1, 2);
semilogx(calib.freq, unwrap(angle(calib.EarCanalH)), 'linew', 2);
ylabel('Response phase (rad)', 'FontSize', 16);
xlabel('Frequency (Hz)', 'FontSize', 16);
linkaxes(ax, 'x');
xlim(lim);


ax(1) = subplot(2, 1, 1);
hold on;
semilogx(calib.freq, db(abs(calib.EarDrumH)), 'r', 'linew', 2);
ylabel('Probetube Response magnitude (dB SPL)', 'FontSize', 16);
ax(2) = subplot(2, 1, 2);
hold on;
semilogx(calib.freq, unwrap(angle(calib.EarDrumH)), 'r', 'linew', 2);
ylabel('Response phase (rad)', 'FontSize', 16);
xlabel('Frequency (Hz)', 'FontSize', 16);
linkaxes(ax, 'x');
xlim(lim);

