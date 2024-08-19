#!/bin/sh


#19 August 2024: $$Naman Jain$$ This function is created videos of the activation maps/ signal change maps




VIDEO_SCM () {

    for i in $(seq -f "%04g" 0 41); do
        slicer frame${i}.nii.gz -a frame${i}.png
    done

    ffmpeg -framerate 10 -i frame%04d.png -c:v libx264 -r 30 -pix_fmt yuv420p output_video.mp4

}