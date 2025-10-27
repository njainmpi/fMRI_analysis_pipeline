# Temporal moving-average smoothing for fMRI (default: 60s window, TR=1.0s).
# Usage:
#   smooth_movavg <input_4D_nii[.gz]> [output_nii.gz] [win_sec]
#   smooth_movavg <input> [output] --win-sec 45 --tr 0.8
smooth_movavg() {
  local IN="" OUT="" WIN_SEC="" TR="1.0"

  # --- Parse args ---
  if [[ $# -lt 1 ]]; then
    echo "Usage: smooth_movavg <input_4D_nii[.gz]> [output_nii.gz] [win_sec] [--win-sec S] [--tr T]" >&2
    return 1
  fi
  IN="$1"; shift

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --win-sec) WIN_SEC="$2"; shift 2;;
      --tr) TR="$2"; shift 2;;
      -*)
        echo "Unknown option: $1" >&2; return 1;;
      *)
        if [[ -z "$OUT" ]]; then
          OUT="$1"
        elif [[ -z "$WIN_SEC" && "$1" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
          WIN_SEC="$1"
        else
          echo "Unexpected argument: $1" >&2; return 1
        fi
        shift
        ;;
    esac
  done

  # Requirements
  if ! command -v python3 >/dev/null 2>&1; then
    echo "Error: python3 not found in PATH." >&2
    return 2
  fi

  # Defaults
  if [[ -z "$OUT" ]]; then
    local fname="${IN##*/}" base="$fname"
    if [[ "$fname" == *.nii.gz ]]; then
      base="${fname%.nii.gz}"
    elif [[ "$fname" == *.nii ]]; then
      base="${fname%.nii}"
    fi
    local tag="${WIN_SEC:-60}"
    OUT="${base}_movavg_${tag}s.nii.gz"
  fi
  if [[ -z "$WIN_SEC" ]]; then WIN_SEC="60"; fi

  # Basic validation
  if ! [[ "$WIN_SEC" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    echo "Error: win-sec must be a positive number (got '$WIN_SEC')." >&2; return 1
  fi
  if ! [[ "$TR" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    echo "Error: TR must be a positive number (got '$TR')." >&2; return 1
  fi

  python3 - <<'PY' "$IN" "$OUT" "$WIN_SEC" "$TR"
import sys, numpy as np, nibabel as nib

inp, outp, win_sec_str, tr_str = sys.argv[1:5]
win_sec = float(win_sec_str)
TR = float(tr_str)
win = max(1, int(round(win_sec / TR)))

def moving_average_1d(x, win):
    k = np.ones(win, dtype=float) / win
    xpad = np.pad(x, (win//2, win-1-win//2), mode='edge')  # reduce edge shrinkage
    return np.convolve(xpad, k, mode='valid')

img = nib.load(inp)
data = img.get_fdata()   # X,Y,Z,T
T = data.shape[-1]
flat = data.reshape(-1, T)
sm = np.vstack([moving_average_1d(ts, win) for ts in flat]).reshape(data.shape)

nib.Nifti1Image(sm, img.affine, img.header).to_filename(outp)
print(f"Wrote: {outp}  (TR={TR}s, window={win_sec}s => {win} vols)")
PY
}
