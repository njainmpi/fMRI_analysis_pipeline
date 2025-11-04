#!/usr/bin/env python3
"""
make_block_average_nifti.py
----------------------------------------
Compute a baseline-aligned averaged block from an fMRI time series.

Each block is assumed to have:
    - n_on volumes (stimulation)
    - n_off volumes (post-stimulation / rest)
and there are n_blocks such repeated cycles.

You can freely define which volumes inside each block are considered
as "baseline" using --baseline_start and --baseline_end (1-based indices).

Final order in the averaged output NIfTI:
    [ baseline(baseline_start–baseline_end) | ON(1–n_on) | OFF(n_on+1–n_on+n_off) ]

Example:
    python make_block_average_nifti.py func.nii.gz mean_block_baselineONOFF.nii.gz \
        --n_on 10 --n_off 10 --n_blocks 7 --n_initial_rest 10 --n_discard 3 \
        --baseline_start 14 --baseline_end 20
"""

import numpy as np
import nibabel as nib
import argparse
import os

def main():
    # ----------- ARGUMENT PARSER -----------
    parser = argparse.ArgumentParser(
        description="Compute baseline-aligned averaged fMRI block."
    )
    parser.add_argument("input", help="Path to input 4D fMRI NIfTI (.nii/.nii.gz)")
    parser.add_argument("output", help="Path to save the averaged NIfTI")

    parser.add_argument("--n_on", type=int, default=10, help="Volumes during stimulation (default=10)")
    parser.add_argument("--n_off", type=int, default=10, help="Volumes after stimulation (default=10)")
    parser.add_argument("--n_blocks", type=int, default=7, help="Number of repeated ON/OFF blocks (default=7)")
    parser.add_argument("--n_initial_rest", type=int, default=10, help="Initial rest volumes before first block (default=10)")
    parser.add_argument("--n_discard", type=int, default=3, help="Volumes discarded from initial rest (default=3)")
    parser.add_argument("--baseline_start", type=int, required=True, help="Start volume of baseline (1-based index)")
    parser.add_argument("--baseline_end", type=int, required=True, help="End volume of baseline (1-based index)")

    args = parser.parse_args()

    # ----------- LOAD DATA -----------
    if not os.path.exists(args.input):
        raise FileNotFoundError(f"Input file not found: {args.input}")

    print(f"📂 Loading {args.input} ...")
    img = nib.load(args.input)
    data = img.get_fdata()
    X, Y, Z, T = data.shape
    print(f"Input shape: {data.shape}")

    block_len = args.n_on + args.n_off
    start_idx = args.n_initial_rest
    usable = data[..., start_idx : start_idx + args.n_blocks * block_len]
    print(f"Using volumes {start_idx+1}–{start_idx + args.n_blocks*block_len} for blocks")

    # ----------- RESHAPE INTO BLOCKS -----------
    vox = X * Y * Z
    blocks = usable.reshape(vox, args.n_blocks, block_len)

    # ----------- AVERAGE ACROSS BLOCKS -----------
    mean_block = blocks.mean(axis=1)  # shape = (vox, block_len)

    # ----------- REORDER BASED ON BASELINE -----------
    baseline_idx = np.arange(args.baseline_start - 1, args.baseline_end)
    on_idx = np.arange(0, args.n_on)
    off_idx = np.arange(args.n_on, args.n_on + args.n_off)

    order = np.concatenate([baseline_idx, on_idx, off_idx])
    reordered_block = mean_block[:, order]

    final_data = reordered_block.reshape(X, Y, Z, len(order))

    # ----------- SAVE NEW NIFTI -----------
    out_img = nib.Nifti1Image(final_data, affine=img.affine, header=img.header)
    nib.save(out_img, args.output)
    print(f"✅ Saved {args.output} with shape {final_data.shape}")
    print(f"   Baseline: {args.baseline_start}-{args.baseline_end}")
    print(f"   Order: baseline({len(baseline_idx)}) + ON({args.n_on}) + OFF({args.n_off}) = {len(order)} total volumes")

if __name__ == "__main__":
    main()
