#!/bin/sh


#19 August 2024: $$Naman Jain$$ This function is created videos of the activation maps/ signal change maps


VIDEO_SCM () {

   #!/bin/bash

# Configuration
IMAGE_FILE="signal_change_map_threshholded.nii.gz"
UNDERLAY_FILE="mean_mc_stc_func.nii"
OUTPUT_FOLDER="frames"
VIDEO_OUTPUT="output_video_test.mp4"
TEMP_SCRIPT="generate_frames.py"

# Check if required commands are available
if ! command -v ffmpeg &> /dev/null
then
    echo "FFmpeg is not installed. Please install it using Homebrew."
    exit 1
fi

if ! command -v python3 &> /dev/null
then
    echo "Python3 is not installed. Please install it."
    exit 1
fi

# Check if the input files exist
if [ ! -f "$IMAGE_FILE" ]; then
    echo "Image file $IMAGE_FILE not found!"
    exit 1
fi

if [ ! -f "$UNDERLAY_FILE" ]; then
    echo "Underlay file $UNDERLAY_FILE not found!"
    exit 1
fi

# Create output directory for frames
mkdir -p "$OUTPUT_FOLDER"

# Create Python script for frame extraction
cat << EOF > $TEMP_SCRIPT
import os
import nibabel as nib
from nilearn import plotting

# File paths
image_file = '$IMAGE_FILE'
underlay_file = '$UNDERLAY_FILE'
output_folder = '$OUTPUT_FOLDER'

# Load NIfTI images
try:
    img = nib.load(image_file)
    underlay_img = nib.load(underlay_file)
except Exception as e:
    print(f"Error loading NIfTI files: {e}")
    exit(1)

num_volumes = img.shape[-1]

# Generate frames
for i in range(num_volumes):
    try:
        display = plotting.plot_img(img.slicer[..., i], 
                                    bg_img=underlay_img,
                                    cmap='hot',  # Use a color map for scaling
                                    display_mode='ortho',
                                    cut_coords=(0, 0, 0),
                                    title=f'Frame {i}')
        frame_filename = os.path.join(output_folder, f'frame_{i:04d}.png')
        display.savefig(frame_filename)
        display.close()
    except Exception as e:
        print(f"Error generating frame {i}: {e}")

print("Frames have been saved.")
EOF

# Run the Python script to generate frames
python3 $TEMP_SCRIPT

# Check if frames were created
if [ -z "$(ls -A $OUTPUT_FOLDER)" ]; then
    echo "No frames were generated. Check the Python script for errors."
    exit 1
fi

# Create video from frames using FFmpeg
ffmpeg -framerate 24 -i "$OUTPUT_FOLDER/frame_%04d.png" -vf "scale=1280:720" -c:v libx264 -pix_fmt yuv420p "$VIDEO_OUTPUT"

# Clean up frame images
# rm -rf "$OUTPUT_FOLDER"

echo "Video created: $VIDEO_OUTPUT"

}