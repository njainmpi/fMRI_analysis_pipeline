# Temporal moving-average smoothing for fMRI (60s window, TR=1.0s).
# Usage: smooth_movavg_60s <input_4D_nii[.gz]> [output_nii.gz]
smooth_movavg_60s() {
  local IN="${1:-}"
  local OUT="${2:-}"

  if [[ -z "$IN" ]]; then
    echo "Usage: smooth_movavg_60s <input_4D_nii[.gz]> [output_nii.gz]" >&2
    return 1
  fi
  if ! command -v python3 >/dev/null 2>&1; then
    echo "Error: python3 not found in PATH." >&2
    return 2
  fi

  # Default output name if not provided: strip .nii.gz or .nii then add suffix
  if [[ -z "$OUT" ]]; then
    local fname="${IN##*/}"
    local base="$fname"
    if [[ "$fname" == *.nii.gz ]]; then
      base="${fname%.nii.gz}"
    elif [[ "$fname" == *.nii ]]; then
      base="${fname%.nii}"
    fi
    OUT="${base}_movavg_60s.nii.gz"
  fi

  python3 - <<'PY' "$IN" "$OUT"
import sys, numpy as np, nibabel as nib

inp, outp = sys.argv[1], sys.argv[2]

def moving_average_1d(x, win):
    k = np.ones(win, dtype=float) / win
    xpad = np.pad(x, (win//2, win-1-win//2), mode='edge')  # reduce edge shrinkage
    return np.convolve(xpad, k, mode='valid')

# Fixed params
TR = 1.0       # seconds
win_sec = 60.0
win = int(round(win_sec / TR))

img = nib.load(inp)
data = img.get_fdata()   # shape: X,Y,Z,T
T = data.shape[-1]

flat = data.reshape(-1, T)
sm = np.vstack([moving_average_1d(ts, win) for ts in flat]).reshape(data.shape)

nib.Nifti1Image(sm, img.affine, img.header).to_filename(outp)
print(f"Wrote: {outp}")
PY
}
