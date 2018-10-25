%% Microphone calibration
% Uses the method described in Siegel 2006 chapter in the OAE book.
% Also described in:
% Rasetshwane, D. M., & Neely, S. T. (2011). Calibration of otoacoustic
% emission probe microphones. The Journal of the Acoustical Society of
% America, 130(4), EL238-EL243.

clear;
close all hidden;

try
    % Initializing TDT
    % Specify path to cardAPI here
    pcard = genpath('C:\Experiments\cardAPI\');
    addpath(pcard);
    card = initializeCard_2Mics;
    
    Fs = card.Fs;
    
    calib = calibSetDefaults(card);
    
    
    % Make directory to save results if it doesn't already exist
    respDir = './MICCAL/';
    
    
    calib.reference = 'BK';
    calib.test = 'ER7C';
    driver = 1; % Which output on RZ6
    calib.driver = driver;
    
    % Make click
    vo = clickStimulus(calib.BufferSize);
    buffdata = zeros(2, numel(vo));
    buffdata(driver, :) = vo; % The other source plays nothing
    
    % Check for clipping and load to buffer
    if(any(abs(buffdata(driver, :)) > 1))
        error('What did you do!? Sound is clipping!! Cannot Continue!!\n');
    end
    
    
    %% Set attenuation and play
    if driver == 1
        dropA = calib.Attenuation;
        dropB = 120;
    else
        dropB = calib.Attenuation;
        dropA = 120;
    end
    
    uiwait(warndlg(...
        'Make sure the test mic (ER7C) is plugged into channel B and the reference mic (BK 1/4") into channel A!',...
        'ATTENTION!'));
    [vins1, vins2] = playCapture_2Mics(buffdata, card, calib.Averages,...
        calib.ThrowAway, dropA, dropB, 1);
    
    
    if calib.doFilt
        % High pass at 100 Hz using IIR filter
        [b, a] = butter(4, 100 * 2/Fs, 'high');
        vins1 = filtfilt(b, a, vins1')';
        vins2 = filtfilt(b, a, vins2')';
    end
    vins1 = demean(vins1, 2);
    vins2 = demean(vins2, 2);
    energy = squeeze(sum(vins1.^2, 2));
    good = energy < median(energy) + 2*mad(energy, 1);
    vavg1 = squeeze(mean(vins1(good, :), 1));
    Vavg1 = rfft(vavg1');
    calib.vavg1 = vavg1;
    
    energy = squeeze(sum(vins2.^2, 2));
    good = energy < median(energy) + 2*mad(energy, 1);
    vavg2 = squeeze(mean(vins2(good, :), 1));
    Vavg2 = rfft(vavg2');
    calib.vavg2 = vavg2;
    
    
    
    freq = 1000*linspace(0,calib.SamplingRate/2,length(Vavg1))';
    calib.freq = freq;
    calib.testH = Vavg2 ./ Vavg1; % Test relative to reference
    
    
    
    %% Plot data
    plotH(calib.freq, calib.testH);
    %% Save measurements
    datetag = datestr(clock);
    calib.date = datetag;
    datetag(strfind(datetag,' ')) = '_';
    datetag(strfind(datetag,':')) = '_';
    fname = strcat(respDir,'Calib_',calib.test,'_vs_', calib.reference,...
        datetag, '.mat');
    save(fname,'calib');
    
    %% Close ER-10X connection
    closeCard(card);
    rmpath(pcard);
catch me
    closeCard(card);
    rmpath(pcard);
    close all hidden;
    rethrow(me);
end
