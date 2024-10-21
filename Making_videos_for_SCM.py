import os
import sys
import nibabel as nib
import numpy as np
import matplotlib.pyplot as plt
import subprocess

# Step 1: Define paths

mean_image_path = sys.argv[1]
processed_image_path = sys.argv[2]
slice_number = int(sys.argv[3])
output_dir = "overlay_screenshots"
movie_output = "Signal_Change_Map.mp4"


# Step 2: Create output directory for screenshots
os.makedirs(output_dir, exist_ok=True)

# Step 3: Load the mean image and processed image
mean_img = nib.load(mean_image_path)
processed_img = nib.load(processed_image_path)

# Checking orientations of the "to be processed" NIFTI files
affine_mean = mean_img.affine
orientation_mean = nib.orientations.aff2axcodes(affine_mean)
print('Orientations of the mean image:', orientation_mean)

affine_processed_img = processed_img.affine
orientation = nib.orientations.aff2axcodes(affine_processed_img)
print('Orientations of the processed image:', orientation)

mean_data = mean_img.get_fdata()  # 3D mean image
processed_data = processed_img.get_fdata()  # 4D processed image

# Ensure the dimensions match (except for the time/volume dimension)
if mean_data.shape != processed_data.shape[:3]:
    raise ValueError("The dimensions of the mean image and processed image do not match!")

# Get the number of volumes in the processed image
num_volumes = processed_data.shape[3]

# Step 4: Scroll through each volume and overlay on the mean image
for vol_idx in range(num_volumes):
    # Extract the current volume of the processed image
    processed_volume = processed_data[..., vol_idx]

    # Overlay: Plot the mean image and processed volume in the same plot
    fig, ax = plt.subplots(figsize=(6, 6))

    # Set slice to 11 for both the mean and processed image
    slice_idx = slice_number  # Fixed slice 11

    # Flip the slices left-right (flip along the horizontal axis, axis 1)
    mean_slice = np.flip(mean_data[..., slice_idx], axis=1)
    processed_slice = np.flip(processed_volume[..., slice_idx], axis=1)

    # Plot the mean image (underlay) with slice 11
    ax.imshow(mean_slice, cmap="gray", vmin=np.min(mean_data), vmax=np.max(mean_data))

    # Plot the combined slice using "coolwarm" colormap to represent both negative and positive values
    im_combined = ax.imshow(processed_slice, cmap="coolwarm", alpha=0.2, vmin=-7, vmax=7)

    # Add a single vertical colorbar representing both positive and negative values
    cbar_combined = fig.colorbar(im_combined, ax=ax, orientation='vertical', fraction=0.046, pad=0.04)
    cbar_combined.set_label('Percent Signal Change', rotation=270, labelpad=15)  # Rotate the label for a vertical bar


    # cbar_neg = fig.colorbar(im_neg, ax=ax, fraction=0.046, pad=0.04)
    # cbar_neg.set_label('Negative Changes', rotation=0, labelpad=15)

    # Set the title
    # ax.set_title(f"Overlay of Mean and Processed Image - Volume {vol_idx} (Slice 7)")
    # ax.axis('off')  # Hide axes for a cleaner look

    # Save the screenshot
    screenshot_path = os.path.join(output_dir, f"frame_{vol_idx}.png")
    plt.savefig(screenshot_path, bbox_inches='tight', pad_inches=0)
    plt.close()

    print(f"Captured overlay for volume {vol_idx}")

# Step 5: Use ffmpeg to combine the frames into an MP4 movie, resizing to make dimensions divisible by 2 and rotating by 90 degrees anti-clockwise
subprocess.run([
    "ffmpeg", "-framerate", "4", "-i", f"{output_dir}/frame_%d.png",
    "-vf", "scale=trunc(iw/2)*2:trunc(ih/2)*2,transpose=2",  # Rotate 90 degrees anti-clockwise using transpose=2
    "-c:v", "libx264", "-pix_fmt", "yuv420p", movie_output 
   
])

print(f"Movie created and saved as {movie_output}")


# Optionally, clean up frame images
# for filename in os.listdir(output_dir):
#     os.remove(os.path.join(output_dir, filename))
