for ii = 1:size (raw_signal, 2)
    base (1, ii) = mean(raw_signal (1:600,ii))
    PSC_voxel  (:, ii) = ((raw_signal (:, ii) - base (1, ii))./base (1, ii))*100;
 
end

base_combined = mean(raw_signal_combined (1:600, 1));
PSC_voxel_combined = ((raw_signal_combined (:, 1) - base_combined)./base_combined)*100;

max_size = size (raw_signal, 1)

figure
plot(PSC_voxel,'DisplayName','PSC_voxel', 'LineStyle','-')
hold on
plot(PSC_voxel_combined, 'linewidth', 4,'Color', 'black' )
set(gca, 'FontSize', 40, 'FontWeight', 'bold');
set(gcf, 'color', 'w');
xlabel('Time (in sec)');
ylabel('PSC');
xlim ([0, max_size])


for ii = 1: size (PSC_voxel, 2)
mean_PSC_Val (1, ii)= prctile (PSC_voxel (200:400, ii), 95);
mean_PSC_Val (2, ii)= prctile (PSC_voxel (700:1700, ii), 95);
% mean_PSC_Val (3, ii)= prctile (PSC_voxel (3700:4800, ii), 95);
end

figure

bar(mean_PSC_Val,'DisplayName','mean_PSC_Val')
mean_PSC_Val =mean_PSC_Val';
bar(mean_PSC_Val,'DisplayName','mean_PSC_Val')

