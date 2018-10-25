function X=rfft(x)
% RFFT: scaled real FFT, X=rfft(x)
% Returns the positive-frequency half of the transform X=FFT(x).
% The transform X is normalized so that if {x} is a sine wave of
% unit amplitude and frequency (n-1)*df, then X[n]=1.
% Usage:    X=rfft(x)
% If x is N points long, NF=N/2+1 complex points are returned.
% N.B. rms(x) = sqrt(N)/2 rms([|X|,|X(2:end-1)|])
% See also IRFFT, FAST, FSST, FFT, IFFT

[m,n]=size(x);
if (m==1 || n==1)
    % original...
    N=length(x)/2+1;
    xc=fft(x);
    X=xc(1:fix(N));
else
    % do it column-wise...
    N=m/2+1;
    xc=fft(x);
    X=xc(1:fix(N),:);
end

X = X / (length(x)/2);
return
