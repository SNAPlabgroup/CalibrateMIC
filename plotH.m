function plotH(f, H)
%% Plot data
figure(1);
ax(1) = subplot(2, 1, 1);
hold on;
plot(f, db(abs(H)), 'linew', 2);
set(gca, 'xscale', 'log');
ylabel({'Transfer Function', '(dB re: reference)'}, 'FontSize', 14);
ax(2) = subplot(2, 1, 2);
hold on;
plot(f, unwrap(angle(H)), 'linew', 2);
xlabel('Frequency (Hz)', 'FontSize', 14);
ylabel('Phase (rad)', 'FontSize', 14);
set(gca, 'xscale', 'log');
linkaxes(ax, 'x');
xlim([100, 20e3]);