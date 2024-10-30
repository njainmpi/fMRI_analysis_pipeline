import nibabel as nib
import numpy as np
from scipy.signal import welch, detrend
import matplotlib.pyplot as plt

# Load the .nii.gz file
fmri_img = nib.load('G1_cp.nii.gz')
fmri_data = fmri_img.get_fdata()

# Check data shape
print("fMRI data shape:", fmri_data.shape)
# Expected shape should be (x, y, z, t), where t=1800 (repetitions)

# Define the repetition time (TR) in seconds, typically known from acquisition details.
TR = 1.0  # Example TR; replace with actual TR if known
n_reps = fmri_data.shape[-1]

# Step 2: Extract the mean time series from all voxels
mean_time_series = fmri_data.mean(axis=(0, 1, 2))

# Step 3: Detrend and filter the time series (optional)
mean_time_series_detrended = detrend(mean_time_series)

# Step 4: Apply Fourier Transform or Welch's method for frequency analysis
# FFT
frequency_spectrum = np.fft.fft(mean_time_series_detrended)
frequencies = np.fft.fftfreq(n_reps, d=TR)

# Only take positive frequencies for visualization
pos_freq_idx = frequencies > 0
frequencies = frequencies[pos_freq_idx]
frequency_spectrum = np.abs(frequency_spectrum[pos_freq_idx])

# Step 5: Using Welch’s method as an alternative for PSD
freqs_welch, psd_welch = welch(mean_time_series_detrended, fs=1/TR)

# Plotting the results
plt.figure(figsize=(12, 6))

# Plot FFT result
plt.subplot(1, 2, 1)
plt.plot(frequencies, frequency_spectrum)
plt.title("Frequency Spectrum using FFT")
plt.xlabel("Frequency (Hz)")
plt.ylabel("Amplitude")

# Plot PSD using Welch's method
plt.subplot(1, 2, 2)
plt.plot(freqs_welch, psd_welch)
plt.title("Power Spectral Density using Welch's Method")
plt.xlabel("Frequency (Hz)")
plt.ylabel("Power")

# Save the figure
plt.tight_layout()
plt.savefig("frequency_spectrum_analysis.png", dpi=300)  # Save as PNG with 300 dpi
plt.show()
